import Foundation
import DepremOlduDomain

public enum FaultConfidence: String, CaseIterable, Codable, Hashable, Sendable {
    case a = "A"
    case b = "B"
    case c = "C"
    case d = "D"

    public static let fallback: FaultConfidence = .c
}

public enum FaultRate: Int, CaseIterable, Codable, Hashable, Sendable {
    case one = 1
    case two = 2
    case three = 3

    public static let fallback: FaultRate = .three
}

public struct FaultLine: Hashable, Sendable {
    public let name: String?
    public let confidence: FaultConfidence
    public let rate: FaultRate
    public let coordinates: [GeoCoordinate]

    public init(
        name: String?,
        confidence: FaultConfidence,
        rate: FaultRate,
        coordinates: [GeoCoordinate]
    ) {
        self.name = name
        self.confidence = confidence
        self.rate = rate
        self.coordinates = coordinates
    }
}

public struct FaultDataset: Hashable, Sendable {
    public let version: Int
    public let source: String
    public let lines: [FaultLine]

    public init(version: Int, source: String, lines: [FaultLine]) {
        self.version = version
        self.source = source
        self.lines = lines
    }
}
