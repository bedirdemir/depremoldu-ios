import SwiftUI
import MapKit
import DepremOlduDomain

struct EarthquakeLocationSheet: View {
    let earthquake: Earthquake
    @Environment(\.dismiss) private var dismiss
    @State private var contentHeight: CGFloat

    private let relativeTimeFormatter = TurkishRelativeTimeFormatter()

    init(earthquake: Earthquake) {
        self.earthquake = earthquake
        _contentHeight = State(initialValue: earthquake.coordinate == nil ? 320 : 520)
    }

    private var palette: MagnitudePalette {
        earthquake.magnitudeClass.palette
    }

    private var relativeTime: String {
        guard let occurredAt = earthquake.occurredAt else { return "-" }
        return relativeTimeFormatter.string(from: occurredAt, relativeTo: Date())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let coordinate = earthquake.coordinate {
                        Map(
                            initialPosition: .region(
                                MKCoordinateRegion(
                                    center: coordinate.clCoordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.25, longitudeDelta: 0.25)
                                )
                            )
                        ) {
                            Annotation(
                                earthquake.region,
                                coordinate: coordinate.clCoordinate
                            ) {
                                Circle()
                                    .fill(palette.accent)
                                    .frame(width: 18, height: 18)
                                    .overlay(Circle().stroke(.black, lineWidth: 3))
                            }
                        }
                        .mapStyle(.standard(pointsOfInterest: .excludingAll))
                        .frame(height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    } else {
                        Text("Bu deprem için konum bilgisi bulunmuyor.")
                            .font(AppFont.regular(14, relativeTo: .subheadline))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 120)
                            .background(AppColor.cream.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    detailCard
                }
                .padding(16)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { newValue in
                    contentHeight = newValue
                }
            }
            .accessibilityIdentifier("location.sheet")
            .navigationTitle("Deprem Konumu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .font(AppFont.semiBold(15, relativeTo: .body))
                }
            }
        }
        .tint(AppColor.primary)
        .presentationDetents([.height(detentHeight)])
        .presentationDragIndicator(.visible)
    }

    private var detentHeight: CGFloat {
        min(max(contentHeight + 60, 320), 760)
    }

    private var detailCard: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 4) {
                Text(earthquake.formattedMagnitude)
                    .font(AppFont.semiBold(24, relativeTo: .title2))
                    .monospacedDigit()
                Text(earthquake.scale)
                    .font(AppFont.regular(11, relativeTo: .caption2))
            }
            .frame(width: 68)
            .frame(minHeight: 92, maxHeight: .infinity)
            .background(palette.badgeBackground)
            .foregroundStyle(palette.badgeForeground)
            .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(earthquake.region)
                    .font(AppFont.semiBold(16, relativeTo: .headline))
                    .fixedSize(horizontal: false, vertical: true)
                Text(relativeTime)
                    .font(AppFont.medium(14, relativeTo: .subheadline))
                detailRow(label: "Tarih", value: earthquake.displayDateTime)
                detailRow(label: "Derinlik", value: "\(earthquake.formattedDepth) km")
                if let coordinate = earthquake.coordinate {
                    detailRow(
                        label: "Koordinat",
                        value: coordinate.displayText
                    )
                }
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(palette.rowGradient)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("\(label):")
                .font(AppFont.semiBold(15, relativeTo: .subheadline))
                .foregroundStyle(.primary)
            Text(value)
                .font(AppFont.regular(15, relativeTo: .subheadline))
                .foregroundStyle(.secondary)
        }
    }
}
