//! Offline entitlement rules (spec §3.4). Pure functions of verified claims and a clock.
//!
//! * `kind = perpetual`: entitled forever. Builds dated after `upd` run in
//!   [`EntitlementMode::UpdatesExpired`]: fully functional, no new-feature gating, a banner
//!   offering the upgrade price.
//! * `kind = subscription | trial`: entitled while `now < sub_exp`. When a refresh comes back
//!   `403`, the host publishes [`revoked_entitlement`] immediately; on network errors it keeps
//!   re-evaluating the stored token until `sub_exp`.
//! * Never phone home more than once a day ([`should_refresh`]). Never block launch on the network.

use super::token::{verify_license_token, LicenseClaims, LicenseError, LicenseKind, TrustedKey};
use super::DAY_SECS;

/// How the app should behave for the current token.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, uniffi::Enum)]
pub enum EntitlementMode {
    /// Everything the plan grants.
    Full,
    /// Perpetual license whose feature-updates window closed before this build was made.
    /// Fully functional; show the upgrade offer (`perpetual_upgrade_after_updates_window`).
    UpdatesExpired,
    /// Subscription or trial period is over. Not entitled.
    Expired,
    /// The server refused to refresh (revoked / refunded / paused). Not entitled.
    Revoked,
}

impl EntitlementMode {
    /// Snake-case wire string (`full`, `updates_expired`, `expired`, `revoked`).
    pub fn as_str(&self) -> &'static str {
        match self {
            EntitlementMode::Full => "full",
            EntitlementMode::UpdatesExpired => "updates_expired",
            EntitlementMode::Expired => "expired",
            EntitlementMode::Revoked => "revoked",
        }
    }
}

/// The single `Entitlements` observable the UI binds to (spec §3.4 rule 5).
#[derive(Debug, Clone, PartialEq, Eq, uniffi::Record)]
pub struct Entitlement {
    /// May the user run Apps right now?
    pub entitled: bool,
    /// Behavioural mode; see [`EntitlementMode`].
    pub mode: EntitlementMode,
    /// Feature flags to gate premium tools on. Empty when not entitled.
    pub features: Vec<String>,
    /// Seconds until the subscription/trial ends (`0` once over). `None` for perpetual
    /// licenses, which never expire.
    pub seconds_remaining: Option<i64>,
    /// Plan wire string from the token.
    pub plan: String,
    /// License kind from the token.
    pub kind: LicenseKind,
}

/// Applies the §3.4 rules to verified claims.
///
/// * `now_unix` — current Unix time from the host clock.
/// * `build_date_unix` — the running build's release date (compare against `upd`).
#[uniffi::export]
pub fn evaluate(claims: LicenseClaims, now_unix: i64, build_date_unix: i64) -> Entitlement {
    match claims.kind {
        LicenseKind::Perpetual => {
            // "Feature updates allowed for builds whose buildDate <= upd." Without an `upd` claim
            // there is no window to be inside of, so the conservative answer is UpdatesExpired.
            let mode = match claims.upd {
                Some(upd) if build_date_unix <= upd => EntitlementMode::Full,
                _ => EntitlementMode::UpdatesExpired,
            };
            Entitlement {
                entitled: true,
                mode,
                features: claims.features,
                seconds_remaining: None,
                plan: claims.plan,
                kind: claims.kind,
            }
        }
        LicenseKind::Subscription | LicenseKind::Trial => match claims.sub_exp {
            Some(sub_exp) if now_unix < sub_exp => Entitlement {
                entitled: true,
                mode: EntitlementMode::Full,
                features: claims.features,
                seconds_remaining: Some(sub_exp - now_unix),
                plan: claims.plan,
                kind: claims.kind,
            },
            _ => Entitlement {
                entitled: false,
                mode: EntitlementMode::Expired,
                features: Vec::new(),
                seconds_remaining: Some(0),
                plan: claims.plan,
                kind: claims.kind,
            },
        },
    }
}

/// The entitlement to publish when `POST /v1/licenses/refresh` answers `403`
/// (revoked / refunded / paused): drop entitlement immediately (spec §3.4 rule 3).
#[uniffi::export]
pub fn revoked_entitlement(claims: LicenseClaims) -> Entitlement {
    Entitlement {
        entitled: false,
        mode: EntitlementMode::Revoked,
        features: Vec::new(),
        seconds_remaining: Some(0),
        plan: claims.plan,
        kind: claims.kind,
    }
}

/// `true` if the entitlement grants a feature flag (exact string match, e.g. `"cli"`).
#[uniffi::export]
pub fn has_feature(entitlement: Entitlement, feature: String) -> bool {
    entitlement.entitled && entitlement.features.contains(&feature)
}

/// Verify a stored token and evaluate it in one call, with a single clock reading.
#[uniffi::export]
pub fn verify_and_evaluate(
    token: String,
    trusted_keys: Vec<TrustedKey>,
    device_id: String,
    now_unix: i64,
    build_date_unix: i64,
) -> Result<Entitlement, LicenseError> {
    let claims = verify_license_token(token, trusted_keys, device_id, now_unix)?;
    Ok(evaluate(claims, now_unix, build_date_unix))
}

/// Should the host call `POST /v1/licenses/refresh` now?
///
/// * Never more than once per day per device (`last_refresh_unix` is the last *attempt*,
///   successful or not; pass `None` if never attempted).
/// * Subscriptions and trials refresh daily (rule 3).
/// * Perpetual licenses refresh once their token's `exp` has passed (rule 2).
#[uniffi::export]
pub fn should_refresh(
    claims: LicenseClaims,
    last_refresh_unix: Option<i64>,
    now_unix: i64,
) -> bool {
    if let Some(last) = last_refresh_unix {
        if now_unix - last < DAY_SECS {
            return false;
        }
    }
    match claims.kind {
        LicenseKind::Perpetual => now_unix >= claims.exp,
        LicenseKind::Subscription | LicenseKind::Trial => true,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::license::token::test_support::{sample_claims, sign, signing_key, trusted};

    const NOW: i64 = 1_800_000_000;
    const BUILD: i64 = NOW - 10 * DAY_SECS;

    fn perpetual(upd: Option<i64>) -> LicenseClaims {
        LicenseClaims {
            kind: LicenseKind::Perpetual,
            features: vec!["vm".into(), "bottles".into(), "no-ads".into()],
            exp: NOW + 30 * DAY_SECS,
            sub_exp: None,
            upd,
            iat: NOW,
            ..sample_claims("k", "dev")
        }
    }

    fn timed(kind: LicenseKind, sub_exp: Option<i64>) -> LicenseClaims {
        LicenseClaims {
            kind,
            plan: if kind == LicenseKind::Trial {
                "trial".into()
            } else {
                "pro".into()
            },
            features: vec!["vm".into(), "cli".into()],
            exp: NOW + 30 * DAY_SECS,
            sub_exp,
            upd: None,
            iat: NOW,
            ..sample_claims("k", "dev")
        }
    }

    #[test]
    fn perpetual_is_always_entitled_and_tracks_the_updates_window() {
        let claims = perpetual(Some(NOW + 365 * DAY_SECS));
        let e = evaluate(claims.clone(), NOW, BUILD);
        assert!(e.entitled);
        assert_eq!(e.mode, EntitlementMode::Full);
        assert_eq!(e.features, claims.features);
        assert_eq!(e.seconds_remaining, None);
        assert_eq!(e.plan, "standard");
        assert_eq!(e.kind, LicenseKind::Perpetual);

        // Build exactly on the boundary is still inside the window.
        let on_boundary = evaluate(claims.clone(), NOW, NOW + 365 * DAY_SECS);
        assert_eq!(on_boundary.mode, EntitlementMode::Full);
        // A newer build runs in updates-expired mode, fully functional, features intact.
        let later_build = evaluate(
            claims.clone(),
            NOW + 400 * DAY_SECS,
            NOW + 365 * DAY_SECS + 1,
        );
        assert!(later_build.entitled);
        assert_eq!(later_build.mode, EntitlementMode::UpdatesExpired);
        assert_eq!(later_build.features, claims.features);
        // Token expiry never revokes a perpetual license.
        let long_after = evaluate(claims.clone(), NOW + 10_000 * DAY_SECS, BUILD);
        assert!(long_after.entitled);
        assert_eq!(long_after.mode, EntitlementMode::Full);
        // Missing `upd` is treated conservatively.
        let no_window = evaluate(perpetual(None), NOW, BUILD);
        assert!(no_window.entitled);
        assert_eq!(no_window.mode, EntitlementMode::UpdatesExpired);
    }

    #[test]
    fn subscriptions_and_trials_expire_at_sub_exp() {
        for kind in [LicenseKind::Subscription, LicenseKind::Trial] {
            let sub_exp = NOW + 37 * DAY_SECS;
            let claims = timed(kind, Some(sub_exp));
            let e = evaluate(claims.clone(), NOW, BUILD);
            assert!(e.entitled);
            assert_eq!(e.mode, EntitlementMode::Full);
            assert_eq!(e.seconds_remaining, Some(37 * DAY_SECS));
            assert_eq!(e.features, claims.features);
            assert_eq!(e.kind, kind);
            // One second before the end: still entitled.
            let last_second = evaluate(claims.clone(), sub_exp - 1, BUILD);
            assert!(last_second.entitled);
            assert_eq!(last_second.seconds_remaining, Some(1));
            // At sub_exp: not entitled, features dropped.
            let over = evaluate(claims.clone(), sub_exp, BUILD);
            assert!(!over.entitled);
            assert_eq!(over.mode, EntitlementMode::Expired);
            assert!(over.features.is_empty());
            assert_eq!(over.seconds_remaining, Some(0));
            assert_eq!(over.plan, claims.plan);
            // Token `exp` passing while sub_exp is in the future keeps working (offline grace).
            let past_exp = evaluate(claims.clone(), claims.exp + 1, BUILD);
            assert!(past_exp.entitled);
            // No sub_exp at all -> not entitled.
            let no_end = evaluate(timed(kind, None), NOW, BUILD);
            assert!(!no_end.entitled);
            assert_eq!(no_end.mode, EntitlementMode::Expired);
        }
    }

    #[test]
    fn revoked_drops_everything_but_keeps_identity() {
        let claims = timed(LicenseKind::Subscription, Some(NOW + DAY_SECS));
        let e = revoked_entitlement(claims.clone());
        assert!(!e.entitled);
        assert_eq!(e.mode, EntitlementMode::Revoked);
        assert!(e.features.is_empty());
        assert_eq!(e.seconds_remaining, Some(0));
        assert_eq!(e.plan, "pro");
        assert_eq!(e.kind, LicenseKind::Subscription);
        assert!(!has_feature(e, "vm".into()));
    }

    #[test]
    fn has_feature_requires_entitlement() {
        let e = evaluate(
            timed(LicenseKind::Subscription, Some(NOW + DAY_SECS)),
            NOW,
            BUILD,
        );
        assert!(has_feature(e.clone(), "cli".into()));
        assert!(!has_feature(e.clone(), "mdm".into()));
        assert!(!has_feature(e, "CLI".into()));
        let expired = evaluate(timed(LicenseKind::Subscription, Some(NOW - 1)), NOW, BUILD);
        assert!(!has_feature(expired, "vm".into()));
    }

    #[test]
    fn verify_and_evaluate_pipeline() {
        let key = signing_key(9);
        let claims = perpetual(Some(NOW + DAY_SECS));
        let token = sign(&claims, &key);
        let e = verify_and_evaluate(
            token.clone(),
            vec![trusted("k", &key)],
            "dev".into(),
            NOW,
            BUILD,
        )
        .unwrap();
        assert!(e.entitled);
        assert_eq!(e.mode, EntitlementMode::Full);
        let err = verify_and_evaluate(
            token,
            vec![trusted("k", &key)],
            "someone-else".into(),
            NOW,
            BUILD,
        );
        assert_eq!(err, Err(LicenseError::DeviceMismatch));
    }

    #[test]
    fn refresh_policy_is_at_most_daily() {
        let sub = timed(LicenseKind::Subscription, Some(NOW + 30 * DAY_SECS));
        assert!(should_refresh(sub.clone(), None, NOW));
        assert!(!should_refresh(sub.clone(), Some(NOW - DAY_SECS + 1), NOW));
        assert!(should_refresh(sub.clone(), Some(NOW - DAY_SECS), NOW));
        let trial = timed(LicenseKind::Trial, Some(NOW + DAY_SECS));
        assert!(should_refresh(trial, Some(NOW - 2 * DAY_SECS), NOW));
        let perp = perpetual(Some(NOW + 365 * DAY_SECS));
        assert!(!should_refresh(perp.clone(), None, NOW));
        assert!(should_refresh(perp.clone(), None, perp.exp));
        assert!(!should_refresh(perp.clone(), Some(perp.exp - 1), perp.exp));
        assert!(should_refresh(
            perp.clone(),
            Some(perp.exp - DAY_SECS),
            perp.exp
        ));
    }

    #[test]
    fn mode_strings() {
        assert_eq!(EntitlementMode::Full.as_str(), "full");
        assert_eq!(EntitlementMode::UpdatesExpired.as_str(), "updates_expired");
        assert_eq!(EntitlementMode::Expired.as_str(), "expired");
        assert_eq!(EntitlementMode::Revoked.as_str(), "revoked");
    }
}
