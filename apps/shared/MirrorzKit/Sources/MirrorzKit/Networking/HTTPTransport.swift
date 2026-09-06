// HTTPTransport.swift
// Minimal, injectable HTTP layer shared by LicenseClient and CompatClient.
// Tests provide a fake transport; apps use URLSession.

import Foundation

/// A completed HTTP exchange. Decoupled from `HTTPURLResponse` so it is plainly `Sendable`
/// and trivially constructible in tests.
public struct HTTPResponse: Hashable, Sendable {
    public var statusCode: Int
    public var headers: [String: String]
    public var body: Data

    public init(statusCode: Int, headers: [String: String] = [:], body: Data = Data()) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
    }

    public var isSuccess: Bool { (200..<300).contains(statusCode) }
}

public protocol HTTPTransport: Sendable {
    func send(_ request: URLRequest) async throws -> HTTPResponse
}

/// Production transport backed by `URLSession`.
public struct URLSessionTransport: HTTPTransport {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// A session with ephemeral storage (no cookies, no cache) sized for small JSON calls.
    public static func ephemeral(timeout: TimeInterval = 20) -> URLSessionTransport {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout * 3
        configuration.waitsForConnectivity = false
        configuration.httpAdditionalHeaders = nil
        return URLSessionTransport(session: URLSession(configuration: configuration))
    }

    public func send(_ request: URLRequest) async throws -> HTTPResponse {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        var headers: [String: String] = [:]
        for (key, value) in http.allHeaderFields {
            if let key = key as? String, let value = value as? String {
                headers[key.lowercased()] = value
            }
        }
        return HTTPResponse(statusCode: http.statusCode, headers: headers, body: data)
    }
}

/// Builds requests with the headers every MIRRORZ API call carries.
struct APIRequestBuilder: Sendable {
    var baseURL: URL
    var userAgent: String
    var timeout: TimeInterval

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return encoder
    }()

    func get(_ path: String, query: [URLQueryItem] = [], headers: [String: String] = [:]) -> URLRequest {
        var request = URLRequest(url: url(path, query: query))
        request.httpMethod = "GET"
        apply(headers: &request)
        for (field, value) in headers { request.setValue(value, forHTTPHeaderField: field) }
        return request
    }

    func post<Body: Encodable>(_ path: String, body: Body, headers: [String: String] = [:]) throws -> URLRequest {
        var request = URLRequest(url: url(path))
        request.httpMethod = "POST"
        request.httpBody = try Self.encoder.encode(body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        apply(headers: &request)
        for (field, value) in headers { request.setValue(value, forHTTPHeaderField: field) }
        return request
    }

    /// `Authorization: Bearer <token>` for endpoints authenticated with a device token.
    static func bearer(_ token: String) -> [String: String] {
        ["Authorization": "Bearer \(token)"]
    }

    private func url(_ path: String, query: [URLQueryItem] = []) -> URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) ?? URLComponents()
        let base = components.path.hasSuffix("/") ? String(components.path.dropLast()) : components.path
        components.path = base + path
        components.queryItems = query.isEmpty ? nil : query
        return components.url ?? baseURL.appendingPathComponent(path)
    }

    private func apply(headers request: inout URLRequest) {
        request.timeoutInterval = timeout
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.cachePolicy = .reloadIgnoringLocalCacheData
    }
}

/// Decodes MIRRORZ API responses and maps the `{ error, message }` envelope to `APIError`.
enum APIResponseDecoder {
    private static let decoder = JSONDecoder()

    private struct ErrorEnvelope: Decodable {
        var error: String
        var message: String?
    }

    static func decode<T: Decodable>(_ type: T.Type, from response: HTTPResponse) throws -> T {
        try check(response)
        do {
            return try decoder.decode(T.self, from: response.body)
        } catch {
            throw APIClientError.decoding(error)
        }
    }

    /// Throws for non-2xx responses; success responses are returned unchanged.
    static func check(_ response: HTTPResponse) throws {
        guard !response.isSuccess else { return }
        if let envelope = try? decoder.decode(ErrorEnvelope.self, from: response.body) {
            throw APIClientError.api(APIError(
                status: response.statusCode,
                code: APIErrorCode(rawValue: envelope.error),
                message: envelope.message ?? envelope.error
            ))
        }
        throw APIClientError.unexpectedStatus(response.statusCode)
    }

    /// Runs a transport call, translating transport failures into `.network`.
    static func send(_ request: URLRequest, via transport: HTTPTransport) async throws -> HTTPResponse {
        do {
            return try await transport.send(request)
        } catch let error as APIClientError {
            throw error
        } catch {
            throw APIClientError.network(error)
        }
    }
}
