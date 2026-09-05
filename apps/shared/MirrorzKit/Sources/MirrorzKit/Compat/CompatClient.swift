// CompatClient.swift
// Compatibility Database client (spec §4): 24 h disk cache in Application Support/MIRRORZ,
// bundled seed fallback for offline use, local search, opt-in anonymous reports.

import Foundation

public actor CompatClient {
    public struct Configuration: Sendable {
        public var baseURL: URL
        public var userAgent: String
        /// Directory holding `compat-cache.json`; nil disables the disk cache.
        public var cacheDirectory: URL?
        /// Catalog freshness window (spec §4: 24 h).
        public var maxAge: TimeInterval
        public var timeout: TimeInterval

        public init(
            baseURL: URL = MirrorzIdentity.productionAPIBaseURL,
            userAgent: String,
            cacheDirectory: URL? = CompatClient.defaultCacheDirectory(),
            maxAge: TimeInterval = 24 * 60 * 60,
            timeout: TimeInterval = 20
        ) {
            self.baseURL = baseURL
            self.userAgent = userAgent
            self.cacheDirectory = cacheDirectory
            self.maxAge = maxAge
            self.timeout = timeout
        }
    }

    public enum CachePolicy: Sendable {
        /// Fresh memory/disk cache, then network, then stale cache, then bundled seed.
        case cachedThenNetwork
        /// Network first; falls back like `cachedThenNetwork` on failure.
        case networkFirst
        /// Never touch the network (memory/disk cache, then bundled seed).
        case offline
    }

    public static let cacheFileName = "compat-cache.json"

    public let configuration: Configuration
    private let transport: HTTPTransport
    private let clock: @Sendable () -> Date
    private let builder: APIRequestBuilder
    private var memory: CacheEnvelope?

    private struct CacheEnvelope: Codable, Sendable {
        var fetchedAt: Date
        var catalog: CompatCatalog
    }

    public init(configuration: Configuration, transport: HTTPTransport = URLSessionTransport.ephemeral(), clock: @escaping @Sendable () -> Date = { Date() }) {
        self.configuration = configuration
        self.transport = transport
        self.clock = clock
        self.builder = APIRequestBuilder(baseURL: configuration.baseURL, userAgent: configuration.userAgent, timeout: configuration.timeout)
    }

    // MARK: Bundled seed and cache locations

    /// `Application Support/MIRRORZ` in the user domain.
    public static func defaultCacheDirectory(fileManager: FileManager = .default) -> URL? {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("MIRRORZ", isDirectory: true)
    }

    /// The copy of server/src/compat/seed.json shipped inside the package.
    public static func bundledSeed() throws -> CompatCatalog {
        guard let url = Bundle.module.url(forResource: "compat-seed", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile, userInfo: [NSFilePathErrorKey: "compat-seed.json"])
        }
        return try JSONDecoder().decode(CompatCatalog.self, from: Data(contentsOf: url))
    }

    // MARK: Catalog

    /// Returns a catalog under the given policy. Never throws: the bundled seed is the floor.
    public func catalog(policy: CachePolicy = .cachedThenNetwork) async -> CompatCatalog {
        let now = clock()
        switch policy {
        case .cachedThenNetwork:
            if let fresh = cached(now: now, requireFresh: true) { return fresh.catalog }
            let fetched = await fetchCatalogOrNil()
            if let fetched { return fetched }
            if let stale = cached(now: now, requireFresh: false) { return stale.catalog }
        case .networkFirst:
            let fetched = await fetchCatalogOrNil()
            if let fetched { return fetched }
            if let stale = cached(now: now, requireFresh: false) { return stale.catalog }
        case .offline:
            if let stale = cached(now: now, requireFresh: false) { return stale.catalog }
        }
        return Self.bundledSeedOrEmpty()
    }

    /// Forces a network refresh and returns the new catalog.
    @discardableResult
    public func refresh() async throws -> CompatCatalog {
        try await fetchCatalog()
    }

    /// True when a cached catalog newer than `maxAge` exists.
    public var hasFreshCache: Bool {
        cached(now: clock(), requireFresh: true) != nil
    }

    public func clearCache() {
        memory = nil
        if let url = cacheFileURL {
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: Queries

    /// Local search over the catalog, mirroring `GET /v1/compat/apps?q=&category=&runtime=`.
    public func search(_ query: String? = nil, category: String? = nil, runtime: CompatRuntime? = nil, policy: CachePolicy = .cachedThenNetwork) async -> [CompatApp] {
        let apps = await catalog(policy: policy).apps
        return Self.filter(apps, query: query, category: category, runtime: runtime)
    }

    /// Pure matcher (same semantics as the server's `search`).
    public static func filter(_ apps: [CompatApp], query: String?, category: String? = nil, runtime: CompatRuntime? = nil) -> [CompatApp] {
        apps.filter { app in
            if let category, !category.isEmpty, app.category != category { return false }
            if let runtime, !app.runtime.matches(runtime) { return false }
            return app.matches(query: query ?? "")
        }
    }

    /// `GET /v1/compat/apps/:id` (adds community counts). Falls back to the local catalog entry
    /// when offline; throws `.api(not_found)` when the app is unknown everywhere.
    public func app(id: String) async throws -> CompatApp {
        do {
            let response = try await APIResponseDecoder.send(builder.get("/v1/compat/apps/\(Self.pathComponent(id))"), via: transport)
            return try APIResponseDecoder.decode(CompatApp.self, from: response)
        } catch let error as APIClientError {
            if case .api(let apiError) = error, apiError.status == 404 { throw error }
            let offline = await catalog(policy: .offline)
            if let local = offline.app(id: id) { return local }
            throw error
        }
    }

    /// Presets from the cached catalog, else the bundled seed.
    public func presets() async -> [String: CompatPreset] {
        let cached = await catalog(policy: .offline).presets
        if !cached.isEmpty { return cached }
        return Self.bundledSeedOrEmpty().presets
    }

    /// `POST /v1/compat/route`; identical local heuristic when offline.
    public func route(_ request: RouteRequest) async -> RouteDecision {
        guard let urlRequest = try? builder.post("/v1/compat/route", body: request) else { return request.localDecision }
        if let response = try? await APIResponseDecoder.send(urlRequest, via: transport),
           let decision = try? APIResponseDecoder.decode(RouteDecision.self, from: response) {
            return decision
        }
        return request.localDecision
    }

    /// `POST /v1/compat/reports` (202). Only call after the user enabled
    /// "Send anonymous compatibility reports" in Settings › Privacy.
    public func report(_ report: CompatReport) async throws -> CompatReportReceipt {
        let request: URLRequest
        do {
            request = try builder.post("/v1/compat/reports", body: report)
        } catch {
            throw APIClientError.decoding(error)
        }
        let response = try await APIResponseDecoder.send(request, via: transport)
        return try APIResponseDecoder.decode(CompatReportReceipt.self, from: response)
    }

    // MARK: Internals

    private var cacheFileURL: URL? {
        configuration.cacheDirectory?.appendingPathComponent(Self.cacheFileName, isDirectory: false)
    }

    private func cached(now: Date, requireFresh: Bool) -> CacheEnvelope? {
        if memory == nil, let url = cacheFileURL, let data = try? Data(contentsOf: url) {
            memory = try? Self.decoder.decode(CacheEnvelope.self, from: data)
        }
        guard let envelope = memory else { return nil }
        if requireFresh, now.timeIntervalSince(envelope.fetchedAt) >= configuration.maxAge { return nil }
        if envelope.fetchedAt > now.addingTimeInterval(60) { return nil } // clock went backwards; distrust
        return envelope
    }

    private func fetchCatalogOrNil() async -> CompatCatalog? {
        do {
            return try await fetchCatalog()
        } catch {
            return nil
        }
    }

    static func bundledSeedOrEmpty() -> CompatCatalog {
        do {
            return try bundledSeed()
        } catch {
            return .empty
        }
    }

    private func fetchCatalog() async throws -> CompatCatalog {
        let response = try await APIResponseDecoder.send(builder.get("/v1/compat/apps"), via: transport)
        var catalog = try APIResponseDecoder.decode(CompatCatalog.self, from: response)
        // The list endpoint returns { version, apps }; presets and runtime descriptions come
        // from /v1/compat/presets or, failing that, from the bundled seed.
        if catalog.presets.isEmpty {
            // Presets change rarely: while the cache is still fresh (< 24 h) reuse the ones we have;
            // once it is stale, refresh them together with the app list.
            if let previous = cached(now: clock(), requireFresh: true)?.catalog.presets, !previous.isEmpty {
                catalog.presets = previous
            } else if let presetResponse = try? await APIResponseDecoder.send(builder.get("/v1/compat/presets"), via: transport),
               let presets = try? APIResponseDecoder.decode([String: CompatPreset].self, from: presetResponse) {
                catalog.presets = presets
            } else if let seed = try? Self.bundledSeed() {
                catalog.presets = seed.presets
            }
        }
        if catalog.runtimes.isEmpty, let seed = try? Self.bundledSeed() {
            catalog.runtimes = seed.runtimes
        }
        let envelope = CacheEnvelope(fetchedAt: clock(), catalog: catalog)
        memory = envelope
        persist(envelope)
        return catalog
    }

    private func persist(_ envelope: CacheEnvelope) {
        guard let directory = configuration.cacheDirectory, let url = cacheFileURL else { return }
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try Self.encoder.encode(envelope)
            try data.write(to: url, options: [.atomic])
        } catch {
            // A failed cache write only costs a refetch next launch.
        }
    }

    private static func pathComponent(_ id: String) -> String {
        id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
    }

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        return encoder
    }()
}
