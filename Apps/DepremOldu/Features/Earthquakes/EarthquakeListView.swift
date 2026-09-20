import SwiftUI
import DepremOlduDomain

struct EarthquakeListView: View {
    @Bindable var model: EarthquakeFeedFeatureModel
    let onShowLocation: (Earthquake) -> Void

    @State private var isUserRefreshing = false

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
        if model.content == nil, case let .failure(failure) = model.state {
            ErrorStateView(failure: failure) {
                Task { await model.retry() }
            }
        } else {
            VStack(spacing: 0) {
                EarthquakeLegendBar()
                if let refreshFailure = model.content?.refreshFailure {
                    RefreshFailureBanner(failure: refreshFailure) {
                        Task { await model.retry() }
                    }
                }
                LoadingIndicatorBar(isVisible: showsLoadingRow)
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

    private var showsLoadingRow: Bool {
        showsTopLoadingIndicator && !isUserRefreshing
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
            isUserRefreshing = true
            await model.refresh()
            isUserRefreshing = false
        }
    }
}

private struct LoadingIndicatorBar: View {
    let isVisible: Bool

    @State private var showsIndicator = false

    var body: some View {
        HStack {
            Spacer()
            if showsIndicator {
                ProgressView()
                    .controlSize(.regular)
                    .tint(nil)
                    .transition(.opacity)
                    .accessibilityIdentifier("earthquake.top-loading")
                    .accessibilityLabel("Depremler yükleniyor")
            }
            Spacer()
        }
        .frame(height: showsIndicator ? 48 : 0)
        .clipped()
        .onAppear {
            withAnimation(Self.animation) {
                showsIndicator = isVisible
            }
        }
        .onChange(of: isVisible) { _, newValue in
            withAnimation(Self.animation) {
                showsIndicator = newValue
            }
        }
    }

    private static let animation = Animation.spring(response: 0.45, dampingFraction: 0.88)
}
