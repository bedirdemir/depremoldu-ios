import Foundation
import Testing

@testable import DepremOlduDomain

@Suite("Magnitude classification")
struct MagnitudeClassTests {
    @Test("Classification boundaries match the web thresholds")
    func classificationBoundaries() {
        #expect(MagnitudeClass(magnitude: 0) == .small)
        #expect(MagnitudeClass(magnitude: 3.9) == .small)
        #expect(MagnitudeClass(magnitude: 3.99) == .small)
        #expect(MagnitudeClass(magnitude: 4.0) == .medium)
        #expect(MagnitudeClass(magnitude: 4.99) == .medium)
        #expect(MagnitudeClass(magnitude: 5.0) == .large)
        #expect(MagnitudeClass(magnitude: 6.49) == .large)
        #expect(MagnitudeClass(magnitude: 6.5) == .veryLarge)
        #expect(MagnitudeClass(magnitude: 7.8) == .veryLarge)
    }

    @Test("Turkish labels match the web copy")
    func turkishLabels() {
        #expect(MagnitudeClass.small.turkishLabel == "Küçük")
        #expect(MagnitudeClass.medium.turkishLabel == "Orta")
        #expect(MagnitudeClass.large.turkishLabel == "Büyük")
        #expect(MagnitudeClass.veryLarge.turkishLabel == "Çok Büyük")
    }
}

@Suite("Earthquake display formatting")
struct EarthquakeDisplayFormattingTests {
    private func earthquake(
        magnitude: Double,
        depth: Double?,
        displayDate: String = "2026.09.11",
        displayTime: String = "23:24:22"
    ) -> Earthquake {
        Earthquake(
            id: "id",
            provider: "kandilli",
            region: "SUGUL-DARENDE (MALATYA)",
            magnitude: magnitude,
            depth: depth,
            displayDate: displayDate,
            displayTime: displayTime,
            occurredAt: nil,
            coordinate: nil
        )
    }

    @Test("Integer magnitudes render with one decimal like the web")
    func integerMagnitude() {
        #expect(earthquake(magnitude: 2, depth: 5).formattedMagnitude == "2.0")
        #expect(earthquake(magnitude: 3, depth: 5).formattedMagnitude == "3.0")
    }

    @Test("Fractional magnitudes render with the raw decimal dot")
    func fractionalMagnitude() {
        #expect(earthquake(magnitude: 4.5, depth: 5).formattedMagnitude == "4.5")
        #expect(earthquake(magnitude: 2.63, depth: 5).formattedMagnitude == "2.63")
    }

    @Test("Depth renders integer values without a decimal and fractional values raw")
    func depthFormatting() {
        #expect(earthquake(magnitude: 2, depth: 5).formattedDepth == "5")
        #expect(earthquake(magnitude: 2, depth: 5.3).formattedDepth == "5.3")
        #expect(earthquake(magnitude: 2, depth: 17.2).formattedDepth == "17.2")
        #expect(earthquake(magnitude: 2, depth: nil).formattedDepth == "-")
        #expect(earthquake(magnitude: 2, depth: -1).formattedDepth == "-")
    }

    @Test("Scale defaults to ML and the display date-time joins with a dash")
    func scaleAndDateTime() {
        let item = earthquake(magnitude: 2, depth: 5)
        #expect(item.scale == "ML")
        #expect(item.displayDateTime == "2026.09.11 - 23:24:22")
    }
}

@Suite("Display date normalization")
struct EarthquakeDisplayDateNormalizerTests {
    @Test("Dashes and slashes normalize to dots")
    func normalization() {
        #expect(EarthquakeDisplayDateNormalizer.displayDate(from: "2026-09-11") == "2026.09.11")
        #expect(EarthquakeDisplayDateNormalizer.displayDate(from: "2026/09/11") == "2026.09.11")
        #expect(EarthquakeDisplayDateNormalizer.displayDate(from: "2026.09.11") == "2026.09.11")
        #expect(EarthquakeDisplayDateNormalizer.displayDate(from: "") == "-")
    }

    @Test("Occurred-at parses in the provider time zone")
    func parsing() throws {
        let date = try #require(
            EarthquakeDisplayDateNormalizer.occurredAt(
                rawDate: "2026-09-11",
                rawTime: "23:24:22",
                timeZoneIdentifier: "Europe/Istanbul"
            )
        )
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "UTC"))
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        #expect(components.year == 2026)
        #expect(components.month == 9)
        #expect(components.day == 11)
        #expect(components.hour == 20)
        #expect(components.minute == 24)
    }

    @Test("Missing time zone falls back to Europe/Istanbul and empty input fails")
    func fallbackAndInvalid() {
        let fallback = EarthquakeDisplayDateNormalizer.occurredAt(
            rawDate: "2026-09-11",
            rawTime: "23:24:22",
            timeZoneIdentifier: nil
        )
        let istanbul = EarthquakeDisplayDateNormalizer.occurredAt(
            rawDate: "2026-09-11",
            rawTime: "23:24:22",
            timeZoneIdentifier: "Europe/Istanbul"
        )
        #expect(fallback == istanbul)
        #expect(EarthquakeDisplayDateNormalizer.occurredAt(
            rawDate: "",
            rawTime: "",
            timeZoneIdentifier: "Europe/Istanbul"
        ) == nil)
        #expect(EarthquakeDisplayDateNormalizer.occurredAt(
            rawDate: "not-a-date",
            rawTime: "23:24:22",
            timeZoneIdentifier: "Europe/Istanbul"
        ) == nil)
    }
}

@Suite("Turkish relative time")
struct TurkishRelativeTimeFormatterTests {
    private let formatter = TurkishRelativeTimeFormatter()
    private let reference = Date(timeIntervalSince1970: 1_800_000_000)

    private func relative(secondsAgo: Double) -> String {
        formatter.string(
            from: reference.addingTimeInterval(-secondsAgo),
            relativeTo: reference
        )
    }

    @Test("Sub-minute ages use the a-few-seconds phrase")
    func seconds() {
        #expect(relative(secondsAgo: 0) == "birkaç saniye önce")
        #expect(relative(secondsAgo: 44) == "birkaç saniye önce")
    }

    @Test("One-minute and minute phrases")
    func minutes() {
        #expect(relative(secondsAgo: 45) == "bir dakika önce")
        #expect(relative(secondsAgo: 89) == "bir dakika önce")
        #expect(relative(secondsAgo: 90) == "2 dakika önce")
        #expect(relative(secondsAgo: 60 * 44) == "44 dakika önce")
    }

    @Test("Hour phrases")
    func hours() {
        #expect(relative(secondsAgo: 60 * 45) == "bir saat önce")
        #expect(relative(secondsAgo: 60 * 89) == "bir saat önce")
        #expect(relative(secondsAgo: 60 * 90) == "2 saat önce")
        #expect(relative(secondsAgo: 3600 * 21) == "21 saat önce")
        #expect(relative(secondsAgo: 3600 * 22) == "bir gün önce")
    }

    @Test("Day phrases")
    func days() {
        #expect(relative(secondsAgo: 3600 * 35) == "bir gün önce")
        #expect(relative(secondsAgo: 3600 * 36) == "2 gün önce")
        #expect(relative(secondsAgo: 86400 * 25) == "25 gün önce")
        #expect(relative(secondsAgo: 86400 * 26) == "bir ay önce")
        #expect(relative(secondsAgo: 86400 * 45) == "bir ay önce")
    }

    @Test("Month and year phrases")
    func monthsAndYears() {
        #expect(relative(secondsAgo: 86400 * 46) == "2 ay önce")
        #expect(relative(secondsAgo: 86400 * 319) == "11 ay önce")
        #expect(relative(secondsAgo: 86400 * 320) == "bir yıl önce")
        #expect(relative(secondsAgo: 86400 * 547) == "bir yıl önce")
        #expect(relative(secondsAgo: 86400 * 548) == "2 yıl önce")
    }

    @Test("Future instants use the in-phrase")
    func future() {
        #expect(
            formatter.string(
                from: reference.addingTimeInterval(120),
                relativeTo: reference
            ) == "2 dakika içinde"
        )
    }
}

@Suite("Geo coordinate validation")
struct GeoCoordinateTests {
    @Test("Longitude-first provider pairs map to latitude/longitude")
    func mapping() throws {
        let coordinate = try #require(GeoCoordinate(longitudeFirst: [37.5222, 38.43]))
        #expect(coordinate.latitude == 38.43)
        #expect(coordinate.longitude == 37.5222)
    }

    @Test("Non-finite or out-of-range values are rejected")
    func rejection() {
        #expect(GeoCoordinate(latitude: .nan, longitude: 30) == nil)
        #expect(GeoCoordinate(latitude: 91, longitude: 30) == nil)
        #expect(GeoCoordinate(latitude: 39, longitude: 181) == nil)
        #expect(GeoCoordinate(longitudeFirst: [30]) == nil)
        #expect(GeoCoordinate(longitudeFirst: [.infinity, 39]) == nil)
    }
}
