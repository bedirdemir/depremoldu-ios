import Foundation

public struct TurkishRelativeTimeFormatter: Sendable {
    public init() {}

    public func string(from date: Date, relativeTo reference: Date) -> String {
        let difference = reference.timeIntervalSince(date)
        guard difference.isFinite else { return "-" }

        let isFuture = difference < 0
        let seconds = Int(abs(difference).rounded())
        let minutes = Int((Double(seconds) / 60).rounded())
        let hours = Int((Double(minutes) / 60).rounded())
        let days = Int((Double(hours) / 24).rounded())
        let months = Int((Double(days) / 30).rounded())
        let years = Int((Double(days) / 365).rounded())

        let phrase: String
        if seconds < 45 {
            phrase = "birkaç saniye"
        } else if seconds < 90 {
            phrase = "bir dakika"
        } else if minutes < 45 {
            phrase = "\(minutes) dakika"
        } else if minutes < 90 {
            phrase = "bir saat"
        } else if hours < 22 {
            phrase = "\(hours) saat"
        } else if hours < 36 {
            phrase = "bir gün"
        } else if days < 26 {
            phrase = "\(days) gün"
        } else if days < 46 {
            phrase = "bir ay"
        } else if days < 320 {
            phrase = "\(months) ay"
        } else if days < 548 {
            phrase = "bir yıl"
        } else {
            phrase = "\(years) yıl"
        }

        return isFuture ? "\(phrase) içinde" : "\(phrase) önce"
    }
}
