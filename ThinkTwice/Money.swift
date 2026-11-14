import Foundation

// The customer's whole transaction history, and every figure the coach is allowed to quote:
// lookups by category, kind of place and month, the three baskets, safe to spend, safe to save and what-if.
// All of it is computed here, in code. The model only words the answer.

struct Tx: Decodable, Equatable {
    let date, category, label: String     // date is yyyy-MM-dd; label is the kind of place, from the merchant category code
    let out, balance: Double              // euros out (negative = money in), balance after

    init(date: String, category: String, label: String, out: Double, balance: Double) {
        self.date = date; self.category = category; self.label = label; self.out = out; self.balance = balance
    }

    init(from decoder: Decoder) throws {
        var c = try decoder.unkeyedContainer()
        date = try c.decode(String.self)
        category = try c.decode(String.self)
        label = try c.decode(String.self)
        out = try c.decode(Double.self)
        balance = try c.decode(Double.self)
    }

    var month: String { String(date.prefix(7)) }
}

/// The sponsor's three baskets.
enum Basket: Int, CaseIterable {
    case regular, irregular, everyday

    var name: String {
        switch self {
        case .regular: return "Fixed costs"
        case .irregular: return "Irregular costs"
        case .everyday: return "Everyday spending"
        }
    }

    var explain: String {
        switch self {
        case .regular: return "must be paid and comes every month, such as rent and utility bills"
        case .irregular: return "larger costs that come less than once a month and cannot be planned to the day, such as a repair, a pharmacy bill or a trip"
        case .everyday: return "small frequent payments that slip through your fingers, such as food, eating out, fun and getting around"
        }
    }
}

struct Money {
    let tx: [Tx]
    let months: [String]                  // every month in the data, oldest first
    private let perMonth: [String: Double]   // payments a month, by category

    static let bundled: Money = {
        let url = Bundle.main.url(forResource: "history", withExtension: "json")!
        return Money((try? JSONDecoder().decode([Tx].self, from: Data(contentsOf: url))) ?? [])
    }()

    init(_ tx: [Tx]) {
        self.tx = tx
        months = Array(Set(tx.map(\.month))).sorted()
        var n: [String: Double] = [:]
        for t in tx { n[t.category, default: 0] += 1 }
        let m = Double(max(months.count, 1))
        perMonth = n.mapValues { $0 / m }
    }

    // MARK: baskets

    /// Rent and bills are fixed. A category paid less than once a month on average is irregular. The rest is everyday.
    func basket(_ category: String) -> Basket? {
        switch category {
        case "Salary": return nil
        case "Housing", "Utilities": return .regular
        default: return (perMonth[category] ?? 0) < 1 ? .irregular : .everyday
        }
    }

    func categories(_ b: Basket) -> [String] {
        Array(Set(tx.map(\.category))).filter { basket($0) == b }.sorted { average($0) > average($1) }
    }

    // MARK: lookups

    var last: String { months.last ?? "" }
    func recent(_ n: Int) -> [String] { Array(months.suffix(n)) }

    func spent(in month: String, category: String? = nil, label: String? = nil) -> (count: Int, total: Double) {
        let rows = tx.filter { $0.month == month && $0.out > 0 && (category == nil || $0.category == category) && (label == nil || $0.label == label) }
        return (rows.count, rows.reduce(0) { $0 + $1.out })
    }

    private func total(_ ms: [String], _ keep: (Tx) -> Bool) -> Double {
        tx.filter { ms.contains($0.month) && keep($0) }.reduce(0) { $0 + $1.out }
    }

    /// Monthly average of one category over the last six months.
    func average(_ category: String) -> Double { total(recent(6)) { $0.category == category } / Double(max(recent(6).count, 1)) }

    /// Monthly average of a basket. Irregular costs are averaged over twelve months, because six can miss them.
    func average(_ b: Basket) -> Double {
        let ms = recent(b == .irregular ? 12 : 6)
        return total(ms) { basket($0.category) == b } / Double(max(ms.count, 1))
    }

    var income: Double { -total(recent(6)) { $0.category == "Salary" } / Double(max(recent(6).count, 1)) }
    var balance: Double { tx.last?.balance ?? 0 }

    // MARK: safe to spend, safe to save, what-if

    /// What is left for everyday spending in a month after fixed costs and a reserve for irregular ones.
    var everydayRoom: Double { max(0, income - average(.regular) - average(.irregular)) }
    var safeToSpendWeek: Double { everydayRoom * 12 / 52 }
    /// Room minus what everyday spending actually takes. Negative means everyday spending eats into the reserve.
    var leftOver: Double { everydayRoom - average(.everyday) }
    var safeToSave: Double { max(0, leftOver) }
    /// How many months of fixed costs the balance covers.
    var bufferMonths: Double { average(.regular) > 0 ? balance / average(.regular) : 0 }

    func whatIf(_ category: String, cut percent: Double) -> (month: Double, year: Double, leftOver: Double) {
        let saved = average(category) * percent / 100
        return (saved, saved * 12, leftOver + saved)
    }

    func biggestIrregular(_ n: Int) -> [Tx] {
        Array(tx.filter { recent(12).contains($0.month) && basket($0.category) == .irregular }.sorted { $0.out > $1.out }.prefix(n))
    }

    // MARK: words

    static let monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    static func name(_ month: String) -> String {
        let p = month.split(separator: "-")
        guard p.count == 2, let m = Int(p[1]), (1...12).contains(m) else { return month }
        return "\(monthNames[m - 1]) \(p[0])"
    }

    /// Words a customer might use, mapped to a category or a kind of place in the data.
    static let words: [(keys: [String], category: String?, label: String?, say: String)] = [
        (["taxi", "cab"], nil, "Taxi", "taxis"),
        (["fuel", "petrol", "gas station"], nil, "Fuel", "fuel"),
        (["parking"], nil, "Parking", "parking"),
        (["public transport", "tram", "metro"], nil, "Public transport", "public transport"),
        (["fast food", "takeaway", "burger"], nil, "Fast food", "fast food"),
        (["bar", "drinks", "pub"], nil, "Bar", "bars"),
        (["cinema", "movie"], nil, "Cinema", "the cinema"),
        (["theatre", "theater"], nil, "Theatre", "the theatre"),
        (["pharmacy", "medicine"], nil, "Pharmacy", "the pharmacy"),
        (["supermarket"], nil, "Supermarket", "supermarkets"),
        (["electronics"], nil, "Electronics", "electronics"),
        (["rent", "housing"], "Housing", nil, "rent"),
        (["utilit", "electricity", "bills"], "Utilities", nil, "utility bills"),
        (["restaurant", "dining", "eating out", "eat out", "dinner", "lunch"], "Restaurants", nil, "eating out"),
        (["grocer", "food shop"], "Groceries", nil, "groceries"),
        (["entertainment", "going out"], "Entertainment", nil, "entertainment"),
        (["transport", "commut"], "Transportation", nil, "transport"),
        (["travel", "trip", "holiday", "vacation"], "Travel", nil, "travel"),
        (["health", "doctor"], "Health", nil, "health"),
        (["home", "tech", "appliance"], "Home & Tech", nil, "home and tech"),
        (["lifestyle", "clothes", "clothing", "sport"], "Lifestyle", nil, "lifestyle"),
    ]

    /// The subject of a question, or of the earlier question in `hint` when this one names none ("and in July?").
    static func subject(of q: String, hint: String?) -> (category: String?, label: String?, say: String)? {
        subject(of: q) ?? hint.flatMap { subject(of: $0) }
    }

    static func subject(of q: String) -> (category: String?, label: String?, say: String)? {
        let t = q.lowercased()
        let parts = t.split { !$0.isLetter }.map(String.init)
        // One-word keys match the start of a word ("rent" must not match "current"); phrases match anywhere.
        func hit(_ k: String) -> Bool { k.contains(" ") ? t.contains(k) : parts.contains { $0.hasPrefix(k) } }
        return words.first { w in w.keys.contains(where: hit) }.map { ($0.category, $0.label, $0.say) }
    }

    /// The month a question is about: a month name, "last month", or nil.
    func month(in q: String) -> String? {
        let t = q.lowercased()
        if t.contains("last month") { return last }
        for (i, n) in Money.monthNames.enumerated() where t.contains(n.lowercased()) {
            return months.last { $0.hasSuffix(String(format: "-%02d", i + 1)) }
        }
        return nil
    }

    static func percent(in q: String) -> Double? {
        guard let r = q.range(of: #"\d{1,3}\s?(%|percent)"#, options: .regularExpression) else { return nil }
        return Double(q[r].prefix { $0.isNumber }).flatMap { (1...100).contains($0) ? $0 : nil }
    }

    // MARK: answers computed in code

    enum Ask: Equatable {
        case whatIf(String, Double), afford(Double), safeToSpend, safeToSave, baskets, spender, lookup
        case whySave, howMuchSave, howSave, health
    }

    /// An amount in euros mentioned in a question, such as "300 €" or "1 200 eur".
    static func amount(in q: String) -> Double? {
        guard let r = q.lowercased().range(of: #"\d[\d ]*([.,]\d{1,2})?\s?(€|eur)"#, options: .regularExpression) else { return nil }
        let digits = q.lowercased()[r].filter { $0.isNumber || $0 == "," || $0 == "." }.replacingOccurrences(of: ",", with: ".")
        return Double(digits).flatMap { $0 > 0 ? $0 : nil }
    }

    private static func one(_ x: Double) -> String { String(format: "%.1f", x).replacingOccurrences(of: ".", with: ",") }

    /// What a question is asking for, when it is something this file can compute.
    func kind(of q: String, hint: String? = nil) -> Ask? {
        let t = q.lowercased()
        let parts = t.split { !$0.isLetter }.map(String.init)
        func has(_ p: String) -> Bool { parts.contains { $0.hasPrefix(p) } }
        // A follow-up keeps the subject of the earlier question; with none at all, eating out is the locked group.
        let own = Money.subject(of: q), ctx = Money.subject(of: q, hint: hint)
        let about = ctx.flatMap { s in s.category ?? tx.first(where: { $0.label == s.label })?.category } ?? "Restaurants"
        if let p = Money.percent(in: q) { return .whatIf(about, p) }
        if let a = Money.amount(in: q), has("afford") || has("buy") || has("purchas") || t.contains("can i") || t.contains("should i") { return .afford(a) }
        let less = t.contains("spend less") || t.contains("spending less")
        if !less, t.contains("safe to spend") || t.contains("safe for me to spend") || t.contains("can i spend") || t.contains("afford") { return .safeToSpend }
        if t.contains("safe to save") || t.contains("how much can i save") || t.contains("how much could i save") { return .safeToSave }
        if t.contains("basket") || t.contains("where does") || t.contains("money go") || t.contains("really go") { return .baskets }
        if t.contains("kind of spender") || t.contains("type of spender") || t.contains("spender am i") { return .spender }
        if own != nil, month(in: q) != nil || t.contains("how much") || t.contains("spend on") || t.contains("spent on") { return .lookup }
        if own == nil, ctx != nil, month(in: q) != nil { return .lookup }
        // Everyday questions about saving, however they are typed: why, how much, how.
        if has("sav") || has("buffer") || t.contains("emergency fund") || t.contains("put aside") || t.contains("rainy day") {
            if t.contains("how much") { return .howMuchSave }
            if has("how") || has("start") || has("tip") || has("build") { return .howSave }
            return .whySave
        }
        if has("cut") || has("reduc") || t.contains("spend less") || t.contains("cut down") || t.contains("cut back") { return .whatIf(about, 20) }
        if t.contains("how am i doing") || t.contains("am i ok") || t.contains("am i doing") || t.contains("good with money")
            || t.contains("financial health") || t.contains("my finances") || t.contains("my situation") { return .health }
        return nil
    }

    /// A complete answer with every figure computed here, or nil when the question is not one of these.
    func answer(_ q: String, hint: String? = nil) -> String? {
        guard let kind = kind(of: q, hint: hint) else { return nil }
        let e = Logic.eur
        switch kind {
        case .whatIf(let c, let p):
            let w = whatIf(c, cut: p)
            let after = w.leftOver >= 0
                ? "With that cut you would end a typical month \(e(w.leftOver)) ahead, which is your safe-to-save amount."
                : "You would still be \(e(-w.leftOver)) over in a typical month."
            return "You spend about \(e(average(c))) a month on \(c.lowercased()), averaged over the last six months. Cutting it by \(Int(p)) % keeps \(e(w.month)) a month, \(e(w.year)) a year. \(after)"
        case .afford(let a):
            if a > balance { return "A purchase of \(e(a)) is more than your balance of \(e(balance)), so it is not affordable right now without credit." }
            let weeks = a / max(safeToSpendWeek, 1)
            let verdict = a <= safeToSpendWeek
                ? "It fits inside one week's safe amount if the rest of that week stays quiet."
                : "It would come out of your reserve for irregular costs unless you spread it over \(Int(weeks.rounded(.up))) weeks of lighter everyday spending."
            return "You can pay \(e(a)) from your balance of \(e(balance)). It equals \(Money.one(weeks)) weeks of your safe everyday spending, which is \(e(safeToSpendWeek)) a week. \(verdict)"
        case .whySave:
            let big = biggestIrregular(1).first.map { ", and the largest was \($0.label.lowercased()) at \(e($0.out))" } ?? ""
            return "Because some costs cannot be planned. Over the last twelve months your irregular costs averaged \(e(average(.irregular))) a month\(big). Your balance of \(e(balance)) covers \(Money.one(bufferMonths)) months of fixed costs. Savings are what pay for the next surprise, so it does not come out of rent or food money."
        case .howMuchSave:
            let next = leftOver > 0 ? "You can safely put aside \(e(safeToSave)) a month."
                : "Everyday spending runs \(e(-leftOver)) a month over right now, so start by freeing \(e(whatIf("Restaurants", cut: 20).month)) a month from eating out."
            return "A common target is three months of fixed costs, which for you is \(e(average(.regular) * 3)). Your balance of \(e(balance)) covers \(Money.one(bufferMonths)) months. \(next)"
        case .howSave:
            return "Start in the everyday basket, because fixed costs barely move. Yours takes \(e(average(.everyday))) a month, and eating out is the easiest part to steer at \(e(average("Restaurants"))). Cutting it by 20 % frees \(e(whatIf("Restaurants", cut: 20).month)) a month. Move that amount to savings on payday, before the month can spend it."
        case .health:
            let net = leftOver >= 0 ? "\(e(leftOver)) ahead" : "\(e(-leftOver)) over"
            let buffer = bufferMonths >= 2 ? "That buffer is solid" : "That buffer is thin"
            return "You earn \(e(income)) a month and a typical month takes \(e(average(.regular))) in fixed costs, \(e(average(.irregular))) in irregular costs and \(e(average(.everyday))) in everyday spending. That leaves you \(net), with a balance covering \(Money.one(bufferMonths)) months of fixed costs. \(buffer); the everyday basket is where a small cut changes the result."
        case .safeToSpend:
            let over = leftOver < 0 ? " Your everyday spending has averaged \(e(average(.everyday) * 12 / 52)) a week, so you are \(e(-leftOver)) a month over." : ""
            return "About \(e(safeToSpendWeek)) a week is safe for everyday spending. That is your income of \(e(income)) a month, minus \(e(average(.regular))) of fixed costs and a \(e(average(.irregular))) reserve for irregular costs, spread over the weeks.\(over)"
        case .safeToSave:
            return leftOver > 0
                ? "You can safely save about \(e(safeToSave)) a month. That is what is left of your \(e(income)) income after fixed costs, the reserve for irregular costs and your usual everyday spending."
                : "Right now nothing is safely left to save: everyday spending runs \(e(-leftOver)) a month over what your income leaves after fixed costs and the reserve for irregular costs. Cutting eating out by 20 % would free \(e(whatIf("Restaurants", cut: 20).month)) a month."
        case .baskets:
            return "Of your \(e(income)) monthly income, \(e(average(.regular))) goes to fixed costs like rent and bills, about \(e(average(.irregular))) to irregular costs such as \(categories(.irregular).prefix(2).map { $0.lowercased() }.joined(separator: " and ")), and \(e(average(.everyday))) to everyday spending. The everyday basket is the one you can steer, and \(categories(.everyday).first?.lowercased() ?? "food") is the largest part of it."
        case .spender:
            let top = categories(.everyday).prefix(2).map { "\($0.lowercased()) \(e(average($0)))" }.joined(separator: " and ")
            let share = income > 0 ? Int((average(.everyday) / income * 100).rounded()) : 0
            return "You are an everyday spender: \(share) % of your income goes to small frequent payments, led by \(top) a month. Your fixed costs are modest at \(e(average(.regular))), so the room to save is in the everyday basket."
        case .lookup:
            guard let s = Money.subject(of: q, hint: hint) else { return nil }
            let m = month(in: q) ?? last
            let r = spent(in: m, category: s.category, label: s.label)
            let b = (s.category ?? tx.first { $0.label == s.label }?.category).flatMap(basket)
            let where_ = b.map { " That sits in your \($0.name.lowercased()) basket." } ?? ""
            return r.count == 0
                ? "You had no payments for \(s.say) in \(Money.name(m))."
                : "You spent \(e(r.total)) on \(s.say) in \(Money.name(m)), across \(r.count) \(r.count == 1 ? "payment" : "payments").\(where_)"
        }
    }

    // MARK: the fact sheet for the model

    func factSheet() -> String {
        let e = Logic.eur
        var l: [String] = []
        l.append("History covers \(Money.name(months.first ?? "")) to \(Money.name(last)). \"Last month\" means \(Money.name(last)). Account balance at the end of \(Money.name(last)): \(e(balance)).")
        l.append("Income: \(e(income)) a month on average (salary, last six months).")
        l.append("THE THREE BASKETS (monthly averages; say which basket a cost belongs to when it helps):")
        for b in Basket.allCases {
            l.append("- \(b.name): \(e(average(b))) a month. This basket \(b.explain). Categories: " + categories(b).map { "\($0) \(e(average($0)))" }.joined(separator: ", ") + ".")
        }
        l.append("Safe to spend on everyday things: \(e(safeToSpendWeek)) a week (\(e(everydayRoom)) a month) = income minus fixed costs minus the irregular reserve.")
        l.append(leftOver >= 0 ? "Safe to save: \(e(safeToSave)) a month after usual everyday spending."
                               : "Safe to save: nothing at the moment; everyday spending runs \(e(-leftOver)) a month over the safe amount.")
        l.append("These basket, safe-to-spend and safe-to-save figures are averages of a typical month over the last six months. They are not last month's figures; never present them as \"last month\".")
        l.append("The balance covers \(String(format: "%.1f", bufferMonths)) months of fixed costs.")
        l.append("Largest irregular costs in the last twelve months: " + biggestIrregular(5).map { "\($0.label) \(e($0.out)) on \($0.date)" }.joined(separator: "; ") + ".")
        l.append("SPENDING BY MONTH AND CATEGORY, total (payments):")
        let cats = Array(Set(tx.map(\.category))).filter { $0 != "Salary" }.sorted()
        for m in recent(12) {
            l.append("\(Money.name(m)): " + cats.compactMap { c in
                let r = spent(in: m, category: c)
                return r.count == 0 ? nil : "\(c) \(e(r.total)) (\(r.count))"
            }.joined(separator: ", "))
        }
        l.append("BY KIND OF PLACE, last three months, total (payments):")
        for m in recent(3) {
            let labels = Array(Set(tx.filter { $0.month == m && $0.out > 0 }.map(\.label))).sorted()
            l.append("\(Money.name(m)): " + labels.map { let r = spent(in: m, label: $0); return "\($0) \(e(r.total)) (\(r.count))" }.joined(separator: ", "))
        }
        l.append("WHAT-IF, cutting an everyday category (saving per month / per year / left over per month afterwards):")
        for c in categories(.everyday) {
            l.append("\(c): " + [10.0, 20, 30, 50].map { p in
                let w = whatIf(c, cut: p)
                return "\(Int(p)) % = \(e(w.month)) / \(e(w.year)) / \(e(w.leftOver))"
            }.joined(separator: "; "))
        }
        return l.joined(separator: "\n")
    }
}
