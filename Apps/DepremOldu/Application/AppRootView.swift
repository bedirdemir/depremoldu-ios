import SwiftUI

struct AppRootView: View {
    @Bindable var model: AppShellModel

    var body: some View {
        TabView(selection: $model.selectedTab) {
            EarthquakeListView(
                model: model.feedModel,
                onShowAbout: { model.isAboutPresented = true },
                onShowLocation: { model.presentedLocationEarthquake = $0 }
            )
            .tabItem {
                Label("Son Depremler", systemImage: "waveform.path.ecg")
            }
            .tag(AppShellModel.Tab.earthquakes)

            EarthquakeMapScreen(
                feedModel: model.feedModel,
                mapModel: model.mapModel,
                onShowAbout: { model.isAboutPresented = true },
                onShowLocation: { model.presentedLocationEarthquake = $0 }
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
        .tint(AppColor.primary)
        .sheet(isPresented: $model.isAboutPresented) {
            AboutView()
        }
        .sheet(item: $model.presentedLocationEarthquake) { earthquake in
            EarthquakeLocationSheet(earthquake: earthquake)
        }
    }
}

struct BrandTitle: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 18, weight: .semibold))
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
