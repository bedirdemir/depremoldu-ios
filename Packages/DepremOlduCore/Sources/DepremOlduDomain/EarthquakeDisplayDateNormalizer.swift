import Foundation

public enum EarthquakeDisplayDateNormalizer {
    public static func displayDate(from rawDate: String) -> String {
        guard !rawDate.isEmpty else { return "-" }
        return rawDate.replacingOccurrences(of: "-", with: ".").replacingOccurrences(of: "/", with: ".")
    }

    public static func occurredAt(
        rawDate: String,
        rawTime: String,
        timeZoneIdentifier: String?
    ) -> Date? {
        guard !rawDate.isEmpty, !rawTime.isEmpty else { return nil }
        let normalizedDate = rawDate.replacingOccurrences(of: ".", with: "-")
        let normalizedTime = rawTime
        guard normalizedDate != "-", normalizedTime != "-" else { return nil }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = timeZone(identifier: timeZoneIdentifier) ?? TimeZone(identifier: "Europe/Istanbul")
        return formatter.date(from: "\(normalizedDate) \(normalizedTime)")
    }

    private static func timeZone(identifier: String?) -> TimeZone? {
        guard let identifier, !identifier.isEmpty else { return nil }
        return TimeZone(identifier: identifier)
    }
}
