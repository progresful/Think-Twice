import SwiftUI
import UserNotifications

@Observable
final class AppModel {
    static let shared = AppModel()

    enum Layer: Equatable { case none, waiting, lockScreen, game, skipped, noNo }

    let data = DemoData.bundled
    let ease: Double                 // -fast: 10, as #fast in the HTML
    /// Inside the bank's own app the bank is known, so the picker is skipped. Launch with -bank to include it.
    let bankPicker: Bool
    /// The no-no list: "Group/Place type" keys that are locked. By default we pick the locked group ourselves.
    var noNo: Set<String>
    private var noNoAtOpen: Set<String> = []

    // onboarding
    var onboarding = true
    var step = 0                     // welcome, bank, approve, reading, strict, card
    var bank: String?
    var tierIndex = 3
    var bankSheet = false

    // session
    var session: Session
    var layer: Layer = .none
    var outcome: Outcome?
    let chat = ChatStore()
    private var due: Date?

    init() {
        _ = ClaudeClient.key      // read at launch, so a key passed once is remembered even if the chat is not opened
        let args = ProcessInfo.processInfo.arguments
        ease = args.contains("-fast") ? 10 : 1
        bankPicker = args.contains("-bank")
        if !bankPicker { bank = Logic.banks[0] }
        let d = DemoData.bundled
        let picked = d.categories.first { $0.name == d.type }
        noNo = Set(picked?.items.map { "\(d.type)/\($0.label)" } ?? [])
        session = Session(data: data, tier: Tier.all[3])
        // -tier N picks the strictness, -skips N starts with the first N locked payments already skipped. For screenshots.
        if let t = Int(UserDefaults.standard.string(forKey: "tier") ?? ""), Tier.all.indices.contains(t) { tierIndex = t; start(); onboarding = true }
        let n = UserDefaults.standard.integer(forKey: "skips")
        if n > 0 {
            let q = session.queue.prefix(n)
            session.skipped = n
            session.saved = Logic.sum(Array(q)) + Logic.sum(data.payments) / Double(max(data.payments.count, 1)) * Double(n - q.count)
        }
        if args.contains("-dash") { onboarding = false }
        if let n = Int(UserDefaults.standard.string(forKey: "step") ?? "") { onboarding = true; step = n }   // -step N opens that setup screen
        // -nag N opens the hold game frozen on its Nth line. For screenshots.
        if args.contains("-nag") { tierIndex = 5; start(); layer = .lockScreen; openGame() }
        // -chat opens the coach at launch; -ask "question" then sends one question. For demos and screenshots.
        if args.contains("-chat") {
            DispatchQueue.main.async {
                self.onboarding = false
                self.openChat()
                if let q = UserDefaults.standard.string(forKey: "ask") {
                    self.askWhenReady(q)
                }
            }
        }
    }

    var tier: Tier { Tier.all[tierIndex] }

    // MARK: onboarding

    func next() { step = step == 0 && !bankPicker ? 2 : step + 1 }
    func back() { step = step == 4 ? 2 : step == 2 && !bankPicker ? 0 : step - 1 }
    func pick(bank b: String) { bank = b; step = 2 }
    func approve() { bankSheet = false; step = 3 }

    func addToWallet() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in
            DispatchQueue.main.async { self.start() }
        }
    }

    func start() {
        session = Session(data: data, tier: tier, enabled: enabledLabels)
        outcome = nil
        layer = .none
        onboarding = false
    }

    func restart() {
        tierIndex = 3
        step = 0
        chat.reset()
        onboarding = true
    }

    // MARK: no-no list

    private func key(_ c: Category, _ item: Category.Item) -> String { "\(c.name)/\(item.label)" }
    func isOn(_ c: Category, _ item: Category.Item) -> Bool { noNo.contains(key(c, item)) }
    func onCount(_ c: Category) -> Int { c.items.filter { isOn(c, $0) }.count }
    func set(_ c: Category, _ item: Category.Item, on: Bool) {
        if on { noNo.insert(key(c, item)) } else { noNo.remove(key(c, item)) }
    }
    func set(_ c: Category, on: Bool) { c.items.forEach { set(c, $0, on: on) } }

    /// Place types of the replayed group that are locked.
    var enabledLabels: Set<String> {
        let c = data.categories.first { $0.name == data.type }
        return Set(c?.items.filter { isOn(c!, $0) }.map(\.label) ?? [])
    }

    func openNoNo() { noNoAtOpen = noNo; layer = .noNo }

    /// A changed list restarts the month's replay with the new locks.
    func closeNoNo() {
        if noNo != noNoAtOpen {
            session = Session(data: data, tier: session.tier, enabled: enabledLabels)
            outcome = nil
        }
        layer = .none
    }

    // MARK: lock alert

    func nextPayment() {
        guard let body = session.alertBody else { return }
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { s in
            DispatchQueue.main.async {
                switch s.authorizationStatus {
                case .authorized, .provisional, .ephemeral:
                    self.schedule(body)
                case .notDetermined:
                    center.requestAuthorization(options: [.alert, .sound]) { ok, _ in
                        DispatchQueue.main.async { if ok { self.schedule(body) } else { self.layer = .lockScreen } }
                    }
                default:
                    self.layer = .lockScreen
                }
            }
        }
    }

    private func schedule(_ body: String) {
        let content = UNMutableNotificationContent()
        content.title = "Think twice"
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: "card-locked", content: content,
                                            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 4, repeats: false))
        UNUserNotificationCenter.current().add(request)
        due = Date().addingTimeInterval(4)
        layer = .waiting
        // The banner stays about five seconds; the drawn lock screen follows it, so the flow never dead-ends.
        DispatchQueue.main.asyncAfter(deadline: .now() + 9.5) { self.alertDue() }
    }

    /// Called when the banner has gone, or when the app comes back to the front after the alert was delivered.
    func alertDue() {
        guard layer == .waiting, let due, Date() >= due,
              UIApplication.shared.applicationState == .active else { return }
        layer = .lockScreen
    }

    // MARK: game, result

    func openGame() {
        guard layer == .waiting || layer == .lockScreen, !session.ended else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["card-locked"])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["card-locked"])
        session.effort = session.effort(ease: ease)
        outcome = nil
        layer = .game
    }

    func finish(skip: Bool) {
        outcome = session.finish(skip: skip)
    }

    func closeGame() { layer = .none }

    // MARK: savings coach

    /// From the skip result the coach knows what was just kept; from the dashboard the field opens ready to type.
    func openChat(focus: Bool = false) {
        let kept = layer == .game && outcome?.skip == true ? outcome?.amount : nil
        chat.show(data, session, afterSkip: kept, focus: focus)
    }

    func ask(_ text: String) { chat.send(text, data, session) }

    /// Sends a question once the coach has finished its opening message, with a pause a viewer can follow.
    private func askWhenReady(_ q: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.chat.typing || self.chat.messages.isEmpty { self.askWhenReady(q) }
            else { DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.ask(q) } }
        }
    }
}
