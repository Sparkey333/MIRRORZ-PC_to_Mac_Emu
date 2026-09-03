// EngineContracts.swift
// MIRRORZ — shared contracts between the UI layer and the runtime engines.
// This file is the agreed interface. Implementations live in Engine/VZ, Engine/QEMU, Engine/Bottle.
// Keep it dependency-free (Foundation only) so it can be compiled into the CLI and tests.

import Foundation

// MARK: - Identifiers

public struct MachineID: Hashable, Codable, Sendable, RawRepresentable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init() { self.rawValue = UUID().uuidString.lowercased() }
}

public struct BottleID: Hashable, Codable, Sendable, RawRepresentable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init() { self.rawValue = UUID().uuidString.lowercased() }
}

public struct AppID: Hashable, Codable, Sendable, RawRepresentable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init() { self.rawValue = UUID().uuidString.lowercased() }
}

// MARK: - Runtime selection

public enum Runtime: String, Codable, Sendable, CaseIterable {
    case vm       // full Windows/Linux Machine
    case bottle   // Wine-based Bottle
    case either   // App Router decides (bottle first, vm fallback)
}

public enum GuestOS: String, Codable, Sendable, CaseIterable {
    case windows11ARM   // Windows 11 on ARM (QEMU + HVF)
    case linuxARM       // Linux aarch64 (Virtualization.framework)
    case macOS          // macOS guest (Virtualization.framework, Apple Silicon only)
}

public enum VMBackend: String, Codable, Sendable, CaseIterable {
    case virtualization // Apple Virtualization.framework (Linux, macOS guests)
    case qemuHVF        // QEMU with Hypervisor.framework acceleration (Windows on ARM)
}

// MARK: - Machine (VM) model

public struct SharedFolder: Codable, Hashable, Sendable {
    public var hostPath: URL
    public var guestName: String
    public var readOnly: Bool
    public init(hostPath: URL, guestName: String, readOnly: Bool = false) {
        self.hostPath = hostPath; self.guestName = guestName; self.readOnly = readOnly
    }
}

public struct DisplayConfig: Codable, Hashable, Sendable {
    public enum ScalingMode: String, Codable, Sendable { case bestForRetina, scaled, moreSpace, native }
    public var widthPixels: Int
    public var heightPixels: Int
    public var pixelsPerInch: Int
    public var scaling: ScalingMode
    public init(widthPixels: Int = 2560, heightPixels: Int = 1600, pixelsPerInch: Int = 144, scaling: ScalingMode = .bestForRetina) {
        self.widthPixels = widthPixels; self.heightPixels = heightPixels; self.pixelsPerInch = pixelsPerInch; self.scaling = scaling
    }
}

public struct GPUConfig: Codable, Hashable, Sendable {
    public enum Mode: String, Codable, Sendable { case software, virtioGPU2D, virtioGPU3D, paravirtMetal }
    public var mode: Mode
    public var vramMB: Int
    public init(mode: Mode = .virtioGPU2D, vramMB: Int = 2048) { self.mode = mode; self.vramMB = vramMB }
}

public struct MachineConfig: Codable, Hashable, Sendable, Identifiable {
    public var id: MachineID
    public var name: String
    public var guestOS: GuestOS
    public var backend: VMBackend
    public var cpuCount: Int
    public var memoryMB: Int
    public var diskGB: Int
    public var display: DisplayConfig
    public var gpu: GPUConfig
    public var sharedFolders: [SharedFolder]
    public var sharedClipboard: Bool
    public var sharePrinters: Bool
    public var usbPassthrough: Bool
    public var rosettaInGuest: Bool          // Linux guests only: expose Rosetta for x86_64 binaries
    public var stableHardwareIdentity: Bool  // keep machine GUID/MAC/disk serial stable across updates (licensing-sensitive apps)
    public var preset: String?               // e.g. "cad-graphics", "office"
    public var createdAt: Date
    public var bundleURL: URL                // ~/Library/Containers/.../Machines/<id>.mirrorzvm

    public init(id: MachineID = MachineID(), name: String, guestOS: GuestOS, backend: VMBackend,
                cpuCount: Int, memoryMB: Int, diskGB: Int, display: DisplayConfig = DisplayConfig(), gpu: GPUConfig = GPUConfig(),
                sharedFolders: [SharedFolder] = [], sharedClipboard: Bool = true, sharePrinters: Bool = true, usbPassthrough: Bool = false,
                rosettaInGuest: Bool = false, stableHardwareIdentity: Bool = true, preset: String? = nil, createdAt: Date = Date(), bundleURL: URL) {
        self.id = id; self.name = name; self.guestOS = guestOS; self.backend = backend; self.cpuCount = cpuCount; self.memoryMB = memoryMB
        self.diskGB = diskGB; self.display = display; self.gpu = gpu; self.sharedFolders = sharedFolders; self.sharedClipboard = sharedClipboard
        self.sharePrinters = sharePrinters; self.usbPassthrough = usbPassthrough; self.rosettaInGuest = rosettaInGuest
        self.stableHardwareIdentity = stableHardwareIdentity; self.preset = preset; self.createdAt = createdAt; self.bundleURL = bundleURL
    }
}

public enum MachineState: String, Codable, Sendable {
    case stopped, starting, running, pausing, paused, resuming, stopping, saving, restoring, error
}

public struct Snapshot: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var createdAt: Date
    public var sizeBytes: Int64
    public init(id: String = UUID().uuidString, name: String, createdAt: Date = Date(), sizeBytes: Int64 = 0) {
        self.id = id; self.name = name; self.createdAt = createdAt; self.sizeBytes = sizeBytes
    }
}

public struct GuestWindowInfo: Codable, Hashable, Sendable, Identifiable {
    public var id: UInt64          // guest-side HWND or window id
    public var title: String
    public var processName: String
    public var frame: CGRect       // guest pixels
    public var isMinimized: Bool
    public init(id: UInt64, title: String, processName: String, frame: CGRect, isMinimized: Bool) {
        self.id = id; self.title = title; self.processName = processName; self.frame = frame; self.isMinimized = isMinimized
    }
}

/// Events streamed by a running Machine.
public enum MachineEvent: Sendable {
    case stateChanged(MachineState)
    case guestToolsReady(version: String)
    case windowsChanged([GuestWindowInfo])     // for Mirror Mode
    case log(String)
    case error(EngineError)
}

// MARK: - Bottle (Wine) model

public struct BottleConfig: Codable, Hashable, Sendable, Identifiable {
    public enum WindowsVersion: String, Codable, Sendable, CaseIterable { case win10, win11, win7, winxp }
    public enum GraphicsBackend: String, Codable, Sendable, CaseIterable { case wined3d, dxmt, d3dMetal, moltenVKDXVK }
    public var id: BottleID
    public var name: String
    public var windowsVersion: WindowsVersion
    public var graphics: GraphicsBackend
    public var engineVersion: String       // e.g. "wine-10.0-mirrorz-3"
    public var esync: Bool
    public var msync: Bool
    public var hiDPI: Bool
    public var installedComponents: [String] // "vcrun2022", "dotnet48", "corefonts", ...
    public var environment: [String: String]
    public var preset: String?
    public var createdAt: Date
    public var prefixURL: URL              // WINEPREFIX

    public init(id: BottleID = BottleID(), name: String, windowsVersion: WindowsVersion = .win10, graphics: GraphicsBackend = .dxmt,
                engineVersion: String, esync: Bool = true, msync: Bool = true, hiDPI: Bool = true, installedComponents: [String] = [],
                environment: [String: String] = [:], preset: String? = nil, createdAt: Date = Date(), prefixURL: URL) {
        self.id = id; self.name = name; self.windowsVersion = windowsVersion; self.graphics = graphics; self.engineVersion = engineVersion
        self.esync = esync; self.msync = msync; self.hiDPI = hiDPI; self.installedComponents = installedComponents
        self.environment = environment; self.preset = preset; self.createdAt = createdAt; self.prefixURL = prefixURL
    }
}

// MARK: - App (the primary user-facing object)

public struct AppRecord: Codable, Hashable, Sendable, Identifiable {
    public enum Location: Codable, Hashable, Sendable {
        case bottle(BottleID, exePath: String)         // path inside the prefix, e.g. "C:\\Program Files\\Foo\\foo.exe"
        case machine(MachineID, exePath: String)       // path inside the guest
    }
    public var id: AppID
    public var name: String
    public var compatID: String?          // id in the Compatibility Database, if matched
    public var location: Location
    public var iconPNG: Data?
    public var arguments: [String]
    public var mirrorMode: Bool           // open in seamless windows
    public var fixups: [Fixup]
    public var lastLaunched: Date?
    public var launchCount: Int

    public init(id: AppID = AppID(), name: String, compatID: String? = nil, location: Location, iconPNG: Data? = nil,
                arguments: [String] = [], mirrorMode: Bool = true, fixups: [Fixup] = [], lastLaunched: Date? = nil, launchCount: Int = 0) {
        self.id = id; self.name = name; self.compatID = compatID; self.location = location; self.iconPNG = iconPNG
        self.arguments = arguments; self.mirrorMode = mirrorMode; self.fixups = fixups; self.lastLaunched = lastLaunched; self.launchCount = launchCount
    }
}

/// Mirrors `fixups[]` entries in the Compatibility Database seed.
public struct Fixup: Codable, Hashable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case hostRequirement = "host_requirement"   // e.g. rosetta2
        case guestSetting = "guest_setting"         // e.g. downloads_folder=guest
        case vmSetting = "vm_setting"               // e.g. cpus=max-1, stable_hwid=true, usb_passthrough=true
        case bottleSetting = "bottle_setting"       // e.g. dxmt=on, dotnet_framework=4.8
        case env                                    // environment variable
        case sysvar                                 // app system variable (AutoCAD DYNMODE etc.)
        case registry                               // HKCU\... value
        case preset                                 // apply a named preset
    }
    public var type: Kind
    public var key: String?
    public var value: String?
    public var reason: String?
    public var optional: Bool
    public init(type: Kind, key: String? = nil, value: String? = nil, reason: String? = nil, optional: Bool = false) {
        self.type = type; self.key = key; self.value = value; self.reason = reason; self.optional = optional
    }
}

// MARK: - Installer analysis → routing

public struct InstallerMetadata: Codable, Hashable, Sendable {
    public enum Arch: String, Codable, Sendable { case x86, x64, arm64, unknown }
    public var fileURL: URL
    public var fileName: String
    public var arch: Arch
    public var isMSI: Bool
    public var needsDriver: Bool
    public var needsService: Bool
    public var dotnetVersion: String?
    public var directXLevel: String?     // "9", "11", "12"
    public var productName: String?      // from VERSIONINFO
    public var companyName: String?
    public var compatID: String?         // matched Compatibility Database id
    public init(fileURL: URL, fileName: String, arch: Arch = .unknown, isMSI: Bool = false, needsDriver: Bool = false, needsService: Bool = false,
                dotnetVersion: String? = nil, directXLevel: String? = nil, productName: String? = nil, companyName: String? = nil, compatID: String? = nil) {
        self.fileURL = fileURL; self.fileName = fileName; self.arch = arch; self.isMSI = isMSI; self.needsDriver = needsDriver; self.needsService = needsService
        self.dotnetVersion = dotnetVersion; self.directXLevel = directXLevel; self.productName = productName; self.companyName = companyName; self.compatID = compatID
    }
}

public struct RouteDecision: Codable, Hashable, Sendable {
    public var runtime: Runtime
    public var reason: String
    public var preset: String?
    public var fixups: [Fixup]
    public var requiresWindowsMachine: Bool
    public init(runtime: Runtime, reason: String, preset: String? = nil, fixups: [Fixup] = [], requiresWindowsMachine: Bool = false) {
        self.runtime = runtime; self.reason = reason; self.preset = preset; self.fixups = fixups; self.requiresWindowsMachine = requiresWindowsMachine
    }
}

// MARK: - Errors

public enum EngineError: Error, Sendable, Equatable {
    case notSupportedOnThisMac(String)
    case backendUnavailable(VMBackend, String)
    case guestImageMissing(GuestOS)
    case invalidConfiguration(String)
    case processFailed(exitCode: Int32, stderr: String)
    case timeout(String)
    case guestToolsNotInstalled
    case insufficientResources(String)
    case cancelled
    case io(String)
}

// MARK: - Progress

public struct Progress: Sendable, Equatable {
    public var fraction: Double     // 0...1, or -1 for indeterminate
    public var message: String
    public init(fraction: Double, message: String) { self.fraction = fraction; self.message = message }
}

// MARK: - Engine protocols

/// A running or stopped virtual machine. One instance per MachineConfig.
public protocol Machine: AnyObject, Sendable {
    var config: MachineConfig { get }
    var state: MachineState { get async }
    var events: AsyncStream<MachineEvent> { get }

    func start() async throws
    func pause() async throws
    func resume() async throws
    func stop(force: Bool) async throws
    func saveState() async throws
    func createSnapshot(name: String) async throws -> Snapshot
    func restoreSnapshot(_ snapshot: Snapshot) async throws
    func deleteSnapshot(_ snapshot: Snapshot) async throws
    func listSnapshots() async throws -> [Snapshot]

    /// Guest Tools channel (installed inside the guest): launch a program, enumerate windows for Mirror Mode, set env/registry.
    func guestLaunch(exePath: String, arguments: [String], environment: [String: String]) async throws -> UInt32
    func guestWindows() async throws -> [GuestWindowInfo]
    func guestApplyFixups(_ fixups: [Fixup]) async throws
    func guestCopyFile(hostURL: URL, toGuestPath: String) async throws
}

/// Creates, lists and manages Machines for one backend.
public protocol VMEngine: AnyObject, Sendable {
    var backend: VMBackend { get }
    var supportedGuests: [GuestOS] { get }
    static func isAvailable() -> (available: Bool, reason: String?)

    func createMachine(config: MachineConfig, installMedia: URL?, progress: @escaping @Sendable (Progress) -> Void) async throws -> any Machine
    func openMachine(config: MachineConfig) async throws -> any Machine
    func cloneMachine(_ machine: any Machine, name: String, linked: Bool) async throws -> MachineConfig
    func deleteMachine(_ config: MachineConfig) async throws
    func validate(config: MachineConfig) -> [String]   // human-readable problems; empty = OK
}

/// Wine-based Bottles.
public protocol BottleEngine: AnyObject, Sendable {
    var engineVersions: [String] { get async }            // installed Wine engine builds
    static func isAvailable() -> (available: Bool, reason: String?)

    func createBottle(config: BottleConfig, progress: @escaping @Sendable (Progress) -> Void) async throws
    func deleteBottle(_ config: BottleConfig) async throws
    func installComponent(_ component: String, into config: BottleConfig, progress: @escaping @Sendable (Progress) -> Void) async throws
    func run(exePath: String, in config: BottleConfig, arguments: [String], environment: [String: String]) async throws -> Process
    func runInstaller(_ installer: URL, in config: BottleConfig, progress: @escaping @Sendable (Progress) -> Void) async throws -> [AppRecord]
    func applyFixups(_ fixups: [Fixup], to config: BottleConfig) async throws
    func windows(in config: BottleConfig) async throws -> [GuestWindowInfo]
}

/// Picks a Runtime for an installer/App and assembles fix-ups from the Compatibility Database.
public protocol AppRouting: Sendable {
    func analyze(installer: URL) async throws -> InstallerMetadata
    func route(_ metadata: InstallerMetadata) async -> RouteDecision
}

/// Downloads Windows 11 ARM install media from Microsoft after the user accepts Microsoft's terms. Never redistributes Windows.
public protocol WindowsMediaProvider: Sendable {
    func availableEditions() async throws -> [WindowsEdition]
    func download(edition: WindowsEdition, to destination: URL, progress: @escaping @Sendable (Progress) -> Void) async throws -> URL
}

public struct WindowsEdition: Codable, Hashable, Sendable, Identifiable {
    public var id: String        // e.g. "win11-arm64-pro-en-us"
    public var name: String      // "Windows 11 Pro (ARM64), English (US)"
    public var language: String
    public var sizeBytes: Int64?
    public var termsURL: URL
    public init(id: String, name: String, language: String, sizeBytes: Int64? = nil, termsURL: URL) {
        self.id = id; self.name = name; self.language = language; self.sizeBytes = sizeBytes; self.termsURL = termsURL
    }
}
