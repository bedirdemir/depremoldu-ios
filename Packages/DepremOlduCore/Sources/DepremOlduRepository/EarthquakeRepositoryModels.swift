import Foundation
import DepremOlduDomain

public enum EarthquakeLoadPolicy: Equatable, Sendable {
    case normal
    case forceRefresh
}

public enum EarthquakeRepositorySource: Equatable, Sendable {
    case network
    case cache
}

public enum EarthquakeRepositoryFreshness: Equatable, Sendable {
    case fresh
    case stale
}

public enum EarthquakeRefreshFailure: Error, Equatable, Sendable {
    case invalidRequest
    case timedOut
    case offline
    case connectionLost
    case httpStatus(code: Int, retryAfter: TimeInterval?)
    case invalidPayload
    case unexpected
}

public struct EarthquakeRepositoryValue: Sendable {
    public let earthquakes: [Earthquake]
    public let fetchedAt: Date
    public let source: EarthquakeRepositorySource
    public let freshness: EarthquakeRepositoryFreshness

    public init(
        earthquakes: [Earthquake],
        fetchedAt: Date,
        source: EarthquakeRepositorySource,
        freshness: EarthquakeRepositoryFreshness
    ) {
        self.earthquakes = earthquakes
        self.fetchedAt = fetchedAt
        self.source = source
        self.freshness = freshness
    }
}

public enum EarthquakeRepositoryEvent: Sendable {
    case refreshing(stale: EarthquakeRepositoryValue?)
    case value(EarthquakeRepositoryValue)
    case refreshFailed(stale: EarthquakeRepositoryValue, failure: EarthquakeRefreshFailure)
    case terminalFailure(failure: EarthquakeRefreshFailure)
}

public protocol EarthquakeRepositoryProviding: Sendable {
    func events(policy: EarthquakeLoadPolicy) -> AsyncThrowingStream<EarthquakeRepositoryEvent, any Error>
}

public enum EarthquakeFeedLimits {
    public static let pageSize = 100
    public static let feedCount = 500
    public static let listCount = 200
    public static let mapCount = 500
}
