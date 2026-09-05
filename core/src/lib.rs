//! # mirrorz-core
//!
//! The shared "brain" of MIRRORZ. One Rust crate, consumed by:
//!
//! * the macOS app and the iOS companion through UniFFI-generated Swift bindings
//!   (module `MirrorzCore`), and
//! * the Android companion through UniFFI-generated Kotlin bindings
//!   (package `com.mirrorz.core`).
//!
//! Everything here is a pure function of its inputs: no I/O, no clocks, no network,
//! no telemetry. Hosts pass in the current time, the local device id, the embedded
//! public keys and the compatibility catalog JSON; the core returns decisions.
//!
//! Modules:
//!
//! | Module | Purpose | Reference implementation |
//! |---|---|---|
//! | [`license::key`] | Human license keys (`MZ-XXXXX-…`), normalization + Luhn mod 32 check | `server/src/license/keyformat.ts` |
//! | [`license::token`] | Ed25519 device tokens (`MZL1.<payload>.<sig>`) | `server/src/license/token.ts` |
//! | [`license::entitlement`] | Offline entitlement rules (spec §3.4) | `docs/spec/platform-contracts.md` |
//! | [`license::plans`] | Plan → feature-flag table | `server/src/license/plans.ts` |
//! | [`router`] | App Router: picks a Runtime and Fix-ups for an App | `server/src/compat/service.ts` (`routeUnknown`) |
//! | [`compat`] | Compatibility Database catalog (search / get / presets) | `server/src/compat/service.ts` + `seed.json` |
//! | [`machine`] | Machine (VM) configuration validation | — |

pub mod compat;
pub mod license;
pub mod machine;
pub mod router;

pub use compat::{
    bundled_compat_seed_json, CompatApp, CompatCatalog, CompatError, CompatFixup, CompatPreset,
    CompatRating, CompatRequirements,
};
pub use license::entitlement::{
    evaluate, has_feature, revoked_entitlement, should_refresh, verify_and_evaluate, Entitlement,
    EntitlementMode,
};
pub use license::key::{
    display_license_key, format_license_key, is_valid_license_key, normalize_license_key,
};
pub use license::plans::{features_for_plan, is_plan_id, plan_features, PlanId};
pub use license::token::{
    decode_license_token_unverified, token_needs_refresh, trusted_key_is_valid,
    verify_license_token, LicenseClaims, LicenseError, LicenseKind, TrustedKey,
};
pub use machine::{
    check_machine_config, validate_machine_config, GuestOs, MachineProblem, ProblemSeverity,
};
pub use router::{route, Arch, RouteDecision, RouteInput, Runtime};

/// Semantic version of this core crate. MIRRORZ ships one version number across
/// every app (spec §7); hosts surface this in Settings › Advanced for support.
#[uniffi::export]
pub fn core_version() -> String {
    env!("CARGO_PKG_VERSION").to_string()
}

uniffi::setup_scaffolding!("mirrorz_core");

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn core_version_is_semver() {
        let v = core_version();
        let parts: Vec<&str> = v.split('.').collect();
        assert_eq!(parts.len(), 3, "{v}");
        for p in parts {
            p.parse::<u32>().expect("numeric component");
        }
    }
}
