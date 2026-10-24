import Foundation

// Fictional company, loads and people for the demo.

public enum Tone: Sendable {
    case red, amber, blue, green
}

public struct Need: Identifiable, Hashable, Sendable {
    public enum Kind: Sendable { case newLoad, detention, checkIn }

    public let id: String
    public let kind: Kind
    public let title: String
    public let subtitle: String
    public let actionTitle: String?
    public let confirmation: String?

    public var label: String {
        switch kind {
        case .newLoad: "New load"
        case .detention: "Detention"
        case .checkIn: "Check-in"
        }
    }

    public var symbol: String {
        switch kind {
        case .newLoad: "truck.box"
        case .detention: "hourglass"
        case .checkIn: "mappin.and.ellipse"
        }
    }

    public var tone: Tone {
        switch kind {
        case .newLoad: .blue
        case .detention: .red
        case .checkIn: .amber
        }
    }

    public static let demo: [Need] = [
        Need(id: "load", kind: .newLoad, title: "DR-2056 · Stockton → Reno",
             subtitle: "Pinecrest Logistics · $2,750 · picks up Sat",
             actionTitle: "Save", confirmation: "DR-2056 saved to Loads"),
        Need(id: "det", kind: .detention, title: "DR-2041 · Lodi Cold Storage",
             subtitle: "", actionTitle: nil, confirmation: nil),
        Need(id: "arrive", kind: .checkIn, title: "Confirm arrival · DR-2038",
             subtitle: "Location check needs a tap from you",
             actionTitle: "Confirm", confirmation: "Arrival confirmed · DR-2038"),
    ]
}

public struct Load: Identifiable, Hashable, Sendable {
    public enum Status: Sendable { case detention, arriving, booked, podSent, paid }

    public let id: String
    public let lane: String
    public let broker: String
    public let amount: Decimal
    public let status: Status

    public var isDelivered: Bool { status == .podSent || status == .paid }

    public func statusLabel(departed: Bool) -> (String, Tone) {
        switch status {
        case .detention: departed ? ("Truck left · bill it", .green) : ("Detention running", .red)
        case .arriving: ("Confirm arrival", .amber)
        case .booked: ("Booked", .blue)
        case .podSent: ("POD sent", .green)
        case .paid: ("Paid", .green)
        }
    }

    public static let demo: [Load] = [
        Load(id: "DR-2041", lane: "Fresno → Lodi", broker: "Pinecrest Logistics", amount: 2100, status: .detention),
        Load(id: "DR-2038", lane: "Modesto → Sacramento", broker: "Bayline Brokerage", amount: 1650, status: .arriving),
        Load(id: "DR-2056", lane: "Stockton → Reno", broker: "Pinecrest Logistics", amount: 2750, status: .booked),
        Load(id: "DR-2033", lane: "Merced → Oakland", broker: "Harbor & Vine", amount: 1380, status: .podSent),
        Load(id: "DR-2029", lane: "Visalia → San Jose", broker: "Bayline Brokerage", amount: 1920, status: .paid),
    ]
}

public enum Automation: String, CaseIterable, Identifiable, Sendable {
    case arrival, departure, headsUp, pod, overdue, invoice

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .arrival: "Arrival updates"
        case .departure: "Departure updates"
        case .headsUp: "Detention heads-up"
        case .pod: "POD send"
        case .overdue: "Follow up on overdue invoices"
        case .invoice: "Invoice automatically"
        }
    }

    public var detail: String {
        switch self {
        case .arrival: "Texts the broker when the driver checks in at pickup or delivery."
        case .departure: "Lets the broker know the truck is rolling again, with the time it left."
        case .headsUp: "Tells the broker before their notice deadline, or the moment detention starts when no advance notice is required."
        case .pod: "Sends the signed proof of delivery as soon as the driver snaps it."
        case .overdue: "A polite nudge at 30 days, another at 45, each with the invoice attached."
        case .invoice: "Builds the invoice with line haul, detention and lumpers once POD is in."
        }
    }

    public var symbol: String {
        switch self {
        case .arrival: "mappin.and.ellipse"
        case .departure: "clock"
        case .headsUp: "hourglass"
        case .pod: "doc.badge.checkmark"
        case .overdue: "clock.arrow.circlepath"
        case .invoice: "doc.text"
        }
    }

    public var isOnByDefault: Bool { self == .headsUp }
}
