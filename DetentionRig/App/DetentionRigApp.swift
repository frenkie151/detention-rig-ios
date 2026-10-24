import SwiftUI

@main
struct DetentionRigApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .task { await model.startLiveActivity() }
                .task {
                    // Keep the Live Activity's amount current while the app is open.
                    while !Task.isCancelled {
                        await model.tick(.now)
                        try? await Task.sleep(for: .seconds(1))
                    }
                }
        }
    }
}
