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
}
