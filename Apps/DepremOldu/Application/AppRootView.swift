import SwiftUI

struct AppRootView: View {
    @Bindable var model: AppShellModel

    var body: some View {
        VStack(spacing: 0) {
            appHeader

            TabView(selection: $model.selectedTab) {
                EarthquakeListView(
                    model: model.feedModel,
                    onShowLocation: { model.presentedLocationEarthquake = $0 }
                )
                .tabItem {
                    Label("Son Depremler", systemImage: "waveform.path.ecg")
                }
                .tag(AppShellModel.Tab.earthquakes)

                EarthquakeMapScreen(
                    feedModel: model.feedModel,
                    mapModel: model.mapModel
                )
                .tabItem {
                    Label("Harita", systemImage: "map")
                }
                .tag(AppShellModel.Tab.map)

                AwarenessView()
                    .tabItem {
                        Label("Afet Bilinci", systemImage: "book")
                    }
                    .tag(AppShellModel.Tab.awareness)
            }
        }
        .background(Color(uiColor: .systemBackground))
        .tint(AppColor.primary)
        .preferredColorScheme(.light)
        .sheet(isPresented: $model.isAboutPresented) {
            AboutView()
        }
        .sheet(item: $model.presentedLocationEarthquake) { earthquake in
            EarthquakeLocationSheet(earthquake: earthquake)
        }
    }

    private var appHeader: some View {
        HStack(spacing: 12) {
            BrandTitle()
            Spacer(minLength: 0)

            if model.selectedTab != .awareness {
                Button {
                    Task { await model.feedModel.refresh() }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Yenile")
                            .font(AppFont.medium(13, relativeTo: .footnote))
                    }
                    .foregroundStyle(AppColor.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppColor.primary.opacity(0.06))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(AppColor.primary.opacity(0.25), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(model.feedModel.content?.refreshState == .refreshing)
                .accessibilityIdentifier("toolbar.refresh")
            }

            Button {
                model.isAboutPresented = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(AppColor.primary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("toolbar.about")
            .accessibilityLabel("Hakkında")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(uiColor: .systemBackground))
    }
}

struct BrandTitle: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(AppColor.primary)
            HStack(spacing: 0) {
                Text("depremoldu")
                    .foregroundStyle(AppColor.secondary)
                Text(".org")
                    .foregroundStyle(AppColor.primary)
            }
            .font(AppFont.medium(18, relativeTo: .title3))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("depremoldu.org")
    }
}

struct ErrorStateView: View {
    let failure: EarthquakePresentationFailure
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: failure.systemImage)
                .font(.system(size: 36, weight: .regular))
                .foregroundStyle(AppColor.primary)
            Text(failure.message)
                .font(AppFont.regular(15, relativeTo: .subheadline))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Tekrar Dene", action: retry)
                .font(AppFont.semiBold(15, relativeTo: .subheadline))
                .buttonStyle(.borderedProminent)
                .tint(AppColor.primary)
                .accessibilityIdentifier("error.retry")
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }
}

struct RefreshFailureBanner: View {
    let failure: EarthquakePresentationFailure
    let retry: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: failure.systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColor.primary)
            Text(failure.message)
                .font(AppFont.regular(13, relativeTo: .footnote))
                .foregroundStyle(.primary)
            Spacer(minLength: 0)
            Button("Yenile", action: retry)
                .font(AppFont.semiBold(13, relativeTo: .footnote))
                .foregroundStyle(AppColor.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppColor.primary.opacity(0.08))
        .accessibilityElement(children: .combine)
    }
}
