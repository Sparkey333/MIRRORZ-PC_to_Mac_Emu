// CompatClientTests.swift
// Bundled seed parsing, server-equivalent search, 24 h cache and offline fallbacks.

import XCTest
@testable import MirrorzKit

final class CompatClientTests: XCTestCase {
    private var cacheDirectory: URL!
    private var clock: TestClock!

    override func setUpWithError() throws {
        cacheDirectory = try makeTemporaryDirectory()
        clock = TestClock(Date(timeIntervalSince1970: 1_800_000_000))
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: cacheDirectory)
    }

    private func makeClient(_ transport: HTTPTransport, cacheDirectory: URL? = nil) -> CompatClient {
        let clock = clock!
        let configuration = CompatClient.Configuration(
            baseURL: URL(string: "http://localhost:8787")!,
            userAgent: "MIRRORZ/1.0.0 (macos)",
            cacheDirectory: cacheDirectory ?? self.cacheDirectory
        )
        return CompatClient(configuration: configuration, transport: transport, clock: { clock.now })
    }

    private static let smallCatalogJSON = #"""
    {"version":"2026.09.10","apps":[{"id":"autocad","name":"AutoCAD","vendor":"Autodesk","category":"cad","runtime":"vm","rating":"gold","fixups":[]}]}
    """#

    private func catalogTransport() -> FakeTransport {
        FakeTransport { request in
            switch request.url?.path {
            case "/v1/compat/apps":
                return FakeTransport.raw(Self.smallCatalogJSON)
            case "/v1/compat/presets":
                return FakeTransport.raw(#"{"office":{"description":"Office","vm":{"printers":"shared"}}}"#)
            default:
                return FakeTransport.error(status: 404, code: "not_found")
            }
        }
    }

    // MARK: Bundled seed

    func testBundledSeedParses() throws {
        let seed = try CompatClient.bundledSeed()
        XCTAssertEqual(seed.version, "2026.09.03")
        XCTAssertEqual(seed.apps.count, 31)
        XCTAssertEqual(seed.runtimes.count, 3)
        XCTAssertEqual(Set(seed.presets.keys), ["cad-graphics", "office", "gaming"])
        XCTAssertEqual(Set(seed.apps.map(\.id)).count, seed.apps.count, "app ids are unique")
        XCTAssertFalse(seed.categories.isEmpty)
        for app in seed.apps {
            XCTAssertFalse(app.name.isEmpty, app.id)
            XCTAssertFalse(app.vendor.isEmpty, app.id)
        }
    }

    func testAutoCADProfile() throws {
        let seed = try CompatClient.bundledSeed()
        let autocad = try XCTUnwrap(seed.app(id: "autocad"))
        XCTAssertEqual(autocad.rating, .gold)
        XCTAssertEqual(autocad.runtime, .vm)
        XCTAssertEqual(autocad.vendor, "Autodesk")
        XCTAssertEqual(autocad.category, "cad")
        XCTAssertEqual(autocad.categoryDisplayName, "CAD")
        XCTAssertEqual(autocad.versions, ["2024", "2025", "2026", "2027"])
        XCTAssertEqual(autocad.arch, "x64")
        XCTAssertEqual(autocad.vendorSupportKind, .unsupportedInVM)
        XCTAssertTrue(autocad.requiresRosetta)
        XCTAssertEqual(autocad.presetName, "cad-graphics")
        let requirements = try XCTUnwrap(autocad.requirements)
        XCTAssertEqual(requirements.directX, "11")
        XCTAssertEqual(requirements.directXRecommended, "12_0")
        XCTAssertEqual(requirements.ramGB, 16)
        XCTAssertEqual(requirements.diskGB, 20)
        XCTAssertEqual(requirements.guestRuntimes.count, 5)
        XCTAssertEqual(autocad.fixups.count, 4)
        XCTAssertTrue(autocad.fixups[0].isRequired)
        XCTAssertEqual(autocad.fixups[0].kind, .hostRequirement)
        XCTAssertEqual(autocad.fixups[0].summary, "Requires rosetta2")
        let sysvar = autocad.fixups[3]
        XCTAssertEqual(sysvar.kind, .sysvar)
        XCTAssertEqual(sysvar.key, "DYNMODE")
        XCTAssertEqual(sysvar.value, "0")
        XCTAssertEqual(sysvar.isOptional, true)
        XCTAssertFalse(sysvar.isRequired)
        XCTAssertEqual(sysvar.summary, "DYNMODE = 0")
    }

    func testPresetValues() throws {
        let seed = try CompatClient.bundledSeed()
        let cad = try XCTUnwrap(seed.presets["cad-graphics"])
        XCTAssertEqual(cad.vm?["vram_mb"]?.intValue, 4096)
        XCTAssertEqual(cad.vm?["display_mode"]?.stringValue, "scaled")
        XCTAssertEqual(cad.guest?["smooth_line_display"]?.stringValue, "off-if-slow")
        XCTAssertEqual(seed.presets["gaming"]?.bottle?["dxmt"]?.stringValue, "on")
        XCTAssertEqual(cad.vm?["vram_mb"]?.displayString, "4096")
    }

    func testRatingsRuntimesAndVendorSupportDecode() throws {
        let seed = try CompatClient.bundledSeed()
        XCTAssertEqual(seed.app(id: "vectorworks")?.rating, .notApplicable)
        XCTAssertEqual(seed.app(id: "vectorworks")?.hasNativeMacVersion, true)
        XCTAssertEqual(seed.app(id: "desktop-connector")?.rating, .broken)
        XCTAssertEqual(seed.app(id: "ms-office-windows")?.runtime, .either)
        XCTAssertEqual(seed.app(id: "ms-office-windows")?.vendorSupportKind, .supported)
        XCTAssertEqual(seed.app(id: "steam-dx11-games")?.runtime, .bottle)
        XCTAssertEqual(seed.app(id: "7zip")?.fixups.count, 0)
        XCTAssertNil(seed.app(id: "7zip")?.requirements)
    }

    // MARK: Search

    func testFilterMirrorsServerSearch() throws {
        let apps = try CompatClient.bundledSeed().apps
        XCTAssertEqual(Set(CompatClient.filter(apps, query: "AutoCAD").map(\.id)), ["autocad", "autocad-lt", "autocad-vertical"])
        XCTAssertEqual(CompatClient.filter(apps, query: "autodesk").count, 9, "vendor match")
        XCTAssertEqual(CompatClient.filter(apps, query: "civil").map(\.id), ["civil3d"], "id match")
        XCTAssertEqual(CompatClient.filter(apps, query: nil, category: "cad").count, 11)
        XCTAssertEqual(CompatClient.filter(apps, query: "  ").count, apps.count, "blank query matches everything")

        let vmApps = CompatClient.filter(apps, query: nil, runtime: .vm).map(\.id)
        XCTAssertTrue(vmApps.contains("ms-office-windows"), "`either` matches every runtime filter")
        XCTAssertFalse(vmApps.contains("steam-dx11-games"))

        let bottleApps = CompatClient.filter(apps, query: nil, runtime: .bottle).map(\.id)
        XCTAssertTrue(bottleApps.contains("notepad-plus-plus"))
        XCTAssertTrue(bottleApps.contains("steam-dx11-games"))
        XCTAssertFalse(bottleApps.contains("autocad"))

        XCTAssertTrue(CompatClient.filter(apps, query: "steam", runtime: .vm).isEmpty)
        XCTAssertEqual(CompatClient.filter(apps, query: "steam", category: "games", runtime: .bottle).count, 2)
    }

    // MARK: Cache and fallbacks

    func testCatalogFallsBackToBundledSeedWhenOffline() async throws {
        let transport = FakeTransport.offline()
        let client = makeClient(transport)
        let catalog = await client.catalog()
        XCTAssertEqual(catalog.version, "2026.09.03")
        XCTAssertEqual(catalog.apps.count, 31)
        XCTAssertEqual(transport.requestCount, 1)
        let fresh = await client.hasFreshCache
        XCTAssertFalse(fresh)
        let results = await client.search("revit")
        XCTAssertEqual(results.map(\.id), ["revit"])
        let presets = await client.presets()
        XCTAssertEqual(presets.count, 3)
    }

    func testNetworkCatalogIsCachedForADay() async throws {
        let transport = catalogTransport()
        let client = makeClient(transport)
        let first = await client.catalog()
        XCTAssertEqual(first.version, "2026.09.10")
        XCTAssertEqual(first.apps.count, 1)
        XCTAssertEqual(first.presets["office"]?.vm?["printers"]?.stringValue, "shared")
        XCTAssertEqual(first.runtimes.count, 3, "runtime descriptions are filled from the bundled seed")
        XCTAssertEqual(transport.requestCount, 2, "apps + presets")
        XCTAssertEqual(transport.requests[0].value(forHTTPHeaderField: "User-Agent"), "MIRRORZ/1.0.0 (macos)")

        _ = await client.catalog()
        XCTAssertEqual(transport.requestCount, 2, "served from the fresh memory cache")
        let fresh = await client.hasFreshCache
        XCTAssertTrue(fresh)
        XCTAssertTrue(FileManager.default.fileExists(atPath: cacheDirectory.appendingPathComponent(CompatClient.cacheFileName).path))

        // A new instance sharing the directory reads the disk cache without a request.
        let second = makeClient(transport)
        let cached = await second.catalog()
        XCTAssertEqual(cached.version, "2026.09.10")
        XCTAssertEqual(transport.requestCount, 2)

        clock.advance(by: 25 * 3_600)
        _ = await second.catalog()
        XCTAssertEqual(transport.requestCount, 4, "stale after 24 h")
    }

    func testStaleCacheBeatsBundledSeedWhenOffline() async throws {
        let transport = catalogTransport()
        let client = makeClient(transport)
        _ = await client.catalog()
        clock.advance(by: 3 * 86_400)
        transport.setHandler { _ in throw URLError(.timedOut) }
        let catalog = await client.catalog()
        XCTAssertEqual(catalog.version, "2026.09.10", "stale cache is better than the seed")
        XCTAssertEqual(transport.requestCount, 3)

        await client.clearCache()
        let afterClear = await client.catalog(policy: .offline)
        XCTAssertEqual(afterClear.version, "2026.09.03")
    }

    func testOfflinePolicyNeverTouchesTheNetwork() async {
        let transport = catalogTransport()
        let client = makeClient(transport)
        let catalog = await client.catalog(policy: .offline)
        XCTAssertEqual(catalog.version, "2026.09.03")
        XCTAssertEqual(transport.requestCount, 0)
    }

    func testNetworkFirstPolicyRefetches() async {
        let transport = catalogTransport()
        let client = makeClient(transport)
        _ = await client.catalog()
        _ = await client.catalog(policy: .networkFirst)
        XCTAssertEqual(transport.requestCount, 3, "apps again; presets already present after merge")
    }

    func testNoCacheDirectoryStillWorks() async {
        let transport = catalogTransport()
        let configuration = CompatClient.Configuration(baseURL: URL(string: "http://localhost:8787")!, userAgent: "MIRRORZ/1.0.0 (ios)", cacheDirectory: nil)
        let client = CompatClient(configuration: configuration, transport: transport, clock: { Date() })
        let catalog = await client.catalog()
        XCTAssertEqual(catalog.version, "2026.09.10")
    }

    // MARK: Decoding robustness

    func testLossyDecodingSkipsUnknownEntries() throws {
        let json = #"""
        {"version":"2027.01.01","apps":[
          {"id":"a","name":"A","vendor":"V","category":"cad","runtime":"vm","rating":"platinum","fixups":[]},
          {"id":"b","name":"B","vendor":"V","category":"cad","runtime":"vm","rating":"gold"}
        ]}
        """#
        let catalog = try JSONDecoder().decode(CompatCatalog.self, from: Data(json.utf8))
        XCTAssertEqual(catalog.apps.map(\.id), ["b"])
        XCTAssertEqual(catalog.apps[0].fixups, [])
        XCTAssertTrue(catalog.presets.isEmpty)
    }

    func testCompatAppCodableRoundTrip() throws {
        let seed = try CompatClient.bundledSeed()
        let data = try JSONEncoder().encode(seed)
        let decoded = try JSONDecoder().decode(CompatCatalog.self, from: data)
        XCTAssertEqual(decoded, seed)
    }

    // MARK: Detail, route, report

    func testAppByIDAddsCommunityAndFallsBackOffline() async throws {
        let detail = #"""
        {"id":"autocad","name":"AutoCAD","vendor":"Autodesk","category":"cad","runtime":"vm","rating":"gold","fixups":[],
         "community":{"works":8,"works_with_fixups":3,"partial":1,"broken":0,"total":12}}
        """#
        let transport = FakeTransport { request in
            switch request.url?.path {
            case "/v1/compat/apps/autocad": return FakeTransport.raw(detail)
            default: return FakeTransport.error(status: 404, code: "not_found", message: "unknown app")
            }
        }
        let client = makeClient(transport)
        let app = try await client.app(id: "autocad")
        XCTAssertEqual(app.community?.total, 12)
        XCTAssertEqual(app.community?.successRate ?? 0, 11.0 / 12.0, accuracy: 0.0001)

        do {
            _ = try await client.app(id: "nope")
            XCTFail("expected not_found")
        } catch let error as APIClientError {
            XCTAssertEqual(error.apiError?.code, .notFound)
        }

        let offline = makeClient(.offline())
        let local = try await offline.app(id: "revit")
        XCTAssertEqual(local.rating, .silver)
        XCTAssertNil(local.community)
        do {
            _ = try await offline.app(id: "nope")
            XCTFail("expected network error")
        } catch let error as APIClientError {
            XCTAssertTrue(error.isNetworkFailure)
        }
    }

    func testRouteLocalMirrorsServerAndRemoteWins() async {
        XCTAssertEqual(RouteRequest(needsDriver: true).localDecision.runtime, .vm)
        XCTAssertEqual(RouteRequest(needsService: true).localDecision.runtime, .vm)
        XCTAssertEqual(RouteRequest(dx: "12").localDecision.runtime, .vm)
        XCTAssertEqual(RouteRequest(arch: .arm64).localDecision.runtime, .vm)
        XCTAssertEqual(RouteRequest(arch: .x64, dx: "11").localDecision.runtime, .bottle)
        XCTAssertEqual(RouteRequest().localDecision.runtime, .bottle)

        let remote = FakeTransport { request in
            XCTAssertEqual(request.url?.path, "/v1/compat/route")
            return FakeTransport.raw(#"{"runtime":"vm","reason":"server said so"}"#)
        }
        let decision = await makeClient(remote).route(RouteRequest(arch: .x86))
        XCTAssertEqual(decision, RouteDecision(runtime: .vm, reason: "server said so"))

        let offline = await makeClient(.offline()).route(RouteRequest(arch: .x86))
        XCTAssertEqual(offline.runtime, .bottle)
    }

    func testReportPostsAnonymousPayload() async throws {
        let transport = FakeTransport { request in
            XCTAssertEqual(request.url?.path, "/v1/compat/reports")
            XCTAssertEqual(request.httpMethod, "POST")
            return FakeTransport.raw(#"{"accepted":true}"#, status: 202)
        }
        let client = makeClient(transport)
        let report = CompatReport(appID: "autocad", appVersion: "2026", runtime: .vm, result: .worksWithFixups, macModel: "Mac15,6", macOSVersion: "14.6", mirrorzVersion: "1.0.0", notes: "cursor lag fixed by preset")
        let receipt = try await client.report(report)
        XCTAssertTrue(receipt.accepted)

        let body = try XCTUnwrap(JSONSerialization.jsonObject(with: try XCTUnwrap(transport.requests[0].httpBody)) as? [String: Any])
        XCTAssertEqual(Set(body.keys), ["app_id", "app_version", "runtime", "result", "mac_model", "macos_version", "mirrorz_version", "notes"])
        XCTAssertEqual(body["result"] as? String, "works_with_fixups")
        XCTAssertNil(body["device"])
        XCTAssertNil(body["device_id"])
    }

    func testReportFieldLimitsMatchServer() {
        let report = CompatReport(appID: String(repeating: "a", count: 100), result: .works, notes: String(repeating: "x", count: 600))
        XCTAssertEqual(report.appID.count, 80)
        XCTAssertEqual(report.notes?.count, 500)
    }

    func testReportRateLimitSurfaces() async {
        let transport = FakeTransport { _ in FakeTransport.error(status: 429, code: "rate_limited", message: "too many reports") }
        do {
            _ = try await makeClient(transport).report(CompatReport(appID: "autocad", result: .works))
            XCTFail("expected rate_limited")
        } catch let error as APIClientError {
            XCTAssertEqual(error.apiError?.code, .rateLimited)
            XCTAssertEqual(error.apiError?.status, 429)
        } catch {
            XCTFail("unexpected \(error)")
        }
    }
}
