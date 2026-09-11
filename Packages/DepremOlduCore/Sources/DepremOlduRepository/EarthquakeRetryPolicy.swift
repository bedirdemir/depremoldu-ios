import Foundation

enum EarthquakeRetryPolicy {
    static let maximumAttempts = 3

    static func shouldRetry(
        failure: EarthquakeRefreshFailure,
        completedAttempts: Int
    ) -> Bool {
        guard completedAttempts < maximumAttempts else { return false }
        switch failure {
        case .timedOut, .connectionLost:
            return true
        case let .httpStatus(code, _):
            return [408, 429, 500, 502, 503, 504].contains(code)
        case .invalidRequest, .offline, .invalidPayload, .unexpected:
            return false
        }
    }

    static func delay(
        for failure: EarthquakeRefreshFailure,
        attempt: Int,
        jitter: Double
    ) -> TimeInterval? {
        if case let .httpStatus(code, retryAfter) = failure,
           code == 429 || code == 503,
           let retryAfter,
           retryAfter.isFinite,
           retryAfter > 0,
           retryAfter <= 60 {
            return retryAfter
        }

        let base: TimeInterval = attempt == 1 ? 0.5 : 1.0
        let boundedJitter = jitter.isFinite ? min(max(jitter, 0.8), 1.2) : 1.0
        return base * boundedJitter
    }
}

package protocol EarthquakeRetrySleeping: Sendable {
    func sleep(for duration: TimeInterval) async throws
}

package struct TaskEarthquakeRetrySleeper: EarthquakeRetrySleeping {
    package func sleep(for duration: TimeInterval) async throws {
        try await Task.sleep(for: .seconds(duration))
    }
}

package protocol EarthquakeRetryJitterProviding: Sendable {
    func nextJitter() -> Double
}

package struct SystemEarthquakeRetryJitterProvider: EarthquakeRetryJitterProviding {
    package func nextJitter() -> Double {
        Double.random(in: 0.8 ... 1.2)
    }
}
