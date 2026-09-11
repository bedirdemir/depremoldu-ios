import Foundation
import DepremOlduDomain

public enum KandilliEarthquakeMapper {
    public static func map(_ dto: KandilliEarthquakeDTO) -> Earthquake {
        let rawDateTime = dto.dateTime ?? ""
        let parts = rawDateTime.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: false)
        let rawDate = parts.first.map(String.init) ?? ""
        let rawTime = parts.count > 1 ? String(parts[1]) : ""

        let magnitude: Double
        if let value = dto.magnitude, value.isFinite {
            magnitude = value
        } else {
            magnitude = 0
        }

        let depth: Double? = if let value = dto.depth, value.isFinite {
            value
        } else {
            nil
        }

        let coordinate = dto.geojson?.coordinates.flatMap(GeoCoordinate.init(longitudeFirst:))

        return Earthquake(
            id: dto.earthquakeID ?? "",
            provider: dto.provider ?? "kandilli",
            region: dto.title ?? "-",
            magnitude: magnitude,
            depth: depth,
            displayDate: EarthquakeDisplayDateNormalizer.displayDate(from: rawDate),
            displayTime: rawTime.isEmpty ? "-" : rawTime,
            occurredAt: EarthquakeDisplayDateNormalizer.occurredAt(
                rawDate: rawDate,
                rawTime: rawTime,
                timeZoneIdentifier: dto.locationTimeZone
            ),
            coordinate: coordinate
        )
    }
}
