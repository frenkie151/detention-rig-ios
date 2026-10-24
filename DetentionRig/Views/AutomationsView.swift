import DetentionCore
import SwiftUI

struct AutomationsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    toggle(for: .headsUp, featured: true)
                }

                Section {
                    ForEach(Automation.allCases) { toggle(for: $0) }
                } header: {
                    Text("All automations")
                } footer: {
                    Text("Each switch acts only from the moment you turn it on.")
                }
            }
            .navigationTitle("Automations")
            .navigationSubtitle("Sent for you")
        }
    }

    private func toggle(for automation: Automation, featured: Bool = false) -> some View {
        Toggle(isOn: Binding(
            get: { model.isOn(automation) },
            set: { model.setAutomation(automation, on: $0) }
        )) {
            Label {
                VStack(alignment: .leading, spacing: 3) {
                    Text(automation.title).font(featured ? .headline : .body)
                    Text(automation.detail).font(.footnote).foregroundStyle(.secondary)
                }
            } icon: {
                IconBadge(symbol: automation.symbol, size: featured ? 40 : 30)
            }
        }
        .tint(.green)
        .padding(.vertical, featured ? 6 : 2)
    }
}
