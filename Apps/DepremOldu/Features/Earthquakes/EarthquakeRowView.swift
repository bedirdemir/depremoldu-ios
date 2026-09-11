import SwiftUI
import DepremOlduDomain

struct EarthquakeRowView: View {
    let earthquake: Earthquake
    let relativeTime: String
    let onShowLocation: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private var palette: MagnitudePalette {
        earthquake.magnitudeClass.palette
    }

    private var accessibilityText: String {
        "\(earthquake.formattedMagnitude) büyüklüğünde deprem. \(earthquake.region). "
            + "\(relativeTime). \(earthquake.displayDateTime). Derinlik \(earthquake.formattedDepth) kilometre."
    }

    var body: some View {
        Button(action: onShowLocation) {
            HStack(alignment: .center, spacing: 20) {
                badge
                VStack(alignment: .leading, spacing: 3) {
                    Text(earthquake.region)
                        .font(AppFont.semiBold(15, relativeTo: .subheadline))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    infoLine(
                        systemImage: "clock",
                        text: relativeTime,
                        font: AppFont.medium(14, relativeTo: .footnote)
                    )
                    infoLine(
                        systemImage: "calendar",
                        text: earthquake.displayDateTime,
                        font: AppFont.regular(14, relativeTo: .footnote),
                        muted: true
                    )
                    infoLine(
                        systemImage: "arrow.down",
                        text: "\(earthquake.formattedDepth) km",
                        font: AppFont.regular(14, relativeTo: .footnote),
                        muted: true
                    )
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 13, weight: .regular))
                        Text("Konumu görüntüle")
                            .font(AppFont.regular(14, relativeTo: .footnote))
                            .underline()
                    }
                    .foregroundStyle(.secondary)
                    .padding(.top, 1)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(palette.rowGradient(for: colorScheme))
        .accessibilityIdentifier("earthquake.row.\(earthquake.id)")
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint("Deprem konumunu haritada açar")
    }

    private var badge: some View {
        VStack(spacing: 4) {
            Text(earthquake.formattedMagnitude)
                .font(AppFont.semiBold(22, relativeTo: .title2))
                .monospacedDigit()
            Text(earthquake.scale)
                .font(AppFont.regular(11, relativeTo: .caption2))
        }
        .frame(width: 64, height: 96)
        .background(palette.badgeBackground)
        .foregroundStyle(palette.badgeForeground)
        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
    }

    private func infoLine(
        systemImage: String,
        text: String,
        font: Font,
        muted: Bool = false
    ) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(muted ? .secondary : .primary)
                .frame(width: 16)
            Text(text)
                .font(font)
                .foregroundStyle(muted ? .secondary : .primary)
        }
    }
}
