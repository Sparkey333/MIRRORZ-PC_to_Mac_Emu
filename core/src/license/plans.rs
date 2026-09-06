//! Plan → feature-flag table. Mirrors `server/src/license/plans.ts`.
//!
//! Feature flags ship *inside* tokens; the client gates premium tools on the
//! `features` list of the verified token (see [`crate::license::entitlement`]).
//! This table exists so the UI can show what a plan *would* unlock on a feature's
//! locked state (spec §5.4: upgrades live only in Settings › License and on locked states).

/// Plan identifiers understood by the server.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, uniffi::Enum)]
pub enum PlanId {
    /// MIRRORZ Standard.
    Standard,
    /// MIRRORZ Pro.
    Pro,
    /// MIRRORZ Business (per-seat, direct only).
    Business,
    /// 14-day trial, one per device.
    Trial,
}

/// Features of the trial plan.
pub const TRIAL_FEATURES: &[&str] = &["vm", "bottles", "coherence", "compat-db"];
/// Features of the Standard plan.
pub const STANDARD_FEATURES: &[&str] = &[
    "vm",
    "bottles",
    "coherence",
    "snapshots",
    "compat-db",
    "cad-presets",
    "mobile-companion",
    "no-ads",
];
/// Features of the Pro plan.
pub const PRO_FEATURES: &[&str] = &[
    "vm",
    "bottles",
    "coherence",
    "snapshots",
    "compat-db",
    "cad-presets",
    "mobile-companion",
    "no-ads",
    "cli",
    "api",
    "nested-virt",
    "linked-clones",
    "pro-tools",
    "cloud-sync",
    "priority-support",
    "network-lab",
];
/// Features of the Business plan.
pub const BUSINESS_FEATURES: &[&str] = &[
    "vm",
    "bottles",
    "coherence",
    "snapshots",
    "compat-db",
    "cad-presets",
    "mobile-companion",
    "no-ads",
    "cli",
    "api",
    "nested-virt",
    "linked-clones",
    "pro-tools",
    "cloud-sync",
    "priority-support",
    "network-lab",
    "mdm",
    "sso",
    "volume-licensing",
    "golden-images",
    "audit-log",
];

impl PlanId {
    /// The wire string (`standard`, `pro`, `business`, `trial`).
    pub fn as_str(&self) -> &'static str {
        match self {
            PlanId::Standard => "standard",
            PlanId::Pro => "pro",
            PlanId::Business => "business",
            PlanId::Trial => "trial",
        }
    }

    /// Parses the wire string. Case-sensitive, like the server.
    pub fn parse(plan: &str) -> Option<PlanId> {
        match plan {
            "standard" => Some(PlanId::Standard),
            "pro" => Some(PlanId::Pro),
            "business" => Some(PlanId::Business),
            "trial" => Some(PlanId::Trial),
            _ => None,
        }
    }

    /// Feature flags the plan grants.
    pub fn features(&self) -> &'static [&'static str] {
        match self {
            PlanId::Trial => TRIAL_FEATURES,
            PlanId::Standard => STANDARD_FEATURES,
            PlanId::Pro => PRO_FEATURES,
            PlanId::Business => BUSINESS_FEATURES,
        }
    }
}

/// `true` if the string is one of the four plan identifiers.
#[uniffi::export]
pub fn is_plan_id(plan: String) -> bool {
    PlanId::parse(&plan).is_some()
}

/// Feature flags for a plan wire string. Unknown plans fall back to Standard, exactly like
/// `featuresFor` on the server.
#[uniffi::export]
pub fn features_for_plan(plan: String) -> Vec<String> {
    let id = PlanId::parse(&plan).unwrap_or(PlanId::Standard);
    plan_features(id)
}

/// Feature flags for a typed plan id.
#[uniffi::export]
pub fn plan_features(plan: PlanId) -> Vec<String> {
    plan.features().iter().map(|s| s.to_string()).collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn plans_are_supersets_in_order() {
        let trial = plan_features(PlanId::Trial);
        let standard = plan_features(PlanId::Standard);
        let pro = plan_features(PlanId::Pro);
        let business = plan_features(PlanId::Business);
        assert!(trial.iter().all(|f| standard.contains(f)));
        assert!(standard.iter().all(|f| pro.contains(f)));
        assert!(pro.iter().all(|f| business.contains(f)));
        assert_eq!(trial.len(), 4);
        assert_eq!(standard.len(), 8);
        assert_eq!(pro.len(), 16);
        assert_eq!(business.len(), 21);
    }

    #[test]
    fn feature_strings_match_the_spec() {
        assert_eq!(
            plan_features(PlanId::Standard),
            [
                "vm",
                "bottles",
                "coherence",
                "snapshots",
                "compat-db",
                "cad-presets",
                "mobile-companion",
                "no-ads"
            ]
        );
        assert!(plan_features(PlanId::Pro).contains(&"network-lab".to_string()));
        assert!(plan_features(PlanId::Business).contains(&"audit-log".to_string()));
        assert!(!plan_features(PlanId::Trial).contains(&"no-ads".to_string()));
    }

    #[test]
    fn unknown_plan_falls_back_to_standard() {
        assert_eq!(
            features_for_plan("enterprise".into()),
            plan_features(PlanId::Standard)
        );
        assert_eq!(features_for_plan("pro".into()), plan_features(PlanId::Pro));
        assert!(is_plan_id("business".into()));
        assert!(!is_plan_id("Business".into()));
        assert_eq!(PlanId::parse("trial").map(|p| p.as_str()), Some("trial"));
    }
}
