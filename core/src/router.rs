//! The App Router: decides where an App runs (a Windows **Machine** or a Wine **Bottle**) and
//! which Fix-ups to apply.
//!
//! Precedence:
//! 1. A Compatibility Database entry wins when present (`compat_*` fields of [`RouteInput`]).
//! 2. Otherwise the file-metadata heuristic from `server/src/compat/service.ts`
//!    (`routeUnknown`) is applied; it is mirrored here so the mobile companions and the
//!    website show the same decision for the same input.

use serde::{Deserialize, Serialize};
use serde_json::{json, Value};

/// CPU architecture of the App's executable (from the PE header).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, uniffi::Enum)]
pub enum Arch {
    /// 32-bit x86.
    X86,
    /// 64-bit x86.
    X64,
    /// ARM64 / ARM64EC.
    Arm64,
    /// Not detected (e.g. an installer wrapper, or a non-PE file).
    Unknown,
}

impl Arch {
    /// Parses the wire strings used by the catalog and the API (`x86`, `x64`, `arm64`);
    /// anything else is [`Arch::Unknown`].
    pub fn parse(s: &str) -> Arch {
        match s.trim().to_ascii_lowercase().as_str() {
            "x86" | "i386" | "i686" | "win32" => Arch::X86,
            "x64" | "x86_64" | "x86-64" | "amd64" | "win64" => Arch::X64,
            "arm64" | "aarch64" | "arm64ec" => Arch::Arm64,
            _ => Arch::Unknown,
        }
    }

    /// Wire string.
    pub fn as_str(&self) -> &'static str {
        match self {
            Arch::X86 => "x86",
            Arch::X64 => "x64",
            Arch::Arm64 => "arm64",
            Arch::Unknown => "unknown",
        }
    }
}

/// Where an App runs.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, uniffi::Enum)]
#[serde(rename_all = "lowercase")]
pub enum Runtime {
    /// A full Windows Machine (VM).
    Vm,
    /// A Wine-based Bottle (no Windows license needed).
    Bottle,
    /// Both work; MIRRORZ tries the Bottle first and falls back to the Machine.
    Either,
}

impl Runtime {
    /// Parses `vm` / `bottle` / `either` (case-insensitive).
    pub fn parse(s: &str) -> Option<Runtime> {
        match s.trim().to_ascii_lowercase().as_str() {
            "vm" => Some(Runtime::Vm),
            "bottle" => Some(Runtime::Bottle),
            "either" => Some(Runtime::Either),
            _ => None,
        }
    }

    /// Wire string.
    pub fn as_str(&self) -> &'static str {
        match self {
            Runtime::Vm => "vm",
            Runtime::Bottle => "bottle",
            Runtime::Either => "either",
        }
    }
}

/// Everything the router looks at. `compat_*` come from the catalog entry when the App is
/// known (see [`crate::compat::CompatCatalog::route`], which fills them for you).
#[derive(Debug, Clone, PartialEq, Eq, uniffi::Record)]
pub struct RouteInput {
    /// Executable architecture.
    pub arch: Arch,
    /// The installer/app ships a kernel driver (anti-cheat, dongles, virtual devices).
    pub needs_driver: bool,
    /// The app installs a Windows service.
    pub needs_service: bool,
    /// .NET Framework / .NET version the app declares (e.g. `"4.8"`, `"8"`), if known.
    pub dotnet: Option<String>,
    /// DirectX generation the app needs (`"9"`, `"11"`, `"12"`, `"12_0"`…), if known.
    pub dx: Option<String>,
    /// Catalog runtime (`vm` / `bottle` / `either`) when the App is in the Compatibility Database.
    pub compat_runtime: Option<String>,
    /// Catalog rating (`gold` / `silver` / `bronze` / `broken` / `n/a`).
    pub compat_rating: Option<String>,
    /// Catalog fix-ups as a JSON array (the entry's `fixups`).
    pub compat_fixups_json: Option<String>,
}

impl RouteInput {
    /// A neutral input for an unknown file: nothing detected, nothing in the catalog.
    pub fn unknown() -> RouteInput {
        RouteInput {
            arch: Arch::Unknown,
            needs_driver: false,
            needs_service: false,
            dotnet: None,
            dx: None,
            compat_runtime: None,
            compat_rating: None,
            compat_fixups_json: None,
        }
    }
}

/// The router's answer.
#[derive(Debug, Clone, PartialEq, Eq, uniffi::Record)]
pub struct RouteDecision {
    /// Runtime to launch in. Never [`Runtime::Either`]: the router always picks.
    pub runtime: Runtime,
    /// Human-readable justification (shown in the per-App settings sheet).
    pub reason: String,
    /// Preset to apply (`cad-graphics`, `office`, `gaming`), if any.
    pub preset: Option<String>,
    /// Fix-ups to apply, as a JSON array of `{type, key?, value?, reason?, optional?}`.
    pub fixups_json: Option<String>,
    /// `true` when a Windows Machine must exist before the App can run (drives the
    /// "Set up Windows" prompt on first launch).
    pub requires_windows_machine: bool,
}

const REASON_DRIVER: &str = "kernel driver or Windows service required";
const REASON_DX12: &str = "DirectX 12 is more reliable in the VM path today";
const REASON_ARM64: &str = "ARM64-native Windows binaries run at full speed in the VM";
const REASON_BOTTLE: &str =
    "Bottle first: fastest launch, no Windows license; VM fallback on failure";

/// Major DirectX generation from strings like `"12"`, `"12_0"`, `"DX11"`, `"DirectX 9.0c"`.
fn dx_major(dx: &str) -> Option<u32> {
    let lower = dx.trim().to_ascii_lowercase();
    let stripped = lower
        .strip_prefix("directx")
        .or_else(|| lower.strip_prefix("dx"))
        .unwrap_or(&lower)
        .trim_start();
    let digits: String = stripped
        .chars()
        .take_while(|c| c.is_ascii_digit())
        .collect();
    digits.parse().ok()
}

/// The `routeUnknown` heuristic from the server, verbatim.
fn route_unknown(input: &RouteInput) -> (Runtime, &'static str) {
    if input.needs_driver || input.needs_service {
        return (Runtime::Vm, REASON_DRIVER);
    }
    if input.dx.as_deref().and_then(dx_major) == Some(12) {
        return (Runtime::Vm, REASON_DX12);
    }
    if input.arch == Arch::Arm64 {
        return (Runtime::Vm, REASON_ARM64);
    }
    (Runtime::Bottle, REASON_BOTTLE)
}

/// Fix-ups the router adds on top of the catalog for a Bottle launch, derived from file metadata.
fn heuristic_bottle_fixups(input: &RouteInput) -> Vec<Value> {
    let mut fixups = Vec::new();
    if let Some(dotnet) = input
        .dotnet
        .as_deref()
        .map(str::trim)
        .filter(|s| !s.is_empty())
    {
        fixups.push(json!({
            "type": "bottle_setting",
            "key": "dotnet_framework",
            "value": dotnet,
            "reason": "Installer declares a .NET dependency; the Bottle installs the matching runtime"
        }));
    }
    if input.dx.as_deref().and_then(dx_major) == Some(11) {
        fixups.push(json!({
            "type": "bottle_setting",
            "key": "dxmt",
            "value": "on",
            "reason": "DirectX 11 app: translate Direct3D 11 to Metal"
        }));
    }
    fixups
}

/// Parses a catalog fix-up array; `None` if it is not a JSON array.
fn parse_fixups(json_text: &str) -> Option<Vec<Value>> {
    match serde_json::from_str::<Value>(json_text) {
        Ok(Value::Array(items)) => Some(items),
        _ => None,
    }
}

/// First `{"type":"preset","value":…}` in a fix-up list.
fn preset_from_fixups(fixups: &[Value]) -> Option<String> {
    fixups
        .iter()
        .find(|f| f.get("type").and_then(Value::as_str) == Some("preset"))
        .and_then(|f| f.get("value").and_then(Value::as_str))
        .map(str::to_string)
}

fn rating_note(rating: Option<&str>) -> &'static str {
    match rating.map(|r| r.trim().to_ascii_lowercase()).as_deref() {
        Some("gold") => " (gold: works out of the box)",
        Some("silver") => " (silver: works with the listed fix-ups)",
        Some("bronze") => " (bronze: usable, known issues)",
        Some("broken") => " (broken: known not to work; launching anyway is unsupported)",
        Some("n/a") => " (a native Mac version exists; MIRRORZ recommends it)",
        _ => "",
    }
}

fn decision(runtime: Runtime, reason: String, fixups: Vec<Value>) -> RouteDecision {
    let preset = preset_from_fixups(&fixups);
    let fixups_json = if fixups.is_empty() {
        None
    } else {
        Some(Value::Array(fixups).to_string())
    };
    RouteDecision {
        runtime,
        reason,
        preset,
        fixups_json,
        requires_windows_machine: runtime == Runtime::Vm,
    }
}

/// Picks a runtime and fix-ups for an App.
#[uniffi::export]
pub fn route(input: RouteInput) -> RouteDecision {
    let catalog_runtime = input.compat_runtime.as_deref().and_then(Runtime::parse);
    let catalog_fixups = input
        .compat_fixups_json
        .as_deref()
        .and_then(parse_fixups)
        .unwrap_or_default();
    let note = rating_note(input.compat_rating.as_deref());

    match catalog_runtime {
        Some(Runtime::Vm) => decision(
            Runtime::Vm,
            format!("Compatibility Database: runs in a Windows Machine{note}"),
            catalog_fixups,
        ),
        Some(Runtime::Bottle) => {
            let mut fixups = catalog_fixups;
            fixups.extend(heuristic_bottle_fixups(&input));
            decision(
                Runtime::Bottle,
                format!("Compatibility Database: runs in a Bottle{note}"),
                fixups,
            )
        }
        Some(Runtime::Either) => {
            // The catalog says both work; the file's own metadata breaks the tie.
            let (runtime, why) = route_unknown(&input);
            let mut fixups = catalog_fixups;
            if runtime == Runtime::Bottle {
                fixups.extend(heuristic_bottle_fixups(&input));
            }
            decision(
                runtime,
                format!("Compatibility Database: works in both runtimes{note}; {why}"),
                fixups,
            )
        }
        None => {
            let (runtime, why) = route_unknown(&input);
            let fixups = if runtime == Runtime::Bottle {
                heuristic_bottle_fixups(&input)
            } else {
                Vec::new()
            };
            decision(runtime, why.to_string(), fixups)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn input(arch: Arch) -> RouteInput {
        RouteInput {
            arch,
            ..RouteInput::unknown()
        }
    }

    #[test]
    fn unknown_apps_follow_the_server_heuristic() {
        let d = route(input(Arch::X64));
        assert_eq!(d.runtime, Runtime::Bottle);
        assert_eq!(d.reason, REASON_BOTTLE);
        assert!(!d.requires_windows_machine);
        assert_eq!(d.preset, None);
        assert_eq!(d.fixups_json, None);

        let d = route(RouteInput {
            needs_driver: true,
            ..input(Arch::X64)
        });
        assert_eq!(d.runtime, Runtime::Vm);
        assert_eq!(d.reason, REASON_DRIVER);
        assert!(d.requires_windows_machine);

        let d = route(RouteInput {
            needs_service: true,
            ..input(Arch::X86)
        });
        assert_eq!((d.runtime, d.reason.as_str()), (Runtime::Vm, REASON_DRIVER));

        let d = route(RouteInput {
            dx: Some("12".into()),
            ..input(Arch::X64)
        });
        assert_eq!((d.runtime, d.reason.as_str()), (Runtime::Vm, REASON_DX12));
        let d = route(RouteInput {
            dx: Some("12_0".into()),
            ..input(Arch::X64)
        });
        assert_eq!(d.runtime, Runtime::Vm);
        let d = route(RouteInput {
            dx: Some("DirectX 12".into()),
            ..input(Arch::X64)
        });
        assert_eq!(d.runtime, Runtime::Vm);

        let d = route(input(Arch::Arm64));
        assert_eq!((d.runtime, d.reason.as_str()), (Runtime::Vm, REASON_ARM64));

        // Precedence: driver beats dx12 beats arm64.
        let d = route(RouteInput {
            needs_driver: true,
            dx: Some("12".into()),
            ..input(Arch::Arm64)
        });
        assert_eq!(d.reason, REASON_DRIVER);
        let d = route(RouteInput {
            dx: Some("12".into()),
            ..input(Arch::Arm64)
        });
        assert_eq!(d.reason, REASON_DX12);
        let d = route(input(Arch::Unknown));
        assert_eq!(d.runtime, Runtime::Bottle);
    }

    #[test]
    fn heuristic_bottle_fixups_from_metadata() {
        let d = route(RouteInput {
            dotnet: Some("4.8".into()),
            dx: Some("11".into()),
            ..input(Arch::X86)
        });
        assert_eq!(d.runtime, Runtime::Bottle);
        let fixups: Vec<Value> = serde_json::from_str(d.fixups_json.as_deref().unwrap()).unwrap();
        assert_eq!(fixups.len(), 2);
        assert_eq!(fixups[0]["type"], "bottle_setting");
        assert_eq!(fixups[0]["key"], "dotnet_framework");
        assert_eq!(fixups[0]["value"], "4.8");
        assert_eq!(fixups[1]["key"], "dxmt");
        assert_eq!(fixups[1]["value"], "on");
        assert_eq!(d.preset, None);
        // dx9 gets no translation fix-up; empty dotnet is ignored.
        let d = route(RouteInput {
            dotnet: Some("  ".into()),
            dx: Some("9.0c".into()),
            ..input(Arch::X86)
        });
        assert_eq!(d.fixups_json, None);
        // A VM decision never carries bottle settings.
        let d = route(RouteInput {
            needs_driver: true,
            dotnet: Some("4.8".into()),
            ..input(Arch::X64)
        });
        assert_eq!(d.fixups_json, None);
    }

    #[test]
    fn catalog_entry_wins_over_heuristics() {
        let autocad_fixups = r#"[
            {"type":"host_requirement","value":"rosetta2","reason":"Installer needs Rosetta 2"},
            {"type":"guest_setting","key":"downloads_folder","value":"guest"},
            {"type":"preset","value":"cad-graphics","reason":"cursor lag"},
            {"type":"sysvar","key":"DYNMODE","value":"0","optional":true}
        ]"#;
        // x64 app that the heuristic would send to a Bottle, catalog says VM.
        let d = route(RouteInput {
            compat_runtime: Some("vm".into()),
            compat_rating: Some("gold".into()),
            compat_fixups_json: Some(autocad_fixups.into()),
            ..input(Arch::X64)
        });
        assert_eq!(d.runtime, Runtime::Vm);
        assert!(d.requires_windows_machine);
        assert_eq!(d.preset.as_deref(), Some("cad-graphics"));
        assert!(d.reason.contains("gold"));
        let fixups: Vec<Value> = serde_json::from_str(d.fixups_json.as_deref().unwrap()).unwrap();
        assert_eq!(fixups.len(), 4);
        assert_eq!(fixups[3]["optional"], true);

        // Catalog Bottle beats a heuristic VM (arm64) and picks up metadata fix-ups.
        let d = route(RouteInput {
            compat_runtime: Some("bottle".into()),
            compat_rating: Some("silver".into()),
            compat_fixups_json: Some(r#"[{"type":"preset","value":"gaming"}]"#.into()),
            dx: Some("11".into()),
            ..input(Arch::Arm64)
        });
        assert_eq!(d.runtime, Runtime::Bottle);
        assert!(!d.requires_windows_machine);
        assert_eq!(d.preset.as_deref(), Some("gaming"));
        let fixups: Vec<Value> = serde_json::from_str(d.fixups_json.as_deref().unwrap()).unwrap();
        assert_eq!(fixups.len(), 2);
        assert_eq!(fixups[1]["key"], "dxmt");
        assert!(d.reason.contains("silver"));
    }

    #[test]
    fn catalog_either_is_broken_by_metadata() {
        let office = RouteInput {
            compat_runtime: Some("either".into()),
            compat_rating: Some("gold".into()),
            compat_fixups_json: Some(r#"[{"type":"preset","value":"office"}]"#.into()),
            ..input(Arch::X64)
        };
        let d = route(office.clone());
        assert_eq!(d.runtime, Runtime::Bottle);
        assert_eq!(d.preset.as_deref(), Some("office"));
        assert!(d.reason.contains("both runtimes"));
        assert!(d.reason.contains(REASON_BOTTLE));
        let d = route(RouteInput {
            arch: Arch::Arm64,
            ..office.clone()
        });
        assert_eq!(d.runtime, Runtime::Vm);
        assert!(d.reason.contains(REASON_ARM64));
        assert_eq!(d.preset.as_deref(), Some("office"));
        let d = route(RouteInput {
            needs_service: true,
            ..office
        });
        assert_eq!(d.runtime, Runtime::Vm);
        assert!(d.requires_windows_machine);
    }

    #[test]
    fn broken_and_native_ratings_are_surfaced_in_the_reason() {
        let d = route(RouteInput {
            compat_runtime: Some("vm".into()),
            compat_rating: Some("broken".into()),
            compat_fixups_json: Some("[]".into()),
            ..input(Arch::X64)
        });
        assert_eq!(d.runtime, Runtime::Vm);
        assert!(d.reason.contains("broken"));
        assert_eq!(d.fixups_json, None);
        let d = route(RouteInput {
            compat_runtime: Some("vm".into()),
            compat_rating: Some("n/a".into()),
            ..input(Arch::Unknown)
        });
        assert!(d.reason.contains("native Mac version"));
    }

    #[test]
    fn malformed_catalog_fields_fall_back_safely() {
        // Unknown runtime string -> heuristic.
        let d = route(RouteInput {
            compat_runtime: Some("cloud".into()),
            ..input(Arch::X64)
        });
        assert_eq!(d.runtime, Runtime::Bottle);
        assert_eq!(d.reason, REASON_BOTTLE);
        // Invalid fix-ups JSON is ignored rather than passed through.
        let d = route(RouteInput {
            compat_runtime: Some("VM".into()),
            compat_fixups_json: Some("{not json".into()),
            compat_rating: Some("Gold".into()),
            ..input(Arch::X64)
        });
        assert_eq!(d.runtime, Runtime::Vm);
        assert_eq!(d.fixups_json, None);
        assert_eq!(d.preset, None);
        assert!(d.reason.contains("gold"));
        // A JSON object instead of an array is also ignored.
        let d = route(RouteInput {
            compat_runtime: Some("bottle".into()),
            compat_fixups_json: Some(r#"{"type":"preset","value":"gaming"}"#.into()),
            ..input(Arch::X64)
        });
        assert_eq!(d.preset, None);
    }

    #[test]
    fn parsers() {
        assert_eq!(Arch::parse("x64"), Arch::X64);
        assert_eq!(Arch::parse("AMD64"), Arch::X64);
        assert_eq!(Arch::parse("arm64ec"), Arch::Arm64);
        assert_eq!(Arch::parse("i386"), Arch::X86);
        assert_eq!(Arch::parse("x86/x64/arm64"), Arch::Unknown);
        assert_eq!(Arch::Arm64.as_str(), "arm64");
        assert_eq!(Runtime::parse(" Either "), Some(Runtime::Either));
        assert_eq!(Runtime::parse("machine"), None);
        assert_eq!(Runtime::Bottle.as_str(), "bottle");
        assert_eq!(serde_json::to_string(&Runtime::Vm).unwrap(), "\"vm\"");
        assert_eq!(dx_major("12_0"), Some(12));
        assert_eq!(dx_major("dx11"), Some(11));
        assert_eq!(dx_major("DirectX 9.0c"), Some(9));
        assert_eq!(dx_major("metal"), None);
        assert_eq!(dx_major(""), None);
    }
}
