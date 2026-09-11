import SwiftUI
import DepremOlduDomain

struct EarthquakeListView: View {
    @Bindable var model: EarthquakeFeedFeatureModel
    let onShowLocation: (Earthquake) -> Void

    var body: some View {
        screenContent
            .task {
                model.loadIfNeeded()
            }
            .task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(30))
                    model.tick()
                }
            }
    }

    @ViewBuilder
    private var screenContent: some View {
        if let content = model.content {
            VStack(spacing: 0) {
                EarthquakeLegendBar()
                if let refreshFailure = content.refreshFailure {
                    RefreshFailureBanner(failure: refreshFailure) {
                        Task { await model.retry() }
                    }
                }
                list
            }
            .background(Color(uiColor: .systemBackground))
        } else if case let .failure(failure) = model.state {
            ErrorStateView(failure: failure) {
                Task { await model.retry() }
            }
        } else {
            ProgressView()
                .controlSize(.large)
                .tint(AppColor.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(uiColor: .systemBackground))
                .accessibilityLabel("Depremler yükleniyor")
        }
    }

    private var list: some View {
        let earthquakes = model.listEarthquakes
        return List {
            ForEach(Array(earthquakes.enumerated()), id: \.element.id) { index, earthquake in
                EarthquakeRowView(
                    earthquake: earthquake,
                    relativeTime: model.relativeTime(for: earthquake),
                    showsDivider: index < earthquakes.count - 1,
                    onShowLocation: { onShowLocation(earthquake) }
                )
            }

            Section {
                EmptyView()
            } footer: {
                Text(model.countSummary)
                    .font(AppFont.regular(12, relativeTo: .caption))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
                    .padding(.leading, 4)
                    .accessibilityIdentifier("earthquake.count")
            }
        }
        .listStyle(.plain)
        .environment(\.defaultMinListRowHeight, 0)
        .contentMargins(.top, 0, for: .scrollContent)
        .refreshable {
            await model.refresh()
        }
    }
}
