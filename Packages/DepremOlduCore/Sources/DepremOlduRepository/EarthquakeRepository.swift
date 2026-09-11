import Foundation
import DepremOlduDomain
import DepremOlduNetworking
import DepremOlduPersistence

public actor EarthquakeRepository: EarthquakeRepositoryProviding {
    public static let freshTimeToLive: TimeInterval = 15
    public static let staleUsabilityWindow: TimeInterval = 24 * 60 * 60
    static let cacheKey = "earthquakes.feed.v1"

    private let service: any KandilliEarthquakeServiceProviding
    private let store: any PersistenceStore
    private let dateProvider: any DateProviding
    private let sleeper: any EarthquakeRetrySleeping
    private let jitterProvider: any EarthquakeRetryJitterProviding
    private let coalescer: EarthquakeFeedCoalescer
    private let pageCount: Int

    public init(
        service: any KandilliEarthquakeServiceProviding,
        store: any PersistenceStore,
        dateProvider: any DateProviding = SystemDateProvider()
    ) {
        self.init(
            service: service,
            store: store,
            dateProvider: dateProvider,
            sleeper: TaskEarthquakeRetrySleeper(),
            jitterProvider: SystemEarthquakeRetryJitterProvider(),
            coalescer: EarthquakeFeedCoalescer(),
            pageCount: Self.pageCount
        )
    }

    package init(
        service: any KandilliEarthquakeServiceProviding,
        store: any PersistenceStore,
        dateProvider: any DateProviding,
        sleeper: any EarthquakeRetrySleeping,
        jitterProvider: any EarthquakeRetryJitterProviding,
        coalescer: EarthquakeFeedCoalescer = EarthquakeFeedCoalescer(),
        pageCount: Int = EarthquakeRepository.pageCount
    ) {
        self.service = service
        self.store = store
        self.dateProvider = dateProvider
        self.sleeper = sleeper
        self.jitterProvider = jitterProvider
        self.coalescer = coalescer
        self.pageCount = pageCount
    }

    public nonisolated func events(
        policy: EarthquakeLoadPolicy = .normal
    ) -> AsyncThrowingStream<EarthquakeRepositoryEvent, any Error> {
        let state = EarthquakeLoadSequenceState(repository: self, policy: policy)
        return AsyncThrowingStream(unfolding: {
            try await state.next()
        })
    }

    package func cachedFeed() async -> EarthquakeCacheLookup {
        let stored: Data
        do {
            guard let data = try await store.data(forKey: Self.cacheKey) else {
                return EarthquakeCacheLookup(value: nil)
            }
            stored = data
        } catch {
            return EarthquakeCacheLookup(value: nil)
        }

        guard let record = try? EarthquakeCacheRecordCodec.decode(stored) else {
            await deleteCache()
            return EarthquakeCacheLookup(value: nil)
        }
        guard record.schemaVersion == EarthquakeCacheRecordV1.currentSchemaVersion else {
            await deleteCache()
            return EarthquakeCacheLookup(value: nil)
        }

        let age = dateProvider.now.timeIntervalSince(record.fetchedAt)
        guard age.isFinite, age >= 0 else {
            await deleteCache()
            return EarthquakeCacheLookup(value: nil)
        }
        guard age <= Self.staleUsabilityWindow else {
            await deleteCache()
            return EarthquakeCacheLookup(value: nil)
        }

        let earthquakes = record.pages.flatMap { $0 }.map(KandilliEarthquakeMapper.map)
        return EarthquakeCacheLookup(
            value: EarthquakeRepositoryValue(
                earthquakes: earthquakes,
                fetchedAt: record.fetchedAt,
                source: .cache,
                freshness: age <= Self.freshTimeToLive ? .fresh : .stale
            )
        )
    }

    package func networkFeed() async throws -> EarthquakeRepositoryValue {
        try await coalescer.value { [service, store, dateProvider, sleeper, jitterProvider, pageCount] in
            let pages = try await withThrowingTaskGroup(
                of: (index: Int, page: KandilliEarthquakePage).self
            ) { group in
                for index in 0 ..< pageCount {
                    group.addTask {
                        let page = try await Self.fetchPageWithRetry(
                            service: service,
                            sleeper: sleeper,
                            jitterProvider: jitterProvider,
                            skip: index * EarthquakeFeedLimits.pageSize,
                            limit: EarthquakeFeedLimits.pageSize
                        )
                        return (index, page)
                    }
                }
                var collected: [(index: Int, page: KandilliEarthquakePage)] = []
                for try await result in group {
                    collected.append(result)
                }
                return collected.sorted { $0.index < $1.index }.map(\.page)
            }

            let fetchedAt = dateProvider.now
            let record = EarthquakeCacheRecordV1(
                schemaVersion: EarthquakeCacheRecordV1.currentSchemaVersion,
                fetchedAt: fetchedAt,
                pages: pages.map(\.items)
            )
            if let encoded = try? EarthquakeCacheRecordCodec.encode(record) {
                try? await store.set(encoded, forKey: Self.cacheKey)
            }

            return EarthquakeRepositoryValue(
                earthquakes: pages.flatMap(\.items).map(KandilliEarthquakeMapper.map),
                fetchedAt: fetchedAt,
                source: .network,
                freshness: .fresh
            )
        }
    }

    private static let pageCount = EarthquakeFeedLimits.feedCount / EarthquakeFeedLimits.pageSize

    private static func fetchPageWithRetry(
        service: any KandilliEarthquakeServiceProviding,
        sleeper: any EarthquakeRetrySleeping,
        jitterProvider: any EarthquakeRetryJitterProviding,
        skip: Int,
        limit: Int
    ) async throws -> KandilliEarthquakePage {
        var attempt = 1
        while true {
            do {
                return try await service.fetchPage(skip: skip, limit: limit)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                let failure = refreshFailure(from: error)
                guard EarthquakeRetryPolicy.shouldRetry(
                    failure: failure,
                    completedAttempts: attempt
                ) else {
                    throw failure
                }
                if let delay = EarthquakeRetryPolicy.delay(
                    for: failure,
                    attempt: attempt,
                    jitter: jitterProvider.nextJitter()
                ) {
                    do {
                        try await sleeper.sleep(for: delay)
                    } catch {
                        throw CancellationError()
                    }
                }
                attempt += 1
            }
        }
    }

    private func deleteCache() async {
        try? await store.set(nil, forKey: Self.cacheKey)
    }

    private static func refreshFailure(from error: any Error) -> EarthquakeRefreshFailure {
        if let failure = error as? EarthquakeRefreshFailure {
            return failure
        }
        guard let serviceError = error as? KandilliEarthquakeServiceError else {
            return .unexpected
        }
        switch serviceError {
        case .endpoint:
            return .invalidRequest
        case let .transport(transport):
            switch transport {
            case .timedOut:
                return .timedOut
            case .notConnectedToInternet:
                return .offline
            case .networkConnectionLost:
                return .connectionLost
            case .invalidResponse, .urlError, .unexpected:
                return .unexpected
            }
        case let .unacceptableStatus(code, retryAfter):
            return .httpStatus(code: code, retryAfter: retryAfter)
        case .malformedPayload:
            return .invalidPayload
        case .unexpected:
            return .unexpected
        }
    }
}

package struct EarthquakeCacheLookup: Sendable {
    package let value: EarthquakeRepositoryValue?

    package init(value: EarthquakeRepositoryValue?) {
        self.value = value
    }
}

private actor EarthquakeLoadSequenceState {
    private enum Phase {
        case initial
        case emitRefreshing(stale: EarthquakeRepositoryValue?)
        case fetch(stale: EarthquakeRepositoryValue?)
        case finished
    }

    private let repository: EarthquakeRepository
    private let policy: EarthquakeLoadPolicy
    private var phase = Phase.initial

    init(repository: EarthquakeRepository, policy: EarthquakeLoadPolicy) {
        self.repository = repository
        self.policy = policy
    }

    func next() async throws -> EarthquakeRepositoryEvent? {
        try Task.checkCancellation()

        switch phase {
        case .initial:
            if policy == .forceRefresh {
                phase = .fetch(stale: nil)
                return .refreshing(stale: nil)
            }

            let cache = await repository.cachedFeed()
            if let value = cache.value, value.freshness == .fresh {
                phase = .finished
                return .value(value)
            }
            if let stale = cache.value {
                phase = .emitRefreshing(stale: stale)
                return .value(stale)
            }

            phase = .fetch(stale: nil)
            return .refreshing(stale: nil)

        case let .emitRefreshing(stale):
            phase = .fetch(stale: stale)
            return .refreshing(stale: stale)

        case let .fetch(stale):
            phase = .finished
            do {
                return .value(try await repository.networkFeed())
            } catch is CancellationError {
                throw CancellationError()
            } catch let failure as EarthquakeRefreshFailure {
                if let stale {
                    return .refreshFailed(stale: stale, failure: failure)
                }
                return .terminalFailure(failure: failure)
            } catch {
                if let stale {
                    return .refreshFailed(stale: stale, failure: .unexpected)
                }
                return .terminalFailure(failure: .unexpected)
            }

        case .finished:
            return nil
        }
    }
}
