import Foundation

/// Rate-con terms for the demo load: two free hours, then $75 an hour in 15-minute steps.
public enum Billing {
    public static let freeTime: TimeInterval = 2 * 3600
    public static let hourlyRate: Decimal = 75
    public static let step: TimeInterval = 15 * 60
    public static let stepAmount: Decimal = hourlyRate / 4
    public static let lineHaul: Decimal = 2100
}

/// Where a detention stands at one moment.
public struct DetentionSnapshot: Equatable, Sendable {
    public let arrivedAt: Date
    public let end: Date
    public let isStopped: Bool
    public let elapsed: TimeInterval
    public let billable: TimeInterval
    public let steps: Int
    public let amount: Decimal
    public let timeToNextStep: TimeInterval

    public init(arrivedAt: Date, departedAt: Date?, now: Date) {
        let end = departedAt ?? now
        let elapsed = max(0, end.timeIntervalSince(arrivedAt))
        let billable = max(0, elapsed - Billing.freeTime)
        let steps = Int((billable / Billing.step).rounded(.down))
        self.arrivedAt = arrivedAt
        self.end = end
        self.isStopped = departedAt != nil
        self.elapsed = elapsed
        self.billable = billable
        self.steps = steps
        self.amount = Decimal(steps) * Billing.stepAmount
        self.timeToNextStep = Billing.step - billable.truncatingRemainder(dividingBy: Billing.step)
    }

    public var freeTimeEndsAt: Date { arrivedAt.addingTimeInterval(Billing.freeTime) }
    public var nextStepAt: Date { end.addingTimeInterval(timeToNextStep) }
    public var nextStepStartedAt: Date { nextStepAt.addingTimeInterval(-Billing.step) }

    /// Share of the elapsed time that was free, from 0 to 1. Drives the timeline bar.
    public var freeFraction: Double {
        elapsed > 0 ? min(elapsed, Billing.freeTime) / elapsed : 1
    }
}

// MARK: - Formatting

public enum Format {
    // Formatters are built per call: they aren't Sendable, and this keeps the helpers safe from any actor.
    private static func dateFormatter(_ format: String, _ timeZone: TimeZone) -> DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = timeZone
        f.dateFormat = format
        return f
    }

    /// "$150" or, with cents, "$150.00".
    public static func usd(_ amount: Decimal, cents: Bool = false) -> String {
        let money = NumberFormatter()
        money.locale = Locale(identifier: "en_US")
        money.numberStyle = .currency
        money.currencyCode = "USD"
        money.minimumFractionDigits = cents ? 2 : 0
        money.maximumFractionDigits = cents ? 2 : 0
        return money.string(from: amount as NSDecimalNumber) ?? "$\(amount)"
    }

    /// "4h 0m"
    public static func hoursMinutes(_ interval: TimeInterval) -> String {
        let minutes = Int(interval / 60)
        return "\(minutes / 60)h \(minutes % 60)m"
    }

    /// "4h 00m", for the big clock.
    public static func clock(_ interval: TimeInterval) -> String {
        let minutes = Int(interval / 60)
        return "\(minutes / 60)h " + String(format: "%02dm", minutes % 60)
    }

    /// "14:55", minutes and seconds left.
    public static func countdown(_ interval: TimeInterval) -> String {
        let seconds = Int(interval.rounded(.up))
        return "\(seconds / 60):" + String(format: "%02d", seconds % 60)
    }

    public static func time(_ date: Date, timeZone: TimeZone = .current) -> String {
        dateFormatter("h:mm a", timeZone).string(from: date)
    }

    public static func day(_ date: Date, timeZone: TimeZone = .current) -> String {
        dateFormatter("MMM d", timeZone).string(from: date)
    }

    /// "2", "2.25": hours with trailing zeros trimmed.
    static func hours(_ interval: TimeInterval) -> String {
        let text = String(format: "%.2f", interval / 3600)
        return text.hasSuffix(".00") ? String(text.dropLast(3)) : text
    }
}

// MARK: - Broker email

public enum DetentionEmail {
    public static let recipient = "dana@pinecrest-logistics.example"
    public static let subject = "Detention on DR-2041"

    public static func body(for s: DetentionSnapshot, timeZone: TimeZone = .current) -> String {
        let start = "\(Format.day(s.arrivedAt, timeZone: timeZone)) at \(Format.time(s.arrivedAt, timeZone: timeZone))"
        var end = "\(Format.day(s.end, timeZone: timeZone)) at \(Format.time(s.end, timeZone: timeZone))"
        if !s.isStopped { end += " (truck still there)" }
        let billed = Format.hours(Double(s.steps) * Billing.step)
        let amount = Format.usd(s.amount, cents: true)
        let total = Format.usd(Billing.lineHaul + s.amount, cents: true)
        return """
        Hi Dana,

        We're requesting detention on load DR-2041:
        • Delivery #1, Lodi Cold Storage, Lodi CA. \(start) to \(end). \
        Sat \(Format.hours(s.elapsed)) hrs, \(billed) hrs past your 2 hrs free. \(billed) × $75/hr = \(amount).

        That comes to \(amount) in detention.

        Could you send over a revised rate confirmation for \(total) total: \
        \(Format.usd(Billing.lineHaul, cents: true)) line haul plus \(amount) in accessorials (detention)?

        Please confirm any approval required by these terms. This request does not assume it has been granted.

        Thanks,
        Northbound Freight Co. dispatch
        (209) 555-0148
        """
    }
}
