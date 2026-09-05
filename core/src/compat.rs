//! Compatibility Database catalog (spec §4).
//!
//! The host supplies the catalog JSON — either the bundled seed
//! ([`bundled_compat_seed_json`]) or the 24-hour cached response of
//! `GET /v1/compat/apps` — and gets typed records plus the same `search` / `get`
//! semantics as `server/src/compat/service.ts`.

use std::collections::{BTreeSet, HashMap};
use std::sync::Arc;

use serde::{Deserialize, Serialize};
use serde_json::Value;

use crate::router::{route, RouteDecision, RouteInput, Runtime};

/// The seed shipped with this build. Same file as `server/src/compat/seed.json` (single source of
/// truth in the monorepo); hosts bundle this for offline use and replace it with the server's
/// catalog when online.
#[uniffi::export]
pub fn bundled_compat_seed_json() -> String {
    include_str!("../../server/src/compat/seed.json").to_string()
}

/// Compatibility rating.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, uniffi::Enum)]
pub enum CompatRating {
    /// Works out of the box.
    #[serde(rename = "gold")]
    Gold,
    /// Works with fix-ups.
    #[serde(rename = "silver")]
    Silver,
    /// Usable, known issues.
    #[serde(rename = "bronze")]
    Bronze,
    /// Does not work.
    #[serde(rename = "broken")]
    Broken,
    /// Use the native Mac version instead.
    #[serde(rename = "n/a")]
    NotApplicable,
}

impl CompatRating {
    /// Wire string (`gold`, `silver`, `bronze`, `broken`, `n/a`).
    pub fn as_str(&self) -> &'static str {
        match self {
            CompatRating::Gold => "gold",
            CompatRating::Silver => "silver",
            CompatRating::Bronze => "bronze",
            CompatRating::Broken => "broken",
            CompatRating::NotApplicable => "n/a",
        }
    }
}

/// A per-App adjustment. Types seen in the seed: `host_requirement`, `guest_setting`, `preset`,
/// `sysvar`, `vm_setting`, `bottle_setting`, `env`.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, uniffi::Record)]
pub struct CompatFixup {
    /// Fix-up type (wire name `type`).
    #[serde(rename = "type")]
    pub fixup_type: String,
    /// Setting / variable name, when the type needs one.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub key: Option<String>,
    /// Value to apply.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub value: Option<String>,
    /// Why (shown in the per-App settings sheet).
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub reason: Option<String>,
    /// Optional fix-ups are offered, not applied automatically.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub optional: Option<bool>,
}

/// Typed view of the free-form `requirements` object. Any key the seed uses that is not modelled
/// here is still available in [`CompatApp::requirements_json`].
#[derive(Debug, Clone, Default, PartialEq, Eq, uniffi::Record)]
pub struct CompatRequirements {
    /// Minimum DirectX generation (`"11"`).
    pub dx: Option<String>,
    /// Recommended DirectX generation (`"12_0"`).
    pub dx_recommended: Option<String>,
    /// Minimum OpenGL version the guest must expose.
    pub opengl: Option<String>,
    /// Recommended guest memory in GB.
    pub ram_gb: Option<u32>,
    /// Disk space the install needs in GB.
    pub disk_gb: Option<u32>,
    /// Guest-side runtimes to install first (`vcredist-x64`, `dotnet-desktop-8`, …).
    pub guest_runtimes: Vec<String>,
}

/// One catalog entry.
#[derive(Debug, Clone, PartialEq, Eq, uniffi::Record)]
pub struct CompatApp {
    /// Stable id (`autocad`, `revit`, …). Used in `mirrorz://app/<id>` deep links.
    pub id: String,
    /// Display name.
    pub name: String,
    /// Vendor.
    pub vendor: String,
    /// Category (`cad`, `bim`, `gis`, `productivity`, `finance`, `engineering`, `eda`, `games`,
    /// `utility`, `enterprise`, `developer`, `creative`).
    pub category: String,
    /// Runtime the catalog recommends.
    pub runtime: Runtime,
    /// Rating.
    pub rating: CompatRating,
    /// Versions the entry covers (may be empty).
    pub versions: Vec<String>,
    /// Architecture note (`x64`, `arm64`, `x86/x64/arm64`).
    pub arch: Option<String>,
    /// Vendor's stance (`supported`, `unsupported_in_vm`, `native_mac_available`, `unsupported`).
    pub vendor_support: Option<String>,
    /// Free-text notes for the detail page.
    pub notes: Option<String>,
    /// Typed requirements.
    pub requirements: CompatRequirements,
    /// The raw `requirements` object as compact JSON, if present.
    pub requirements_json: Option<String>,
    /// Fix-ups the App Router applies.
    pub fixups: Vec<CompatFixup>,
}

impl CompatApp {
    /// Fix-ups as the JSON array the router consumes.
    pub fn fixups_json(&self) -> String {
        serde_json::to_string(&self.fixups).unwrap_or_else(|_| "[]".to_string())
    }

    /// Fills the `compat_*` fields of a detected-metadata [`RouteInput`] from this entry.
    pub fn route_input(&self, detected: RouteInput) -> RouteInput {
        RouteInput {
            compat_runtime: Some(self.runtime.as_str().to_string()),
            compat_rating: Some(self.rating.as_str().to_string()),
            compat_fixups_json: Some(self.fixups_json()),
            ..detected
        }
    }
}

/// A bundle of Machine/Bottle settings (`cad-graphics`, `office`, `gaming`).
#[derive(Debug, Clone, PartialEq, Eq, uniffi::Record)]
pub struct CompatPreset {
    /// Preset id.
    pub id: String,
    /// One-line description.
    pub description: String,
    /// The full preset object as compact JSON (engine-specific keys under `vm`, `guest`, `bottle`).
    pub json: String,
}

/// Why a catalog could not be loaded.
#[derive(Debug, Clone, PartialEq, Eq, thiserror::Error, uniffi::Error)]
pub enum CompatError {
    /// The JSON did not parse or did not have the catalog shape.
    #[error("invalid compatibility catalog: {message}")]
    InvalidJson {
        /// Parser message (for logs; not user-facing).
        message: String,
    },
}

// ---- seed wire shapes (private) ----

#[derive(Deserialize)]
struct SeedFile {
    version: String,
    #[serde(default)]
    runtimes: HashMap<String, String>,
    #[serde(default)]
    apps: Vec<SeedApp>,
    #[serde(default)]
    presets: serde_json::Map<String, Value>,
}

#[derive(Deserialize)]
struct SeedApp {
    id: String,
    name: String,
    vendor: String,
    category: String,
    runtime: Runtime,
    rating: CompatRating,
    #[serde(default)]
    versions: Vec<String>,
    #[serde(default)]
    arch: Option<String>,
    #[serde(default)]
    vendor_support: Option<String>,
    #[serde(default)]
    notes: Option<String>,
    #[serde(default)]
    requirements: Option<Value>,
    #[serde(default)]
    fixups: Vec<CompatFixup>,
}

fn value_to_string(v: &Value) -> Option<String> {
    match v {
        Value::String(s) => Some(s.clone()),
        Value::Number(n) => Some(n.to_string()),
        _ => None,
    }
}

fn value_to_u32(v: &Value) -> Option<u32> {
    match v {
        Value::Number(n) => n.as_f64().filter(|f| *f >= 0.0).map(|f| f.round() as u32),
        Value::String(s) => s.trim().parse().ok(),
        _ => None,
    }
}

fn typed_requirements(raw: Option<&Value>) -> CompatRequirements {
    let Some(Value::Object(map)) = raw else {
        return CompatRequirements::default();
    };
    CompatRequirements {
        dx: map.get("dx").and_then(value_to_string),
        dx_recommended: map.get("dx_recommended").and_then(value_to_string),
        opengl: map.get("opengl").and_then(value_to_string),
        ram_gb: map.get("ram_gb").and_then(value_to_u32),
        disk_gb: map.get("disk_gb").and_then(value_to_u32),
        guest_runtimes: map
            .get("guest_runtimes")
            .and_then(Value::as_array)
            .map(|items| items.iter().filter_map(value_to_string).collect())
            .unwrap_or_default(),
    }
}

impl From<SeedApp> for CompatApp {
    fn from(app: SeedApp) -> Self {
        let requirements = typed_requirements(app.requirements.as_ref());
        let requirements_json = app
            .requirements
            .as_ref()
            .filter(|v| v.is_object())
            .map(Value::to_string);
        CompatApp {
            id: app.id,
            name: app.name,
            vendor: app.vendor,
            category: app.category,
            runtime: app.runtime,
            rating: app.rating,
            versions: app.versions,
            arch: app.arch,
            vendor_support: app.vendor_support,
            notes: app.notes,
            requirements,
            requirements_json,
            fixups: app.fixups,
        }
    }
}

/// A parsed catalog. Create once per catalog JSON and keep it around; every query is a cheap
/// scan of an in-memory list.
#[derive(Debug, uniffi::Object)]
pub struct CompatCatalog {
    version: String,
    runtimes: HashMap<String, String>,
    apps: Vec<CompatApp>,
    presets: Vec<CompatPreset>,
}

#[uniffi::export]
impl CompatCatalog {
    /// Parses catalog JSON (the seed file or `GET /v1/compat/apps` response).
    #[uniffi::constructor]
    pub fn from_json(json: String) -> Result<Arc<Self>, CompatError> {
        let seed: SeedFile = serde_json::from_str(&json).map_err(|e| CompatError::InvalidJson {
            message: e.to_string(),
        })?;
        let mut presets: Vec<CompatPreset> = seed
            .presets
            .iter()
            .map(|(id, value)| CompatPreset {
                id: id.clone(),
                description: value
                    .get("description")
                    .and_then(Value::as_str)
                    .unwrap_or_default()
                    .to_string(),
                json: value.to_string(),
            })
            .collect();
        presets.sort_by(|a, b| a.id.cmp(&b.id));
        Ok(Arc::new(CompatCatalog {
            version: seed.version,
            runtimes: seed.runtimes,
            apps: seed.apps.into_iter().map(CompatApp::from).collect(),
            presets,
        }))
    }

    /// Catalog version (a date string, e.g. `2026.09.03`).
    pub fn version(&self) -> String {
        self.version.clone()
    }

    /// Number of Apps in the catalog.
    pub fn app_count(&self) -> u32 {
        self.apps.len() as u32
    }

    /// All Apps, in catalog order.
    pub fn apps(&self) -> Vec<CompatApp> {
        self.apps.clone()
    }

    /// Sorted, de-duplicated category ids (for filter chips).
    pub fn categories(&self) -> Vec<String> {
        self.apps
            .iter()
            .map(|a| a.category.clone())
            .collect::<BTreeSet<_>>()
            .into_iter()
            .collect()
    }

    /// One-line description of a runtime from the catalog's `runtimes` table.
    pub fn runtime_description(&self, runtime: Runtime) -> Option<String> {
        self.runtimes.get(runtime.as_str()).cloned()
    }

    /// All presets, sorted by id.
    pub fn presets(&self) -> Vec<CompatPreset> {
        self.presets.clone()
    }

    /// One preset by id.
    pub fn preset(&self, id: String) -> Option<CompatPreset> {
        self.presets.iter().find(|p| p.id == id).cloned()
    }

    /// Same semantics as the server's `search(q, category, runtime)`:
    /// * `category` must match exactly;
    /// * `runtime` keeps Apps whose runtime is that runtime **or** `either`;
    /// * `query` (trimmed, lower-cased) must be contained in the id, name or vendor.
    pub fn search(
        &self,
        query: Option<String>,
        category: Option<String>,
        runtime: Option<Runtime>,
    ) -> Vec<CompatApp> {
        let needle = query
            .as_deref()
            .map(|q| q.trim().to_lowercase())
            .filter(|q| !q.is_empty());
        self.apps
            .iter()
            .filter(|a| {
                if let Some(c) = &category {
                    if &a.category != c {
                        return false;
                    }
                }
                if let Some(r) = runtime {
                    if a.runtime != r && a.runtime != Runtime::Either {
                        return false;
                    }
                }
                match &needle {
                    None => true,
                    Some(n) => {
                        a.id.contains(n.as_str())
                            || a.name.to_lowercase().contains(n.as_str())
                            || a.vendor.to_lowercase().contains(n.as_str())
                    }
                }
            })
            .cloned()
            .collect()
    }

    /// One App by id.
    pub fn get(&self, id: String) -> Option<CompatApp> {
        self.apps.iter().find(|a| a.id == id).cloned()
    }

    /// Routes an App: if `app_id` is in the catalog its entry wins, otherwise the detected
    /// metadata alone decides (see [`crate::router::route`]).
    pub fn route(&self, app_id: Option<String>, detected: RouteInput) -> RouteDecision {
        let input = match app_id.and_then(|id| self.get(id)) {
            Some(app) => app.route_input(detected),
            None => RouteInput {
                compat_runtime: None,
                compat_rating: None,
                compat_fixups_json: None,
                ..detected
            },
        };
        route(input)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::router::Arch;

    fn catalog() -> Arc<CompatCatalog> {
        CompatCatalog::from_json(bundled_compat_seed_json()).expect("seed parses")
    }

    #[test]
    fn seed_parses_completely() {
        let c = catalog();
        assert_eq!(c.version(), "2026.09.03");
        assert!(c.app_count() >= 30, "{}", c.app_count());
        assert_eq!(c.apps().len() as u32, c.app_count());
        let ids: BTreeSet<String> = c.apps().into_iter().map(|a| a.id).collect();
        assert_eq!(ids.len() as u32, c.app_count(), "ids are unique");
        for app in c.apps() {
            assert!(!app.name.is_empty());
            assert!(!app.vendor.is_empty());
            assert!(!app.category.is_empty());
            for f in &app.fixups {
                assert!(!f.fixup_type.is_empty(), "{}", app.id);
            }
        }
        assert!(c
            .runtime_description(Runtime::Vm)
            .unwrap()
            .contains("Windows 11 ARM"));
        assert!(c
            .runtime_description(Runtime::Bottle)
            .unwrap()
            .contains("Wine"));
        assert!(c.runtime_description(Runtime::Either).is_some());
    }

    #[test]
    fn autocad_entry_is_fully_typed() {
        let c = catalog();
        let autocad = c.get("autocad".into()).unwrap();
        assert_eq!(autocad.vendor, "Autodesk");
        assert_eq!(autocad.category, "cad");
        assert_eq!(autocad.runtime, Runtime::Vm);
        assert_eq!(autocad.rating, CompatRating::Gold);
        assert_eq!(autocad.versions, ["2024", "2025", "2026", "2027"]);
        assert_eq!(autocad.arch.as_deref(), Some("x64"));
        assert_eq!(autocad.vendor_support.as_deref(), Some("unsupported_in_vm"));
        assert_eq!(autocad.requirements.dx.as_deref(), Some("11"));
        assert_eq!(autocad.requirements.dx_recommended.as_deref(), Some("12_0"));
        assert_eq!(autocad.requirements.ram_gb, Some(16));
        assert_eq!(autocad.requirements.disk_gb, Some(20));
        assert_eq!(autocad.requirements.guest_runtimes.len(), 5);
        assert!(autocad
            .requirements
            .guest_runtimes
            .contains(&"dotnet-desktop-10".to_string()));
        let raw: Value =
            serde_json::from_str(autocad.requirements_json.as_deref().unwrap()).unwrap();
        assert_eq!(raw["ram_gb"], 16);
        assert_eq!(autocad.fixups.len(), 4);
        assert_eq!(autocad.fixups[0].fixup_type, "host_requirement");
        assert_eq!(autocad.fixups[0].value.as_deref(), Some("rosetta2"));
        assert_eq!(autocad.fixups[1].key.as_deref(), Some("downloads_folder"));
        assert_eq!(autocad.fixups[2].fixup_type, "preset");
        assert_eq!(autocad.fixups[2].value.as_deref(), Some("cad-graphics"));
        assert_eq!(autocad.fixups[3].optional, Some(true));
        // Round trip of fix-ups keeps the wire name `type`.
        let json = autocad.fixups_json();
        assert!(json.contains("\"type\":\"preset\""));
        assert!(!json.contains("fixup_type"));
        let back: Vec<CompatFixup> = serde_json::from_str(&json).unwrap();
        assert_eq!(back, autocad.fixups);
    }

    #[test]
    fn entries_without_requirements_have_defaults() {
        let c = catalog();
        let seven_zip = c.get("7zip".into()).unwrap();
        assert_eq!(seven_zip.requirements, CompatRequirements::default());
        assert_eq!(seven_zip.requirements_json, None);
        assert!(seven_zip.fixups.is_empty());
        assert!(seven_zip.versions.is_empty());
        assert_eq!(seven_zip.runtime, Runtime::Either);
        let vectorworks = c.get("vectorworks".into()).unwrap();
        assert_eq!(vectorworks.rating, CompatRating::NotApplicable);
        assert_eq!(vectorworks.rating.as_str(), "n/a");
        let broken = c.get("desktop-connector".into()).unwrap();
        assert_eq!(broken.rating, CompatRating::Broken);
        assert!(c.get("does-not-exist".into()).is_none());
    }

    #[test]
    fn search_mirrors_the_server() {
        let c = catalog();
        assert_eq!(c.search(None, None, None).len() as u32, c.app_count());
        assert_eq!(
            c.search(Some("   ".into()), None, None).len() as u32,
            c.app_count()
        );
        let autodesk = c.search(Some("AutoDesk".into()), None, None);
        assert!(autodesk.len() >= 8);
        assert!(autodesk.iter().all(|a| a.vendor == "Autodesk"));
        let by_id = c.search(Some("autocad-lt".into()), None, None);
        assert_eq!(by_id.len(), 1);
        let cad = c.search(None, Some("cad".into()), None);
        assert!(cad.iter().all(|a| a.category == "cad"));
        assert!(cad.iter().any(|a| a.id == "solidworks"));
        // Category is an exact match (no partial / case folding), as on the server.
        assert!(c.search(None, Some("CAD".into()), None).is_empty());
        // Runtime filter keeps `either`.
        let bottle = c.search(None, None, Some(Runtime::Bottle));
        assert!(bottle.iter().all(|a| a.runtime != Runtime::Vm));
        assert!(bottle.iter().any(|a| a.id == "7zip"));
        assert!(bottle.iter().any(|a| a.id == "steam-dx11-games"));
        let vm = c.search(None, None, Some(Runtime::Vm));
        assert!(vm.iter().any(|a| a.id == "autocad"));
        assert!(vm.iter().any(|a| a.id == "ms-office-windows"));
        assert!(!vm.iter().any(|a| a.id == "steam-dx11-games"));
        // Combined filters.
        let games_bottle = c.search(
            Some("steam".into()),
            Some("games".into()),
            Some(Runtime::Bottle),
        );
        assert_eq!(games_bottle.len(), 2);
        assert!(c.search(Some("zzz-nothing".into()), None, None).is_empty());
        let cats = c.categories();
        assert!(cats.windows(2).all(|w| w[0] < w[1]), "sorted");
        assert!(cats.contains(&"cad".to_string()));
    }

    #[test]
    fn presets_are_exposed() {
        let c = catalog();
        let presets = c.presets();
        let ids: Vec<&str> = presets.iter().map(|p| p.id.as_str()).collect();
        assert_eq!(ids, ["cad-graphics", "gaming", "office"]);
        let cad = c.preset("cad-graphics".into()).unwrap();
        assert!(cad.description.contains("AutoCAD"));
        let json: Value = serde_json::from_str(&cad.json).unwrap();
        assert_eq!(json["vm"]["vram_mb"], 4096);
        assert_eq!(json["vm"]["mouse_mode"], "precision");
        assert!(c.preset("nope".into()).is_none());
    }

    #[test]
    fn catalog_routes_known_and_unknown_apps() {
        let c = catalog();
        let detected = RouteInput {
            arch: Arch::X64,
            ..RouteInput::unknown()
        };
        let d = c.route(Some("autocad".into()), detected.clone());
        assert_eq!(d.runtime, Runtime::Vm);
        assert!(d.requires_windows_machine);
        assert_eq!(d.preset.as_deref(), Some("cad-graphics"));
        let fixups: Vec<CompatFixup> =
            serde_json::from_str(d.fixups_json.as_deref().unwrap()).unwrap();
        assert_eq!(fixups.len(), 4);
        // Office is `either`: an x64 build goes to a Bottle, an arm64 build to the VM.
        let d = c.route(Some("ms-office-windows".into()), detected.clone());
        assert_eq!(d.runtime, Runtime::Bottle);
        assert_eq!(d.preset.as_deref(), Some("office"));
        let d = c.route(
            Some("ms-office-windows".into()),
            RouteInput {
                arch: Arch::Arm64,
                ..detected.clone()
            },
        );
        assert_eq!(d.runtime, Runtime::Vm);
        // Unknown id and no id both fall back to the heuristic.
        let d = c.route(Some("not-in-catalog".into()), detected.clone());
        assert_eq!(d.runtime, Runtime::Bottle);
        assert_eq!(d.preset, None);
        let d = c.route(
            None,
            RouteInput {
                needs_driver: true,
                ..detected
            },
        );
        assert_eq!(d.runtime, Runtime::Vm);
    }

    #[test]
    fn invalid_json_is_an_error() {
        let err = CompatCatalog::from_json("{".into()).err().unwrap();
        assert!(matches!(err, CompatError::InvalidJson { .. }));
        assert!(err.to_string().starts_with("invalid compatibility catalog"));
        let err = CompatCatalog::from_json(r#"{"version":"x","apps":[{"id":"a"}]}"#.into())
            .err()
            .unwrap();
        assert!(matches!(err, CompatError::InvalidJson { .. }));
        let err = CompatCatalog::from_json(r#"{"version":"x","apps":[{"id":"a","name":"A","vendor":"V","category":"c","runtime":"cloud","rating":"gold"}]}"#.into()).err().unwrap();
        assert!(matches!(err, CompatError::InvalidJson { .. }));
        // Minimal valid catalog: only `version` is required.
        let c = CompatCatalog::from_json(r#"{"version":"2026.01.01"}"#.into()).unwrap();
        assert_eq!(c.app_count(), 0);
        assert!(c.presets().is_empty());
        assert!(c.categories().is_empty());
        assert!(c.runtime_description(Runtime::Vm).is_none());
    }

    #[test]
    fn lenient_requirement_values() {
        let json = r#"{"version":"v","apps":[{"id":"a","name":"A","vendor":"V","category":"c","runtime":"vm","rating":"silver",
            "requirements":{"dx":12,"ram_gb":"32","disk_gb":10.6,"guest_runtimes":["x",1,null],"extra":{"k":true}}}]}"#;
        let c = CompatCatalog::from_json(json.into()).unwrap();
        let a = c.get("a".into()).unwrap();
        assert_eq!(a.requirements.dx.as_deref(), Some("12"));
        assert_eq!(a.requirements.ram_gb, Some(32));
        assert_eq!(a.requirements.disk_gb, Some(11));
        assert_eq!(a.requirements.guest_runtimes, ["x", "1"]);
        assert!(a.requirements_json.unwrap().contains("\"extra\""));
        let json = r#"{"version":"v","apps":[{"id":"b","name":"B","vendor":"V","category":"c","runtime":"vm","rating":"silver","requirements":"none"}]}"#;
        let c = CompatCatalog::from_json(json.into()).unwrap();
        let b = c.get("b".into()).unwrap();
        assert_eq!(b.requirements, CompatRequirements::default());
        assert_eq!(b.requirements_json, None);
    }
}
