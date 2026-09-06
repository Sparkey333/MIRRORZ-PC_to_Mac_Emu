// LicenseToken.swift
// Offline device tokens (spec §3.4, mirror of server/src/license/token.ts).
//
//   MZL1.<base64url(JSON claims)>.<base64url(Ed25519 signature over UTF-8 "MZL1.<payload>")>
//
// Verification order: split → decode claims → known kid → signature → version → device id.

import CryptoKit
import Foundation

/// Claims embedded in a signed device token. All times are Unix seconds.
public struct LicenseClaims: Codable, Hashable, Sendable {
    public var v: Int
    public var kid: String
    /// License id (`lic_…`).
    public var lid: String
    public var kind: LicenseKind
    /// Raw plan string; see `planID` for the typed value.
    public var plan: String
    public var product: String
    /// Raw feature strings; see `featureSet` for the typed value.
    public var features: [String]
    /// Device id the token is bound to.
    public var dev: String
    public var maxDev: Int
    public var iat: Int
    /// Token expiry. For perpetual licenses this only schedules a refresh.
    public var exp: Int
    /// Subscription/trial period end (including grace).
    public var subExp: Int?
    /// Perpetual: feature updates allowed for builds dated on or before this.
    public var upd: Int?

    enum CodingKeys: String, CodingKey {
        case v, kid, lid, kind, plan, product, features, dev
        case maxDev = "max_dev"
        case iat, exp
        case subExp = "sub_exp"
        case upd
    }

    public init(
        v: Int = 1,
        kid: String,
        lid: String,
        kind: LicenseKind,
        plan: String,
        product: String = MirrorzIdentity.tokenProduct,
        features: [String],
        dev: String,
        maxDev: Int,
        iat: Int,
        exp: Int,
        subExp: Int? = nil,
        upd: Int? = nil
    ) {
        self.v = v
        self.kid = kid
        self.lid = lid
        self.kind = kind
        self.plan = plan
        self.product = product
        self.features = features
        self.dev = dev
        self.maxDev = maxDev
        self.iat = iat
        self.exp = exp
        self.subExp = subExp
        self.upd = upd
    }

    public var planID: Plan? { Plan(rawValue: plan) }
    public var featureSet: Set<Feature> { Feature.set(from: features) }
    public var issuedAt: Date { Date(timeIntervalSince1970: TimeInterval(iat)) }
    public var expiresAt: Date { Date(timeIntervalSince1970: TimeInterval(exp)) }
    public var subscriptionEndsAt: Date? { subExp.map { Date(timeIntervalSince1970: TimeInterval($0)) } }
    public var updatesUntil: Date? { upd.map { Date(timeIntervalSince1970: TimeInterval($0)) } }
}

/// A trusted Ed25519 signing key: `kid` plus the raw 32-byte public key, base64url.
public struct TrustedKey: Codable, Hashable, Sendable {
    public let kid: String
    public let x: String

    public init(kid: String, x: String) {
        self.kid = kid
        self.x = x
    }

    public func publicKey() throws -> Curve25519.Signing.PublicKey {
        guard let raw = Base64URL.decode(x), raw.count == 32 else {
            throw LicenseTokenError.badPublicKey(kid: kid)
        }
        do {
            return try Curve25519.Signing.PublicKey(rawRepresentation: raw)
        } catch {
            throw LicenseTokenError.badPublicKey(kid: kid)
        }
    }

    /// The key id the server derives for a raw public key: first 16 hex chars of sha256(x).
    public var derivedKid: String {
        let digest = SHA256.hash(data: Data(x.utf8))
        return digest.map { String(format: "%02x", $0) }.joined().prefix(16).description
    }
}

public enum TrustedKeys {
    /// Info.plist key holding an array of `{ kid, x }` dictionaries with the embedded
    /// production public keys. Each app target ships the current key set there.
    public static let infoPlistKey = "MZTrustedLicenseKeys"

    /// Loads the embedded keys from a bundle. Returns an empty list when the key is absent;
    /// an empty list rejects every token, so release builds must carry at least one key.
    public static func embedded(in bundle: Bundle = .main) -> [TrustedKey] {
        guard let entries = bundle.object(forInfoDictionaryKey: infoPlistKey) as? [[String: Any]] else { return [] }
        return entries.compactMap { entry in
            guard let kid = entry["kid"] as? String, let x = entry["x"] as? String else { return nil }
            return TrustedKey(kid: kid, x: x)
        }
    }
}

public enum LicenseTokenError: Error, Hashable, Sendable {
    case malformed
    case unsupportedVersion(Int)
    case unknownKid(String)
    case badPublicKey(kid: String)
    case badSignature
    case deviceMismatch

    /// Stable code, aligned with the cross-language fixtures.
    public var code: String {
        switch self {
        case .malformed: return "malformed"
        case .unsupportedVersion: return "unsupported_version"
        case .unknownKid: return "unknown_kid"
        case .badPublicKey: return "bad_public_key"
        case .badSignature: return "bad_signature"
        case .deviceMismatch: return "device_mismatch"
        }
    }
}

extension LicenseTokenError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .malformed: return "The license token is malformed."
        case .unsupportedVersion(let v): return "Unsupported license token version \(v)."
        case .unknownKid(let kid): return "The license token was signed with an unknown key (\(kid))."
        case .badPublicKey(let kid): return "The embedded public key \(kid) is invalid."
        case .badSignature: return "The license token signature is invalid."
        case .deviceMismatch: return "The license token belongs to a different device."
        }
    }
}

public enum LicenseToken {
    public static let prefix = "MZL1"

    public struct Parts: Hashable, Sendable {
        public let header: String
        public let payload: String
        public let signature: String

        /// The bytes the signature covers: UTF-8 of `MZL1.<payload>`.
        public var signingInput: Data { Data("\(header).\(payload)".utf8) }
    }

    public static func split(_ token: String) throws -> Parts {
        let parts = token.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0] == prefix else { throw LicenseTokenError.malformed }
        return Parts(header: String(parts[0]), payload: String(parts[1]), signature: String(parts[2]))
    }

    /// Decodes the claims without checking the signature. Only for display/debugging;
    /// entitlement decisions must use `verify`.
    public static func decodeUnverified(_ token: String) throws -> LicenseClaims {
        try decodeClaims(try split(token).payload)
    }

    /// Verifies the token against the embedded trusted keys and, when given, the local device id.
    public static func verify(_ token: String, trustedKeys: [TrustedKey], deviceID: String?) throws -> LicenseClaims {
        let parts = try split(token)
        let claims = try decodeClaims(parts.payload)
        guard let key = trustedKeys.first(where: { $0.kid == claims.kid }) else {
            throw LicenseTokenError.unknownKid(claims.kid)
        }
        guard let signature = Base64URL.decode(parts.signature), signature.count == 64 else {
            throw LicenseTokenError.badSignature
        }
        let publicKey = try key.publicKey()
        guard publicKey.isValidSignature(signature, for: parts.signingInput) else {
            throw LicenseTokenError.badSignature
        }
        guard claims.v == 1 else { throw LicenseTokenError.unsupportedVersion(claims.v) }
        if let deviceID, claims.dev != deviceID {
            throw LicenseTokenError.deviceMismatch
        }
        return claims
    }

    private static func decodeClaims(_ payload: String) throws -> LicenseClaims {
        guard let data = Base64URL.decode(payload) else { throw LicenseTokenError.malformed }
        do {
            return try JSONDecoder().decode(LicenseClaims.self, from: data)
        } catch {
            throw LicenseTokenError.malformed
        }
    }
}

/// RFC 4648 §5 base64url without padding (what Node's `base64url` encoding produces).
public enum Base64URL {
    public static func encode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    public static func decode(_ string: String) -> Data? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder == 1 { return nil }
        if remainder > 0 { base64.append(String(repeating: "=", count: 4 - remainder)) }
        return Data(base64Encoded: base64)
    }
}
