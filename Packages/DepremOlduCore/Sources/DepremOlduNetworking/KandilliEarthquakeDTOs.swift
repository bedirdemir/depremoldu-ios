import Foundation

public struct KandilliEarthquakeSearchResponseDTO: Decodable, Sendable {
    public let status: Bool?
    public let httpStatus: Int?
    public let result: [KandilliEarthquakeDTO]?

    public init(status: Bool?, httpStatus: Int?, result: [KandilliEarthquakeDTO]?) {
        self.status = status
        self.httpStatus = httpStatus
        self.result = result
    }

    private enum CodingKeys: String, CodingKey {
        case status
        case httpStatus = "httpStatus"
        case result
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try? container.decodeIfPresent(Bool.self, forKey: .status)
        httpStatus = try? container.decodeIfPresent(Int.self, forKey: .httpStatus)
        result = try Self.decodeLossyResult(from: container)
    }

    private static func decodeLossyResult(
        from container: KeyedDecodingContainer<CodingKeys>
    ) throws -> [KandilliEarthquakeDTO]? {
        guard container.contains(.result) else { return nil }
        if (try? container.decodeNil(forKey: .result)) == true { return nil }
        return try? container.decode([KandilliEarthquakeDTO].self, forKey: .result)
    }
}

public struct KandilliEarthquakeDTO: Codable, Sendable {
    public let earthquakeID: String?
    public let provider: String?
    public let title: String?
    public let magnitude: Double?
    public let depth: Double?
    public let geojson: KandilliGeoJSONPointDTO?
    public let dateTime: String?
    public let locationTimeZone: String?

    public init(
        earthquakeID: String?,
        provider: String?,
        title: String?,
        magnitude: Double?,
        depth: Double?,
        geojson: KandilliGeoJSONPointDTO?,
        dateTime: String?,
        locationTimeZone: String?
    ) {
        self.earthquakeID = earthquakeID
        self.provider = provider
        self.title = title
        self.magnitude = magnitude
        self.depth = depth
        self.geojson = geojson
        self.dateTime = dateTime
        self.locationTimeZone = locationTimeZone
    }

    private enum CodingKeys: String, CodingKey {
        case earthquakeID = "earthquake_id"
        case provider
        case title
        case magnitude = "mag"
        case depth
        case geojson
        case dateTime = "date_time"
        case locationTimeZone = "location_tz"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        earthquakeID = try? container.decodeIfPresent(String.self, forKey: .earthquakeID)
        provider = try? container.decodeIfPresent(String.self, forKey: .provider)
        title = try? container.decodeIfPresent(String.self, forKey: .title)
        magnitude = try? container.decodeIfPresent(LossyDouble.self, forKey: .magnitude)?.value
        depth = try? container.decodeIfPresent(LossyDouble.self, forKey: .depth)?.value
        geojson = try? container.decodeIfPresent(KandilliGeoJSONPointDTO.self, forKey: .geojson)
        dateTime = try? container.decodeIfPresent(String.self, forKey: .dateTime)
        locationTimeZone = try? container.decodeIfPresent(String.self, forKey: .locationTimeZone)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(earthquakeID, forKey: .earthquakeID)
        try container.encodeIfPresent(provider, forKey: .provider)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(magnitude, forKey: .magnitude)
        try container.encodeIfPresent(depth, forKey: .depth)
        try container.encodeIfPresent(geojson, forKey: .geojson)
        try container.encodeIfPresent(dateTime, forKey: .dateTime)
        try container.encodeIfPresent(locationTimeZone, forKey: .locationTimeZone)
    }
}

public struct KandilliGeoJSONPointDTO: Codable, Sendable {
    public let type: String?
    public let coordinates: [Double]?

    public init(type: String?, coordinates: [Double]?) {
        self.type = type
        self.coordinates = coordinates
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case coordinates
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try? container.decodeIfPresent(String.self, forKey: .type)
        if let values = try? container.decodeIfPresent([LossyDouble].self, forKey: .coordinates) {
            coordinates = values.compactMap(\.value)
        } else {
            coordinates = nil
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encodeIfPresent(coordinates, forKey: .coordinates)
    }
}

private struct LossyDouble: Decodable {
    let value: Double?

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let number = try? container.decode(Double.self) {
            value = number
            return
        }
        if let text = try? container.decode(String.self) {
            value = Double(text)
            return
        }
        value = nil
    }
}
