import Foundation
import DepremOlduDomain

public enum FaultDatasetDecodingError: Error, Equatable, Sendable {
    case malformedPayload
    case unsupportedVersion(Int)
}

public struct FaultDatasetJSONDecoder: Sendable {
    public static let supportedVersion = 1

    public init() {}

    public func decode(_ data: Data) throws -> FaultDataset {
        let payload: Payload
        do {
            payload = try JSONDecoder().decode(Payload.self, from: data)
        } catch {
            throw FaultDatasetDecodingError.malformedPayload
        }

        guard payload.version == Self.supportedVersion else {
            throw FaultDatasetDecodingError.unsupportedVersion(payload.version)
        }

        let lines = payload.lines.compactMap { line -> FaultLine? in
            let coordinates = line.coordinates.compactMap { pair -> GeoCoordinate? in
                guard pair.count == 2 else { return nil }
                return GeoCoordinate(latitude: pair[1], longitude: pair[0])
            }
            guard coordinates.count >= 2 else { return nil }
            return FaultLine(
                name: line.name,
                confidence: FaultConfidence(rawValue: line.confidence ?? "") ?? .fallback,
                rate: FaultRate(rawValue: line.rate ?? 0) ?? .fallback,
                coordinates: coordinates
            )
        }

        return FaultDataset(
            version: payload.version,
            source: payload.source,
            lines: lines
        )
    }

    private struct Payload: Decodable {
        let version: Int
        let source: String
        let lines: [Line]
    }

    private struct Line: Decodable {
        let name: String?
        let confidence: String?
        let rate: Int?
        let coordinates: [[Double]]

        private enum CodingKeys: String, CodingKey {
            case name
            case confidence = "c"
            case rate = "r"
            case coordinates = "p"
        }
    }
}

public protocol FaultDatasetProviding: Sendable {
    func loadDataset() async throws -> FaultDataset
}

public struct DataFaultDatasetProvider: FaultDatasetProviding {
    private let data: Data

    public init(data: Data) {
        self.data = data
    }

    public func loadDataset() async throws -> FaultDataset {
        try FaultDatasetJSONDecoder().decode(data)
    }
}
