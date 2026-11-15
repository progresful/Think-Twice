import Foundation

// Port of the script in ../think-twice/index.html. Names follow the HTML.

struct Payment: Decodable, Equatable {
    let label, longDate, time: String
    let amount: Double
    let openUntil, shortDate: String

    init(from decoder: Decoder) throws {
        var c = try decoder.unkeyedContainer()
        label = try c.decode(String.self)
        longDate = try c.decode(String.self)
        time = try c.decode(String.self)
        amount = try c.decode(Double.self)
        openUntil = try c.decode(String.self)
        shortDate = try c.decode(String.self)
    }
}

struct DemoData: Decodable {
    let customer: String
    let age: Int
    let month, beforeMonth, type: String
    let usual, read: Int
    let before, payments: [Payment]
    let categories: [Category]

    static let bundled: DemoData = {
        let url = Bundle.main.url(forResource: "demo-data", withExtension: "json")!
        return try! JSONDecoder().decode(DemoData.self, from: Data(contentsOf: url))
    }()
}

/// A group on the no-no list, with the kinds of places inside it.
struct Category: Decodable, Identifiable {
    struct Item: Decodable, Identifiable {
        let label: String
        let count: Int
        let total: Double
        var id: String { label }
    }
    let name: String
    let items: [Item]
    var id: String { name }
    var count: Int { items.reduce(0) { $0 + $1.count } }
    var total: Double { items.reduce(0) { $0 + $1.total } }
}

struct Tier: Equatable {
    let name: String
    let pct: Double?      // share of the usual monthly count allowed before the lock
    let len: Double       // game length factor
    let games: String

    static let all: [Tier] = [
        // Every stop locks something: 9, 8, 7, 5, 3 and 0 payments allowed for a usual month of 10.
        Tier(name: "Broke by Friday", pct: 0.9, len: 0.5, games: "Short"),
        Tier(name: "Treats Myself Daily", pct: 0.8, len: 0.5, games: "Short"),
        Tier(name: "Says No Sometimes", pct: 0.7, len: 0.5, games: "Short"),
        Tier(name: "Thinks Twice", pct: 0.5, len: 1, games: "Standard"),
        Tier(name: "Boring but Rich", pct: 0.25, len: 1.5, games: "Long"),
        Tier(name: "Financially Free", pct: 0, len: 1.5, games: "Long"),
    ]
}

enum GameKind: Equatable {
    case tap, hold, type

    var name: String {
        switch self {
        case .tap: return "Tap it out"
        case .hold: return "Hold on"
        case .type: return "Say it"
        }
    }
    var rule: String {
        switch self {
        case .tap: return "1 tap for every 10 cents, 50 at most"
        case .hold: return "1 second for every 2 €, at least 20. Letting go restarts."
        case .type: return "Big payment. Type the sentence exactly."
        }
    }
    var unit: String {
        switch self {
        case .tap: return "taps to pay"
        case .hold: return "seconds to pay"
        case .type: return ""
        }
    }
}

struct Effort: Equatable {
    let kind: GameKind
    let goal: Int
}

enum Logic {
    static let levels = [0, 1, 2, 3, 5, 8]      // skips needed for each rung
    static let banks = ["S-Pankki", "OP", "Nordea", "Danske Bank", "Aktia", "Säästöpankki",
                        "Handelsbanken", "POP Pankki", "Ålandsbanken", "Revolut", "N26"]

    /// JS Math.round: half rounds up.
    static func round(_ x: Double) -> Int { Int((x + 0.5).rounded(.down)) }

    static func sum(_ a: [Payment]) -> Double { a.reduce(0) { $0 + $1.amount } }

    /// nil means no lock (Infinity in the HTML).
    static func limitOf(_ t: Tier, _ d: DemoData) -> Int? {
        guard let pct = t.pct else { return nil }
        return round(Double(d.usual) * pct)
    }

    static func limitText(_ t: Tier, _ d: DemoData) -> String {
        guard let lim = limitOf(t, d) else { return "No reminder. Weekly report only." }
        return lim == 0 ? "A reminder on every payment." : "After \(lim) payments a month."
    }

    /// What the lock would have caught in the month before.
    static func couldSave(_ t: Tier, _ d: DemoData) -> Double {
        guard let lim = limitOf(t, d) else { return 0 }
        return sum(Array(d.before.dropFirst(lim)))
    }

    static func pick(_ amount: Double) -> GameKind {
        amount < 20 ? .tap : amount < 40 ? .hold : .type
    }

    static func level(_ skipped: Int) -> Int { levels.filter { skipped >= $0 }.count - 1 }

    static func eur(_ n: Double) -> String {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "fi_FI")
        f.numberStyle = .decimal
        f.roundingMode = .halfUp
        f.minimumFractionDigits = n.truncatingRemainder(dividingBy: 1) != 0 ? 2 : 0
        f.maximumFractionDigits = 2
        return (f.string(from: NSNumber(value: n)) ?? "\(n)") + " €"
    }

    static func nth(_ n: Int) -> String {
        if n % 100 > 10 && n % 100 < 14 { return "\(n)th" }
        let s = ["th", "st", "nd", "rd"]
        return "\(n)" + (n % 10 < s.count ? s[n % 10] : "th")
    }
}

struct LogEntry: Identifiable {
    let id: Int
    let payment: Payment
    let skipped: Bool
}

struct Outcome: Equatable {
    let skip: Bool
    let amount: Double
    let line: String
    let newLevel: String?
}

struct Session {
    let data: DemoData
    let tier: Tier
    var saved = 0.0
    var skipped = 0
    var log: [LogEntry]
    let queue: [Payment]
    private let queueIndex: [Int]     // position of each queued payment in the month
    private let passIndex: [Int]      // payments at places switched off on the no-no list: never locked
    var i = 0
    var effort: Effort?

    /// `enabled`: the place types on the no-no list; nil locks every type.
    init(data: DemoData, tier: Tier, enabled: Set<String>? = nil) {
        self.data = data
        self.tier = tier
        let lim = Logic.limitOf(tier, data) ?? Int.max
        var counted = 0, q: [Payment] = [], qi: [Int] = [], pass: [Int] = [], paid: [Int] = []
        for (n, p) in data.payments.enumerated() {
            if let enabled, !enabled.contains(p.label) { pass.append(n) }
            else if counted < lim { counted += 1; paid.append(n) }
            else { q.append(p); qi.append(n) }
        }
        queue = q
        queueIndex = qi
        passIndex = pass
        let first = qi.first ?? Int.max
        log = (paid + pass.filter { $0 < first }).sorted()
            .map { LogEntry(id: $0, payment: data.payments[$0], skipped: false) }
    }

    var paid: [Payment] { log.filter { !$0.skipped }.map(\.payment) }
    var ended: Bool { i >= queue.count }
    var current: Payment? { ended ? nil : queue[i] }
    var level: Int { Logic.level(skipped) }
    var need: Int { level < 5 ? Logic.levels[level + 1] - skipped : 0 }

    /// "6th this month, 177,58 € so far."
    var runningLine: String {
        "\(Logic.nth(paid.count + 1)) this month, \(Logic.eur(Logic.sum(paid))) so far."
    }

    var alertBody: String? {
        guard let p = current else { return nil }
        return "\(p.label), \(Logic.eur(p.amount)). \(runningLine)"
    }

    func sentence(ease: Double) -> String {
        guard let p = current else { return "" }
        if ease > 1 { return "I want it." }
        return "This is my \(Logic.nth(paid.count + 1)) \(p.label.lowercased()) payment this month"
            + (tier.len > 1 ? " and I still want it" : "") + "."
    }

    func effort(ease: Double) -> Effort? {
        guard let p = current else { return nil }
        let k = Logic.pick(p.amount)
        switch k {
        case .type: return Effort(kind: k, goal: sentence(ease: ease).count)
        // Never more than 50 taps for one purchase.
        case .tap: return Effort(kind: k, goal: min(50, max(1, Logic.round(p.amount * 10 * tier.len / ease))))
        // Never a quick hold: at least 20 seconds before -fast shortens it.
        case .hold: return Effort(kind: k, goal: max(1, Logic.round(max(20, p.amount / 2 * tier.len) / ease)))
        }
    }

    /// After a locked payment is paid anyway: one line about it, built from the real numbers. Rotates.
    func diss(_ index: Int) -> String {
        let n = paid.count, t = Logic.sum(paid)
        switch index % 5 {
        case 0: return "\(Logic.nth(n)) this month. The food at home sends its regards."
        case 1: return "\(Logic.eur(t)) on restaurants in \(data.month). A chef somewhere thanks you."
        case 2:
            let e = effort ?? Effort(kind: .tap, goal: 0)
            let did: String
            switch e.kind {
            case .tap: did = "tapped \(e.goal) times"
            case .hold: did = "held on for \(e.goal) seconds"
            case .type: did = "typed \(e.goal) letters"
            }
            return "You \(did) for this. Dedication, wrongly aimed."
        case 3: return "You got a reminder for a reason. You were the reason."
        default: return "\(Tier.all[5].name) just moved one rung further away."
        }
    }

    mutating func finish(skip: Bool) -> Outcome? {
        guard let p = current else { return nil }
        let before = level
        if skip { saved += p.amount; skipped += 1 }
        log.append(LogEntry(id: queueIndex[i], payment: p, skipped: skip))
        let next = i + 1 < queue.count ? queueIndex[i + 1] : Int.max
        for n in passIndex where n > queueIndex[i] && n < next {
            log.append(LogEntry(id: n, payment: data.payments[n], skipped: false))
        }
        i += 1
        let after = level
        return Outcome(skip: skip, amount: p.amount,
                       line: skip ? "Stays in your account. No action needed." : diss(i - 1),
                       newLevel: after > before ? Tier.all[after].name : nil)
    }
}
