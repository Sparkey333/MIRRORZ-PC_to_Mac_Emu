//! Signed device tokens: the offline entitlement (spec §3.4).
//!
//! ```text
//! MZL1.<base64url(JSON claims)>.<base64url(Ed25519 signature over UTF-8 "MZL1.<payload>")>
//! ```
//!
//! Mirrors `server/src/license/token.ts`. The client verifies with an *embedded* list of
//! public keys (`[{kid, x}]`, raw 32-byte Ed25519, base64url) and rejects a token whose
//! `kid` is unknown or whose `dev` is not the local device id. Verification is a pure
//! function: no clock, no network.

use base64::{alphabet, engine, Engine as _};
use ed25519_dalek::{Signature, VerifyingKey, PUBLIC_KEY_LENGTH};
use serde::{Deserialize, Serialize};
use serde_json::Value;

/// Token format identifier; also the first segment of every token.
pub const TOKEN_PREFIX: &str = "MZL1";

/// base64url without padding (what Node's `Buffer.toString('base64url')` emits); decoding is
/// padding-indifferent so a token that picked up `=` in transit still verifies.
const B64URL: engine::GeneralPurpose = engine::GeneralPurpose::new(
    &alphabet::URL_SAFE,
    engine::GeneralPurposeConfig::new()
        .with_encode_padding(false)
        .with_decode_padding_mode(engine::DecodePaddingMode::Indifferent),
);

/// Decodes base64url (padding optional). `None` on any invalid character.
pub fn b64url_decode(input: &str) -> Option<Vec<u8>> {
    B64URL.decode(input).ok()
}

/// Encodes base64url without padding.
pub fn b64url_encode(bytes: &[u8]) -> String {
    B64URL.encode(bytes)
}

/// JSON numbers as JavaScript emits them: integers, but tolerate an integral float
/// (`1.0`) because the producer has no integer type. Non-integral values are rejected.
mod lenient_num {
    use serde::de::{self, Deserialize, Deserializer};

    fn integral(v: serde_json::Value) -> Option<i64> {
        match v {
            serde_json::Value::Number(n) => n.as_i64().or_else(|| {
                n.as_f64()
                    .filter(|f| f.fract() == 0.0 && f.abs() < 9.0e15)
                    .map(|f| f as i64)
            }),
            _ => None,
        }
    }

    pub fn u32<'de, D: Deserializer<'de>>(d: D) -> Result<u32, D::Error> {
        let v = serde_json::Value::deserialize(d)?;
        integral(v)
            .and_then(|i| u32::try_from(i).ok())
            .ok_or_else(|| de::Error::custom("expected an unsigned 32-bit integer"))
    }

    pub fn i64<'de, D: Deserializer<'de>>(d: D) -> Result<i64, D::Error> {
        let v = serde_json::Value::deserialize(d)?;
        integral(v).ok_or_else(|| de::Error::custom("expected an integer"))
    }

    pub fn opt_i64<'de, D: Deserializer<'de>>(d: D) -> Result<Option<i64>, D::Error> {
        let v = serde_json::Value::deserialize(d)?;
        if v.is_null() {
            return Ok(None);
        }
        integral(v)
            .map(Some)
            .ok_or_else(|| de::Error::custom("expected an integer or null"))
    }
}

/// A signing key the app trusts. Hosts embed the list (also served at
/// `GET /.well-known/mirrorz-license-key.json`, `keys[].kid` / `keys[].x`).
#[derive(Debug, Clone, PartialEq, Eq, uniffi::Record)]
pub struct TrustedKey {
    /// Key id: `sha256(x)` hex, first 16 chars. Tokens carry it as `kid`.
    pub kid: String,
    /// Raw 32-byte Ed25519 public key, base64url (the JWK `x` member).
    pub x_b64url: String,
}

/// What kind of license the token represents.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, uniffi::Enum)]
#[serde(rename_all = "lowercase")]
pub enum LicenseKind {
    /// Bought once; entitled forever, feature updates for builds dated `<= upd`.
    Perpetual,
    /// Auto-renewing; entitled while `now < sub_exp`.
    Subscription,
    /// 14-day trial; entitled while `now < sub_exp`.
    Trial,
}

impl LicenseKind {
    /// Wire string (`perpetual`, `subscription`, `trial`).
    pub fn as_str(&self) -> &'static str {
        match self {
            LicenseKind::Perpetual => "perpetual",
            LicenseKind::Subscription => "subscription",
            LicenseKind::Trial => "trial",
        }
    }
}

/// Claims embedded in a signed device token. Field names are the wire names
/// (`server/src/license/token.ts` `LicenseClaims`). All times are Unix seconds.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, uniffi::Record)]
pub struct LicenseClaims {
    /// Claims version; only `1` is understood.
    #[serde(deserialize_with = "lenient_num::u32")]
    pub v: u32,
    /// Id of the key that signed the token.
    pub kid: String,
    /// License id (opaque).
    pub lid: String,
    /// License kind.
    pub kind: LicenseKind,
    /// Plan wire string (`standard`, `pro`, `business`, `trial`).
    pub plan: String,
    /// Always `mirrorz`.
    pub product: String,
    /// Feature flags granted to this device. Gate premium tools on these.
    #[serde(default)]
    pub features: Vec<String>,
    /// Device id the token was issued to; must equal the local device id.
    pub dev: String,
    /// Maximum number of devices this license may activate.
    #[serde(deserialize_with = "lenient_num::u32")]
    pub max_dev: u32,
    /// Issued-at.
    #[serde(deserialize_with = "lenient_num::i64")]
    pub iat: i64,
    /// Token expiry. Only schedules a background refresh — it never revokes entitlement offline.
    #[serde(deserialize_with = "lenient_num::i64")]
    pub exp: i64,
    /// Subscription / trial end (period end + grace). Present for `subscription` and `trial`.
    #[serde(
        default,
        deserialize_with = "lenient_num::opt_i64",
        skip_serializing_if = "Option::is_none"
    )]
    pub sub_exp: Option<i64>,
    /// End of the feature-updates window. Present for `perpetual`.
    #[serde(
        default,
        deserialize_with = "lenient_num::opt_i64",
        skip_serializing_if = "Option::is_none"
    )]
    pub upd: Option<i64>,
}

/// Why a token was rejected. Variant names map to the server's error codes (see
/// [`LicenseError::code`]) so logs read the same on both sides.
#[derive(Debug, Clone, PartialEq, Eq, thiserror::Error, uniffi::Error)]
pub enum LicenseError {
    /// Not three dot-separated segments, wrong prefix, undecodable payload, or claims that do not
    /// parse.
    #[error("malformed license token")]
    Malformed,
    /// No embedded key matches the token's `kid` (or the matching embedded key is itself invalid).
    #[error("license token signed by an unknown key")]
    UnknownKid,
    /// Signature does not verify (tampered payload or a foreign signer).
    #[error("license token signature is invalid")]
    BadSignature,
    /// `dev` is not this device.
    #[error("license token was issued to a different device")]
    DeviceMismatch,
    /// `v` is not `1`.
    #[error("license token version is not supported by this build")]
    UnsupportedVersion,
}

impl LicenseError {
    /// Server-compatible short code: `malformed`, `unknown_kid`, `bad_signature`,
    /// `device_mismatch`, `version`.
    pub fn code(&self) -> &'static str {
        match self {
            LicenseError::Malformed => "malformed",
            LicenseError::UnknownKid => "unknown_kid",
            LicenseError::BadSignature => "bad_signature",
            LicenseError::DeviceMismatch => "device_mismatch",
            LicenseError::UnsupportedVersion => "version",
        }
    }
}

/// Splits `MZL1.<payload>.<sig>` into its two base64url segments.
fn split_token(token: &str) -> Result<(&str, &str), LicenseError> {
    let parts: Vec<&str> = token.split('.').collect();
    if parts.len() != 3 || parts[0] != TOKEN_PREFIX {
        return Err(LicenseError::Malformed);
    }
    Ok((parts[1], parts[2]))
}

/// Decodes the payload segment into a JSON object (no signature check).
fn decode_payload(payload_b64: &str) -> Result<serde_json::Map<String, Value>, LicenseError> {
    let bytes = b64url_decode(payload_b64).ok_or(LicenseError::Malformed)?;
    match serde_json::from_slice::<Value>(&bytes) {
        Ok(Value::Object(map)) => Ok(map),
        _ => Err(LicenseError::Malformed),
    }
}

/// Parses an embedded public key. `None` if it is not 32 base64url bytes or not a valid point.
pub fn parse_verifying_key(x_b64url: &str) -> Option<VerifyingKey> {
    let bytes = b64url_decode(x_b64url)?;
    let array: [u8; PUBLIC_KEY_LENGTH] = bytes.try_into().ok()?;
    VerifyingKey::from_bytes(&array).ok()
}

/// `true` if the trusted key decodes to a usable Ed25519 public key. Hosts should assert this
/// over their embedded key list in a unit test so a bad paste is caught at build time.
#[uniffi::export]
pub fn trusted_key_is_valid(key: TrustedKey) -> bool {
    !key.kid.is_empty() && parse_verifying_key(&key.x_b64url).is_some()
}

/// Verifies a device token and returns its claims.
///
/// Order of checks (each maps to one [`LicenseError`]):
/// 1. structure — three segments, `MZL1` prefix, base64url JSON object payload → `Malformed`;
/// 2. `kid` must name one of `trusted_keys` → `UnknownKid`;
/// 3. Ed25519 signature over the UTF-8 bytes of `"MZL1.<payload>"` → `BadSignature`;
/// 4. `v == 1` → `UnsupportedVersion`;
/// 5. claims parse into [`LicenseClaims`] → `Malformed`;
/// 6. `dev == device_id` → `DeviceMismatch`.
///
/// `now_unix` is deliberately **not** used to reject anything: per spec §3.4 the token's `exp`
/// only schedules a refresh and expiry of a subscription is an *entitlement* question answered by
/// [`crate::license::entitlement::evaluate`] with the same clock reading. The parameter is part of
/// the FFI signature so hosts thread one timestamp through the whole pipeline
/// (see [`crate::license::entitlement::verify_and_evaluate`]) and so a future clock-based
/// policy can be added without breaking bindings.
#[uniffi::export]
pub fn verify_license_token(
    token: String,
    trusted_keys: Vec<TrustedKey>,
    device_id: String,
    now_unix: i64,
) -> Result<LicenseClaims, LicenseError> {
    let _ = now_unix;
    let (payload_b64, sig_b64) = split_token(&token)?;
    let payload = decode_payload(payload_b64)?;

    let kid = payload
        .get("kid")
        .and_then(Value::as_str)
        .ok_or(LicenseError::Malformed)?;
    let trusted = trusted_keys
        .iter()
        .find(|k| k.kid == kid)
        .ok_or(LicenseError::UnknownKid)?;
    let verifying_key = parse_verifying_key(&trusted.x_b64url).ok_or(LicenseError::UnknownKid)?;

    let sig_bytes = b64url_decode(sig_b64).ok_or(LicenseError::BadSignature)?;
    let signature = Signature::from_slice(&sig_bytes).map_err(|_| LicenseError::BadSignature)?;
    let signing_input = format!("{TOKEN_PREFIX}.{payload_b64}");
    verifying_key
        .verify_strict(signing_input.as_bytes(), &signature)
        .map_err(|_| LicenseError::BadSignature)?;

    let version_ok = matches!(payload.get("v"), Some(Value::Number(n)) if n.as_f64() == Some(1.0));
    if !version_ok {
        return Err(LicenseError::UnsupportedVersion);
    }

    let claims: LicenseClaims =
        serde_json::from_value(Value::Object(payload)).map_err(|_| LicenseError::Malformed)?;
    if claims.dev != device_id {
        return Err(LicenseError::DeviceMismatch);
    }
    Ok(claims)
}

/// Decodes claims **without** checking the signature. Only for display/diagnostics
/// (e.g. showing which `kid` a stored token uses); never gate anything on the result.
#[uniffi::export]
pub fn decode_license_token_unverified(token: String) -> Result<LicenseClaims, LicenseError> {
    let (payload_b64, _) = split_token(&token)?;
    let payload = decode_payload(payload_b64)?;
    serde_json::from_value(Value::Object(payload)).map_err(|_| LicenseError::Malformed)
}

/// `true` once the token's `exp` has passed: time to call `POST /v1/licenses/refresh` in the
/// background. Never blocks launch and never changes entitlement by itself.
#[uniffi::export]
pub fn token_needs_refresh(claims: LicenseClaims, now_unix: i64) -> bool {
    now_unix >= claims.exp
}

#[cfg(test)]
pub(crate) mod test_support {
    //! Helpers to mint tokens in tests. The real signer lives on the server.
    use super::*;
    use ed25519_dalek::{Signer, SigningKey};

    /// Deterministic signing key from a seed byte.
    pub fn signing_key(seed: u8) -> SigningKey {
        SigningKey::from_bytes(&[seed; 32])
    }

    /// `TrustedKey` for a signing key, with the server's `kid` derivation
    /// (first 16 hex chars of sha256 over the base64url public key) replaced by a
    /// test-local scheme: the kid is caller-supplied.
    pub fn trusted(kid: &str, key: &SigningKey) -> TrustedKey {
        TrustedKey {
            kid: kid.to_string(),
            x_b64url: b64url_encode(&key.verifying_key().to_bytes()),
        }
    }

    /// Signs arbitrary JSON claims exactly like `signLicenseToken` on the server.
    pub fn sign_json(claims: &Value, key: &SigningKey) -> String {
        let payload = b64url_encode(claims.to_string().as_bytes());
        let signing_input = format!("{TOKEN_PREFIX}.{payload}");
        let sig = key.sign(signing_input.as_bytes());
        format!("{signing_input}.{}", b64url_encode(&sig.to_bytes()))
    }

    /// Signs typed claims.
    pub fn sign(claims: &LicenseClaims, key: &SigningKey) -> String {
        sign_json(&serde_json::to_value(claims).unwrap(), key)
    }

    /// A representative perpetual token's claims.
    pub fn sample_claims(kid: &str, dev: &str) -> LicenseClaims {
        LicenseClaims {
            v: 1,
            kid: kid.to_string(),
            lid: "lic_1".into(),
            kind: LicenseKind::Perpetual,
            plan: "standard".into(),
            product: "mirrorz".into(),
            features: vec!["vm".into()],
            dev: dev.to_string(),
            max_dev: 3,
            iat: 1000,
            exp: 2000,
            sub_exp: None,
            upd: Some(5000),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::test_support::*;
    use super::*;

    const DEV: &str = "device-1234";

    #[test]
    fn sign_verify_roundtrip_with_the_raw_public_key_a_client_would_embed() {
        let key = signing_key(1);
        let trusted_key = trusted("k", &key);
        assert!(trusted_key_is_valid(trusted_key.clone()));
        let claims = sample_claims("k", DEV);
        let token = sign(&claims, &key);
        assert!(token.starts_with("MZL1."));
        let out = verify_license_token(token.clone(), vec![trusted_key], DEV.into(), 1500).unwrap();
        assert_eq!(out, claims);
        assert_eq!(decode_license_token_unverified(token).unwrap(), claims);
    }

    #[test]
    fn tampering_and_wrong_keys_are_rejected() {
        let key = signing_key(1);
        let other = signing_key(2);
        let claims = sample_claims("k", DEV);
        let token = sign(&claims, &key);
        let keys = vec![trusted("k", &key)];

        // Foreign signer with the trusted kid.
        let foreign = sign(&claims, &other);
        assert_eq!(
            verify_license_token(foreign, keys.clone(), DEV.into(), 0),
            Err(LicenseError::BadSignature)
        );
        // Forged payload, original signature.
        let parts: Vec<&str> = token.split('.').collect();
        let mut forged_claims = claims.clone();
        forged_claims.plan = "pro".into();
        let forged_payload =
            b64url_encode(serde_json::to_string(&forged_claims).unwrap().as_bytes());
        let forged = format!("{}.{}.{}", parts[0], forged_payload, parts[2]);
        assert_eq!(
            verify_license_token(forged, keys.clone(), DEV.into(), 0),
            Err(LicenseError::BadSignature)
        );
        // Wrong prefix / wrong segment count.
        let bad_prefix = format!("X.{}.{}", parts[1], parts[2]);
        assert_eq!(
            verify_license_token(bad_prefix, keys.clone(), DEV.into(), 0),
            Err(LicenseError::Malformed)
        );
        assert_eq!(
            verify_license_token("MZL1.abc".into(), keys.clone(), DEV.into(), 0),
            Err(LicenseError::Malformed)
        );
        assert_eq!(
            verify_license_token(format!("{token}.extra"), keys.clone(), DEV.into(), 0),
            Err(LicenseError::Malformed)
        );
        // Garbage signature bytes.
        let short_sig = format!("{}.{}.{}", parts[0], parts[1], "AAAA");
        assert_eq!(
            verify_license_token(short_sig, keys.clone(), DEV.into(), 0),
            Err(LicenseError::BadSignature)
        );
        let bad_b64 = format!("{}.{}.{}", parts[0], parts[1], "!!!!");
        assert_eq!(
            verify_license_token(bad_b64, keys, DEV.into(), 0),
            Err(LicenseError::BadSignature)
        );
    }

    #[test]
    fn unknown_kid_and_device_mismatch() {
        let key = signing_key(3);
        let claims = sample_claims("k", DEV);
        let token = sign(&claims, &key);
        assert_eq!(
            verify_license_token(token.clone(), vec![trusted("other", &key)], DEV.into(), 0),
            Err(LicenseError::UnknownKid)
        );
        assert_eq!(
            verify_license_token(token.clone(), vec![], DEV.into(), 0),
            Err(LicenseError::UnknownKid)
        );
        assert_eq!(
            verify_license_token(token, vec![trusted("k", &key)], "device-other".into(), 0),
            Err(LicenseError::DeviceMismatch)
        );
        // A matching kid whose embedded key is garbage cannot verify anything -> UnknownKid.
        let broken = TrustedKey {
            kid: "k".into(),
            x_b64url: "not-a-key".into(),
        };
        assert!(!trusted_key_is_valid(broken.clone()));
        let token = sign(&claims, &key);
        assert_eq!(
            verify_license_token(token, vec![broken], DEV.into(), 0),
            Err(LicenseError::UnknownKid)
        );
    }

    #[test]
    fn version_and_claim_shape_checks() {
        let key = signing_key(4);
        let keys = vec![trusted("k", &key)];
        let mut v2 = serde_json::to_value(sample_claims("k", DEV)).unwrap();
        v2["v"] = serde_json::json!(2);
        assert_eq!(
            verify_license_token(sign_json(&v2, &key), keys.clone(), DEV.into(), 0),
            Err(LicenseError::UnsupportedVersion)
        );
        let mut no_v = serde_json::to_value(sample_claims("k", DEV)).unwrap();
        no_v.as_object_mut().unwrap().remove("v");
        assert_eq!(
            verify_license_token(sign_json(&no_v, &key), keys.clone(), DEV.into(), 0),
            Err(LicenseError::UnsupportedVersion)
        );
        // Integral floats are still integers (JavaScript has no integer type).
        let mut v_float = serde_json::to_value(sample_claims("k", DEV)).unwrap();
        v_float["v"] = serde_json::json!(1.0);
        v_float["exp"] = serde_json::json!(2000.0);
        v_float["upd"] = serde_json::json!(5000.0);
        v_float["max_dev"] = serde_json::json!(3.0);
        let parsed =
            verify_license_token(sign_json(&v_float, &key), keys.clone(), DEV.into(), 0).unwrap();
        assert_eq!(parsed, sample_claims("k", DEV));
        // Fractional or negative values are not.
        let mut frac = serde_json::to_value(sample_claims("k", DEV)).unwrap();
        frac["exp"] = serde_json::json!(2000.5);
        assert_eq!(
            verify_license_token(sign_json(&frac, &key), keys.clone(), DEV.into(), 0),
            Err(LicenseError::Malformed)
        );
        let mut neg = serde_json::to_value(sample_claims("k", DEV)).unwrap();
        neg["max_dev"] = serde_json::json!(-1);
        assert_eq!(
            verify_license_token(sign_json(&neg, &key), keys.clone(), DEV.into(), 0),
            Err(LicenseError::Malformed)
        );
        // An explicit null optional claim is the same as an absent one.
        let mut null_upd = serde_json::to_value(sample_claims("k", DEV)).unwrap();
        null_upd["upd"] = serde_json::Value::Null;
        let parsed =
            verify_license_token(sign_json(&null_upd, &key), keys.clone(), DEV.into(), 0).unwrap();
        assert_eq!(parsed.upd, None);
        // Unknown kind string -> claims do not parse.
        let mut bad_kind = serde_json::to_value(sample_claims("k", DEV)).unwrap();
        bad_kind["kind"] = serde_json::json!("lifetime");
        assert_eq!(
            verify_license_token(sign_json(&bad_kind, &key), keys.clone(), DEV.into(), 0),
            Err(LicenseError::Malformed)
        );
        // Missing required claim.
        let mut no_lid = serde_json::to_value(sample_claims("k", DEV)).unwrap();
        no_lid.as_object_mut().unwrap().remove("lid");
        assert_eq!(
            verify_license_token(sign_json(&no_lid, &key), keys.clone(), DEV.into(), 0),
            Err(LicenseError::Malformed)
        );
        // Payload that is valid JSON but not an object.
        let array_payload = b64url_encode(b"[1,2,3]");
        assert_eq!(
            verify_license_token(
                format!("MZL1.{array_payload}.AAAA"),
                keys.clone(),
                DEV.into(),
                0
            ),
            Err(LicenseError::Malformed)
        );
        // Missing kid is structural.
        let mut no_kid = serde_json::to_value(sample_claims("k", DEV)).unwrap();
        no_kid.as_object_mut().unwrap().remove("kid");
        assert_eq!(
            verify_license_token(sign_json(&no_kid, &key), keys.clone(), DEV.into(), 0),
            Err(LicenseError::Malformed)
        );
        // Unknown extra claims are tolerated (forward compatibility).
        let mut extra = serde_json::to_value(sample_claims("k", DEV)).unwrap();
        extra["future_claim"] = serde_json::json!({"x": 1});
        assert!(verify_license_token(sign_json(&extra, &key), keys, DEV.into(), 0).is_ok());
    }

    #[test]
    fn padded_base64url_still_verifies() {
        let key = signing_key(5);
        let token = sign(&sample_claims("k", DEV), &key);
        let parts: Vec<&str> = token.split('.').collect();
        let pad = |s: &str| {
            let mut s = s.to_string();
            while s.len() % 4 != 0 {
                s.push('=');
            }
            s
        };
        let padded = format!("{}.{}.{}", parts[0], pad(parts[1]), pad(parts[2]));
        assert!(verify_license_token(padded, vec![trusted("k", &key)], DEV.into(), 0).is_ok());
    }

    #[test]
    fn needs_refresh_follows_exp() {
        let claims = sample_claims("k", DEV);
        assert!(!token_needs_refresh(claims.clone(), 1999));
        assert!(token_needs_refresh(claims.clone(), 2000));
        assert!(token_needs_refresh(claims, 9999));
    }

    #[test]
    fn error_codes_match_the_server() {
        assert_eq!(LicenseError::Malformed.code(), "malformed");
        assert_eq!(LicenseError::UnknownKid.code(), "unknown_kid");
        assert_eq!(LicenseError::BadSignature.code(), "bad_signature");
        assert_eq!(LicenseError::DeviceMismatch.code(), "device_mismatch");
        assert_eq!(LicenseError::UnsupportedVersion.code(), "version");
        assert_eq!(LicenseKind::Subscription.as_str(), "subscription");
        assert_eq!(
            LicenseError::BadSignature.to_string(),
            "license token signature is invalid"
        );
    }
}
