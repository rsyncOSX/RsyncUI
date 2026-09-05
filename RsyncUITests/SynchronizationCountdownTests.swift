@testable import RsyncUI
import Foundation
import Testing

@Suite("Deep-link synchronization countdown")
struct SynchronizationCountdownTests {
    private let start = Date(timeIntervalSinceReferenceDate: 1000)

    @Test("Wait the full six seconds despite repeated ticks")
    func fullDelay() {
        var countdown = SynchronizationCountdown(start: start, withoutTimeDelay: false)
        for second in 0 ..< 6 {
            let now = start.addingTimeInterval(Double(second))
            #expect(countdown.remainingSeconds(at: now) == 6 - second)
            let expired1 = countdown.consumeExpiration(at: now)
            #expect(expired1 == false)
        }
        #expect(countdown.remainingSeconds(at: start.addingTimeInterval(5.99)) == 1)
        let expired2 = countdown.consumeExpiration(at: start.addingTimeInterval(5.99))
        #expect(expired2 == false)
        let expired3 = countdown.consumeExpiration(at: start.addingTimeInterval(6))
        #expect(expired3)
        let expired4 = countdown.consumeExpiration(at: start.addingTimeInterval(7))
        #expect(expired4 == false)
    }

    @Test("A late tick expires once without negative remaining time")
    func lateTick() {
        var countdown = SynchronizationCountdown(start: start, withoutTimeDelay: false)
        let late = start.addingTimeInterval(12)
        #expect(countdown.remainingSeconds(at: late) == 0)
        let expired5 = countdown.consumeExpiration(at: late)
        #expect(expired5)
        let expired6 = countdown.consumeExpiration(at: late)
        #expect(expired6 == false)
    }

    @Test("No delay expires immediately")
    func immediate() {
        var countdown = SynchronizationCountdown(start: start, withoutTimeDelay: true)
        #expect(countdown.remainingSeconds(at: start) == 0)
        let expired7 = countdown.consumeExpiration(at: start)
        #expect(expired7)
        let expired8 = countdown.consumeExpiration(at: start.addingTimeInterval(1))
        #expect(expired8 == false)
    }

    @Test("Cancellation prevents execution", arguments: [false, true])
    func cancellation(withoutTimeDelay: Bool) {
        var countdown = SynchronizationCountdown(start: start, withoutTimeDelay: withoutTimeDelay)
        countdown.cancel()
        let expired9 = countdown.consumeExpiration(at: start.addingTimeInterval(10))
        #expect(expired9 == false)
    }
}
