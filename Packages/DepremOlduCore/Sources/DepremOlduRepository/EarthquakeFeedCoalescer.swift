import Foundation

package actor EarthquakeFeedCoalescer {
    private var inFlight: Task<EarthquakeRepositoryValue, any Error>?

    package func value(
        operation: @Sendable @escaping () async throws -> EarthquakeRepositoryValue
    ) async throws -> EarthquakeRepositoryValue {
        if let inFlight {
            return try await inFlight.value
        }

        let task = Task { try await operation() }
        inFlight = task

        do {
            let value = try await task.value
            inFlight = nil
            return value
        } catch {
            inFlight = nil
            throw error
        }
    }

    package func invalidate() {
        inFlight?.cancel()
        inFlight = nil
    }
}
