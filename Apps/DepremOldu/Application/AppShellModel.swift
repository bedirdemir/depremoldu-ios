import Foundation
import Observation
import DepremOlduDomain

@Observable
@MainActor
final class AppShellModel {
    enum Tab: Hashable {
        case earthquakes
        case map
        case awareness
    }

    var selectedTab: Tab = .earthquakes
    var isAboutPresented = false
    var presentedLocationEarthquake: Earthquake?

    let feedModel: EarthquakeFeedFeatureModel
    let mapModel: EarthquakeMapFeatureModel

    init(dependencies: AppDependencies) {
        feedModel = dependencies.feedModel
        mapModel = dependencies.mapModel
    }
}
