import SwiftUI

@main
struct DepremOlduApp: App {
    @State private var shellModel: AppShellModel

    init() {
        let dependencies: AppDependencies
        #if TESTING
        dependencies = AppDependencies.testing()
        #else
        dependencies = AppDependencies.live()
        #endif
        _shellModel = State(initialValue: AppShellModel(dependencies: dependencies))
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(model: shellModel)
        }
    }
}
