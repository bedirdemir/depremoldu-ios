import SwiftUI
import DepremOlduDomain

struct EarthquakeRowView: View {
    let earthquake: Earthquake
    let relativeTime: String
    let showsDivider: Bool
    let onShowLocation: () -> Void

    private var palette: MagnitudePalette {
        earthquake.magnitudeClass.palette
    }

    private var accessibilityText: String {
        "\(earthquake.formattedMagnitude) büyüklüğünde deprem. \(earthquake.region). "
            + "\(relativeTime). \(earthquake.displayDateTime). Derinlik \(earthquake.formattedDepth) kilometre."
    }

    var body: some View {
        Button(action: onShowLocation) {
            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 12) {
                    badge
                    VStack(alignment: .leading, spacing: 2) {
                        Text(earthquake.region)
                            .font(AppFont.bold(14, relativeTo: .subheadline))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)

                        infoLine(
                            systemImage: "clock",
                            text: relativeTime,
                            font: AppFont.medium(13, relativeTo: .footnote)
                        )
                        infoLine(
                            systemImage: "calendar",
                            text: earthquake.displayDateTime,
                            font: AppFont.regular(13, relativeTo: .footnote),
                            muted: true
                        )
                        infoLine(
                            systemImage: "arrow.down",
                            text: "\(earthquake.formattedDepth) km",
                            font: AppFont.regular(13, relativeTo: .footnote),
                            muted: true
                        )
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 12, weight: .regular))
                            Text("Konumu görüntüle")
                                .font(AppFont.regular(13, relativeTo: .footnote))
                                .underline()
                        }
                        .foregroundStyle(.secondary)
                        .padding(.top, 1)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 5)
                .padding(.leading, 12)
                .padding(.trailing, 8)

                if showsDivider {
                    Rectangle()
                        .fill(Color(uiColor: .separator))
                        .frame(height: 0.5)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .listRowBackground(palette.rowGradient)
        .accessibilityIdentifier("earthquake.row.\(earthquake.id)")
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint("Deprem konumunu haritada açar")
    }

    private var badge: some View {
        VStack(spacing: 3) {
            Text(earthquake.formattedMagnitude)
                .font(AppFont.bold(20, relativeTo: .title2))
                .monospacedDigit()
            Text(earthquake.scale)
                .font(AppFont.regular(10, relativeTo: .caption2))
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
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(muted ? .secondary : .primary)
                .frame(width: 15)
            Text(text)
                .font(font)
                .foregroundStyle(muted ? .secondary : .primary)
        }
    }
}
