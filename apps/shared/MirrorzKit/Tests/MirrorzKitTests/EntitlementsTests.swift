// EntitlementsTests.swift
// Entitlements state machine with a fixed clock, an in-memory keychain and a fake transport.

import XCTest
@testable import MirrorzKit

@MainActor
final class EntitlementsTests: XCTestCase {
    private var fixtures: Fixtures!
    private var clock: TestClock!
    private var store: InMemorySecureStore!

    /// Per-test state. Not a `setUpWithError` override: XCTest declares that method nonisolated,
    /// and overriding it inside a `@MainActor` test class conflicts with the class isolation.
    private func prepare() throws {
        fixtures = try Fixtures.load()
        clock = TestClock(fixtures.nowDate)
        store = InMemorySecureStore()
    }

    private func makeEntitlements(transport: FakeTransport, buildDate: Date? = nil) -> Entitlements {
        let clock = clock!
        let configuration = Entitlements.Configuration(
            trustedKeys: fixtures.trusted,
            device: .fixture,
            buildInfo: BuildInfo(version: "1.0.0", buildDate: buildDate ?? fixtures.nowDate),
            now: { clock.now },
            automaticRefresh: false
        )
        let client = LicenseClient(configuration: .init(baseURL: URL(string: "http://localhost:8787")!, appVersion: "1.0.0", platform: .macos), transport: transport)
        return Entitlements(configuration: configuration, client: client, store: store)
    }

    private func seedToken(_ name: String) throws {
        let state = Entitlements.PersistedState(token: try fixtures.token(named: name))
        try store.encode(state, forKey: "license-state")
    }

    // MARK: Bootstrap

    func testBootstrapWithoutTokenIsNotEntitledAndMakesNoRequests() throws {
        try prepare()
        let transport = FakeTransport.offline()
        let entitlements = makeEntitlements(transport: transport)
        entitlements.bootstrap()
        XCTAssertTrue(entitlements.isBootstrapped)
        XCTAssertEqual(entitlements.mode, .none)
        XCTAssertFalse(entitlements.isEntitled)
        XCTAssertTrue(entitlements.features.isEmpty)
        XCTAssertFalse(entitlements.has(.vm))
        XCTAssertEqual(transport.requestCount, 0, "launch never touches the network")
    }

    func testBootstrapWithStoredPerpetualToken() throws {
        try prepare()
        try seedToken("perpetual-standard")
        let transport = FakeTransport.offline()
        let entitlements = makeEntitlements(transport: transport)
        entitlements.bootstrap()
        XCTAssertEqual(entitlements.mode, .full)
        XCTAssertTrue(entitlements.isEntitled)
        XCTAssertEqual(entitlements.plan, .standard)
        XCTAssertEqual(entitlements.kind, .perpetual)
        XCTAssertEqual(entitlements.features, [.vm, .bottles, .noAds])
        XCTAssertTrue(entitlements.has(.noAds))
        XCTAssertFalse(entitlements.has(.cli))
        XCTAssertNil(entitlements.daysRemaining)
        XCTAssertEqual(transport.requestCount, 0)
    }

    func testPerpetualNewerBuildRunsInUpdatesExpiredMode() throws {
        try prepare()
        try seedToken("perpetual-standard")
        let claims = try LicenseToken.decodeUnverified(try fixtures.token(named: "perpetual-standard"))
        let afterWindow = try XCTUnwrap(claims.updatesUntil).addingTimeInterval(86_400)
        let entitlements = makeEntitlements(transport: .offline(), buildDate: afterWindow)
        entitlements.bootstrap()
        XCTAssertEqual(entitlements.mode, .updatesExpired)
        XCTAssertTrue(entitlements.isEntitled, "still fully functional")
        XCTAssertEqual(entitlements.features, [.vm, .bottles, .noAds], "no new-feature gating")
        XCTAssertTrue(entitlements.showsUpdateUpgradeBanner)
    }

    func testSubscriptionEntitledUntilSubExp() throws {
        try prepare()
        try seedToken("subscription-pro-active")
        let entitlements = makeEntitlements(transport: .offline())
        entitlements.bootstrap()
        XCTAssertEqual(entitlements.mode, .full)
        XCTAssertEqual(entitlements.plan, .pro)
        XCTAssertEqual(entitlements.features, [.vm, .cli])
        XCTAssertEqual(entitlements.daysRemaining, 37)

        clock.advance(by: 38 * 86_400)
        let later = makeEntitlements(transport: .offline())
        later.bootstrap()
        XCTAssertEqual(later.mode, .expired)
        XCTAssertFalse(later.isEntitled)
        XCTAssertTrue(later.features.isEmpty)
        XCTAssertEqual(later.plan, .pro, "plan stays visible for the expired-state UI")
    }

    func testTrialExpires() throws {
        try prepare()
        try seedToken("trial")
        clock.advance(by: 15 * 86_400)
        let entitlements = makeEntitlements(transport: .offline())
        entitlements.bootstrap()
        XCTAssertEqual(entitlements.kind, .trial)
        XCTAssertEqual(entitlements.mode, .expired)
        XCTAssertTrue(entitlements.isTrial)
    }

    func testWrongDeviceTokenIsDroppedAtBootstrap() throws {
        try prepare()
        try seedToken("wrong-device")
        let entitlements = makeEntitlements(transport: .offline())
        entitlements.bootstrap()
        XCTAssertEqual(entitlements.mode, .none)
        XCTAssertEqual(entitlements.lastError as? LicenseTokenError, .deviceMismatch)
        XCTAssertFalse(entitlements.hasToken)
    }

    // MARK: Apply / activate

    func testApplyRejectsForeignSignerAndKeepsState() throws {
        try prepare()
        let entitlements = makeEntitlements(transport: .offline())
        entitlements.bootstrap()
        XCTAssertThrowsError(try entitlements.apply(token: try fixtures.token(named: "foreign-signer"), license: nil)) { error in
            XCTAssertEqual(error as? LicenseTokenError, .badSignature)
        }
        XCTAssertEqual(entitlements.mode, .none)
        XCTAssertFalse(entitlements.hasToken)
    }

    func testActivateSendsNormalizedKeyAndStoresTokenAndKey() async throws {
        try prepare()
        let token = try fixtures.token(named: "subscription-pro-active")
        let transport = FakeTransport { request in
            XCTAssertEqual(request.url?.path, "/v1/licenses/activate")
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "User-Agent"), "MIRRORZ/1.0.0 (macos)")
            return FakeTransport.json(ActivationResponse(token: token, license: .sample(kind: .subscription, plan: .pro)))
        }
        let entitlements = makeEntitlements(transport: transport)
        entitlements.bootstrap()
        let typed = "mz bpj2w f5c8d 4nldj koyzz m7e8v"
        let license = try await entitlements.activate(key: typed)
        XCTAssertEqual(license.plan, "pro")
        XCTAssertEqual(entitlements.mode, .full)
        XCTAssertEqual(entitlements.licenseKey, "MZ-BPJ2W-F5C8D-4N1DJ-K0YZZ-M7E8V")
        XCTAssertEqual(entitlements.license?.devices.count, 1)
        XCTAssertNotNil(entitlements.lastRefreshSuccess)

        struct Body: Decodable { var key: String; var device: DeviceRecord }
        let body = try transport.body(Body.self, ofRequestAt: 0)
        XCTAssertEqual(body.key, "BPJ2WF5C8D4N1DJK0YZZM7E8V")
        XCTAssertEqual(body.device, .fixture)

        // A second instance restores everything from the keychain.
        let restored = makeEntitlements(transport: .offline())
        restored.bootstrap()
        XCTAssertEqual(restored.mode, .full)
        XCTAssertEqual(restored.licenseKey, "MZ-BPJ2W-F5C8D-4N1DJ-K0YZZ-M7E8V")
    }

    func testActivateWithBadKeyFailsLocally() async throws {
        try prepare()
        let transport = FakeTransport.offline()
        let entitlements = makeEntitlements(transport: transport)
        entitlements.bootstrap()
        do {
            _ = try await entitlements.activate(key: "MZ-UUUUU-UUUUU-UUUUU-UUUUU-UUUUU")
            XCTFail("expected invalidKey")
        } catch let error as APIClientError {
            guard case .invalidKey = error else { return XCTFail("unexpected \(error)") }
        }
        XCTAssertEqual(transport.requestCount, 0)
    }

    func testActivateSurfacesServerErrors() async throws {
        try prepare()
        let transport = FakeTransport { _ in FakeTransport.error(status: 409, code: "device_limit", message: "device limit reached (3)") }
        let entitlements = makeEntitlements(transport: transport)
        entitlements.bootstrap()
        do {
            _ = try await entitlements.activate(key: "MZ-BPJ2W-F5C8D-4N1DJ-K0YZZ-M7E8V")
            XCTFail("expected device_limit")
        } catch let error as APIClientError {
            XCTAssertEqual(error.apiError?.code, .deviceLimit)
            XCTAssertEqual(error.apiError?.status, 409)
        }
        XCTAssertEqual(entitlements.mode, .none)
    }

    func testStartTrialStoresToken() async throws {
        try prepare()
        let token = try fixtures.token(named: "trial")
        let transport = FakeTransport { request in
            XCTAssertEqual(request.url?.path, "/v1/trials")
            return FakeTransport.json(TrialResponse(token: token, license: .sample(kind: .trial, plan: .trial), existing: false), status: 201)
        }
        let entitlements = makeEntitlements(transport: transport)
        entitlements.bootstrap()
        let response = try await entitlements.startTrial()
        XCTAssertFalse(response.existing)
        XCTAssertEqual(entitlements.kind, .trial)
        XCTAssertEqual(entitlements.mode, .full)
        XCTAssertEqual(entitlements.daysRemaining, 14)
    }

    // MARK: Refresh rules

    func testRefreshForbiddenDropsEntitlementImmediately() async throws {
        try prepare()
        try seedToken("subscription-pro-active")
        let transport = FakeTransport { request in
            XCTAssertEqual(request.url?.path, "/v1/licenses/refresh")
            return FakeTransport.error(status: 403, code: "revoked", message: "license is not entitled: revoked")
        }
        let entitlements = makeEntitlements(transport: transport)
        entitlements.bootstrap()
        XCTAssertTrue(entitlements.isEntitled)
        await entitlements.refreshIfNeeded()
        XCTAssertEqual(transport.requestCount, 1)
        XCTAssertEqual(entitlements.mode, .expired)
        XCTAssertFalse(entitlements.isEntitled)
        XCTAssertTrue(entitlements.features.isEmpty)
        XCTAssertEqual(entitlements.droppedReason, .revoked)
        XCTAssertTrue(entitlements.hasToken, "token is kept so a later successful refresh can restore a paused license")

        // The drop survives a relaunch.
        let relaunched = makeEntitlements(transport: transport)
        relaunched.bootstrap()
        XCTAssertEqual(relaunched.mode, .expired)
    }

    func testRefreshNetworkErrorKeepsEntitlement() async throws {
        try prepare()
        try seedToken("subscription-pro-active")
        let transport = FakeTransport.offline()
        let entitlements = makeEntitlements(transport: transport)
        entitlements.bootstrap()
        await entitlements.refreshIfNeeded()
        XCTAssertEqual(transport.requestCount, 1)
        XCTAssertEqual(entitlements.mode, .full)
        XCTAssertTrue(entitlements.isEntitled)
        XCTAssertTrue((entitlements.lastError as? APIClientError)?.isNetworkFailure ?? false)
    }

    func testRefreshBadTokenKeepsWorkingUntilSubExp() async throws {
        try prepare()
        try seedToken("subscription-pro-active")
        let transport = FakeTransport { _ in FakeTransport.error(status: 401, code: "bad_token") }
        let entitlements = makeEntitlements(transport: transport)
        entitlements.bootstrap()
        await entitlements.refreshIfNeeded()
        XCTAssertEqual(entitlements.mode, .full, "only 403 drops the entitlement")
        XCTAssertEqual((entitlements.lastError as? APIClientError)?.apiError?.code, .badToken)
    }

    func testRefreshHappensAtMostOncePerDay() async throws {
        try prepare()
        try seedToken("subscription-pro-active")
        let token = try fixtures.token(named: "subscription-pro-active")
        let transport = FakeTransport { _ in FakeTransport.json(ActivationResponse(token: token, license: .sample(kind: .subscription, plan: .pro))) }
        let entitlements = makeEntitlements(transport: transport)
        entitlements.bootstrap()

        await entitlements.refreshIfNeeded()
        XCTAssertEqual(transport.requestCount, 1)
        XCTAssertEqual(entitlements.lastRefreshSuccess, clock.now)

        await entitlements.refreshIfNeeded()
        clock.advance(by: 23 * 3_600)
        await entitlements.refreshIfNeeded()
        XCTAssertEqual(transport.requestCount, 1, "throttled inside the 24 h window")

        clock.advance(by: 2 * 3_600)
        await entitlements.refreshIfNeeded()
        XCTAssertEqual(transport.requestCount, 2)

        // The throttle is persisted: a relaunch does not refresh again.
        let relaunched = makeEntitlements(transport: transport)
        relaunched.bootstrap()
        await relaunched.refreshIfNeeded()
        XCTAssertEqual(transport.requestCount, 2)
    }

    func testFailedAttemptsAreAlsoThrottled() async throws {
        try prepare()
        try seedToken("subscription-pro-active")
        let transport = FakeTransport.offline()
        let entitlements = makeEntitlements(transport: transport)
        entitlements.bootstrap()
        await entitlements.refreshIfNeeded()
        await entitlements.refreshIfNeeded()
        XCTAssertEqual(transport.requestCount, 1)
    }

    func testRefreshNowBypassesThrottleAndThrows() async throws {
        try prepare()
        try seedToken("subscription-pro-active")
        let transport = FakeTransport.offline()
        let entitlements = makeEntitlements(transport: transport)
        entitlements.bootstrap()
        await entitlements.refreshIfNeeded()
        do {
            try await entitlements.refreshNow()
            XCTFail("expected network error")
        } catch {
            XCTAssertTrue((error as? APIClientError)?.isNetworkFailure ?? false)
        }
        XCTAssertEqual(transport.requestCount, 2)
    }

    func testSuccessfulRefreshClearsDrop() async throws {
        try prepare()
        try seedToken("subscription-pro-active")
        let token = try fixtures.token(named: "subscription-pro-active")
        let transport = FakeTransport { _ in FakeTransport.error(status: 403, code: "paused") }
        let entitlements = makeEntitlements(transport: transport)
        entitlements.bootstrap()
        await entitlements.refreshIfNeeded()
        XCTAssertEqual(entitlements.mode, .expired)
        XCTAssertEqual(entitlements.droppedReason, .paused)

        transport.setHandler { _ in FakeTransport.json(ActivationResponse(token: token, license: .sample(kind: .subscription, plan: .pro))) }
        clock.advance(by: 25 * 3_600)
        await entitlements.refreshIfNeeded()
        XCTAssertEqual(entitlements.mode, .full)
        XCTAssertNil(entitlements.droppedReason)
    }

    // MARK: Deactivate / clear

    func testDeactivateThisDeviceClearsLocalState() async throws {
        try prepare()
        let token = try fixtures.token(named: "perpetual-standard")
        let transport = FakeTransport { request in
            if request.url?.path == "/v1/licenses/activate" {
                return FakeTransport.json(ActivationResponse(token: token, license: .sample()))
            }
            XCTAssertEqual(request.url?.path, "/v1/licenses/deactivate")
            return FakeTransport.json(DeactivationResponse(deactivated: true, license: .sample()))
        }
        let entitlements = makeEntitlements(transport: transport)
        entitlements.bootstrap()
        try await entitlements.activate(key: "MZ-BPJ2W-F5C8D-4N1DJ-K0YZZ-M7E8V")
        try await entitlements.deactivate(deviceID: DeviceRecord.fixture.id)
        XCTAssertEqual(entitlements.mode, .none)
        XCTAssertNil(entitlements.licenseKey)
        XCTAssertFalse(entitlements.hasToken)

        struct Body: Decodable { var key: String; var device_id: String }
        let body = try transport.body(Body.self, ofRequestAt: 1)
        XCTAssertEqual(body.key, "BPJ2WF5C8D4N1DJK0YZZM7E8V")
        XCTAssertEqual(body.device_id, DeviceRecord.fixture.id)
    }

    func testDeactivateWithoutKnownKeyFails() async throws {
        try prepare()
        try seedToken("perpetual-standard")
        let entitlements = makeEntitlements(transport: .offline())
        entitlements.bootstrap()
        do {
            try await entitlements.deactivate(deviceID: "other")
            XCTFail("expected keyUnknown")
        } catch {
            XCTAssertEqual(error as? EntitlementsError, .keyUnknown)
        }
    }

    func testClearRemovesEverything() throws {
        try prepare()
        try seedToken("perpetual-standard")
        let entitlements = makeEntitlements(transport: .offline())
        entitlements.bootstrap()
        XCTAssertTrue(entitlements.isEntitled)
        entitlements.clear()
        XCTAssertEqual(entitlements.mode, .none)
        XCTAssertNil(try store.decode(Entitlements.PersistedState.self, forKey: "license-state")?.token)
    }

    // MARK: Pure evaluation

    func testEvaluateWithoutClaims() throws {
        try prepare()
        let snapshot = Entitlements.evaluate(claims: nil, now: fixtures.nowDate, buildDate: fixtures.nowDate)
        XCTAssertEqual(snapshot, .none)
    }

    func testEvaluateDroppedPerpetual() throws {
        try prepare()
        let claims = try LicenseToken.decodeUnverified(try fixtures.token(named: "perpetual-standard"))
        let snapshot = Entitlements.evaluate(claims: claims, now: fixtures.nowDate, buildDate: fixtures.nowDate, dropped: true)
        XCTAssertEqual(snapshot.mode, .expired)
        XCTAssertTrue(snapshot.features.isEmpty)
        XCTAssertEqual(snapshot.plan, .standard)
    }

    func testPlanFeatureTablesMirrorServer() throws {
        try prepare()
        XCTAssertEqual(Plan.trial.features, [.vm, .bottles, .coherence, .compatDB])
        XCTAssertEqual(Plan.standard.features.count, 8)
        XCTAssertEqual(Plan.pro.features.count, 16)
        XCTAssertEqual(Plan.business.features.count, 21)
        XCTAssertEqual(Plan.features(forPlanNamed: "enterprise"), Plan.standard.features, "unknown plans fall back to Standard")
        XCTAssertEqual(Set(Feature.allCases.map(\.rawValue)).count, Feature.allCases.count)
        for feature in Feature.allCases {
            XCTAssertTrue(feature.minimumPlan.features.contains(feature))
        }
        XCTAssertEqual(StoreProductID.appStoreProductIDs.count, 6)
        XCTAssertEqual(StoreProductID.product(plan: .pro, term: .perpetual)?.rawValue, "com.mirrorz.pro.perpetual")
        XCTAssertNil(StoreProductID.product(plan: .business, term: .monthly))
    }
}
