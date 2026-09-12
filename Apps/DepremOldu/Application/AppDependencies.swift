import Foundation
import DepremOlduDomain
import DepremOlduFaults
import DepremOlduNetworking
import DepremOlduPersistence
import DepremOlduRepository

struct AppDependencies {
    let feedModel: EarthquakeFeedFeatureModel
    let mapModel: EarthquakeMapFeatureModel

    @MainActor
    static func live() -> AppDependencies {
        makeDependencies(repository: liveRepository())
    }

    @MainActor
    private static func makeDependencies(
        repository: any EarthquakeRepositoryProviding
    ) -> AppDependencies {
        AppDependencies(
            feedModel: EarthquakeFeedFeatureModel(repository: repository),
            mapModel: EarthquakeMapFeatureModel(faultProvider: bundledFaultProvider())
        )
    }

    private static func liveRepository() -> any EarthquakeRepositoryProviding {
        do {
            let client = try URLSessionHTTPClient()
            let service = KandilliEarthquakeService(client: client)
            let store = try FilePersistenceStore(directoryURL: FeedCacheDirectoryPolicy.makeDirectory())
            return EarthquakeRepository(service: service, store: store)
        } catch {
            return UnavailableEarthquakeRepository()
        }
    }

    private static func bundledFaultProvider() -> any FaultDatasetProviding {
        guard let url = Bundle.main.url(forResource: "Faults", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return UnavailableFaultDatasetProvider()
        }
        return DataFaultDatasetProvider(data: data)
    }
}

struct UnavailableEarthquakeRepository: EarthquakeRepositoryProviding {
    func events(
        policy: EarthquakeLoadPolicy = .normal
    ) -> AsyncThrowingStream<EarthquakeRepositoryEvent, any Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(.terminalFailure(failure: .unexpected))
            continuation.finish()
        }
    }
}

struct UnavailableFaultDatasetProvider: FaultDatasetProviding {
    func loadDataset() async throws -> FaultDataset {
        throw FaultDatasetDecodingError.malformedPayload
    }
}

#if TESTING
extension AppDependencies {
    @MainActor
    static func testing() -> AppDependencies {
        let arguments = ProcessInfo.processInfo.arguments
        let repository: any EarthquakeRepositoryProviding
        if arguments.contains("-depremoldu-ui-live") {
            repository = liveRepository()
        } else if arguments.contains("-depremoldu-ui-failure") {
            repository = UnavailableEarthquakeRepository()
        } else if arguments.contains("-depremoldu-ui-empty") {
            repository = StaticEarthquakeRepository(
                events: [
                    .value(
                        EarthquakeRepositoryValue(
                            earthquakes: [],
                            fetchedAt: Date(),
                            source: .network,
                            freshness: .fresh
                        )
                    ),
                ]
            )
        } else {
            let count = arguments.contains("-depremoldu-ui-many") ? 120 : 8
            repository = StaticEarthquakeRepository(
                events: [
                    .value(
                        EarthquakeRepositoryValue(
                            earthquakes: UITestingEarthquakeFixtures.feed(count: count),
                            fetchedAt: Date(),
                            source: .network,
                            freshness: .fresh
                        )
                    ),
                ]
            )
        }
        return makeDependencies(repository: repository)
    }
}

struct StaticEarthquakeRepository: EarthquakeRepositoryProviding {
    let events: [EarthquakeRepositoryEvent]

    init(events: [EarthquakeRepositoryEvent]) {
        self.events = events
    }

    func events(
        policy: EarthquakeLoadPolicy = .normal
    ) -> AsyncThrowingStream<EarthquakeRepositoryEvent, any Error> {
        let scripted = events
        return AsyncThrowingStream { continuation in
            for event in scripted {
                continuation.yield(event)
            }
            continuation.finish()
        }
    }
}

enum UITestingEarthquakeFixtures {
    private static let samples: [(String, String, Double, Double, TimeInterval)] = [
        ("ui-1", "SUGUL-DARENDE (MALATYA)", 2.0, 5.3, 300),
        ("ui-2", "EGE DENIZI", 1.9, 17.2, 2_400),
        ("ui-3", "GIRIT ADASI ACIKLARI (AKDENIZ)", 4.2, 6.1, 7_200),
        ("ui-4", "KAHRAMANMARAS MERKEZ", 5.4, 10.0, 90_000),
        ("ui-5", "VAN GOLU ACIKLARI", 6.7, 12.5, 400_000),
        ("ui-6", "IZMIR KORFEZI", 3.4, 8.8, 1_800_000),
        ("ui-7", "BINGOL KARLIOVA", 2.7, 4.4, 7_000_000),
        ("ui-8", "ANTALYA KAS ACIKLARI", 1.2, 22.0, 40_000_000),
    ]

    static func feed(count: Int = samples.count) -> [Earthquake] {
        let now = Date()
        return (0 ..< count).map { index in
            let sample = samples[index % samples.count]
            let cycle = index / samples.count
            return Earthquake(
                id: "ui-\(index + 1)",
                provider: "kandilli",
                region: "FIXTURE REGION \(index + 1)",
                magnitude: sample.2 + Double(cycle % 3),
                depth: sample.3,
                displayDate: "2026.09.11",
                displayTime: "23:24:22",
                occurredAt: now.addingTimeInterval(-sample.4 - Double(index) * 60),
                coordinate: GeoCoordinate(
                    latitude: 36.0 + Double(index % 40) * 0.35,
                    longitude: 26.0 + Double(index % 60) * 0.28
                )
            )
        }
    }
}
#endif
