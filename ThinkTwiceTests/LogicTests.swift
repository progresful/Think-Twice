import XCTest
@testable import ThinkTwice

final class LogicTests: XCTestCase {
    let d = DemoData.bundled

    func testCouldSaveForSixTiers() {
        let want = [19.04, 54.61, 70.34, 106.44, 152.36, 238.84]      // every stop saves something
        for (t, w) in zip(Tier.all, want) {
            XCTAssertEqual(Logic.couldSave(t, d), w, accuracy: 0.001, t.name)
        }
    }

    func testLimits() {
        XCTAssertEqual(Tier.all.map { Logic.limitOf($0, d) }, [9, 8, 7, 5, 3, 0])
        XCTAssertEqual(Tier.all.map { Logic.limitText($0, d) }, [
            "After 9 payments a month.", "After 8 payments a month.", "After 7 payments a month.",
            "After 5 payments a month.", "After 3 payments a month.", "Every payment locked.",
        ])
    }

    func testDefaultTierQueueAndGames() {
        let s = Session(data: d, tier: Tier.all[3])
        XCTAssertEqual(s.paid.count, 5)
        XCTAssertEqual(s.queue.map(\.amount), [19.70, 15.06, 40.29, 21.66, 40.94])
        XCTAssertEqual(s.queue.map { Logic.pick($0.amount) }, [.tap, .tap, .type, .hold, .type])
    }

    func testEveryTierLocksSomething() {
        XCTAssertEqual(Tier.all.map { Session(data: d, tier: $0).queue.count }, [1, 2, 3, 5, 7, 10])
        XCTAssertEqual(Session(data: d, tier: Tier.all[0]).queue.map(\.amount), [40.94])
    }

    func testNoNoListSwitchesOffAPlaceType() {
        // Fast food off: those payments are never locked and do not count towards the limit.
        var s = Session(data: d, tier: Tier.all[3], enabled: ["Restaurant", "Bar"])
        XCTAssertEqual(s.queue.map(\.label), ["Restaurant", "Restaurant"])
        XCTAssertEqual(s.queue.map(\.amount), [21.66, 40.94])
        XCTAssertEqual(s.paid.count, 8)                 // 5 allowed restaurants and 3 fast food before the first lock
        _ = s.finish(skip: true)
        _ = s.finish(skip: true)
        XCTAssertEqual(s.log.count, d.payments.count)
        XCTAssertTrue(Session(data: d, tier: Tier.all[3], enabled: []).queue.isEmpty)
    }

    func testCategoriesForTheNoNoList() {
        XCTAssertEqual(d.categories.first?.name, d.type)
        XCTAssertEqual(d.categories.first?.count, d.before.count)
        XCTAssertEqual(d.categories.first?.total ?? 0, Logic.sum(d.before), accuracy: 0.001)
    }

    func testFirstAlertBody() {
        let s = Session(data: d, tier: Tier.all[3])
        XCTAssertEqual(s.alertBody, "Restaurant, 19,70 €. 6th this month, 177,58 € so far.")
    }

    func testEffortAndSentence() {
        var s = Session(data: d, tier: Tier.all[3])
        XCTAssertEqual(s.effort(ease: 1), Effort(kind: .tap, goal: 50))
        XCTAssertEqual(s.effort(ease: 10), Effort(kind: .tap, goal: 20))
        _ = s.finish(skip: true)                       // 19.70
        XCTAssertEqual(s.effort(ease: 1), Effort(kind: .tap, goal: 50))
        _ = s.finish(skip: true)                       // 15.06
        XCTAssertEqual(s.sentence(ease: 1), "This is my 6th fast food payment this month.")
        XCTAssertEqual(s.sentence(ease: 10), "I want it.")
        XCTAssertEqual(s.effort(ease: 1)?.goal, s.sentence(ease: 1).count)
        _ = s.finish(skip: true)                       // 40.29
        XCTAssertEqual(s.effort(ease: 1), Effort(kind: .hold, goal: 20))     // 21,66 € is 11 s by the rule, held to the 20 s minimum
        XCTAssertEqual(s.effort(ease: 10), Effort(kind: .hold, goal: 2))
        XCTAssertEqual(Session(data: d, tier: Tier.all[5]).effort(ease: 1), Effort(kind: .hold, goal: 25))   // 33,18 € at the long setting

        let long = Session(data: d, tier: Tier.all[5])
        XCTAssertEqual(long.sentence(ease: 1), "This is my 1st fast food payment this month and I still want it.")
    }

    func testFormatting() {
        XCTAssertEqual(Logic.eur(19.70), "19,70 €")
        XCTAssertEqual(Logic.eur(106.44), "106,44 €")
        XCTAssertEqual(Logic.eur(222), "222 €")
        XCTAssertEqual(Logic.eur(0), "0 €")
    }

    func testOrdinals() {
        XCTAssertEqual([1, 2, 3, 4, 11, 12, 13, 21].map(Logic.nth),
                       ["1st", "2nd", "3rd", "4th", "11th", "12th", "13th", "21st"])
    }

    func testLevelThresholds() {
        XCTAssertEqual(Logic.levels, [0, 1, 2, 3, 5, 8])
        XCTAssertEqual((0...9).map(Logic.level), [0, 1, 2, 3, 3, 4, 4, 4, 5, 5])
    }

    func testSkipAndPayOutcomes() {
        var s = Session(data: d, tier: Tier.all[3])
        let skip = s.finish(skip: true)
        XCTAssertEqual(skip?.line, "Stays in your account. No action needed.")
        XCTAssertEqual(skip?.newLevel, "Treats Myself Daily")
        XCTAssertEqual(s.saved, 19.70, accuracy: 0.001)
        s.effort = s.effort(ease: 1)
        let paid = s.finish(skip: false)
        XCTAssertEqual(paid?.line, "192,64 € on restaurants in September. A chef somewhere thanks you.")
        XCTAssertNil(paid?.newLevel)
        s.effort = s.effort(ease: 1)
        XCTAssertEqual(s.finish(skip: false)?.line, "You typed 44 letters for this. Dedication, wrongly aimed.")
    }

    // MARK: savings coach

    private var data: DemoData { d }

    func testCoachHasThirtyCleanPractices() {
        XCTAssertEqual(Coach.practices.count, 30)
        XCTAssertEqual(Set(Coach.practices.map(\.id)).count, 30)
        XCTAssertFalse(Coach.practices.contains { $0.text.contains("!") })
        for t in Topic.allCases where t != .overview {
            XCTAssertTrue(Coach.practices.contains { $0.topic == t }, "\(t)")
        }
    }

    func testCoachFactsComeFromThePayments() {
        let f = Coach.Facts(data)
        XCTAssertEqual(f.count, 10)
        XCTAssertEqual(f.total, 238.84, accuracy: 0.001)
        XCTAssertEqual(f.weekend, 6)
        XCTAssertEqual(f.evening, 7)
        XCTAssertEqual(f.biggest?.amount, 36.38)
        XCTAssertEqual(f.byPlace.first?.label, "Restaurant")
        let sheet = Coach.factSheet(data, Session(data: data, tier: Tier.all[3]))
        XCTAssertTrue(sheet.contains("238,84 €"))
    }

    func testCoachFallbackIsGuardedAndDoesNotRepeat() {
        let s = Session(data: data, tier: Tier.all[3])
        XCTAssertEqual(Coach.fallback("Which stocks should I buy", data, s, used: []).text, Coach.offLimits)
        // Saving questions get a direct answer from the customer's figures, not a stock tip.
        let a = Coach.fallback("How do I build a buffer", data, s, used: [])
        XCTAssertNil(a.practice)
        XCTAssertTrue(a.text.hasPrefix("Start in the everyday basket"))
        XCTAssertTrue(Coach.fallback("whu do i need to save>", data, s, used: []).text.hasPrefix("Because some costs cannot be planned"))
        // Topics the money engine does not cover still pair a fact with a practice, without repeating one.
        let c = Coach.fallback("How do I stop impulse buying", data, s, used: [])
        XCTAssertEqual(c.practice, 20)
        XCTAssertEqual(Coach.fallback("I keep giving in to the urge", data, s, used: [20]).practice, 21)
        XCTAssertTrue(Coach.fallback("x", data, s, used: []).text.hasPrefix("I did not catch that"))
        XCTAssertTrue(Coach.fallback("why am i sad", data, s, used: []).text.hasPrefix("I am sorry it feels that way"))
        let cut = Coach.fallback("how to cut by 10%", data, s, used: [])
        XCTAssertTrue(cut.text.contains("One way to do it"))
        XCTAssertEqual(cut.practice, 1)
        XCTAssertEqual(Coach.topic(of: "What if something breaks"), .emergency)
        XCTAssertEqual(Coach.topic(of: "Where does my money go"), .overview)
        XCTAssertNil(Coach.fallback("x", data, s, used: Set(1...30)).practice)
    }

    func testTapsAreCappedAtFifty() {
        for t in Tier.all {
            var s = Session(data: data, tier: t)
            while let e = s.effort(ease: 1) {
                if e.kind == .tap { XCTAssertLessThanOrEqual(e.goal, 50) }
                _ = s.finish(skip: true)
            }
        }
    }

    // MARK: money engine

    /// Two months: salary 2 000, rent 600, bills 100, a 240 repair once, groceries and restaurants every month.
    private func sample() -> Money {
        var t: [Tx] = []
        for m in ["2026-07", "2026-08"] {
            t.append(Tx(date: "\(m)-01", category: "Salary", label: "Salary", out: -2000, balance: 2000))
            t.append(Tx(date: "\(m)-02", category: "Housing", label: "Rent", out: 600, balance: 1400))
            t.append(Tx(date: "\(m)-03", category: "Utilities", label: "Utility bill", out: 100, balance: 1300))
            for d in 10...13 { t.append(Tx(date: "\(m)-\(d)", category: "Groceries", label: "Supermarket", out: 100, balance: 900)) }
            for d in 20...23 { t.append(Tx(date: "\(m)-\(d)", category: "Restaurants", label: d == 20 ? "Bar" : "Restaurant", out: 50, balance: 700)) }
        }
        t.append(Tx(date: "2026-08-15", category: "Home & Tech", label: "Appliances", out: 240, balance: 500))
        t.append(Tx(date: "2026-08-16", category: "Transportation", label: "Taxi", out: 30, balance: 470))
        return Money(t)
    }

    func testBasketsFollowTheRule() {
        let m = sample()
        XCTAssertEqual(m.basket("Housing"), .regular)
        XCTAssertEqual(m.basket("Home & Tech"), .irregular)      // one payment in two months
        XCTAssertEqual(m.basket("Restaurants"), .everyday)
        XCTAssertNil(m.basket("Salary"))
        XCTAssertEqual(m.average(.regular), 700, accuracy: 0.001)
        XCTAssertEqual(m.average(.irregular), 135, accuracy: 0.001)    // 240 + 30 over two months
        XCTAssertEqual(m.average(.everyday), 600, accuracy: 0.001)
    }

    func testSafeToSpendAndSave() {
        let m = sample()
        XCTAssertEqual(m.income, 2000, accuracy: 0.001)
        XCTAssertEqual(m.everydayRoom, 1165, accuracy: 0.001)          // 2 000 − 700 − 135
        XCTAssertEqual(m.safeToSpendWeek, 1165 * 12 / 52, accuracy: 0.001)
        XCTAssertEqual(m.safeToSave, 565, accuracy: 0.001)
        XCTAssertEqual(m.balance, 470)
    }

    func testLookupsAndWhatIf() {
        let m = sample()
        XCTAssertEqual(m.spent(in: "2026-08", label: "Taxi").total, 30)
        XCTAssertEqual(m.spent(in: "2026-07", label: "Taxi").count, 0)
        XCTAssertEqual(m.spent(in: "2026-08", category: "Restaurants").total, 200)
        let w = m.whatIf("Restaurants", cut: 20)
        XCTAssertEqual(w.month, 40, accuracy: 0.001)
        XCTAssertEqual(w.year, 480, accuracy: 0.001)
        XCTAssertEqual(w.leftOver, 605, accuracy: 0.001)
    }

    func testQuestionsAreUnderstood() {
        let m = sample()
        XCTAssertEqual(m.kind(of: "How much did I spend on taxis last month?"), .lookup)
        XCTAssertTrue(m.answer("How much did I spend on taxis last month?")!.contains("30 €"))
        XCTAssertEqual(m.kind(of: "How much could I save if I reduced dining out by 20%?"), .whatIf("Restaurants", 20))
        XCTAssertEqual(m.kind(of: "What is safe for me to spend this week?"), .safeToSpend)
        XCTAssertEqual(m.kind(of: "What kind of spender am I?"), .spender)
        XCTAssertEqual(m.kind(of: "Where does my money go"), .baskets)
        XCTAssertEqual(m.kind(of: "whu do i need to save>"), .whySave)
        XCTAssertEqual(m.kind(of: "how much should I save"), .howMuchSave)
        XCTAssertEqual(m.kind(of: "Can I afford a 300 € phone?"), .afford(300))
        XCTAssertEqual(m.kind(of: "how am i doing"), .health)
        // Follow-ups keep the earlier subject; with none, the locked group is assumed.
        XCTAssertEqual(m.kind(of: "how to cut by 10%"), .whatIf("Restaurants", 10))
        XCTAssertEqual(m.kind(of: "what about 30%", hint: "how much do I spend on groceries"), .whatIf("Groceries", 30))
        XCTAssertEqual(m.kind(of: "and in July?", hint: "taxis last month"), .lookup)
        XCTAssertTrue(m.answer("and in July?", hint: "taxis last month")!.contains("no payments for taxis in July"))
        XCTAssertEqual(m.kind(of: "how can I spend less"), .whatIf("Restaurants", 20))
        XCTAssertNil(m.kind(of: "why am i sad"))
        XCTAssertNil(m.kind(of: "What is my current plan"))             // "rent" inside "current" is not a match
        XCTAssertNil(Money.subject(of: "different"))
    }

    func testTaxisAreNotTaxes() {
        XCTAssertFalse(Coach.isBlocked("How much did I spend on taxis last month?"))
        XCTAssertTrue(Coach.isBlocked("How do I lower my taxes"))
        XCTAssertTrue(Coach.isBlocked("Should I invest in an index fund now"))
        XCTAssertTrue(Coach.isBlocked("which stocks to buy"))
    }

    func testBundledHistoryLoads() {
        let m = Money.bundled
        XCTAssertGreaterThan(m.tx.count, 500)
        XCTAssertEqual(m.last, "2026-08")
        XCTAssertGreaterThan(m.safeToSpendWeek, 0)
        XCTAssertTrue(m.factSheet().contains("THE THREE BASKETS"))
    }
}
