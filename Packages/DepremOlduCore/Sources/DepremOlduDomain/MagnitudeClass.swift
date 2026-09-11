import Foundation

public enum MagnitudeClass: String, CaseIterable, Hashable, Sendable {
    case small
    case medium
    case large
    case veryLarge

    public init(magnitude: Double) {
        if magnitude >= 6.5 {
            self = .veryLarge
        } else if magnitude >= 5.0 {
            self = .large
        } else if magnitude >= 4.0 {
            self = .medium
        } else {
            self = .small
        }
    }

    public var turkishLabel: String {
        switch self {
        case .small: "Küçük"
        case .medium: "Orta"
        case .large: "Büyük"
        case .veryLarge: "Çok Büyük"
        }
    }
}
