import Foundation

public struct Earthquake: Hashable, Identifiable, Sendable {
    public let id: String
    public let provider: String
    public let region: String
    public let magnitude: Double
    public let scale: String
    public let depth: Double?
    public let displayDate: String
    public let displayTime: String
    public let occurredAt: Date?
    public let coordinate: GeoCoordinate?

    public init(
        id: String,
        provider: String,
        region: String,
        magnitude: Double,
        scale: String = "ML",
        depth: Double?,
        displayDate: String,
        displayTime: String,
        occurredAt: Date?,
        coordinate: GeoCoordinate?
    ) {
        self.id = id
        self.provider = provider
        self.region = region
        self.magnitude = magnitude
        self.scale = scale
        self.depth = depth
        self.displayDate = displayDate
        self.displayTime = displayTime
        self.occurredAt = occurredAt
        self.coordinate = coordinate
    }

    public var magnitudeClass: MagnitudeClass {
        MagnitudeClass(magnitude: magnitude)
    }

    public var formattedMagnitude: String {
        guard magnitude.isFinite else { return "-" }
        if magnitude.rounded() == magnitude {
            return String(format: "%.1f", magnitude)
        }
        return String(magnitude)
    }

    public var formattedDepth: String {
        guard let depth, depth.isFinite, depth >= 0 else { return "-" }
        if depth.rounded() == depth {
            return String(Int(depth))
        }
        return String(depth)
    }

    public var displayDateTime: String {
        "\(displayDate) - \(displayTime)"
    }
}
