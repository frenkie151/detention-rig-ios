import DetentionCore
import SwiftUI

struct DetentionView: View {
    @Environment(AppModel.self) private var model
    @State private var showEmail = false
    @State private var confirmDeparture = false
    @State private var timelineGrown = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let s = model.snapshot(at: context.date)
            ScrollView {
                VStack(spacing: 16) {
                    hero(s)
                    headsUpNotice(s)
                    people
                    figured(s)
                    broker
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .safeAreaBar(edge: .bottom) { actions(s) }
            .confirmationDialog("Truck left the receiver?", isPresented: $confirmDeparture, titleVisibility: .visible) {
                Button("Stop the clock") { model.markDeparted() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("The clock stops now with \(Format.hoursMinutes(s.elapsed)) at the receiver. \(Format.usd(s.amount)) is ready to bill.")
            }
        }
        .navigationTitle("Detention")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // iOS 27: secondary actions collapse into an overflow menu when space runs short.
            ToolbarOverflowMenu {
                Button("Copy load number", systemImage: "doc.on.doc") {
                    UIPasteboard.general.string = "DR-2041"
                    model.say("Copied DR-2041")
                }
                Button("Call driver", systemImage: "phone") {
                    model.say("Maria Ortiz · (209) 555-0193")
                }
            }
        }
        .sheet(isPresented: $showEmail) {
            EmailSheet(snapshot: model.snapshot())
        }
        .sensoryFeedback(.success, trigger: model.isStopped)
        .onAppear {
            timelineGrown = false
            withAnimation(.smooth(duration: 1.1).delay(0.15)) { timelineGrown = true }
        }
    }

    // MARK: Sections

    private func hero(_ s: DetentionSnapshot) -> some View {
        VStack(spacing: 6) {
            PulseLabel(text: s.isStopped ? "Truck left · \(s.end.formatted(date: .omitted, time: .shortened))" : "Elapsed · and counting",
                       stopped: s.isStopped)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(Format.clock(s.elapsed))
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                Text(String(format: "%02ds", Int(s.elapsed) % 60))
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .monospacedDigit()
            .contentTransition(.numericText(countsDown: false))
            .padding(.top, 8)

            Text("\(Text(Format.usd(s.amount)).bold().foregroundStyle(.primary))\(s.isStopped ? " to bill · clock stopped" : " accruing · after 2 hrs free")")
                .foregroundStyle(.secondary)
                .contentTransition(.numericText(value: NSDecimalNumber(decimal: s.amount).doubleValue))
                .animation(.spring(duration: 0.5, bounce: 0.4), value: s.amount)

            timeline(s).padding(.top, 14)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 28)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(.radialGradient(colors: [(s.isStopped ? Color.green : .red).opacity(0.14), .clear],
                                              center: .top, startRadius: 0, endRadius: 260))
                }
        }
        .animation(.smooth, value: s.isStopped)
        .accessibilityElement(children: .combine)
    }

    private func timeline(_ s: DetentionSnapshot) -> some View {
        let billColor: Color = s.isStopped ? .green : .red
        return VStack(spacing: 10) {
            GeometryReader { geo in
                let width = timelineGrown ? geo.size.width : 0
                HStack(spacing: 0) {
                    Rectangle().fill(.secondary.opacity(0.5)).frame(width: width * s.freeFraction)
                    Rectangle().fill(billColor).frame(width: width * (1 - s.freeFraction))
                    Spacer(minLength: 0)
                }
                .background(Color(.tertiarySystemFill))
                .clipShape(.capsule)
            }
            .frame(height: 8)

            HStack(alignment: .top) {
                mark(s.arrivedAt.formatted(date: .omitted, time: .shortened), "Arrived", alignment: .leading)
                Spacer()
                mark(s.freeTimeEndsAt.formatted(date: .omitted, time: .shortened), "Free time up", alignment: .center)
                Spacer()
                mark(s.isStopped ? s.end.formatted(date: .omitted, time: .shortened) : "now",
                     s.isStopped ? "Departed" : Format.hoursMinutes(s.elapsed),
                     alignment: .trailing, tint: billColor)
            }
        }
    }

    private func mark(_ value: String, _ label: String, alignment: HorizontalAlignment, tint: Color = .primary) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(value).font(.subheadline.weight(.semibold)).foregroundStyle(tint)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .monospacedDigit()
    }

    @ViewBuilder
    private func headsUpNotice(_ s: DetentionSnapshot) -> some View {
        if model.isOn(.headsUp) {
            Label("Broker heads-up sent at \(s.arrivedAt.addingTimeInterval(3600).formatted(date: .omitted, time: .shortened)), before the notice deadline.",
                  systemImage: "bell")
                .noticeStyle(.green)
        } else {
            Label("Heads-up automation is off. Turn it on in Automations to notify brokers for you.", systemImage: "bell.slash")
                .noticeStyle(.accentColor)
        }
    }

    private var people: some View {
        HStack(spacing: 10) {
            Person(eyebrow: "Driver", name: "Maria Ortiz") {
                Text("MO").font(.footnote.weight(.semibold)).foregroundStyle(Color.accentColor)
            }
            Person(eyebrow: "Receiver", name: "Lodi Cold Storage") {
                Image(systemName: "mappin.and.ellipse").foregroundStyle(.secondary)
            }
        }
    }

    private func figured(_ s: DetentionSnapshot) -> some View {
        Grouped(title: "How it was figured",
                note: "Receiver detention on DR-2041. Two free hours from the rate con, then $75 an hour, billed in 15-minute steps.") {
            Row("Time at receiver", Format.hoursMinutes(s.elapsed))
            Row("Free time", "2h 0m")
            Row("Billable", "\(Format.hoursMinutes(s.billable)) · \(s.steps) steps")
            Row("Rate", "$75 / hr · \(Format.usd(Billing.stepAmount, cents: true)) a step")
            if !s.isStopped {
                Row("Next step") {
                    HStack(spacing: 8) {
                        Gauge(value: 1 - s.timeToNextStep / Billing.step) {}
                            .gaugeStyle(.accessoryCircularCapacity)
                            .tint(.red)
                            .scaleEffect(0.42)
                            .frame(width: 24, height: 24)
                        Text("+\(Format.usd(Billing.stepAmount, cents: true)) in \(Format.countdown(s.timeToNextStep))")
                    }
                }
            }
            Row("To bill", Format.usd(s.amount, cents: true), emphasized: true)
        }
    }

    private var broker: some View {
        Grouped(title: "Broker") {
            Row("Pinecrest Logistics", "Dana Whitfield")
            Row("Rate con", "$2,100 line haul")
            Row("Request") {
                if let sent = model.requestSentAt {
                    Text("Sent \(sent.formatted(date: .omitted, time: .shortened))").foregroundStyle(.green)
                } else {
                    Text("Not sent yet")
                }
            }
        }
    }

    private func actions(_ s: DetentionSnapshot) -> some View {
        HStack(spacing: 10) {
            Button {
                if s.isStopped { model.undoDeparture() } else { confirmDeparture = true }
            } label: {
                Label(s.isStopped ? "Undo" : "Truck left", systemImage: s.isStopped ? "arrow.uturn.backward" : "flag")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)

            Button { showEmail = true } label: {
                Label("Write email", systemImage: "envelope").frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
        }
        .controlSize(.large)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Building blocks

private struct Person<Avatar: View>: View {
    let eyebrow: String
    let name: String
    @ViewBuilder let avatar: Avatar

    var body: some View {
        HStack(spacing: 10) {
            avatar
                .frame(width: 34, height: 34)
                .background(Color(.tertiarySystemFill), in: .circle)
            VStack(alignment: .leading, spacing: 1) {
                Eyebrow(text: eyebrow)
                Text(name).font(.subheadline.weight(.semibold)).lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .card()
        .accessibilityElement(children: .combine)
    }
}

private struct Grouped<Content: View>: View {
    let title: String
    var note: String?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: title).padding([.horizontal, .top], 16).padding(.bottom, 6)
            if let note {
                Text(note).font(.subheadline).foregroundStyle(.secondary)
                    .padding(.horizontal, 16).padding(.bottom, 10)
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}

private struct Row<Value: View>: View {
    let label: String
    var emphasized = false
    @ViewBuilder let value: Value

    init(_ label: String, emphasized: Bool = false, @ViewBuilder value: () -> Value) {
        self.label = label
        self.emphasized = emphasized
        self.value = value()
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider().padding(.leading, 16)
            HStack {
                Text(label).foregroundStyle(.secondary)
                Spacer()
                value.font(emphasized ? .title3.bold() : .body.weight(.semibold))
            }
            .monospacedDigit()
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
        }
        .accessibilityElement(children: .combine)
    }
}

extension Row where Value == Text {
    init(_ label: String, _ value: String, emphasized: Bool = false) {
        self.init(label, emphasized: emphasized) { Text(value) }
    }
}

private extension View {
    func noticeStyle(_ color: Color) -> some View {
        self.font(.subheadline)
            .foregroundStyle(color)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color.opacity(0.13), in: .rect(cornerRadius: 16))
    }
}
