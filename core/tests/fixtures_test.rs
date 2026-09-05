//! Cross-language fixtures: the server (`server/src/tools/fixtures.ts`) mints real tokens and
//! keys; this test proves the Rust core reaches the exact same verdicts. The Swift and Kotlin
//! layers run the same file through the generated bindings.

use std::collections::BTreeMap;
use std::fs;
use std::path::PathBuf;

use mirrorz_core::license::DAY_SECS;
use mirrorz_core::{
    evaluate, format_license_key, is_valid_license_key, normalize_license_key,
    trusted_key_is_valid, verify_and_evaluate, verify_license_token, EntitlementMode, LicenseError,
    LicenseKind, TrustedKey,
};
use serde::Deserialize;

#[derive(Deserialize)]
struct Fixtures {
    now: i64,
    device_id: String,
    trusted_keys: Vec<FixtureKey>,
    untrusted_key: FixtureKey,
    tokens: Vec<TokenFixture>,
    license_keys: KeyFixtures,
}

#[derive(Deserialize, Clone)]
struct FixtureKey {
    kid: String,
    x: String,
}

impl From<&FixtureKey> for TrustedKey {
    fn from(k: &FixtureKey) -> Self {
        TrustedKey {
            kid: k.kid.clone(),
            x_b64url: k.x.clone(),
        }
    }
}

#[derive(Deserialize)]
struct TokenFixture {
    name: String,
    token: String,
    expect: Expect,
}

#[derive(Deserialize)]
struct Expect {
    valid: bool,
    #[serde(default)]
    error: Option<String>,
    #[serde(default)]
    entitled_at_now: Option<bool>,
    #[serde(default)]
    mode_at_now: Option<String>,
    #[serde(default)]
    mode_after_updates_window: Option<String>,
    #[serde(default)]
    entitled_after_updates_window: Option<bool>,
    #[serde(default)]
    entitled_at: BTreeMap<String, bool>,
}

#[derive(Deserialize)]
struct KeyFixtures {
    valid: Vec<String>,
    invalid: Vec<String>,
    normalization: Vec<Normalization>,
}

#[derive(Deserialize)]
struct Normalization {
    input: String,
    normalized: String,
}

fn load() -> Fixtures {
    let path = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("tests")
        .join("fixtures")
        .join("license-fixtures.json");
    let text = fs::read_to_string(&path).unwrap_or_else(|e| panic!("read {}: {e}", path.display()));
    serde_json::from_str(&text).expect("fixtures parse")
}

fn error_for(code: &str) -> LicenseError {
    match code {
        "malformed" => LicenseError::Malformed,
        "unknown_kid" => LicenseError::UnknownKid,
        "bad_signature" => LicenseError::BadSignature,
        "device_mismatch" => LicenseError::DeviceMismatch,
        "version" => LicenseError::UnsupportedVersion,
        other => panic!("fixture uses unknown error code {other}"),
    }
}

fn mode_for(s: &str) -> EntitlementMode {
    match s {
        "full" => EntitlementMode::Full,
        "updates_expired" => EntitlementMode::UpdatesExpired,
        "expired" => EntitlementMode::Expired,
        "revoked" => EntitlementMode::Revoked,
        other => panic!("fixture uses unknown mode {other}"),
    }
}

#[test]
fn fixture_keys_are_usable() {
    let f = load();
    assert!(!f.trusted_keys.is_empty());
    for k in &f.trusted_keys {
        assert!(trusted_key_is_valid(k.into()), "{}", k.kid);
    }
    assert!(trusted_key_is_valid((&f.untrusted_key).into()));
    assert_ne!(f.untrusted_key.kid, f.trusted_keys[0].kid);
}

#[test]
fn every_token_fixture_matches_its_expected_outcome() {
    let f = load();
    let trusted: Vec<TrustedKey> = f.trusted_keys.iter().map(TrustedKey::from).collect();
    // The fixture's build is "today" relative to NOW.
    let build_date = f.now;
    let mut checked = 0;

    for t in &f.tokens {
        let result =
            verify_license_token(t.token.clone(), trusted.clone(), f.device_id.clone(), f.now);
        if !t.expect.valid {
            let expected = error_for(t.expect.error.as_deref().expect("error code"));
            assert_eq!(result, Err(expected), "token {}", t.name);
            checked += 1;
            continue;
        }

        let claims = result.unwrap_or_else(|e| panic!("token {} should verify: {e}", t.name));
        assert_eq!(claims.v, 1);
        assert_eq!(claims.dev, f.device_id);
        assert_eq!(claims.product, "mirrorz");
        assert_eq!(claims.kid, f.trusted_keys[0].kid);

        let now_ent = evaluate(claims.clone(), f.now, build_date);
        if let Some(expected) = t.expect.entitled_at_now {
            assert_eq!(
                now_ent.entitled, expected,
                "token {} entitled_at_now",
                t.name
            );
            if expected {
                assert_eq!(now_ent.features, claims.features);
                assert_eq!(now_ent.plan, claims.plan);
                assert_eq!(now_ent.kind, claims.kind);
            }
        }
        if let Some(mode) = &t.expect.mode_at_now {
            assert_eq!(now_ent.mode, mode_for(mode), "token {} mode_at_now", t.name);
        }
        if let Some(mode) = &t.expect.mode_after_updates_window {
            let upd = claims.upd.expect("perpetual fixture carries upd");
            let later = evaluate(claims.clone(), f.now, upd + DAY_SECS);
            assert_eq!(
                later.mode,
                mode_for(mode),
                "token {} mode_after_updates_window",
                t.name
            );
            // The boundary itself is still inside the window.
            assert_eq!(
                evaluate(claims.clone(), f.now, upd).mode,
                EntitlementMode::Full
            );
            if let Some(expected) = t.expect.entitled_after_updates_window {
                assert_eq!(
                    later.entitled, expected,
                    "token {} entitled_after_updates_window",
                    t.name
                );
                assert_eq!(
                    later.features, claims.features,
                    "updates-expired keeps features"
                );
            }
        }
        for (ts, expected) in &t.expect.entitled_at {
            let at: i64 = ts.parse().expect("timestamp key");
            let e = evaluate(claims.clone(), at, build_date);
            assert_eq!(e.entitled, *expected, "token {} entitled_at {ts}", t.name);
            if !expected {
                assert_eq!(e.mode, EntitlementMode::Expired);
                assert!(e.features.is_empty());
            }
        }
        // Kind-specific sanity that mirrors the server's claim assembly.
        match claims.kind {
            LicenseKind::Perpetual => {
                assert!(claims.upd.is_some());
                assert_eq!(now_ent.seconds_remaining, None);
            }
            LicenseKind::Subscription | LicenseKind::Trial => {
                let sub_exp = claims.sub_exp.expect("sub_exp");
                assert_eq!(now_ent.seconds_remaining, Some(sub_exp - f.now));
            }
        }
        // The one-shot pipeline agrees with the two-step one.
        let piped = verify_and_evaluate(
            t.token.clone(),
            trusted.clone(),
            f.device_id.clone(),
            f.now,
            build_date,
        )
        .unwrap();
        assert_eq!(piped, now_ent, "token {} verify_and_evaluate", t.name);
        checked += 1;
    }
    assert_eq!(checked, f.tokens.len());
    assert!(
        checked >= 8,
        "fixture file should carry the full token matrix"
    );
}

#[test]
fn trusted_tokens_fail_against_the_untrusted_key() {
    let f = load();
    let wrong_kid = vec![TrustedKey::from(&f.untrusted_key)];
    // Same key material but the trusted kid: proves the signature check, not just the kid lookup.
    let impostor = vec![TrustedKey {
        kid: f.trusted_keys[0].kid.clone(),
        x_b64url: f.untrusted_key.x.clone(),
    }];
    for t in f.tokens.iter().filter(|t| t.expect.valid) {
        assert_eq!(
            verify_license_token(
                t.token.clone(),
                wrong_kid.clone(),
                f.device_id.clone(),
                f.now
            ),
            Err(LicenseError::UnknownKid),
            "token {}",
            t.name
        );
        assert_eq!(
            verify_license_token(
                t.token.clone(),
                impostor.clone(),
                f.device_id.clone(),
                f.now
            ),
            Err(LicenseError::BadSignature),
            "token {}",
            t.name
        );
        assert_eq!(
            verify_license_token(t.token.clone(), vec![], f.device_id.clone(), f.now),
            Err(LicenseError::UnknownKid),
            "token {}",
            t.name
        );
    }
}

#[test]
fn every_valid_license_key_validates_and_round_trips() {
    let f = load();
    assert!(f.license_keys.valid.len() >= 50);
    for key in &f.license_keys.valid {
        assert!(is_valid_license_key(key.clone()), "{key}");
        let canonical = normalize_license_key(key.clone()).unwrap_or_else(|| panic!("{key}"));
        assert_eq!(canonical.len(), 25, "{key}");
        assert_eq!(canonical, key.replace("MZ-", "").replace('-', ""), "{key}");
        assert_eq!(format_license_key(canonical.clone()), *key, "{key}");
        // Already-canonical input normalizes to itself.
        assert_eq!(normalize_license_key(canonical.clone()), Some(canonical));
    }
}

#[test]
fn every_invalid_license_key_is_rejected() {
    let f = load();
    assert!(f.license_keys.invalid.len() >= 20);
    for key in &f.license_keys.invalid {
        assert!(
            !is_valid_license_key(key.clone()),
            "{key:?} should be invalid"
        );
        assert_eq!(normalize_license_key(key.clone()), None, "{key:?}");
    }
}

#[test]
fn every_normalization_case_matches_the_server() {
    let f = load();
    assert!(f.license_keys.normalization.len() >= 10);
    for n in &f.license_keys.normalization {
        assert_eq!(
            normalize_license_key(n.input.clone()).as_deref(),
            Some(n.normalized.as_str()),
            "{:?}",
            n.input
        );
        assert!(is_valid_license_key(n.input.clone()));
    }
}
