import ActivityKit
import Foundation

/// The Live Activity for a running detention clock, shared by the app and the widget extension.
struct DetentionActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable, Sendable {
        /// Billed so far, in whole 15-minute steps.
        var amount: Decimal
        /// When the next step lands; nil once the truck has left.
        var nextStepAt: Date?
        var departedAt: Date?
    }

    var loadID: String
    var receiver: String
    var arrivedAt: Date
    var freeTimeEndsAt: Date
}
