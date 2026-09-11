import Foundation

public enum FaultMapStylePolicy {
    public static let lineOpacity: Double = 0.9

    public static func colorName(for confidence: FaultConfidence) -> String {
        switch confidence {
        case .a: "b91c1c"
        case .b: "ef4444"
        case .c: "f87171"
        case .d: "fca5a5"
        }
    }

    public static func baseWeight(for rate: FaultRate) -> Double {
        switch rate {
        case .one: 4
        case .two: 3
        case .three: 2
        }
    }

    public static func zoomFactor(for zoom: Double) -> Double {
        let raw = 0.58 + (zoom - 5) * 0.09
        return min(1.25, max(0.58, raw))
    }

    public static func lineWidth(rate: FaultRate, zoom: Double) -> Double {
        let width = baseWeight(for: rate) * zoomFactor(for: zoom)
        return (width * 100).rounded() / 100
    }
}
