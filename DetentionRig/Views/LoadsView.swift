import DetentionCore
import SwiftUI

struct LoadsView: View {
    @Environment(AppModel.self) private var model
    @State private var filter = Filter.all

    enum Filter: String, CaseIterable, Identifiable {
        case all = "All", active = "Active", delivered = "Delivered"
        var id: Self { self }
    }

    private var loads: [Load] {
        Load.demo.filter {
            switch filter {
            case .all: true
            case .active: !$0.isDelivered
            case .delivered: $0.isDelivered
            }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Show", selection: $filter.animation(.snappy)) {
                        ForEach(Filter.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                Section {
                    ForEach(loads) { load in
                        if load.status == .detention {
                            NavigationLink(value: Route.detention) { LoadRow(load: load, departed: model.isStopped) }
                        } else {
                            LoadRow(load: load, departed: model.isStopped)
                        }
                    }
                }
            }
            .navigationTitle("Loads")
            .navigationSubtitle("This week")
            .navigationDestination(for: Route.self) { _ in DetentionView() }
        }
    }
}

private struct LoadRow: View {
    let load: Load
    let departed: Bool

    var body: some View {
        let (status, tone) = load.statusLabel(departed: departed)
        HStack(spacing: 12) {
            IconBadge(symbol: "truck.box", tone: tone)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(load.id) · \(load.lane)").font(.body.weight(.semibold)).lineLimit(1)
                Text(load.broker).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 4) {
                Text(Format.usd(load.amount)).font(.subheadline.weight(.semibold)).monospacedDigit()
                StatusPill(text: status, tone: tone)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}
