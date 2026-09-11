import SwiftUI
import DepremOlduDomain

struct EarthquakeCalloutRoot: View {
    let earthquake: Earthquake

    var body: some View {
        EarthquakeCalloutContent(earthquake: earthquake)
            .environment(\.dynamicTypeSize, .large)
    }
}

struct EarthquakeCalloutContent: View {
    let earthquake: Earthquake

    private let relativeTimeFormatter = TurkishRelativeTimeFormatter()

    private var palette: MagnitudePalette {
        earthquake.magnitudeClass.palette
    }

    private var relativeTime: String {
        guard let occurredAt = earthquake.occurredAt else { return "-" }
        return relativeTimeFormatter.string(from: occurredAt, relativeTo: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .top, spacing: 8) {
                VStack(spacing: 2) {
                    Text(earthquake.formattedMagnitude)
                        .font(AppFont.semiBold(16, relativeTo: .body))
                        .monospacedDigit()
                    Text(earthquake.scale)
                        .font(AppFont.regular(9, relativeTo: .caption2))
                }
                .frame(width: 44, height: 50)
                .background(palette.badgeBackground)
                .foregroundStyle(palette.badgeForeground)
                .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(earthquake.region)
                        .font(AppFont.semiBold(13, relativeTo: .footnote))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(relativeTime)
                        .font(AppFont.regular(12, relativeTo: .caption))
                        .italic()
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }

            detailRow(label: "Derinlik", value: "\(earthquake.formattedDepth) km")
            detailRow(label: "Tarih", value: earthquake.displayDateTime)
            if let coordinate = earthquake.coordinate {
                detailRow(
                    label: "Koordinat",
                    value: coordinate.displayText
                )
            }
        }
        .padding(10)
        .frame(width: 236, height: 156, alignment: .topLeading)
        .background(Color(uiColor: .systemBackground))
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("\(label):")
                .font(AppFont.semiBold(12, relativeTo: .caption))
                .foregroundStyle(.primary)
            Text(value)
                .font(AppFont.regular(12, relativeTo: .caption))
                .foregroundStyle(.secondary)
        }
    }
}
