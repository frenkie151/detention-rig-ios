import DetentionCore
import SwiftUI

struct TodayView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        NavigationStack {
            ScrollView {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let s = model.snapshot(at: context.date)
                    VStack(alignment: .leading, spacing: 24) {
                        NavigationLink(value: Route.detention) {
                            LiveDetentionCard(snapshot: s)
                        }
                        .buttonStyle(.plain)

                        tiles(s)
                        needsSection(s)

                        Text("Example company and loads. Numbers are demo data.")
                            .font(.footnote)
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
            // iOS 27: swipe actions work on any view inside a container that opts in.
            .swipeActionsContainer()
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Today")
            .navigationSubtitle(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
            .toolbar {
                ToolbarItem(placement: .topBarPinnedTrailing) {
                    Text("NF")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                        .accessibilityLabel("Northbound Freight dispatch")
                }
            }
            .navigationDestination(for: Route.self) { _ in DetentionView() }
        }
    }

    private func tiles(_ s: DetentionSnapshot) -> some View {
        HStack(spacing: 10) {
            NavigationLink(value: Route.detention) {
                Tile(symbol: "hourglass", tone: .red, title: "Detention", detail: "\(Format.usd(s.amount)) to bill")
            }
            Button { model.say("3 lumper receipts on file · $570") } label: {
                Tile(symbol: "receipt", tone: .amber, title: "Lumpers", detail: "$570 to recover")
            }
            Button { model.selectedTab = .loads } label: {
                Tile(symbol: "exclamationmark.triangle", tone: .blue, title: "Alerts", detail: "4 to look at")
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func needsSection(_ s: DetentionSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Needs you").font(.title3.bold())
                Spacer()
                Text(model.needs.isEmpty ? "All clear" : "\(model.needs.count) waiting")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }

            if model.needs.isEmpty {
                ContentUnavailableView("You're all caught up", systemImage: "checkmark.circle")
                    .card()
            }

            ForEach(model.needs) { need in
                NeedRow(need: need, snapshot: s)
                    .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading).combined(with: .opacity)))
            }
        }
        .animation(.snappy, value: model.needs)
        .sensoryFeedback(.success, trigger: model.needs.count)
    }
}

private struct LiveDetentionCard: View {
    let snapshot: DetentionSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                PulseLabel(text: snapshot.isStopped ? "Detention · truck left" : "Detention · clock running",
                           stopped: snapshot.isStopped)
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(Format.clock(snapshot.elapsed))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("\(Format.usd(snapshot.amount)) to bill")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText(value: NSDecimalNumber(decimal: snapshot.amount).doubleValue))
            }
            Text("DR-2041 · Maria Ortiz at Lodi Cold Storage")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the detention details")
    }
}

private struct Tile: View {
    let symbol: String
    let tone: Tone
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            IconBadge(symbol: symbol, tone: tone, size: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.footnote.weight(tone == .red ? .semibold : .regular))
                    .foregroundStyle(tone == .red ? AnyShapeStyle(Color.red) : AnyShapeStyle(HierarchicalShapeStyle.secondary))
                    .lineLimit(1)
                    .monospacedDigit()
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
        .contentShape(.rect)
    }
}

private struct NeedRow: View {
    @Environment(AppModel.self) private var model
    let need: Need
    let snapshot: DetentionSnapshot

    var body: some View {
        Group {
            if need.kind == .detention {
                NavigationLink(value: Route.detention) { content }
                    .buttonStyle(.plain)
            } else {
                content
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button("Dismiss", systemImage: "xmark", role: .destructive) {
                            model.resolve(need, confirmed: false)
                        }
                    }
            }
        }
    }

    private var content: some View {
        HStack(spacing: 12) {
            IconBadge(symbol: need.symbol, tone: need.tone)
            VStack(alignment: .leading, spacing: 1) {
                Eyebrow(text: need.label)
                Text(need.title).font(.body.weight(.semibold)).lineLimit(1)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary).lineLimit(1).monospacedDigit()
            }
            Spacer(minLength: 8)
            if let action = need.actionTitle {
                Button(action) { model.resolve(need, confirmed: true) }
                    .buttonStyle(.glassProminent)
                    .controlSize(.small)
            } else {
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
        }
        .padding(14)
        .card()
        .contentShape(.rect)
    }

    private var subtitle: String {
        need.kind == .detention
            ? "\(Format.hoursMinutes(snapshot.elapsed)) at receiver · \(Format.usd(snapshot.amount)) to bill"
            : need.subtitle
    }
}
