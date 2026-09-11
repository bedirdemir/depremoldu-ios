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
        ScrollViewReader { proxy in
            List {
                Color.clear
                    .frame(height: 0)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .id(Self.listTopID)

                ForEach(model.paginatedEarthquakes) { earthquake in
                    EarthquakeRowView(
                        earthquake: earthquake,
                        relativeTime: model.relativeTime(for: earthquake),
                        onShowLocation: { onShowLocation(earthquake) }
                    )
                }

                Section {
                    EmptyView()
                } footer: {
                    paginationFooter(proxy: proxy)
                }
            }
            .listStyle(.plain)
            .refreshable {
                await model.refresh()
            }
        }
    }

    private func paginationFooter(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(model.countSummary)
                .font(AppFont.regular(12, relativeTo: .caption))
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("earthquake.count")

            if model.listPageCount > 1 {
                HStack(spacing: 8) {
                    arrowButton(
                        title: "Önceki",
                        systemImage: "chevron.left",
                        isEnabled: !model.isFirstPage,
                        identifier: "pagination.previous"
                    ) {
                        model.previousPage()
                        scrollToTop(proxy)
                    }

                    ForEach(1 ... model.listPageCount, id: \.self) { page in
                        pageButton(page) {
                            model.goToPage(page)
                            scrollToTop(proxy)
                        }
                    }

                    arrowButton(
                        title: "Sonraki",
                        systemImage: "chevron.right",
                        isEnabled: !model.isLastPage,
                        identifier: "pagination.next"
                    ) {
                        model.nextPage()
                        scrollToTop(proxy)
                    }
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
    }

    private func arrowButton(
        title: String,
        systemImage: String,
        isEnabled: Bool,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if systemImage == "chevron.left" {
                    Image(systemName: systemImage)
                        .font(.system(size: 10, weight: .semibold))
                }
                Text(title)
                    .font(AppFont.medium(13, relativeTo: .footnote))
                if systemImage == "chevron.right" {
                    Image(systemName: systemImage)
                        .font(.system(size: 10, weight: .semibold))
                }
            }
            .foregroundStyle(isEnabled ? .white : Color(uiColor: .tertiaryLabel))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(isEnabled ? AppColor.secondary : Color(uiColor: .secondarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityIdentifier(identifier)
    }

    private func pageButton(_ page: Int, action: @escaping () -> Void) -> some View {
        let isCurrent = page == model.currentPage
        return Button(action: action) {
            Text("\(page)")
                .font(AppFont.semiBold(13, relativeTo: .footnote))
                .foregroundStyle(isCurrent ? .white : Color(uiColor: .label))
                .frame(minWidth: 34, minHeight: 32)
                .background(isCurrent ? AppColor.primary : Color(uiColor: .systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(
                            isCurrent ? Color.clear : Color(uiColor: .separator),
                            lineWidth: 1
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("pagination.page.\(page)")
        .accessibilityLabel("Sayfa \(page)")
        .accessibilityAddTraits(isCurrent ? [.isSelected] : [])
    }

    private func scrollToTop(_ proxy: ScrollViewProxy) {
        withAnimation {
            proxy.scrollTo(Self.listTopID, anchor: .top)
        }
    }

    private static let listTopID = "earthquake.list.top"
}
