import Foundation
import Testing
import DepremOlduDomain
import DepremOlduFaults
import DepremOlduRepository
import DepremOlduTestSupport

@testable import DepremOldu

@MainActor
@Suite("Earthquake feed feature model")
struct EarthquakeFeedFeatureModelTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func makeModel(
        repository: any EarthquakeRepositoryProviding
    ) -> EarthquakeFeedFeatureModel {
        EarthquakeFeedFeatureModel(repository: repository, nowProvider: { self.now })
    }

    private func waitUntil(
        timeout: TimeInterval = 2,
        _ condition: @MainActor () -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    @Test("Initial state is idle")
    func initialState() {
        let model = makeModel(repository: StubEarthquakeRepository(scriptedEvents: []))
        #expect(model.state == .idle)
        #expect(model.listEarthquakes.isEmpty)
    }

    @Test("Load publishes network content")
    func loadContent() async {
        let earthquakes = EarthquakeFixtures.feed(count: 12)
        let model = makeModel(repository: StubEarthquakeRepository.content(earthquakes))
        model.loadIfNeeded()
        await waitUntil { model.content != nil }

        guard let content = model.content else {
            Issue.record("Expected content")
            return
        }
        #expect(content.earthquakes.count == 12)
        #expect(content.source == .network)
        #expect(content.freshness == .fresh)
        #expect(content.refreshState == .idle)
        #expect(content.refreshFailure == nil)
        #expect(model.countSummary == "12 deprem")
    }

    @Test("List shows at most 200 continuously and the map at most 500")
    func listAndMapLimits() async {
        let model = makeModel(repository: StubEarthquakeRepository.content(EarthquakeFixtures.feed(count: 600)))
        model.loadIfNeeded()
        await waitUntil { model.content != nil }

        #expect(model.listEarthquakes.count == 200)
        #expect(model.mapEarthquakes.count == 500)
        #expect(model.listEarthquakes.first?.id == "fixture-0")
        #expect(model.listEarthquakes.last?.id == "fixture-199")
        #expect(model.countSummary == "200 deprem")
    }

    @Test("Refresh replaces the content and the count")
    func refreshReplacesContent() async {
        let repository = TwoPhaseEarthquakeRepository(
            first: EarthquakeFixtures.feed(count: 120),
            second: EarthquakeFixtures.feed(count: 20)
        )
        let model = makeModel(repository: repository)
        model.loadIfNeeded()
        await waitUntil { model.content != nil }
        #expect(model.countSummary == "120 deprem")

        await model.refresh()
        await waitUntil { model.listTotalCount == 20 }

        #expect(model.listEarthquakes.count == 20)
        #expect(model.countSummary == "20 deprem")
    }

    @Test("Refresh shows the refreshing state while the network is in flight")
    func refreshShowsRefreshingState() async {
        let repository = GatedFeedRepository(earthquakes: EarthquakeFixtures.feed(count: 5))
        let model = makeModel(repository: repository)
        model.loadIfNeeded()
        await waitUntil { model.content != nil }
        #expect(model.content?.refreshState == .idle)

        let refreshTask = Task { await model.refresh() }
        await waitUntil { model.content?.refreshState == .refreshing }
        #expect(model.content?.refreshState == .refreshing)
        #expect(model.content?.earthquakes.count == 5)

        repository.release()
        await refreshTask.value
        #expect(model.content?.refreshState == .idle)
    }

    @Test("Empty content has a zero summary")
    func emptyContent() async {
        let model = makeModel(repository: StubEarthquakeRepository.content([]))
        model.loadIfNeeded()
        await waitUntil { model.content != nil }

        #expect(model.countSummary == "0 deprem")
    }

    @Test("Terminal failure without content is exposed as failure state")
    func terminalFailure() async {
        let model = makeModel(repository: StubEarthquakeRepository.failure(.offline))
        model.loadIfNeeded()
        await waitUntil { model.state == .failure(.offline) }

        #expect(model.state == .failure(.offline))
        #expect(model.content == nil)
    }

    @Test("Refresh failure keeps the previous content")
    func refreshFailureKeepsContent() async {
        let earthquakes = EarthquakeFixtures.feed(count: 5)
        let staleValue = EarthquakeRepositoryValue(
            earthquakes: earthquakes,
            fetchedAt: now.addingTimeInterval(-3600),
            source: .cache,
            freshness: .stale
        )
        let repository = StubEarthquakeRepository(
            scriptedEvents: [
                .value(staleValue),
                .refreshFailed(stale: staleValue, failure: .offline),
            ]
        )
        let model = makeModel(repository: repository)
        model.loadIfNeeded()
        await waitUntil { model.content?.refreshFailure != nil }

        guard let content = model.content else {
            Issue.record("Expected content")
            return
        }
        #expect(content.earthquakes.count == 5)
        #expect(content.refreshFailure == .offline)
        #expect(content.refreshState == .idle)
    }

    @Test("Stale value followed by a fresh value ends fresh")
    func staleThenFresh() async {
        let stale = EarthquakeRepositoryValue(
            earthquakes: EarthquakeFixtures.feed(count: 3),
            fetchedAt: now.addingTimeInterval(-3600),
            source: .cache,
            freshness: .stale
        )
        let fresh = EarthquakeRepositoryValue(
            earthquakes: EarthquakeFixtures.feed(count: 9),
            fetchedAt: now,
            source: .network,
            freshness: .fresh
        )
        let repository = StubEarthquakeRepository(
            scriptedEvents: [
                .value(stale),
                .refreshing(stale: stale),
                .value(fresh),
            ]
        )
        let model = makeModel(repository: repository)
        model.loadIfNeeded()
        await waitUntil { model.content?.freshness == .fresh }

        #expect(model.content?.earthquakes.count == 9)
        #expect(model.content?.refreshState == .idle)
    }

    @Test("Relative time uses the Turkish ladder and the injected clock")
    func relativeTime() async {
        let earthquake = Earthquake(
            id: "rt",
            provider: "kandilli",
            region: "TEST",
            magnitude: 3,
            depth: 5,
            displayDate: "2026.09.11",
            displayTime: "23:24:22",
            occurredAt: now.addingTimeInterval(-300),
            coordinate: nil
        )
        let model = makeModel(repository: StubEarthquakeRepository.content([earthquake]))
        model.loadIfNeeded()
        await waitUntil { model.content != nil }

        #expect(model.relativeTime(for: earthquake) == "5 dakika önce")

        let withoutDate = EarthquakeFixtures.earthquake(occurredAt: nil)
        #expect(model.relativeTime(for: withoutDate) == "-")
    }
}

@MainActor
@Suite("Earthquake map feature model")
struct EarthquakeMapFeatureModelTests {
    private func waitUntil(
        timeout: TimeInterval = 3,
        _ condition: @MainActor () -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    @Test("Fault dataset loads once and the layer toggles")
    func loadsFaultsAndToggles() async {
        let dataset = FaultDataset(
            version: 1,
            source: "GINRAS/AFEAD",
            lines: [
                FaultLine(
                    name: "TEST FAULT",
                    confidence: .a,
                    rate: .one,
                    coordinates: [
                        GeoCoordinate(latitude: 38.0, longitude: 26.0)!,
                        GeoCoordinate(latitude: 38.1, longitude: 26.1)!,
                    ]
                ),
            ]
        )
        let model = EarthquakeMapFeatureModel(
            faultProvider: StubFaultDatasetProvider(dataset: dataset)
        )
        #expect(model.faultState == .idle)
        #expect(!model.showsFaultLines)

        model.loadFaultsIfNeeded()
        await waitUntil { model.faultDataset != nil }

        #expect(model.faultDataset?.lines.count == 1)
        model.toggleFaultLines()
        #expect(model.showsFaultLines)
        #expect(model.showsFaultLegend)
    }

    @Test("Fault provider failure is a typed failed state")
    func faultFailure() async {
        let model = EarthquakeMapFeatureModel(faultProvider: FailingFaultDatasetProvider())
        model.loadFaultsIfNeeded()
        await waitUntil { model.faultState == .failed }

        #expect(model.faultState == .failed)
        #expect(model.faultDataset == nil)
        #expect(!model.showsFaultLegend)
    }
}

final class GatedFeedRepository: EarthquakeRepositoryProviding, @unchecked Sendable {
    private let value: EarthquakeRepositoryValue
    private let lock = NSLock()
    private var callCount = 0
    private var isReleased = false
    private var releaseContinuation: CheckedContinuation<Void, Never>?

    init(earthquakes: [Earthquake]) {
        value = EarthquakeRepositoryValue(
            earthquakes: earthquakes,
            fetchedAt: Date(),
            source: .network,
            freshness: .fresh
        )
    }

    func events(
        policy: EarthquakeLoadPolicy = .normal
    ) -> AsyncThrowingStream<EarthquakeRepositoryEvent, any Error> {
        let index = lock.withLock {
            callCount += 1
            return callCount
        }
        let value = value
        return AsyncThrowingStream { continuation in
            Task {
                if index > 1 {
                    await self.waitForRelease()
                }
                continuation.yield(.value(value))
                continuation.finish()
            }
        }
    }

    func release() {
        let continuation: CheckedContinuation<Void, Never>? = lock.withLock {
            isReleased = true
            let pending = releaseContinuation
            releaseContinuation = nil
            return pending
        }
        continuation?.resume()
    }

    private func waitForRelease() async {
        await withCheckedContinuation { continuation in
            let alreadyReleased: Bool = lock.withLock {
                if isReleased {
                    return true
                }
                releaseContinuation = continuation
                return false
            }
            if alreadyReleased {
                continuation.resume()
            }
        }
    }
}

final class TwoPhaseEarthquakeRepository: EarthquakeRepositoryProviding, @unchecked Sendable {
    private let first: [Earthquake]
    private let second: [Earthquake]
    private let lock = NSLock()
    private var callCount = 0

    init(first: [Earthquake], second: [Earthquake]) {
        self.first = first
        self.second = second
    }

    func events(
        policy: EarthquakeLoadPolicy = .normal
    ) -> AsyncThrowingStream<EarthquakeRepositoryEvent, any Error> {
        let earthquakes: [Earthquake] = lock.withLock {
            callCount += 1
            return callCount == 1 ? first : second
        }
        let value = EarthquakeRepositoryValue(
            earthquakes: earthquakes,
            fetchedAt: Date(),
            source: .network,
            freshness: .fresh
        )
        return AsyncThrowingStream { continuation in
            continuation.yield(.value(value))
            continuation.finish()
        }
    }
}

struct StubFaultDatasetProvider: FaultDatasetProviding {
    let dataset: FaultDataset

    func loadDataset() async throws -> FaultDataset {
        dataset
    }
}

struct FailingFaultDatasetProvider: FaultDatasetProviding {
    func loadDataset() async throws -> FaultDataset {
        throw FaultDatasetDecodingError.malformedPayload
    }
}

@Suite("Awareness content")
struct AwarenessContentTests {
    @Test("Content mirrors the web cards with unique ids and secure links")
    func contentIntegrity() {
        let items = AwarenessContent.items
        #expect(items.count == 14)
        #expect(Set(items.map(\.id)).count == items.count)
        for item in items {
            #expect(item.url.scheme == "https")
            #expect(["Oku", "İzle", "Görüntüle"].contains(item.actionTitle))
            #expect(!item.title.isEmpty)
        }
    }

    @Test("Action titles map to system images")
    func actionIcons() {
        let map = Dictionary(
            AwarenessContent.items.map { ($0.actionTitle, $0.systemImage) },
            uniquingKeysWith: { first, _ in first }
        )
        #expect(map["Oku"] == "book")
        #expect(map["İzle"] == "play.rectangle")
        #expect(map["Görüntüle"] == "arrow.up.right.square")
    }

    @Test("No placeholder or broken links remain")
    func noPlaceholders() {
        for item in AwarenessContent.items {
            #expect(!item.url.absoluteString.contains("example.com"))
        }
    }
}

@Suite("About links")
struct AboutLinksTests {
    @Test("GINRAS points at the GINRAS service and the remaining links are intact")
    func links() {
        #expect(AboutLinks.ginras.host == "neotec.ginras.ru")
        #expect(AboutLinks.ginras.absoluteString == "http://neotec.ginras.ru/")
        #expect(AboutLinks.koeri.host == "www.koeri.boun.edu.tr")
        #expect(AboutLinks.website.absoluteString == "https://www.depremoldu.org")
        #expect(AboutLinks.depremAPI.host == "api.orhanaydogdu.com.tr")
        #expect(AboutLinks.developerWebsite.absoluteString == "https://bedirdemir.com")
        #expect(AboutLinks.repository.host == "github.com")
    }
}

@Suite("UI testing fixtures")
struct UITestingFixtureTests {
    @Test("Fixture feed is deterministic and supports every magnitude class")
    func fixtures() {
        let feed = UITestingEarthquakeFixtures.feed()
        #expect(feed.count == 8)
        #expect(Set(feed.map(\.id)).count == feed.count)
        #expect(feed.contains { $0.magnitudeClass == .small })
        #expect(feed.contains { $0.magnitudeClass == .medium })
        #expect(feed.contains { $0.magnitudeClass == .large })
        #expect(feed.contains { $0.magnitudeClass == .veryLarge })
        #expect(feed.allSatisfy { $0.region.hasPrefix("FIXTURE REGION") })

        let many = UITestingEarthquakeFixtures.feed(count: 120)
        #expect(many.count == 120)
        #expect(Set(many.map(\.id)).count == many.count)
        #expect(many.first?.id == "ui-1")
        #expect(many.last?.id == "ui-120")
    }
}
