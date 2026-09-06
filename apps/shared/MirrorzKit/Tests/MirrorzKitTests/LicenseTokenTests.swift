// LicenseTokenTests.swift
// Token verification and spec §3.4 rules, driven by the cross-language fixtures.

import XCTest
@testable import MirrorzKit

final class LicenseTokenTests: XCTestCase {
    private var fixtures: Fixtures!

    override func setUpWithError() throws {
        fixtures = try Fixtures.load()
    }

    func testFixtureTokensVerifyAsExpected() throws {
        XCTAssertEqual(fixtures.tokens.count, 8)
        for fixture in fixtures.tokens {
            do {
                let claims = try LicenseToken.verify(fixture.token, trustedKeys: fixtures.trusted, deviceID: fixtures.deviceID)
                XCTAssertTrue(fixture.expect.valid, "\(fixture.name) should have been rejected")
                XCTAssertEqual(claims.dev, fixtures.deviceID)
                XCTAssertEqual(claims.v, 1)
                XCTAssertEqual(claims.product, "mirrorz")
                XCTAssertEqual(claims.kid, fixtures.trustedKeys[0].kid)
                try checkEntitlementRules(fixture, claims: claims)
            } catch let error as LicenseTokenError {
                XCTAssertFalse(fixture.expect.valid, "\(fixture.name) should have verified: \(error)")
                XCTAssertEqual(error.code, fixture.expect.error, fixture.name)
            }
        }
    }

    private func checkEntitlementRules(_ fixture: Fixtures.TokenFixture, claims: LicenseClaims) throws {
        let now = fixtures.nowDate
        let snapshot = Entitlements.evaluate(claims: claims, now: now, buildDate: now)
        if let entitledNow = fixture.expect.entitledAtNow {
            XCTAssertEqual(snapshot.isEntitled, entitledNow, "\(fixture.name) entitled_at_now")
        }
        if let mode = fixture.expect.modeAtNow {
            XCTAssertEqual(snapshot.mode.rawValue, mode, "\(fixture.name) mode_at_now")
        }
        if let mode = fixture.expect.modeAfterUpdatesWindow {
            let upd = try XCTUnwrap(claims.updatesUntil)
            let later = Entitlements.evaluate(claims: claims, now: upd.addingTimeInterval(86_400), buildDate: upd.addingTimeInterval(86_400))
            XCTAssertEqual(later.mode.rawValue, mode, "\(fixture.name) mode_after_updates_window")
            XCTAssertEqual(later.isEntitled, fixture.expect.entitledAfterUpdatesWindow ?? true)
            XCTAssertEqual(later.features, claims.featureSet, "updates-expired mode keeps every feature")
        }
        for (at, entitled) in fixture.expect.entitledAt ?? [:] {
            let date = Date(timeIntervalSince1970: TimeInterval(try XCTUnwrap(Int(at))))
            let snapshotAt = Entitlements.evaluate(claims: claims, now: date, buildDate: now)
            XCTAssertEqual(snapshotAt.isEntitled, entitled, "\(fixture.name) entitled_at \(at)")
            XCTAssertEqual(snapshotAt.features.isEmpty, !entitled)
        }
    }

    func testPerpetualClaimsAndFeatures() throws {
        let claims = try LicenseToken.verify(try fixtures.token(named: "perpetual-standard"), trustedKeys: fixtures.trusted, deviceID: fixtures.deviceID)
        XCTAssertEqual(claims.kind, .perpetual)
        XCTAssertEqual(claims.planID, .standard)
        XCTAssertEqual(claims.featureSet, [.vm, .bottles, .noAds])
        XCTAssertEqual(claims.maxDev, 3)
        XCTAssertEqual(claims.lid, "lic_perp")
        XCTAssertNil(claims.subExp)
        XCTAssertEqual(claims.upd, fixtures.now + 365 * 86_400)
    }

    func testSubscriptionClaims() throws {
        let claims = try LicenseToken.verify(try fixtures.token(named: "subscription-pro-active"), trustedKeys: fixtures.trusted, deviceID: fixtures.deviceID)
        XCTAssertEqual(claims.kind, .subscription)
        XCTAssertEqual(claims.planID, .pro)
        XCTAssertEqual(claims.features, ["vm", "cli"])
        XCTAssertEqual(claims.subExp, fixtures.now + 37 * 86_400)
    }

    func testUnknownFeatureStringsAreIgnored() {
        XCTAssertEqual(Feature.set(from: ["vm", "teleport", "cli"]), [.vm, .cli])
    }

    func testTrustedKeyWithWrongMaterialFailsSignature() throws {
        // Same kid as the signer, but the untrusted public key: signature must fail, not kid lookup.
        let swapped = [TrustedKey(kid: fixtures.trustedKeys[0].kid, x: fixtures.untrustedKey.x)]
        XCTAssertThrowsError(try LicenseToken.verify(try fixtures.token(named: "perpetual-standard"), trustedKeys: swapped, deviceID: fixtures.deviceID)) { error in
            XCTAssertEqual(error as? LicenseTokenError, .badSignature)
        }
    }

    func testEmptyTrustedKeysRejectEverything() throws {
        XCTAssertThrowsError(try LicenseToken.verify(try fixtures.token(named: "perpetual-standard"), trustedKeys: [], deviceID: fixtures.deviceID)) { error in
            XCTAssertEqual(error as? LicenseTokenError, .unknownKid(fixtures.trustedKeys[0].kid))
        }
    }

    func testDeviceCheckCanBeSkippedServerStyle() throws {
        let claims = try LicenseToken.verify(try fixtures.token(named: "wrong-device"), trustedKeys: fixtures.trusted, deviceID: nil)
        XCTAssertEqual(claims.dev, "device-other")
    }

    func testTamperedPayloadDecodesUnverifiedButFailsVerification() throws {
        let token = try fixtures.token(named: "tampered")
        let unverified = try LicenseToken.decodeUnverified(token)
        XCTAssertEqual(unverified.plan, "pro")
        XCTAssertThrowsError(try LicenseToken.verify(token, trustedKeys: fixtures.trusted, deviceID: fixtures.deviceID)) { error in
            XCTAssertEqual(error as? LicenseTokenError, .badSignature)
        }
    }

    func testMalformedTokens() {
        for token in ["", "MZL1", "MZL1.abc", "MZL2.a.b", "MZL1..", "MZL1.!!!.sig", "a.b.c.d"] {
            XCTAssertThrowsError(try LicenseToken.verify(token, trustedKeys: fixtures.trusted, deviceID: fixtures.deviceID), token) { error in
                XCTAssertEqual(error as? LicenseTokenError, .malformed, token)
            }
        }
    }

    func testBadPublicKeyMaterial() throws {
        let broken = [TrustedKey(kid: fixtures.trustedKeys[0].kid, x: "not-base64url-32-bytes")]
        XCTAssertThrowsError(try LicenseToken.verify(try fixtures.token(named: "perpetual-standard"), trustedKeys: broken, deviceID: fixtures.deviceID)) { error in
            XCTAssertEqual(error as? LicenseTokenError, .badPublicKey(kid: fixtures.trustedKeys[0].kid))
        }
    }

    func testKidDerivationMatchesServer() {
        for key in fixtures.trusted {
            XCTAssertEqual(key.derivedKid, key.kid)
        }
        XCTAssertEqual(fixtures.untrustedKey.trustedKey.derivedKid, fixtures.untrustedKey.kid)
    }

    func testBase64URL() {
        let data = Data([0, 1, 2, 250, 251, 252, 253, 254, 255])
        let encoded = Base64URL.encode(data)
        XCTAssertFalse(encoded.contains("="))
        XCTAssertFalse(encoded.contains("+"))
        XCTAssertFalse(encoded.contains("/"))
        XCTAssertEqual(Base64URL.decode(encoded), data)
        XCTAssertEqual(Base64URL.decode("AQ"), Data([1]))
        XCTAssertEqual(Base64URL.decode("AQI"), Data([1, 2]))
        XCTAssertNil(Base64URL.decode("A"))
        XCTAssertEqual(Base64URL.decode(""), Data())
    }

    func testClaimsCodableUsesWireKeys() throws {
        let claims = LicenseClaims(kid: "k", lid: "lic_x", kind: .subscription, plan: "pro", features: ["vm"], dev: "d", maxDev: 5, iat: 1, exp: 2, subExp: 3, upd: nil)
        let data = try JSONEncoder().encode(claims)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(object["max_dev"] as? Int, 5)
        XCTAssertEqual(object["sub_exp"] as? Int, 3)
        XCTAssertEqual(object["product"] as? String, "mirrorz")
        XCTAssertNil(object["upd"])
        XCTAssertEqual(try JSONDecoder().decode(LicenseClaims.self, from: data), claims)
    }

    func testPublicKeyDocumentMapsToTrustedKeys() throws {
        let json = #"{"keys":[{"kty":"OKP","crv":"Ed25519","x":"\#(fixtures.trustedKeys[0].x)","use":"sig","alg":"EdDSA","kid":"\#(fixtures.trustedKeys[0].kid)"}],"raw":"\#(fixtures.trustedKeys[0].x)","format":"MZL1"}"#
        let document = try JSONDecoder().decode(PublicKeyDocument.self, from: Data(json.utf8))
        XCTAssertEqual(document.trustedKeys, fixtures.trusted)
    }
}
