import SwiftUI
import DepremOlduDomain

struct EarthquakeLegendBar: View {
    var body: some View {
        HStack(spacing: 0) {
            segment(.small, isFirst: true, isLast: false)
            segment(.medium, isFirst: false, isLast: false)
            segment(.large, isFirst: false, isLast: false)
            segment(.veryLarge, isFirst: false, isLast: true)
        }
        .font(AppFont.regular(12, relativeTo: .caption))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .accessibilityIdentifier("earthquake.legend")
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Büyüklük aralıkları: Küçük, Orta, Büyük, Çok Büyük")
    }

    private func segment(_ magnitudeClass: MagnitudeClass, isFirst: Bool, isLast: Bool) -> some View {
        let palette = magnitudeClass.palette
        return Text(magnitudeClass.turkishLabel)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .background(palette.accent)
            .foregroundStyle(palette.badgeForeground)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: isFirst ? 4 : 0,
                    bottomLeadingRadius: isFirst ? 4 : 0,
                    bottomTrailingRadius: isLast ? 4 : 0,
                    topTrailingRadius: isLast ? 4 : 0
                )
            )
    }
}
