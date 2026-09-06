//! Machine (VM) configuration validation for the Machines detail view and the
//! "Set up Windows" wizard. Pure rules; the host supplies what it knows about the Mac.

/// Guest operating system of a Machine.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, uniffi::Enum)]
pub enum GuestOs {
    /// Windows 11 on ARM (the only Windows MIRRORZ sets up; x64 apps run through Prism).
    Windows11Arm,
    /// A Linux guest (Virtualization.framework).
    Linux,
    /// A macOS guest (Virtualization.framework, Apple Silicon only).
    MacOs,
}

/// How serious a configuration problem is.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, uniffi::Enum)]
pub enum ProblemSeverity {
    /// The Machine cannot start (or the guest cannot install) with this setting. Block "Save".
    Error,
    /// Allowed, but the experience will suffer. Show inline, let the user proceed.
    Warning,
}

/// A single validation finding.
#[derive(Debug, Clone, PartialEq, Eq, uniffi::Record)]
pub struct MachineProblem {
    /// Error or warning.
    pub severity: ProblemSeverity,
    /// Stable machine-readable code (`cpus_zero`, `memory_over_75_percent`, …) for tests and
    /// for attaching the message to the right field in the form.
    pub code: String,
    /// User-facing sentence.
    pub message: String,
}

/// Minimum memory for Windows 11 (Microsoft's published requirement), in MB.
pub const WINDOWS_11_MIN_MEMORY_MB: u64 = 4096;
/// Minimum storage for Windows 11 (Microsoft's published requirement), in GB.
pub const WINDOWS_11_MIN_DISK_GB: u64 = 64;
/// Minimum CPU cores for Windows 11 (Microsoft's published requirement).
pub const WINDOWS_11_MIN_CPUS: u32 = 2;
/// Share of host memory a Machine may take before macOS itself starts paging.
pub const HOST_MEMORY_SHARE_PERCENT: u64 = 75;

fn error(code: &str, message: String) -> MachineProblem {
    MachineProblem {
        severity: ProblemSeverity::Error,
        code: code.to_string(),
        message,
    }
}

fn warning(code: &str, message: String) -> MachineProblem {
    MachineProblem {
        severity: ProblemSeverity::Warning,
        code: code.to_string(),
        message,
    }
}

fn gb(mb: u64) -> String {
    if mb % 1024 == 0 {
        format!("{} GB", mb / 1024)
    } else {
        format!("{:.1} GB", mb as f64 / 1024.0)
    }
}

/// Validates a Machine configuration against the host, returning every finding (errors first).
///
/// Rules:
/// * at least 1 CPU, no more than the host has; `cpus <= host_cpus - 1` is recommended so macOS
///   keeps a core;
/// * memory > 0, not more than the host has, and at most 75 % of host memory (recommended);
/// * disk > 0 and not more than the free space on the host volume;
/// * Windows 11 ARM: at least 2 CPUs, 4 GB of memory and 64 GB of disk;
/// * macOS guests only on Apple Silicon.
#[allow(clippy::too_many_arguments)] // Flat FFI signature by design; see README.
#[uniffi::export]
pub fn check_machine_config(
    cpus: u32,
    memory_mb: u64,
    disk_gb: u64,
    host_cpus: u32,
    host_memory_mb: u64,
    free_disk_gb: u64,
    host_apple_silicon: bool,
    guest_os: GuestOs,
) -> Vec<MachineProblem> {
    let mut errors = Vec::new();
    let mut warnings = Vec::new();

    // ---- CPUs ----
    if cpus == 0 {
        errors.push(error(
            "cpus_zero",
            "A Machine needs at least 1 CPU.".to_string(),
        ));
    } else if cpus > host_cpus {
        errors.push(error(
            "cpus_over_host",
            format!("This Mac has {host_cpus} CPU cores; the Machine asks for {cpus}."),
        ));
    } else if host_cpus > 1 && cpus > host_cpus - 1 {
        warnings.push(warning(
            "cpus_no_headroom",
            format!(
                "Leave at least one core for macOS: up to {} of {host_cpus} cores is recommended.",
                host_cpus - 1
            ),
        ));
    }

    // ---- Memory ----
    if memory_mb == 0 {
        errors.push(error(
            "memory_zero",
            "A Machine needs some memory.".to_string(),
        ));
    } else if memory_mb > host_memory_mb {
        errors.push(error(
            "memory_over_host",
            format!(
                "This Mac has {} of memory; the Machine asks for {}.",
                gb(host_memory_mb),
                gb(memory_mb)
            ),
        ));
    } else if memory_mb * 100 > host_memory_mb * HOST_MEMORY_SHARE_PERCENT {
        let limit = host_memory_mb * HOST_MEMORY_SHARE_PERCENT / 100;
        warnings.push(warning(
            "memory_over_75_percent",
            format!(
                "Keep Machine memory at or below {HOST_MEMORY_SHARE_PERCENT}% of this Mac's memory ({}) so macOS stays responsive.",
                gb(limit)
            ),
        ));
    }

    // ---- Disk ----
    if disk_gb == 0 {
        errors.push(error("disk_zero", "A Machine needs a disk.".to_string()));
    } else if disk_gb > free_disk_gb {
        errors.push(error(
            "disk_over_free",
            format!("Not enough free space: the disk needs {disk_gb} GB but only {free_disk_gb} GB is free."),
        ));
    }

    // ---- Guest-specific ----
    match guest_os {
        GuestOs::Windows11Arm => {
            if cpus > 0 && cpus < WINDOWS_11_MIN_CPUS {
                errors.push(error(
                    "windows11_min_cpus",
                    format!("Windows 11 needs at least {WINDOWS_11_MIN_CPUS} CPU cores."),
                ));
            }
            if memory_mb > 0 && memory_mb < WINDOWS_11_MIN_MEMORY_MB {
                errors.push(error(
                    "windows11_min_memory",
                    format!(
                        "Windows 11 ARM needs at least {} of memory.",
                        gb(WINDOWS_11_MIN_MEMORY_MB)
                    ),
                ));
            }
            if disk_gb > 0 && disk_gb < WINDOWS_11_MIN_DISK_GB {
                errors.push(error(
                    "windows11_min_disk",
                    format!("Windows 11 ARM needs a disk of at least {WINDOWS_11_MIN_DISK_GB} GB."),
                ));
            }
        }
        GuestOs::MacOs => {
            if !host_apple_silicon {
                errors.push(error(
                    "macos_guest_needs_apple_silicon",
                    "macOS guests can only run on a Mac with Apple silicon.".to_string(),
                ));
            }
        }
        GuestOs::Linux => {}
    }

    errors.extend(warnings);
    errors
}

/// Same rules as [`check_machine_config`], flattened to user-facing messages (errors first).
/// An empty list means the configuration is fine.
#[allow(clippy::too_many_arguments)] // Flat FFI signature by design; see README.
#[uniffi::export]
pub fn validate_machine_config(
    cpus: u32,
    memory_mb: u64,
    disk_gb: u64,
    host_cpus: u32,
    host_memory_mb: u64,
    free_disk_gb: u64,
    host_apple_silicon: bool,
    guest_os: GuestOs,
) -> Vec<String> {
    check_machine_config(
        cpus,
        memory_mb,
        disk_gb,
        host_cpus,
        host_memory_mb,
        free_disk_gb,
        host_apple_silicon,
        guest_os,
    )
    .into_iter()
    .map(|p| p.message)
    .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    // A typical MacBook Pro: 10 cores, 32 GB, 400 GB free, Apple silicon.
    const HOST_CPUS: u32 = 10;
    const HOST_MEM: u64 = 32 * 1024;
    const FREE_DISK: u64 = 400;

    fn codes(problems: &[MachineProblem]) -> Vec<&str> {
        problems.iter().map(|p| p.code.as_str()).collect()
    }

    fn check(cpus: u32, memory_mb: u64, disk_gb: u64, guest: GuestOs) -> Vec<MachineProblem> {
        check_machine_config(
            cpus, memory_mb, disk_gb, HOST_CPUS, HOST_MEM, FREE_DISK, true, guest,
        )
    }

    #[test]
    fn a_sensible_windows_machine_has_no_problems() {
        assert!(check(6, 16 * 1024, 128, GuestOs::Windows11Arm).is_empty());
        assert!(validate_machine_config(
            6,
            16 * 1024,
            128,
            HOST_CPUS,
            HOST_MEM,
            FREE_DISK,
            true,
            GuestOs::Windows11Arm
        )
        .is_empty());
        // Exactly the recommended maximums are fine.
        assert!(check(
            HOST_CPUS - 1,
            HOST_MEM * 75 / 100,
            FREE_DISK,
            GuestOs::Windows11Arm
        )
        .is_empty());
        // Exactly the Windows minimums are fine.
        assert!(check(2, 4096, 64, GuestOs::Windows11Arm).is_empty());
    }

    #[test]
    fn cpu_rules() {
        let p = check(0, 8192, 100, GuestOs::Linux);
        assert_eq!(codes(&p), ["cpus_zero"]);
        assert_eq!(p[0].severity, ProblemSeverity::Error);
        let p = check(HOST_CPUS + 1, 8192, 100, GuestOs::Linux);
        assert_eq!(codes(&p), ["cpus_over_host"]);
        let p = check(HOST_CPUS, 8192, 100, GuestOs::Linux);
        assert_eq!(codes(&p), ["cpus_no_headroom"]);
        assert_eq!(p[0].severity, ProblemSeverity::Warning);
        assert!(p[0].message.contains("up to 9 of 10"));
        // A single-core host cannot leave headroom; no warning, no error.
        let p = check_machine_config(1, 2048, 20, 1, 8192, 100, true, GuestOs::Linux);
        assert!(p.is_empty());
        // Windows needs two cores even if the host allows one.
        let p = check(1, 8192, 100, GuestOs::Windows11Arm);
        assert_eq!(codes(&p), ["windows11_min_cpus"]);
    }

    #[test]
    fn memory_rules() {
        let p = check(4, 0, 100, GuestOs::Linux);
        assert_eq!(codes(&p), ["memory_zero"]);
        let p = check(4, HOST_MEM + 1, 100, GuestOs::Linux);
        assert_eq!(codes(&p), ["memory_over_host"]);
        assert!(p[0].message.contains("32 GB"));
        let p = check(4, HOST_MEM * 75 / 100 + 1, 100, GuestOs::Linux);
        assert_eq!(codes(&p), ["memory_over_75_percent"]);
        assert_eq!(p[0].severity, ProblemSeverity::Warning);
        assert!(p[0].message.contains("24 GB"));
        let p = check(4, 2048, 100, GuestOs::Windows11Arm);
        assert_eq!(codes(&p), ["windows11_min_memory"]);
        assert!(p[0].message.contains("4 GB"));
        // Linux is happy with 2 GB.
        assert!(check(4, 2048, 100, GuestOs::Linux).is_empty());
    }

    #[test]
    fn disk_rules() {
        let p = check(4, 8192, 0, GuestOs::Linux);
        assert_eq!(codes(&p), ["disk_zero"]);
        let p = check(4, 8192, FREE_DISK + 1, GuestOs::Linux);
        assert_eq!(codes(&p), ["disk_over_free"]);
        assert!(p[0].message.contains("401 GB"));
        let p = check(4, 8192, 63, GuestOs::Windows11Arm);
        assert_eq!(codes(&p), ["windows11_min_disk"]);
        // Zero disk reports only the zero problem, not the Windows minimum too.
        let p = check(4, 8192, 0, GuestOs::Windows11Arm);
        assert_eq!(codes(&p), ["disk_zero"]);
    }

    #[test]
    fn macos_guest_requires_apple_silicon() {
        assert!(check(4, 8192, 100, GuestOs::MacOs).is_empty());
        let p = check_machine_config(
            4,
            8192,
            100,
            HOST_CPUS,
            HOST_MEM,
            FREE_DISK,
            false,
            GuestOs::MacOs,
        );
        assert_eq!(codes(&p), ["macos_guest_needs_apple_silicon"]);
        assert_eq!(p[0].severity, ProblemSeverity::Error);
        // Windows and Linux do not care about the flag.
        assert!(check_machine_config(
            4,
            8192,
            100,
            HOST_CPUS,
            HOST_MEM,
            FREE_DISK,
            false,
            GuestOs::Windows11Arm
        )
        .is_empty());
        assert!(check_machine_config(
            4,
            8192,
            100,
            HOST_CPUS,
            HOST_MEM,
            FREE_DISK,
            false,
            GuestOs::Linux
        )
        .is_empty());
    }

    #[test]
    fn errors_come_before_warnings_and_messages_flatten() {
        // Too many cpus for headroom (warning) + too little memory for Windows (error).
        let p = check(HOST_CPUS, 2048, 100, GuestOs::Windows11Arm);
        assert_eq!(codes(&p), ["windows11_min_memory", "cpus_no_headroom"]);
        let msgs = validate_machine_config(
            HOST_CPUS,
            2048,
            100,
            HOST_CPUS,
            HOST_MEM,
            FREE_DISK,
            true,
            GuestOs::Windows11Arm,
        );
        assert_eq!(msgs.len(), 2);
        assert_eq!(msgs[0], p[0].message);
        assert_eq!(msgs[1], p[1].message);
        // Everything wrong at once.
        let p = check_machine_config(0, 0, 0, 1, 1024, 10, false, GuestOs::MacOs);
        assert_eq!(
            codes(&p),
            [
                "cpus_zero",
                "memory_zero",
                "disk_zero",
                "macos_guest_needs_apple_silicon"
            ]
        );
    }

    #[test]
    fn gb_formatting() {
        assert_eq!(gb(4096), "4 GB");
        assert_eq!(gb(1536), "1.5 GB");
        assert_eq!(gb(24 * 1024), "24 GB");
    }
}
