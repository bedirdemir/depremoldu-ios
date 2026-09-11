import Foundation
import DepremOlduNetworking

struct EarthquakeCacheRecordV1: Codable, Sendable {
    static let currentSchemaVersion = 1

    let schemaVersion: Int
    let fetchedAt: Date
    let pages: [[KandilliEarthquakeDTO]]
}

enum EarthquakeCacheRecordCodec {
    static func encode(_ record: EarthquakeCacheRecordV1) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        return try encoder.encode(record)
    }

    static func decode(_ data: Data) throws -> EarthquakeCacheRecordV1 {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try decoder.decode(EarthquakeCacheRecordV1.self, from: data)
    }
}
