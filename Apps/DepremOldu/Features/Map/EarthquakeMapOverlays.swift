import SwiftUI
import DepremOlduDomain

struct EarthquakeMapLegendView: View {
    let showsFaultSource: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("SON 500 DEPREM")
                .font(AppFont.semiBold(11, relativeTo: .caption2))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .background(AppColor.primary)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(MagnitudeClass.allCases, id: \.self) { magnitudeClass in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(magnitudeClass.palette.accent)
                            .frame(width: dotSize(for: magnitudeClass), height: dotSize(for: magnitudeClass))
                            .overlay(Circle().stroke(.black, lineWidth: 2))
                        Text(magnitudeClass.turkishLabel)
                            .font(AppFont.regular(11, relativeTo: .caption2))
                            .foregroundStyle(.primary)
                    }
                }
                if showsFaultSource {
                    Text("Fay hatları: GINRAS/AFEAD")
                        .font(AppFont.regular(9, relativeTo: .caption2))
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .systemBackground))
        }
        .frame(width: 148)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 4, y: 1)
        .accessibilityIdentifier("map.legend")
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Son 500 deprem büyüklük göstergesi")
    }

    private func dotSize(for magnitudeClass: MagnitudeClass) -> CGFloat {
        switch magnitudeClass {
        case .small: 10
        case .medium: 12
        case .large: 14
        case .veryLarge: 16
        }
    }
}

struct FaultToggleChip: View {
    let isOn: Bool
    let isLoading: Bool
    let isAvailable: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isLoading {
                    ProgressView()
                        .controlSize(.mini)
                } else {
                    Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isOn ? AppColor.primary : .secondary)
                }
                Text("Fay Hatları")
                    .font(AppFont.medium(13, relativeTo: .footnote))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .appGlassSurface(cornerRadius: 10)
        .disabled(!isAvailable || isLoading)
        .opacity(isAvailable ? 1 : 0.5)
        .accessibilityIdentifier("map.fault-toggle")
        .accessibilityLabel("Fay hatlarını göster")
        .accessibilityValue(isOn ? "Açık" : "Kapalı")
    }
}
