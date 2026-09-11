import Foundation
import Observation
import DepremOlduDomain
import DepremOlduRepository

enum EarthquakePresentationFailure: Equatable {
    case timedOut
    case offline
    case connectionLost
    case server
    case invalidData
    case unexpected

    var message: String {
        switch self {
        case .timedOut:
            "İstek zaman aşımına uğradı. Lütfen tekrar deneyin."
        case .offline:
            "İnternet bağlantısı yok. Bağlantınızı kontrol edip tekrar deneyin."
        case .connectionLost:
            "Bağlantı koptu. Lütfen tekrar deneyin."
        case .server:
            "Sunucuya şu anda ulaşılamıyor. Lütfen daha sonra tekrar deneyin."
        case .invalidData:
            "Deprem verisi şu anda okunamıyor."
        case .unexpected:
            "Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin."
        }
    }

    var systemImage: String {
        switch self {
        case .offline:
            "wifi.slash"
        case .timedOut:
            "clock.badge.exclamationmark"
        case .connectionLost:
            "antenna.radiowaves.left.and.right.slash"
        case .server, .invalidData, .unexpected:
            "exclamationmark.triangle"
        }
    }
}

@Observable
@MainActor
final class EarthquakeFeedFeatureModel {
    enum RefreshState: Equatable {
        case idle
        case refreshing
    }

    struct Content: Equatable {
        var earthquakes: [Earthquake]
        var fetchedAt: Date
        var source: EarthquakeRepositorySource
        var freshness: EarthquakeRepositoryFreshness
        var refreshState: RefreshState
        var refreshFailure: EarthquakePresentationFailure?
    }

    enum State: Equatable {
        case idle
        case loading
        case content(Content)
        case failure(EarthquakePresentationFailure)
    }

    private let repository: any EarthquakeRepositoryProviding
    private let nowProvider: () -> Date
    private let relativeTimeFormatter = TurkishRelativeTimeFormatter()
    private var nextGeneration: UInt64 = 0
    private var activeGeneration: UInt64?
    private var loadTask: Task<Void, Never>?

    static let listPageSize = 50

    private(set) var state: State = .idle
    private(set) var relativeTimeTick = Date.distantPast
    private(set) var currentPage = 1

    init(
        repository: any EarthquakeRepositoryProviding,
        nowProvider: @escaping () -> Date = { Date() }
    ) {
        self.repository = repository
        self.nowProvider = nowProvider
        relativeTimeTick = nowProvider()
    }

    isolated deinit {
        loadTask?.cancel()
    }

    var content: Content? {
        if case let .content(content) = state {
            return content
        }
        return nil
    }

    var listEarthquakes: [Earthquake] {
        Array((content?.earthquakes ?? []).prefix(EarthquakeFeedLimits.listCount))
    }

    var mapEarthquakes: [Earthquake] {
        Array((content?.earthquakes ?? []).prefix(EarthquakeFeedLimits.mapCount))
    }

    var totalCount: Int {
        content?.earthquakes.count ?? 0
    }

    var listTotalCount: Int {
        min(totalCount, EarthquakeFeedLimits.listCount)
    }

    var listPageCount: Int {
        max(1, (listTotalCount + Self.listPageSize - 1) / Self.listPageSize)
    }

    var isFirstPage: Bool {
        currentPage == 1
    }

    var isLastPage: Bool {
        currentPage >= listPageCount
    }

    var paginatedEarthquakes: [Earthquake] {
        let all = listEarthquakes
        let start = (currentPage - 1) * Self.listPageSize
        guard start < all.count else { return [] }
        return Array(all[start ..< min(start + Self.listPageSize, all.count)])
    }

    var countSummary: String {
        guard listTotalCount > 0 else { return "0 deprem" }
        let start = (currentPage - 1) * Self.listPageSize + 1
        let end = min(currentPage * Self.listPageSize, listTotalCount)
        return "\(start)-\(end) / \(listTotalCount) deprem"
    }

    func goToPage(_ page: Int) {
        currentPage = min(max(1, page), listPageCount)
    }

    func nextPage() {
        goToPage(currentPage + 1)
    }

    func previousPage() {
        goToPage(currentPage - 1)
    }

    func relativeTime(for earthquake: Earthquake) -> String {
        guard let occurredAt = earthquake.occurredAt else { return "-" }
        return relativeTimeFormatter.string(from: occurredAt, relativeTo: nowProvider())
    }

    func loadIfNeeded() {
        guard case .idle = state else { return }
        startOperation(policy: .normal)
    }

    func refresh() async {
        await startOperation(policy: .forceRefresh).value
    }

    func retry() async {
        await startOperation(policy: .normal).value
    }

    func tick() {
        relativeTimeTick = nowProvider()
    }

    @discardableResult
    private func startOperation(policy: EarthquakeLoadPolicy) -> Task<Void, Never> {
        loadTask?.cancel()
        let generation = makeGeneration()
        activeGeneration = generation

        if case let .content(content) = state {
            state = .content(content.with(refreshState: .refreshing, refreshFailure: nil))
        } else {
            state = .loading
        }

        let task: Task<Void, Never> = Task { @MainActor [weak self, repository] in
            guard let self else { return }
            await self.consume(repository: repository, generation: generation, policy: policy)
        }
        loadTask = task
        return task
    }

    private func consume(
        repository: any EarthquakeRepositoryProviding,
        generation: UInt64,
        policy: EarthquakeLoadPolicy
    ) async {
        defer {
            if activeGeneration == generation {
                loadTask = nil
            }
        }

        do {
            for try await event in repository.events(policy: policy) {
                guard activeGeneration == generation else { return }
                apply(event)
            }
        } catch is CancellationError {
            return
        } catch {
            guard activeGeneration == generation else { return }
            applyTerminalFailure(.unexpected)
        }
    }

    private func apply(_ event: EarthquakeRepositoryEvent) {
        switch event {
        case let .value(value):
            state = .content(
                Content(
                    earthquakes: value.earthquakes,
                    fetchedAt: value.fetchedAt,
                    source: value.source,
                    freshness: value.freshness,
                    refreshState: .idle,
                    refreshFailure: nil
                )
            )
            clampCurrentPage()

        case let .refreshing(stale):
            if let stale {
                state = .content(
                    Content(
                        earthquakes: stale.earthquakes,
                        fetchedAt: stale.fetchedAt,
                        source: stale.source,
                        freshness: stale.freshness,
                        refreshState: .refreshing,
                        refreshFailure: nil
                    )
                )
            } else if case let .content(content) = state {
                state = .content(content.with(refreshState: .refreshing, refreshFailure: nil))
            } else {
                state = .loading
            }

        case let .refreshFailed(stale, failure):
            state = .content(
                Content(
                    earthquakes: stale.earthquakes,
                    fetchedAt: stale.fetchedAt,
                    source: stale.source,
                    freshness: stale.freshness,
                    refreshState: .idle,
                    refreshFailure: Self.presentationFailure(from: failure)
                )
            )

        case let .terminalFailure(failure):
            applyTerminalFailure(Self.presentationFailure(from: failure))
        }
    }

    private func applyTerminalFailure(_ failure: EarthquakePresentationFailure) {
        if case let .content(content) = state {
            state = .content(content.with(refreshState: .idle, refreshFailure: failure))
        } else {
            state = .failure(failure)
        }
    }

    private func clampCurrentPage() {
        currentPage = min(max(1, currentPage), listPageCount)
    }

    private func makeGeneration() -> UInt64 {
        precondition(nextGeneration < .max, "Earthquake operation generation exhausted")
        nextGeneration += 1
        return nextGeneration
    }

    private static func presentationFailure(
        from failure: EarthquakeRefreshFailure
    ) -> EarthquakePresentationFailure {
        switch failure {
        case .invalidRequest:
            .unexpected
        case .timedOut:
            .timedOut
        case .offline:
            .offline
        case .connectionLost:
            .connectionLost
        case .httpStatus:
            .server
        case .invalidPayload:
            .invalidData
        case .unexpected:
            .unexpected
        }
    }
}

private extension EarthquakeFeedFeatureModel.Content {
    func with(
        refreshState: EarthquakeFeedFeatureModel.RefreshState,
        refreshFailure: EarthquakePresentationFailure?
    ) -> EarthquakeFeedFeatureModel.Content {
        var copy = self
        copy.refreshState = refreshState
        copy.refreshFailure = refreshFailure
        return copy
    }
}
