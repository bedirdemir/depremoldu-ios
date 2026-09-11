import SwiftUI
import MapKit
import DepremOlduDomain

struct EarthquakeMapScreen: View {
    @Bindable var feedModel: EarthquakeFeedFeatureModel
    @Bindable var mapModel: EarthquakeMapFeatureModel
    let onShowAbout: () -> Void
    let onShowLocation: (Earthquake) -> Void

    private var items: [EarthquakeMapItem] {
        feedModel.mapEarthquakes.compactMap { earthquake in
            guard let coordinate = earthquake.coordinate else { return nil }
            return EarthquakeMapItem(earthquake: earthquake, coordinate: coordinate.clCoordinate)
        }
    }

    private var selectedItem: EarthquakeMapItem? {
        guard let selectedID = mapModel.selectedEarthquakeID else { return nil }
        return items.first { $0.id == selectedID }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                EarthquakeMapBridge(
                    items: items,
                    faultDataset: mapModel.faultDataset,
                    showsFaultLines: mapModel.showsFaultLines,
                    selectedEarthquakeID: $mapModel.selectedEarthquakeID
                )
                .ignoresSafeArea(edges: .bottom)

                if let content = feedModel.content {
                    if content.refreshFailure != nil {
                        failureBanner(content.refreshFailure)
                    }
                } else if case let .failure(failure) = feedModel.state {
                    ErrorStateView(failure: failure) {
                        Task { await feedModel.retry() }
                    }
                } else if feedModel.mapEarthquakes.isEmpty {
                    ProgressView()
                        .controlSize(.large)
                        .tint(AppColor.primary)
                        .padding(16)
                        .appGlassSurface(cornerRadius: 12)
                        .accessibilityLabel("Depremler yükleniyor")
                }
            }
            .overlay(alignment: .top) {
                mapHeader
            }
            .overlay(alignment: .bottom) {
                if let selectedItem {
                    EarthquakeMapSelectionCard(
                        item: selectedItem,
                        relativeTime: feedModel.relativeTime(for: selectedItem.earthquake),
                        onClose: { mapModel.selectedEarthquakeID = nil },
                        onDetails: { onShowLocation(selectedItem.earthquake) }
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    BrandTitle()
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        Task { await feedModel.refresh() }
                    } label: {
                        Label("Yenile", systemImage: "arrow.clockwise")
                    }
                    .disabled(feedModel.content?.refreshState == .refreshing)

                    Button {
                        onShowAbout()
                    } label: {
                        Label("Hakkında", systemImage: "info.circle")
                    }
                }
            }
        }
        .tint(AppColor.primary)
        .task {
            feedModel.loadIfNeeded()
            mapModel.loadFaultsIfNeeded()
        }
    }

    private var mapHeader: some View {
        HStack(alignment: .top) {
            FaultToggleChip(
                isOn: mapModel.showsFaultLines,
                isLoading: mapModel.isFaultLoading,
                isAvailable: mapModel.faultState != .failed,
                action: { mapModel.toggleFaultLines() }
            )
            Spacer()
            EarthquakeMapLegendView(showsFaultSource: mapModel.showsFaultLegend)
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
    }

    @ViewBuilder
    private func failureBanner(_ failure: EarthquakePresentationFailure?) -> some View {
        if let failure {
            VStack {
                RefreshFailureBanner(failure: failure) {
                    Task { await feedModel.retry() }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(.horizontal, 12)
                Spacer()
            }
            .padding(.top, 60)
        }
    }
}
