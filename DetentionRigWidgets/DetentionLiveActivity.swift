import ActivityKit
import DetentionCore
import SwiftUI
import WidgetKit

@main
struct DetentionRigWidgets: WidgetBundle {
    var body: some Widget {
        DetentionLiveActivity()
    }
}

/// The running detention clock on the Lock Screen and in the Dynamic Island.
/// The timer counts up on its own; the dollar amount updates whenever the app publishes a new step.
struct DetentionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DetentionActivityAttributes.self) { context in
            LockScreenView(context: context)
                .padding(16)
                .activityBackgroundTint(nil)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.loadID, systemImage: "hourglass")
                        .font(.headline)
                        .foregroundStyle(.orange)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(Format.usd(context.state.amount))
                        .font(.title3.bold())
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        ElapsedText(context: context).font(.title2.bold())
                        NextStep(context: context)
                    }
                }
            } compactLeading: {
                Image(systemName: "hourglass").foregroundStyle(.orange)
            } compactTrailing: {
                ElapsedText(context: context)
                    .frame(maxWidth: 56)
                    .font(.caption.weight(.semibold))
            } minimal: {
                Image(systemName: "hourglass").foregroundStyle(.orange)
            }
            .keylineTint(.orange)
        }
    }
}

private struct LockScreenView: View {
    let context: ActivityViewContext<DetentionActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(context.state.departedAt == nil ? "Detention · clock running" : "Truck left",
                      systemImage: "hourglass")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(context.state.departedAt == nil ? .red : .green)
                Spacer()
                Text("\(context.attributes.loadID) · \(context.attributes.receiver)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(alignment: .firstTextBaseline) {
                ElapsedText(context: context)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                Spacer()
                Text("\(Format.usd(context.state.amount)) to bill")
                    .font(.headline)
                    .monospacedDigit()
            }
            NextStep(context: context)
        }
    }
}

/// Counts up from arrival while the truck waits; frozen once it leaves.
private struct ElapsedText: View {
    let context: ActivityViewContext<DetentionActivityAttributes>

    var body: some View {
        Group {
            if let departed = context.state.departedAt {
                Text(Format.hoursMinutes(departed.timeIntervalSince(context.attributes.arrivedAt)))
            } else {
                Text(timerInterval: context.attributes.arrivedAt...Date.distantFuture, countsDown: false)
            }
        }
        .monospacedDigit()
    }
}

private struct NextStep: View {
    let context: ActivityViewContext<DetentionActivityAttributes>

    var body: some View {
        if context.isStale {
            Text("Open Detention Rig to refresh the amount")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else if let next = context.state.nextStepAt {
            ProgressView(timerInterval: next.addingTimeInterval(-Billing.step)...next, countsDown: false) {
                Text("Next +\(Format.usd(Billing.stepAmount, cents: true))")
            } currentValueLabel: {
                Text(timerInterval: Date.now...next, countsDown: true)
            }
            .font(.caption)
            .tint(.red)
        }
    }
}
