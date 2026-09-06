// LicenseKey.swift
// Human-typed license keys. Exact mirror of server/src/license/keyformat.ts (spec §3.3).
//
// Format:   MZ-XXXXX-XXXXX-XXXXX-XXXXX-XXXXX
// Alphabet: Crockford base32 (no I, L, O, U) — unambiguous when read aloud or typed.
// 24 random symbols (120 bits of entropy) + 1 check symbol (Luhn mod N, N = 32).
// Keys are never stored in clear; the server keeps sha256(normalized key).

import Foundation

public enum LicenseKey {
    public static let alphabet = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
    public static let prefix = "MZ"
    /// Random symbols in a key.
    public static let bodyLength = 24
    /// Body plus the check symbol: the length of a normalized key.
    public static let symbolCount = 25
    /// Symbols per dash-separated group in the formatted form.
    public static let groupSize = 5

    private static let alphabetSymbols: [Character] = Array(alphabet)
    private static let alphabetIndex: [Character: Int] = {
        var map: [Character: Int] = [:]
        for (index, symbol) in alphabet.enumerated() { map[symbol] = index }
        return map
    }()
    private static let modulus = 32

    // MARK: Normalization

    /// Normalizes user input: uppercases, drops separators/whitespace, maps look-alikes
    /// (O→0, I/L→1), strips the MZ prefix and validates length, alphabet and check symbol.
    /// Returns the 25-symbol canonical body, or nil when the input is not a valid key.
    public static func normalize(_ input: String) -> String? {
        let symbols = cleanSymbols(input, droppingInvalid: false)
        guard symbols.count == symbolCount else { return nil }
        for symbol in symbols where alphabetIndex[symbol] == nil { return nil }
        guard luhnIsValid(symbols) else { return nil }
        return symbols
    }

    public static func isValid(_ input: String) -> Bool {
        normalize(input) != nil
    }

    /// Formats a run of symbols as `MZ-XXXXX-XXXXX-…` (mirror of `formatKey`).
    public static func format(_ symbols: String) -> String {
        var groups: [String] = []
        var current = ""
        for symbol in symbols {
            current.append(symbol)
            if current.count == groupSize {
                groups.append(current)
                current = ""
            }
        }
        if !current.isEmpty { groups.append(current) }
        return "\(prefix)-\(groups.joined(separator: "-"))"
    }

    /// The canonical display form of a valid key, or nil when invalid.
    public static func canonical(_ input: String) -> String? {
        normalize(input).map(format)
    }

    // MARK: Live typing support

    /// Applies the normalization steps that do not depend on the full key being present:
    /// uppercase, strip separators and whitespace, map look-alikes, strip one leading `MZ`.
    /// With `droppingInvalid` the result contains only alphabet symbols (used while typing);
    /// otherwise foreign characters are kept so `normalize` can reject them.
    public static func cleanSymbols(_ input: String, droppingInvalid: Bool = true, maxLength: Int? = nil) -> String {
        var cleaned = ""
        for scalarCharacter in input.uppercased() {
            if scalarCharacter.isWhitespace || scalarCharacter == "-" || scalarCharacter == "_"
                || scalarCharacter == "." || scalarCharacter == "\u{FEFF}" {
                continue
            }
            switch scalarCharacter {
            case "O": cleaned.append("0")
            case "I", "L": cleaned.append("1")
            default: cleaned.append(scalarCharacter)
            }
        }
        if cleaned.hasPrefix(prefix) {
            cleaned.removeFirst(prefix.count)
        }
        if droppingInvalid {
            cleaned.removeAll { alphabetIndex[$0] == nil }
        }
        if let maxLength, cleaned.count > maxLength {
            cleaned = String(cleaned.prefix(maxLength))
        }
        return cleaned
    }

    /// Progressive formatting for a text field: `""` stays empty, otherwise the cleaned
    /// symbols are grouped as `MZ-XXXXX-XX`. At most 25 symbols are kept.
    public static func formatPartial(_ input: String) -> String {
        let symbols = cleanSymbols(input, droppingInvalid: true, maxLength: symbolCount)
        return symbols.isEmpty ? "" : format(symbols)
    }

    /// Instant feedback for the key entry field.
    public enum Validation: Hashable, Sendable {
        case empty
        case incomplete(entered: Int)
        case invalidCharacter(Character)
        case badCheckSymbol
        case valid(normalized: String)

        public var isValid: Bool {
            if case .valid = self { return true }
            return false
        }
    }

    public static func validation(of input: String) -> Validation {
        let symbols = cleanSymbols(input, droppingInvalid: false)
        if symbols.isEmpty { return .empty }
        if let foreign = symbols.first(where: { alphabetIndex[$0] == nil }) { return .invalidCharacter(foreign) }
        if symbols.count < symbolCount { return .incomplete(entered: symbols.count) }
        if symbols.count > symbolCount { return .badCheckSymbol }
        return luhnIsValid(symbols) ? .valid(normalized: symbols) : .badCheckSymbol
    }

    // MARK: Luhn mod N (N = 32)

    /// Mirror of `luhnModNValid`: true when the 25-symbol string has a correct check symbol.
    static func luhnIsValid(_ full: String) -> Bool {
        var factor = 1
        var sum = 0
        for symbol in full.reversed() {
            guard let code = alphabetIndex[symbol] else { return false }
            var addend = factor * code
            factor = factor == 2 ? 1 : 2
            addend = addend / modulus + addend % modulus
            sum += addend
        }
        return sum % modulus == 0
    }

    /// Mirror of `luhnModNCheck`: the check symbol for a 24-symbol body (nil for foreign symbols).
    static func checkSymbol(forBody body: String) -> Character? {
        var factor = 2
        var sum = 0
        for symbol in body.reversed() {
            guard let code = alphabetIndex[symbol] else { return nil }
            var addend = factor * code
            factor = factor == 2 ? 1 : 2
            addend = addend / modulus + addend % modulus
            sum += addend
        }
        let remainder = sum % modulus
        return alphabetSymbols[(modulus - remainder) % modulus]
    }

    // MARK: Generation (tests and tooling only)

    /// Generates a well-formed key. Real keys are issued by the server, which stores their
    /// hash; a locally generated key activates nothing. Exposed for tests and previews.
    public static func generate<G: RandomNumberGenerator>(using generator: inout G) -> String {
        var body = ""
        for _ in 0..<bodyLength {
            body.append(alphabetSymbols[Int.random(in: 0..<modulus, using: &generator)])
        }
        let check = checkSymbol(forBody: body) ?? "0"
        return format(body + String(check))
    }

    public static func generate() -> String {
        var generator = SystemRandomNumberGenerator()
        return generate(using: &generator)
    }
}
