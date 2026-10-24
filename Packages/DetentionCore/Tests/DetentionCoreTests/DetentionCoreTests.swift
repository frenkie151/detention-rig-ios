import Foundation
import Testing
@testable import DetentionCore

@Suite struct DetentionMathTests {
    let arrival = Date(timeIntervalSince1970: 1_792_822_000)
    let utc = TimeZone(identifier: "UTC")!

    func at(_ hours: Double, departed: Bool = false) -> DetentionSnapshot {
        let t = arrival.addingTimeInterval(hours * 3600)
        return DetentionSnapshot(arrivedAt: arrival, departedAt: departed ? t : nil, now: t)
    }

    @Test func nothingBillableDuringFreeTime() {
        let s = at(1.99)
        #expect(s.amount == 0)
        #expect(s.steps == 0)
        #expect(s.freeFraction == 1)
    }

    @Test func fourHoursIsOneFifty() {
        let s = at(4)
        #expect(s.steps == 8)
        #expect(s.amount == 150)
        #expect(s.timeToNextStep == Billing.step)
        #expect(s.freeFraction == 0.5)
    }

    @Test func partialStepIsNotBilled() {
        let s = at(4 + 14.0 / 60)
        #expect(s.amount == 150)
        #expect(Int(s.timeToNextStep) == 60)
        #expect(at(4.25).amount == 168.75)
    }

    @Test func departureFreezesTheClock() {
        let s = DetentionSnapshot(arrivedAt: arrival, departedAt: arrival.addingTimeInterval(4 * 3600),
                                  now: arrival.addingTimeInterval(9 * 3600))
        #expect(s.isStopped)
        #expect(s.amount == 150)
    }

    @Test func formatting() {
        #expect(Format.usd(150) == "$150")
        #expect(Format.usd(2250, cents: true) == "$2,250.00")
        #expect(Format.hoursMinutes(4 * 3600 + 5) == "4h 0m")
        #expect(Format.clock(4 * 3600 + 5 * 60) == "4h 05m")
        #expect(Format.countdown(14 * 60 + 55) == "14:55")
        #expect(Format.hours(2.25 * 3600) == "2.25")
        #expect(Format.hours(2 * 3600) == "2")
    }

    @Test func emailCarriesTheNumbers() {
        let body = DetentionEmail.body(for: at(4, departed: true), timeZone: utc)
        #expect(body.contains("Sat 4 hrs, 2 hrs past your 2 hrs free. 2 × $75/hr = $150.00."))
        #expect(body.contains("revised rate confirmation for $2,250.00 total"))
        #expect(!body.contains("truck still there"))
        #expect(DetentionEmail.body(for: at(4), timeZone: utc).contains("(truck still there)"))
    }

    @Test func loadStatusFollowsDeparture() {
        let det = Load.demo[0]
        #expect(det.statusLabel(departed: false).0 == "Detention running")
        #expect(det.statusLabel(departed: true).0 == "Truck left · bill it")
        #expect(Load.demo.filter(\.isDelivered).count == 2)
    }
}
