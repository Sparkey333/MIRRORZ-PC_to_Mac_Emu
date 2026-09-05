// RemoteClient.swift
// HTTP side of docs/spec/remote-protocol.md: create pairings (§3.1), fetch ICE servers (§6),
// and build the authenticated WebSocket request (§4). The socket itself is driven by the app
// (`URLSessionWebSocketTask`) with `RemoteCodec` for framing.

import Foundation

public actor RemoteClient {
    public struct Configuration: Sendable {
        public var baseURL: URL
        public var userAgent: String
        public var timeout: TimeInterval

        public init(baseURL: URL = MirrorzIdentity.productionAPIBaseURL, userAgent: String, timeout: TimeInterval = 20) {
            self.baseURL = baseURL
            self.userAgent = userAgent
            self.timeout = timeout
        }
    }

    public let configuration: Configuration
    private let transport: HTTPTransport
    private let builder: APIRequestBuilder

    public init(configuration: Configuration, transport: HTTPTransport = URLSessionTransport.ephemeral()) {
        self.configuration = configuration
        self.transport = transport
        self.builder = APIRequestBuilder(baseURL: configuration.baseURL, userAgent: configuration.userAgent, timeout: configuration.timeout)
    }

    private struct PairingBody: Encodable {
        var token: String
        var name: String?
    }

    /// `POST /v1/remote/pairings` (host). Returns the code, room and deep link for the QR code.
    /// `name` is the host display name (≤ 60 characters, truncated here).
    public func createPairing(token: String, name: String? = nil) async throws -> PairingResponse {
        let body = PairingBody(token: token, name: name.map { String($0.prefix(RemoteProtocol.maxNameLength)) })
        let request: URLRequest
        do {
            request = try builder.post("/v1/remote/pairings", body: body)
        } catch {
            throw APIClientError.decoding(error)
        }
        let response = try await APIResponseDecoder.send(request, via: transport)
        return try APIResponseDecoder.decode(PairingResponse.self, from: response)
    }

    /// `GET /v1/remote/ice` with `Authorization: Bearer <token>`.
    public func iceServers(token: String) async throws -> ICEServersResponse {
        let request = builder.get("/v1/remote/ice", headers: APIRequestBuilder.bearer(token))
        let response = try await APIResponseDecoder.send(request, via: transport)
        return try APIResponseDecoder.decode(ICEServersResponse.self, from: response)
    }

    /// Request for `GET /v1/remote/ws` with the token in the `Authorization` header (preferred
    /// by the spec; native WebSocket clients can set headers).
    public nonisolated func webSocketRequest(_ socket: RemoteSocketRequest) -> URLRequest {
        socket.urlRequest(base: configuration.baseURL, userAgent: configuration.userAgent)
    }
}
