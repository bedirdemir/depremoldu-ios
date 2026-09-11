import Foundation
import DepremOlduDomain
import DepremOlduNetworking
import DepremOlduPersistence
import DepremOlduTestSupport
import Testing

@testable import DepremOlduRepository

@Suite("Earthquake repository")
struct EarthquakeRepositoryTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func makeComponents(
        service: any KandilliEarthquakeServiceProviding,
        store: MemoryStore = MemoryStore(),
        pageCount: Int = 2,
        sleeper: RecordingSleeper = RecordingSleeper()
    ) -> (EarthquakeRepository, MemoryStore, RecordingSleeper) {
        let repository = EarthquakeRepository(
            service: service,
            store: store,
            dateProvider: FixedDateProvider(now: now),
            sleeper: sleeper,
            jitterProvider: FixedJitterProvider(),
            pageCount: pageCount
        )
        return (repository, store, sleeper)
    }

    private func collect(
        _ repository: EarthquakeRepository,
        policy: EarthquakeLoadPolicy = .normal
    ) async throws -> [EarthquakeRepositoryEvent] {
        var events: [EarthquakeRepositoryEvent] = []
        for try await event in repository.events(policy: policy) {
            events.append(event)
        }
        return events
    }

    private func writeCache(
        into store: MemoryStore,
        fetchedAt: Date,
        itemsPerPage: Int = 2,
        pageCount: Int = 2
    ) async throws {
        let record = EarthquakeCacheRecordV1(
            schemaVersion: EarthquakeCacheRecordV1.currentSchemaVersion,
            fetchedAt: fetchedAt,
            pages: (0 ..< pageCount).map { index in
                EarthquakeFixtures.page(count: itemsPerPage, startIndex: index * itemsPerPage)
            }
        )
        try await store.set(
            EarthquakeCacheRecordCodec.encode(record),
            forKey: EarthquakeRepository.cacheKey
        )
    }

    @Test("Fresh cache serves content without touching the network")
    func freshCacheShortCircuitsNetwork() async throws {
        let service = ScriptedService()
        let (repository, store, _) = makeComponents(service: service)
        try await writeCache(into: store, fetchedAt: now.addingTimeInterval(-5))

        let events = try await collect(repository)

        #expect(events.count == 1)
        guard case let .value(value) = events[0] else {
            Issue.record("Expected a cache value")
            return
        }
        #expect(value.source == .cache)
        #expect(value.freshness == .fresh)
        #expect(value.earthquakes.count == 4)
        let calls = await service.calls
        #expect(calls == 0)
    }

    @Test("Stale cache is emitted first and refreshed afterwards")
    func staleCacheRefreshes() async throws {
        let service = ScriptedService(itemsPerPage: 3)
        let (repository, store, _) = makeComponents(service: service)
        try await writeCache(into: store, fetchedAt: now.addingTimeInterval(-3600))

        let events = try await collect(repository)

        #expect(events.count == 3)
        guard case let .value(stale) = events[0] else {
            Issue.record("Expected stale cache value")
            return
        }
        #expect(stale.source == .cache)
        #expect(stale.freshness == .stale)
        #expect(stale.earthquakes.count == 4)

        guard case let .refreshing(refreshingStale) = events[1] else {
            Issue.record("Expected refreshing event")
            return
        }
        #expect(refreshingStale?.earthquakes.count == 4)

        guard case let .value(fresh) = events[2] else {
            Issue.record("Expected network value")
            return
        }
        #expect(fresh.source == .network)
        #expect(fresh.freshness == .fresh)
        #expect(fresh.earthquakes.count == 6)
        let calls = await service.calls
        #expect(calls == 2)
    }

    @Test("A failed refresh preserves usable stale content")
    func refreshFailurePreservesStale() async throws {
        let service = ScriptedService(error: .unacceptableStatus(code: 500, retryAfter: nil))
        let (repository, store, _) = makeComponents(service: service)
        try await writeCache(into: store, fetchedAt: now.addingTimeInterval(-3600))

        let events = try await collect(repository)

        guard case .refreshFailed(let stale, let failure) = try #require(events.last) else {
            Issue.record("Expected refresh failure")
            return
        }
        #expect(stale.freshness == .stale)
        #expect(failure == .httpStatus(code: 500, retryAfter: nil))
    }

    @Test("A failure without usable cache is terminal")
    func terminalFailureWithoutCache() async throws {
        let service = ScriptedService(error: .transport(.notConnectedToInternet))
        let (repository, _, _) = makeComponents(service: service)

        let events = try await collect(repository)

        guard case .terminalFailure(let failure) = try #require(events.last) else {
            Issue.record("Expected terminal failure")
            return
        }
        #expect(failure == .offline)
        #expect(events.count == 2)
    }

    @Test("Force refresh bypasses a fresh cache")
    func forceRefreshBypassesCache() async throws {
        let service = ScriptedService(itemsPerPage: 3)
        let (repository, store, _) = makeComponents(service: service)
        try await writeCache(into: store, fetchedAt: now.addingTimeInterval(-5))

        let events = try await collect(repository, policy: .forceRefresh)

        #expect(events.count == 2)
        guard case let .value(value) = events[1] else {
            Issue.record("Expected network value")
            return
        }
        #expect(value.source == .network)
        let calls = await service.calls
        #expect(calls == 2)
    }

    @Test("Transient HTTP failures retry with bounded backoff")
    func transientFailuresRetry() async throws {
        let service = ScriptedService(
            failuresPerPageBeforeSuccess: 1,
            failure: .unacceptableStatus(code: 503, retryAfter: nil)
        )
        let (repository, _, sleeper) = makeComponents(service: service)

        let events = try await collect(repository)

        guard case let .value(value) = try #require(events.last) else {
            Issue.record("Expected network value after retry")
            return
        }
        #expect(value.earthquakes.count == 4)
        let calls = await service.calls
        #expect(calls == 4)
        let durations = await sleeper.durations
        #expect(durations.count == 2)
        #expect(durations.allSatisfy { $0 == 0.5 })
    }

    @Test("429 and 503 honor a short Retry-After header")
    func retryAfterHeader() async throws {
        let service = ScriptedService(
            failuresPerPageBeforeSuccess: 1,
            failure: .unacceptableStatus(code: 429, retryAfter: 30)
        )
        let (repository, _, sleeper) = makeComponents(service: service)

        _ = try await collect(repository)

        let durations = await sleeper.durations
        #expect(durations == [30, 30])
    }

    @Test("Non-retryable statuses fail on the first attempt")
    func nonRetryableStatus() async throws {
        let service = ScriptedService(error: .unacceptableStatus(code: 404, retryAfter: nil))
        let (repository, _, sleeper) = makeComponents(service: service, pageCount: 1)

        let events = try await collect(repository)

        let calls = await service.calls
        #expect(calls == 1)
        let durations = await sleeper.durations
        #expect(durations.isEmpty)
        guard case .terminalFailure(let failure) = try #require(events.last) else {
            Issue.record("Expected terminal failure")
            return
        }
        #expect(failure == .httpStatus(code: 404, retryAfter: nil))
    }

    @Test("Concurrent loads coalesce into one network operation")
    func coalescesConcurrentLoads() async throws {
        let service = GatedService(itemsPerPage: 2)
        let (repository, _, _) = makeComponents(service: service)

        async let first = collect(repository)
        async let second = collect(repository)
        try await Task.sleep(for: .milliseconds(50))
        await service.release()
        let results = try await [first, second]

        let calls = await service.calls
        #expect(calls == 2)
        for events in results {
            guard case let .value(value) = try #require(events.last) else {
                Issue.record("Expected network value")
                continue
            }
            #expect(value.earthquakes.count == 4)
        }
    }

    @Test("Network success writes a durable cache record")
    func writesCacheRecord() async throws {
        let service = ScriptedService(itemsPerPage: 2)
        let (repository, store, _) = makeComponents(service: service)

        _ = try await collect(repository)

        let stored = try #require(try await store.data(forKey: EarthquakeRepository.cacheKey))
        let record = try EarthquakeCacheRecordCodec.decode(stored)
        #expect(record.schemaVersion == EarthquakeCacheRecordV1.currentSchemaVersion)
        #expect(record.fetchedAt == now)
        #expect(record.pages.count == 2)
        #expect(record.pages.flatMap { $0 }.count == 4)
    }

    @Test("Corrupted cache is discarded and refetched")
    func corruptedCacheIsDiscarded() async throws {
        let service = ScriptedService()
        let (repository, store, _) = makeComponents(service: service)
        try await store.set(Data("not json".utf8), forKey: EarthquakeRepository.cacheKey)

        let events = try await collect(repository)

        guard case let .value(value) = try #require(events.last) else {
            Issue.record("Expected network value")
            return
        }
        #expect(value.source == .network)
        let stored = try #require(try await store.data(forKey: EarthquakeRepository.cacheKey))
        _ = try EarthquakeCacheRecordCodec.decode(stored)
    }

    @Test("Expired cache beyond the usability window is discarded")
    func expiredCacheIsDiscarded() async throws {
        let service = ScriptedService()
        let (repository, store, _) = makeComponents(service: service)
        try await writeCache(
            into: store,
            fetchedAt: now.addingTimeInterval(-(EarthquakeRepository.staleUsabilityWindow + 60))
        )

        let events = try await collect(repository)

        let calls = await service.calls
        #expect(calls == 2)
        guard case let .value(value) = try #require(events.last) else {
            Issue.record("Expected network value")
            return
        }
        #expect(value.source == .network)
    }

    @Test("Future-dated cache records are treated as invalid")
    func futureCacheIsInvalid() async throws {
        let service = ScriptedService()
        let (repository, store, _) = makeComponents(service: service)
        try await writeCache(into: store, fetchedAt: now.addingTimeInterval(120))

        let events = try await collect(repository)

        let calls = await service.calls
        #expect(calls == 2)
        guard case let .value(value) = try #require(events.last) else {
            Issue.record("Expected network value")
            return
        }
        #expect(value.source == .network)
    }
}

@Suite("Earthquake retry policy")
struct EarthquakeRetryPolicyTests {
    @Test("Retryable failures match the allowlist")
    func allowlist() {
        #expect(EarthquakeRetryPolicy.shouldRetry(failure: .timedOut, completedAttempts: 1))
        #expect(EarthquakeRetryPolicy.shouldRetry(failure: .connectionLost, completedAttempts: 2))
        for code in [408, 429, 500, 502, 503, 504] {
            #expect(EarthquakeRetryPolicy.shouldRetry(
                failure: .httpStatus(code: code, retryAfter: nil),
                completedAttempts: 1
            ))
        }
        #expect(!EarthquakeRetryPolicy.shouldRetry(failure: .offline, completedAttempts: 1))
        #expect(!EarthquakeRetryPolicy.shouldRetry(failure: .invalidPayload, completedAttempts: 1))
        #expect(!EarthquakeRetryPolicy.shouldRetry(
            failure: .httpStatus(code: 404, retryAfter: nil),
            completedAttempts: 1
        ))
        #expect(!EarthquakeRetryPolicy.shouldRetry(failure: .timedOut, completedAttempts: 3))
    }

    @Test("Backoff uses 0.5s then 1.0s with bounded jitter")
    func backoff() {
        #expect(EarthquakeRetryPolicy.delay(for: .timedOut, attempt: 1, jitter: 1.0) == 0.5)
        #expect(EarthquakeRetryPolicy.delay(for: .timedOut, attempt: 2, jitter: 1.0) == 1.0)
        #expect(EarthquakeRetryPolicy.delay(for: .timedOut, attempt: 1, jitter: 0.5) == 0.4)
        #expect(EarthquakeRetryPolicy.delay(for: .timedOut, attempt: 1, jitter: 2.0) == 0.6)
    }

    @Test("Short Retry-After values win over the backoff ladder")
    func retryAfter() {
        #expect(
            EarthquakeRetryPolicy.delay(
                for: .httpStatus(code: 503, retryAfter: 12),
                attempt: 1,
                jitter: 1.0
            ) == 12
        )
        #expect(
            EarthquakeRetryPolicy.delay(
                for: .httpStatus(code: 503, retryAfter: 120),
                attempt: 1,
                jitter: 1.0
            ) == 0.5
        )
    }
}

struct FixedDateProvider: DateProviding {
    let now: Date
}

struct FixedJitterProvider: EarthquakeRetryJitterProviding {
    func nextJitter() -> Double { 1.0 }
}

actor RecordingSleeper: EarthquakeRetrySleeping {
    private(set) var durations: [TimeInterval] = []

    func sleep(for duration: TimeInterval) async throws {
        durations.append(duration)
    }
}

actor MemoryStore: PersistenceStore {
    private var storage: [String: Data] = [:]

    func data(forKey key: String) async throws -> Data? {
        storage[key]
    }

    func set(_ data: Data?, forKey key: String) async throws {
        storage[key] = data
    }
}

actor ScriptedService: KandilliEarthquakeServiceProviding {
    private let itemsPerPage: Int
    private let error: KandilliEarthquakeServiceError?
    private let failure: KandilliEarthquakeServiceError?
    private let failuresPerPage: Int
    private var recordedCalls = 0
    private var pageFailuresUsed: [Int: Int] = [:]

    init(
        itemsPerPage: Int = 2,
        error: KandilliEarthquakeServiceError? = nil,
        failuresPerPageBeforeSuccess: Int = 0,
        failure: KandilliEarthquakeServiceError? = nil
    ) {
        self.itemsPerPage = itemsPerPage
        self.error = error
        self.failure = failure
        failuresPerPage = failuresPerPageBeforeSuccess
    }

    var calls: Int { recordedCalls }

    func fetchPage(skip: Int, limit: Int) async throws -> KandilliEarthquakePage {
        recordedCalls += 1

        if let error {
            throw error
        }
        let pageIndex = skip / max(limit, 1)
        if let failure {
            let used = pageFailuresUsed[pageIndex, default: 0]
            if used < failuresPerPage {
                pageFailuresUsed[pageIndex] = used + 1
                throw failure
            }
        }

        let items = EarthquakeFixtures.page(
            count: itemsPerPage,
            startIndex: pageIndex * itemsPerPage
        )
        return KandilliEarthquakePage(items: items, rawResponseBody: Data())
    }

    nonisolated func decodePage(_ body: Data) throws -> [KandilliEarthquakeDTO] {
        []
    }
}

actor GatedService: KandilliEarthquakeServiceProviding {
    private let itemsPerPage: Int
    private var recordedCalls = 0
    private var gateContinuations: [CheckedContinuation<Void, Never>] = []
    private var isOpen = false

    init(itemsPerPage: Int) {
        self.itemsPerPage = itemsPerPage
    }

    var calls: Int { recordedCalls }

    func release() {
        isOpen = true
        for continuation in gateContinuations {
            continuation.resume()
        }
        gateContinuations.removeAll()
    }

    func fetchPage(skip: Int, limit: Int) async throws -> KandilliEarthquakePage {
        recordedCalls += 1
        if !isOpen {
            await withCheckedContinuation { continuation in
                gateContinuations.append(continuation)
            }
        }
        let pageIndex = skip / max(limit, 1)
        let items = EarthquakeFixtures.page(
            count: itemsPerPage,
            startIndex: pageIndex * itemsPerPage
        )
        return KandilliEarthquakePage(items: items, rawResponseBody: Data())
    }

    nonisolated func decodePage(_ body: Data) throws -> [KandilliEarthquakeDTO] {
        []
    }
}
