import SwiftUI
import DepremOlduDomain

struct EarthquakeListView: View {
    @Bindable var model: EarthquakeFeedFeatureModel
    let onShowAbout: () -> Void
    let onShowLocation: (Earthquake) -> Void

    @State private var safariItem: SafariItem?

    var body: some View {
        NavigationStack {
            screenContent
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        BrandTitle()
                    }
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button {
                            Task { await model.refresh() }
                        } label: {
                            Label("Yenile", systemImage: "arrow.clockwise")
                        }
                        .disabled(model.content?.refreshState == .refreshing)
                        .accessibilityIdentifier("toolbar.refresh")

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
            model.loadIfNeeded()
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                model.tick()
            }
        }
        .sheet(item: $safariItem) { item in
            SafariView(url: item.url)
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
        List {
            ForEach(model.listEarthquakes) { earthquake in
                EarthquakeRowView(
                    earthquake: earthquake,
                    relativeTime: model.relativeTime(for: earthquake),
                    onShowLocation: { onShowLocation(earthquake) }
                )
            }

            Section {
                EmptyView()
            } footer: {
                footer
            }
        }
        .listStyle(.plain)
        .refreshable {
            await model.refresh()
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(model.countSummary)
                .font(AppFont.regular(12, relativeTo: .caption))
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("earthquake.count")

            Text(
                "Veriler Boğaziçi Üniversitesi Kandilli Rasathanesi ve Deprem Araştırma "
                    + "Enstitüsü Bölgesel Deprem-Tsunami İzleme ve Değerlendirme Merkezi'nden gelmektedir."
            )
            .font(AppFont.regular(12, relativeTo: .caption))
            .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Button {
                    safariItem = SafariItem(url: Self.kandilliURL)
                } label: {
                    Text("koeri.boun.edu.tr")
                        .font(AppFont.medium(12, relativeTo: .caption))
                        .foregroundStyle(AppColor.secondary)
                }
                .buttonStyle(.plain)

                Button {
                    safariItem = SafariItem(url: Self.repositoryURL)
                } label: {
                    Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                        .font(AppFont.medium(12, relativeTo: .caption))
                        .foregroundStyle(AppColor.secondary)
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)
            }

            Text("Bu uygulama resmî bir deprem uyarı sistemi değildir; veriler bilgilendirme amaçlıdır.")
                .font(AppFont.regular(11, relativeTo: .caption2))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
    }

    private static let kandilliURL = URL(string: "http://www.koeri.boun.edu.tr/sismo/2/tr/")!
    private static let repositoryURL = URL(string: "https://github.com/bedirdemir/depremolduorg-nuxtjs")!
}
