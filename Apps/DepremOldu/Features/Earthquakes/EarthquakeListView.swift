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
            VStack(spacing: 0) {
                EarthquakeLegendBar()
                list
            }
            .background(Color(uiColor: .systemBackground))
        }
    }

    private var showsTopLoadingIndicator: Bool {
        switch model.state {
        case .loading:
            true
        case let .content(content):
            content.refreshState == .refreshing && content.freshness == .stale
        case .idle, .failure:
            false
        }
    }

    private var list: some View {
        let earthquakes = model.listEarthquakes
        return List {
            if showsTopLoadingIndicator {
                HStack {
                    Spacer()
                    ProgressView()
                        .controlSize(.regular)
                        .tint(AppColor.primary)
                    Spacer()
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .padding(.vertical, 14)
                .accessibilityIdentifier("earthquake.top-loading")
                .accessibilityLabel("Depremler yükleniyor")
            }

            ForEach(Array(earthquakes.enumerated()), id: \.element.id) { index, earthquake in
                EarthquakeRowView(
                    earthquake: earthquake,
                    relativeTime: model.relativeTime(for: earthquake),
                    showsDivider: index < earthquakes.count - 1,
                    onShowLocation: { onShowLocation(earthquake) }
                )
            }

            if model.content != nil {
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
        }
        .listStyle(.plain)
        .environment(\.defaultMinListRowHeight, 0)
        .contentMargins(.top, 0, for: .scrollContent)
        .refreshable {
            await model.refresh()
        }
    }
}
