// LicenseKeyTests.swift
// Driven by core/tests/fixtures/license-fixtures.json so Swift, Rust and the server agree.

import XCTest
@testable import MirrorzKit

final class LicenseKeyTests: XCTestCase {
    private var fixtures: Fixtures!

    override func setUpWithError() throws {
        fixtures = try Fixtures.load()
    }

    func testValidFixtureKeysNormalizeAndRoundTrip() {
        XCTAssertEqual(fixtures.licenseKeys.valid.count, 50)
        for key in fixtures.licenseKeys.valid {
            let normalized = LicenseKey.normalize(key)
            XCTAssertNotNil(normalized, "expected \(key) to be valid")
            XCTAssertEqual(normalized?.count, LicenseKey.symbolCount)
            XCTAssertTrue(LicenseKey.isValid(key))
            XCTAssertEqual(LicenseKey.canonical(key), key, "format(normalize(key)) must reproduce the fixture key")
            XCTAssertEqual(LicenseKey.validation(of: key), .valid(normalized: normalized ?? ""))
        }
    }

    func testInvalidFixtureKeysAreRejected() {
        XCTAssertEqual(fixtures.licenseKeys.invalid.count, 20)
        for key in fixtures.licenseKeys.invalid {
            XCTAssertNil(LicenseKey.normalize(key), "expected \(key) to be invalid")
            XCTAssertFalse(LicenseKey.isValid(key))
            XCTAssertFalse(LicenseKey.validation(of: key).isValid)
        }
    }

    func testNormalizationVectors() {
        for vector in fixtures.licenseKeys.normalization {
            XCTAssertEqual(LicenseKey.normalize(vector.input), vector.normalized, "input: \(vector.input)")
        }
    }

    func testCheckSymbolMirrorsServer() {
        for key in fixtures.licenseKeys.valid {
            let normalized = LicenseKey.normalize(key)!
            let body = String(normalized.prefix(LicenseKey.bodyLength))
            XCTAssertEqual(LicenseKey.checkSymbol(forBody: body), normalized.last)
        }
    }

    func testFormatGroupsInFives() {
        XCTAssertEqual(LicenseKey.format("BPJ2WF5C8D4N1DJK0YZZM7E8V"), "MZ-BPJ2W-F5C8D-4N1DJ-K0YZZ-M7E8V")
        XCTAssertEqual(LicenseKey.format("BPJ2WF5"), "MZ-BPJ2W-F5")
        XCTAssertEqual(LicenseKey.format(""), "MZ-")
    }

    func testFormatPartialWhileTyping() {
        XCTAssertEqual(LicenseKey.formatPartial(""), "")
        XCTAssertEqual(LicenseKey.formatPartial("b"), "MZ-B")
        XCTAssertEqual(LicenseKey.formatPartial("MZ-B"), "MZ-B")
        XCTAssertEqual(LicenseKey.formatPartial("MZ-BPJ2W"), "MZ-BPJ2W")
        XCTAssertEqual(LicenseKey.formatPartial("MZ-BPJ2WF"), "MZ-BPJ2W-F")
        XCTAssertEqual(LicenseKey.formatPartial("mz bpj2w f5c8d 4nldj koyzz m7e8v"), "MZ-BPJ2W-F5C8D-4N1DJ-K0YZZ-M7E8V")
        // Foreign characters are dropped while typing; extra symbols are truncated.
        XCTAssertEqual(LicenseKey.formatPartial("MZ-BPJ2W-U!"), "MZ-BPJ2W")
        XCTAssertEqual(LicenseKey.formatPartial("MZ-BPJ2W-F5C8D-4N1DJ-K0YZZ-M7E8V-EXTRA"), "MZ-BPJ2W-F5C8D-4N1DJ-K0YZZ-M7E8V")
        // Typing "M" then "Z": one prefix is stripped, the rest stays body symbols.
        XCTAssertEqual(LicenseKey.formatPartial("MZ-MZ"), "MZ-MZ")
    }

    func testValidationStates() {
        XCTAssertEqual(LicenseKey.validation(of: ""), .empty)
        XCTAssertEqual(LicenseKey.validation(of: "MZ-"), .empty)
        XCTAssertEqual(LicenseKey.validation(of: "MZ-BPJ2W-F5C8D"), .incomplete(entered: 10))
        XCTAssertEqual(LicenseKey.validation(of: "MZ-BPJ2W-U"), .invalidCharacter("U"))
        XCTAssertEqual(LicenseKey.validation(of: "MZ-CPJ2W-F5C8D-4N1DJ-K0YZZ-M7E8V"), .badCheckSymbol)
        XCTAssertEqual(LicenseKey.validation(of: "MZ-BPJ2W-F5C8D-4N1DJ-K0YZZ-M7E8V"), .valid(normalized: "BPJ2WF5C8D4N1DJK0YZZM7E8V"))
        XCTAssertEqual(LicenseKey.validation(of: "MZ-BPJ2W-F5C8D-4N1DJ-K0YZZ-M7E8VX"), .badCheckSymbol)
    }

    func testLookAlikeMapping() {
        XCTAssertEqual(LicenseKey.cleanSymbols("oOiIlL"), "001111")
        XCTAssertEqual(LicenseKey.cleanSymbols("mz-abc"), "ABC")
        XCTAssertEqual(LicenseKey.cleanSymbols(" a b\tc\nd_e.f-g "), "ABCDEFG")
    }

    func testGeneratedKeysAreValid() {
        for _ in 0..<200 {
            let key = LicenseKey.generate()
            XCTAssertTrue(key.hasPrefix("MZ-"))
            XCTAssertEqual(key.count, "MZ-XXXXX-XXXXX-XXXXX-XXXXX-XXXXX".count)
            XCTAssertNotNil(LicenseKey.normalize(key), key)
        }
    }

    func testCorruptingAnySymbolBreaksTheCheck() {
        let key = "MZ-BPJ2W-F5C8D-4N1DJ-K0YZZ-M7E8V"
        let normalized = LicenseKey.normalize(key)!
        var chars = Array(normalized)
        for index in chars.indices {
            let original = chars[index]
            let replacement = LicenseKey.alphabet.first { $0 != original }!
            chars[index] = replacement
            XCTAssertNil(LicenseKey.normalize(String(chars)), "position \(index)")
            chars[index] = original
        }
    }
}
