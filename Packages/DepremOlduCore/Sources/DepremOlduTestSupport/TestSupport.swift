import Foundation
import DepremOlduDomain
import DepremOlduNetworking
import DepremOlduRepository

public enum EarthquakeFixtures {
    public static let referenceDate = Date(timeIntervalSince1970: 1_789_158_000)

    public static func coordinate(index: Int) -> GeoCoordinate {
        GeoCoordinate(
            latitude: 36.0 + Double(index) * 0.05,
            longitude: 26.0 + Double(index) * 0.07
        )!
    }

    public static func earthquake(
        id: String = "fixture-id",
        region: String = "SUGUL-DARENDE (MALATYA)",
        magnitude: Double = 2.0,
        depth: Double? = 5.3,
        displayDate: String = "2026.09.11",
        displayTime: String = "23:24:22",
        occurredAt: Date? = referenceDate,
        coordinate: GeoCoordinate? = nil
    ) -> Earthquake {
        Earthquake(
            id: id,
            provider: "kandilli",
            region: region,
            magnitude: magnitude,
            depth: depth,
            displayDate: displayDate,
            displayTime: displayTime,
            occurredAt: occurredAt,
            coordinate: coordinate
        )
    }

    public static func feed(count: Int) -> [Earthquake] {
        (0 ..< count).map { index in
            earthquake(
                id: "fixture-\(index)",
                region: "FIXTURE REGION \(index)",
                magnitude: 1.0 + Double(index % 70) / 10,
                depth: 5 + Double(index % 30),
                coordinate: coordinate(index: index)
            )
        }
    }

    public static func dto(index: Int) -> KandilliEarthquakeDTO {
        KandilliEarthquakeDTO(
            earthquakeID: "fixture-\(index)",
            provider: "kandilli",
            title: "FIXTURE REGION \(index)",
            magnitude: 1.0 + Double(index % 70) / 10,
            depth: 5 + Double(index % 30),
            geojson: KandilliGeoJSONPointDTO(
                type: "Point",
                coordinates: [
                    26.0 + Double(index) * 0.07,
                    36.0 + Double(index) * 0.05,
                ]
            ),
            dateTime: "2026-09-11 23:24:22",
            locationTimeZone: "Europe/Istanbul"
        )
    }

    public static func page(count: Int, startIndex: Int = 0) -> [KandilliEarthquakeDTO] {
        (0 ..< count).map { dto(index: startIndex + $0) }
    }

    public static func pageData(items: [KandilliEarthquakeDTO]) throws -> Data {
        let payload: [String: Any] = [
            "status": true,
            "httpStatus": 200,
            "desc": "",
            "serverloadms": 11,
            "result": try items.map(Self.jsonObject(item:)),
        ]
        return try JSONSerialization.data(withJSONObject: payload)
    }

    private static func jsonObject(item: KandilliEarthquakeDTO) throws -> [String: Any] {
        let encoder = JSONEncoder()
        let data = try encoder.encode(item)
        let object = try JSONSerialization.jsonObject(with: data)
        guard let dictionary = object as? [String: Any] else {
            throw TestSupportError.invalidFixture
        }
        return dictionary
    }
}

public enum TestSupportError: Error {
    case invalidFixture
}

public struct StubEarthquakeRepository: EarthquakeRepositoryProviding {
    public var scriptedEvents: [EarthquakeRepositoryEvent]
    public var error: (any Error & Sendable)?

    public init(
        scriptedEvents: [EarthquakeRepositoryEvent],
        error: (any Error & Sendable)? = nil
    ) {
        self.scriptedEvents = scriptedEvents
        self.error = error
    }

    public static func content(
        _ earthquakes: [Earthquake],
        source: EarthquakeRepositorySource = .network,
        freshness: EarthquakeRepositoryFreshness = .fresh,
        fetchedAt: Date = EarthquakeFixtures.referenceDate
    ) -> StubEarthquakeRepository {
        StubEarthquakeRepository(
            scriptedEvents: [
                .value(
                    EarthquakeRepositoryValue(
                        earthquakes: earthquakes,
                        fetchedAt: fetchedAt,
                        source: source,
                        freshness: freshness
                    )
                ),
            ]
        )
    }

    public static func failure(_ failure: EarthquakeRefreshFailure) -> StubEarthquakeRepository {
        StubEarthquakeRepository(scriptedEvents: [.terminalFailure(failure: failure)])
    }

    public func events(
        policy: EarthquakeLoadPolicy = .normal
    ) -> AsyncThrowingStream<EarthquakeRepositoryEvent, any Error> {
        let scriptedEvents = scriptedEvents
        let error = error
        return AsyncThrowingStream { continuation in
            for event in scriptedEvents {
                continuation.yield(event)
            }
            if let error {
                continuation.finish(throwing: error)
            } else {
                continuation.finish()
            }
        }
    }
}
