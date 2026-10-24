import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        TabView(selection: $model.selectedTab) {
            Tab("Today", systemImage: "calendar", value: AppTab.today) {
                TodayView()
            }
            .badge(model.needs.count)

            Tab("Loads", systemImage: "shippingbox", value: AppTab.loads) {
                LoadsView()
            }

            Tab("Automations", systemImage: "switch.2", value: AppTab.automations) {
                AutomationsView()
            }
        }
        .modifier(ToastOverlay(message: model.toast))
    }
}
