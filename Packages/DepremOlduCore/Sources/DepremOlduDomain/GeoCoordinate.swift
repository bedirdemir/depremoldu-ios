import Foundation

public struct GeoCoordinate: Hashable, Sendable {
    public let latitude: Double
    public let longitude: Double

    public init?(latitude: Double, longitude: Double) {
        guard latitude.isFinite, longitude.isFinite,
              (-90.0 ... 90.0).contains(latitude),
              (-180.0 ... 180.0).contains(longitude) else {
            return nil
        }
        self.latitude = latitude
        self.longitude = longitude
    }

    public init?(longitudeFirst coordinates: [Double]) {
        guard coordinates.count == 2 else { return nil }
        self.init(latitude: coordinates[1], longitude: coordinates[0])
    }

    public var displayText: String {
        "\(Self.trimmed(latitude)), \(Self.trimmed(longitude))"
    }

    private static func trimmed(_ value: Double) -> String {
        var text = String(format: "%.5f", value)
        while text.contains("."), text.hasSuffix("0") {
            text.removeLast()
        }
        if text.hasSuffix(".") {
            text.removeLast()
        }
        return text
    }
}
