import ActivityKit
import DetentionCore
import Foundation
import Observation

enum AppTab: Hashable {
    case today, loads, automations
}

enum Route: Hashable {
    case detention
}

/// App state for the demo load. Everything lives in memory; a real build would back it with SwiftData.
@MainActor @Observable
final class AppModel {
    /// The driver checked in a little over four hours before launch and is still waiting.
    let arrivedAt = Date.now.addingTimeInterval(-(4 * 3600 + 5))
    private(set) var departedAt: Date?
    private(set) var requestSentAt: Date?
    private(set) var needs = Need.demo
    var automations = Dictionary(uniqueKeysWithValues: Automation.allCases.map { ($0, $0.isOnByDefault) })
    var selectedTab = AppTab.today
    var toast: String?

    private var activity: Activity<DetentionActivityAttributes>?
    private var lastPublishedAmount: Decimal?

    func snapshot(at now: Date = .now) -> DetentionSnapshot {
        DetentionSnapshot(arrivedAt: arrivedAt, departedAt: departedAt, now: now)
    }

    var isStopped: Bool { departedAt != nil }

    func isOn(_ automation: Automation) -> Bool { automations[automation] ?? false }

    func setAutomation(_ automation: Automation, on: Bool) {
        automations[automation] = on
        say(on ? "\(automation.title) on · acts from now" : "\(automation.title) off")
    }

    func resolve(_ need: Need, confirmed: Bool) {
        needs.removeAll { $0.id == need.id }
        if confirmed, let message = need.confirmation { say(message) }
    }

    func markDeparted() {
        let now = Date.now
        departedAt = now
        say("Truck left. \(Format.usd(snapshot(at: now).amount)) to bill.")
        Task { await publishActivity() }
    }

    func undoDeparture() {
        departedAt = nil
        say("Clock running again")
        Task { await publishActivity() }
    }

    func markRequestSent() {
        requestSentAt = .now
        say("Marked as sent to Pinecrest")
    }

    func say(_ message: String) {
        toast = message
        Task {
            try? await Task.sleep(for: .seconds(2.2))
            if toast == message { toast = nil }
        }
    }

    // MARK: Live Activity

    /// Shows the running clock on the Lock Screen and in the Dynamic Island.
    func startLiveActivity() async {
        guard activity == nil, ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let s = snapshot()
        let attributes = DetentionActivityAttributes(
            loadID: "DR-2041", receiver: "Lodi Cold Storage",
            arrivedAt: arrivedAt, freeTimeEndsAt: s.freeTimeEndsAt)
        activity = try? Activity.request(
            attributes: attributes,
            content: content(for: s),
            pushType: nil)
        lastPublishedAmount = s.amount
    }

    /// Call once a second while the app is open; only talks to ActivityKit when the bill changes.
    func tick(_ now: Date) async {
        let amount = snapshot(at: now).amount
        guard activity != nil, amount != lastPublishedAmount else { return }
        await publishActivity(now)
    }

    private func publishActivity(_ now: Date = .now) async {
        guard let activity else { return }
        let s = snapshot(at: now)
        lastPublishedAmount = s.amount
        await activity.update(content(for: s))
    }

    private func content(for s: DetentionSnapshot) -> ActivityContent<DetentionActivityAttributes.ContentState> {
        let state = DetentionActivityAttributes.ContentState(
            amount: s.amount,
            nextStepAt: s.isStopped ? nil : s.nextStepAt,
            departedAt: departedAt)
        // Without push updates the amount can't change on its own, so mark it stale at the next step.
        return ActivityContent(state: state, staleDate: s.isStopped ? nil : s.nextStepAt)
    }
}
