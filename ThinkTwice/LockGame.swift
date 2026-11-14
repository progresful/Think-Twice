import Combine
import SwiftUI
import UIKit

// MARK: waiting for the real notification

struct WaitingView: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("Payment sent").font(.system(size: 34, weight: .heavy)).tracking(-1)
            Text("The alert arrives in 4 seconds. Lock the phone to see it on the Lock Screen.")
                .sub().multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gameBg.ignoresSafeArea())
    }
}

// MARK: drawn lock screen (fallback)

struct LockScreenView: View {
    @Environment(AppModel.self) private var m
    @State private var dropped = false

    var body: some View {
        VStack(spacing: 0) {
            if let p = m.session.current {
                Text(p.longDate).font(.system(size: 20, weight: .semibold)).opacity(0.85)
                Text(p.time).num(96, weight: .semibold).padding(.top, 2)
                Spacer(minLength: 0)
                Button { m.openGame() } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "lock").font(.system(size: 18, weight: .semibold)).foregroundStyle(Color.limeInk)
                            .frame(width: 40, height: 40)
                            .background(Color.lime, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Text("Card locked").font(.system(size: 15, weight: .semibold))
                                Spacer()
                                Text("now").font(.system(size: 13)).opacity(0.6)
                            }
                            Text(m.session.alertBody ?? "").font(.system(size: 15))
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(14)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
                .buttonStyle(.plain)
                .scaleEffect(dropped ? 1 : 0.96).offset(y: dropped ? 0 : -24).opacity(dropped ? 1 : 0)
                .padding(.bottom, 62)
            }
        }
        .padding(.horizontal, 12).padding(.top, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RadialGradient(stops: [.init(color: Color(red: 0x24 / 255, green: 0x46 / 255, blue: 0x3A / 255), location: 0),
                                   .init(color: Color(red: 0x0C / 255, green: 0x15 / 255, blue: 0x12 / 255), location: 0.6),
                                   .init(color: Color(red: 0x05 / 255, green: 0x08 / 255, blue: 0x07 / 255), location: 1)],
                           center: .top, startRadius: 0, endRadius: 700)
                .ignoresSafeArea()
        )
        .onAppear { withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.35)) { dropped = true } }
    }
}

// MARK: game and result

struct GameLayer: View {
    @Environment(AppModel.self) private var m

    var body: some View {
        Group {
            if let o = m.outcome {
                ResultView(o: o)
            } else if let p = m.session.current, let e = m.session.effort {
                GameView(p: p, effort: e).id(m.session.i)
            }
        }
        .padding(.horizontal, 24).padding(.top, 16).padding(.bottom, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gameBg.ignoresSafeArea())
    }
}

private struct GameView: View {
    @Environment(AppModel.self) private var m
    let p: Payment
    let effort: Effort
    @State private var unlocked = false

    var body: some View {
        VStack(spacing: 0) {
            Text("Card locked").font(.system(size: 13, weight: .semibold)).tracking(0.8)
                .textCase(.uppercase).opacity(0.6)
            Text(Logic.eur(p.amount)).num(56).padding(.top, 8)
            Text(p.label).font(.system(size: 17, weight: .semibold)).padding(.top, 6)
            Text(m.session.runningLine).sub()
            Group {
                if effort.kind == .type {
                    SayPad(line: m.session.sentence(ease: m.ease)) { unlocked = true }
                } else {
                    RingPad(kind: effort.kind, goal: effort.goal) { unlocked = true }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            Text(effort.kind.name).font(.system(size: 15, weight: .semibold))
            Text(unlocked ? "Tap your card again. Open until \(p.openUntil)." : effort.kind.rule)
                .font(.system(size: 13)).opacity(0.55).multilineTextAlignment(.center)
                .padding(.top, 2).padding(.bottom, 18)
            Button("Skip and save \(Logic.eur(p.amount))") { m.finish(skip: true) }.buttonStyle(Btn())
            if unlocked {
                Button("Pay \(Logic.eur(p.amount))") { m.finish(skip: false) }
                    .buttonStyle(Btn(bg: .white.opacity(0.12), fg: .white)).padding(.top, 10)
            }
        }
    }
}

/// Tap it out and Hold on: one ring, one count.
private struct RingPad: View {
    let kind: GameKind
    let goal: Int
    let onWin: () -> Void
    @State private var left: Double
    @State private var down = false
    @State private var done = false
    @State private var t0: Date?
    @State private var nag: Int?
    private let timer = Timer.publish(every: 0.04, on: .main, in: .common).autoconnect()

    init(kind: GameKind, goal: Int, onWin: @escaping () -> Void) {
        self.kind = kind
        self.goal = goal
        self.onWin = onWin
        _left = State(initialValue: Double(goal))
        if kind == .hold, let n = UserDefaults.standard.object(forKey: "nag") as? Int ?? Int(UserDefaults.standard.string(forKey: "nag") ?? "") {
            _nag = State(initialValue: n)
            _left = State(initialValue: Double(goal) - Double(n) * 2.2 - 1)
            _down = State(initialValue: true)
        }
    }

    /// Shown one after another while the user holds on.
    static let nags = [
        "This is a poor choice.",
        "Your kids will not be happy.",
        "Your future is getting gray.",
        "There is food at home.",
        "Your savings just sighed.",
        "Future you is watching this.",
        "Still holding. Still a bad idea.",
        "Retirement moved one day further.",
    ]

    var body: some View {
        VStack(spacing: 14) {
            if kind == .hold {
                ZStack {
                    if let nag {
                        Text(Self.nags[nag % Self.nags.count])
                            .font(.system(size: 20, weight: .bold)).tracking(-0.3)
                            .foregroundStyle(Color.white.opacity(max(0.4, 1 - Double(nag) * 0.1)))
                            .multilineTextAlignment(.center)
                            .id(nag)
                            .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity),
                                                    removal: .move(edge: .top).combined(with: .opacity)))
                    }
                }
                .frame(maxWidth: .infinity).frame(height: 52).clipped()
                .animation(.easeOut(duration: 0.35), value: nag)
            }
            ring
            if kind == .hold { Color.clear.frame(height: 52) }
        }
    }

    private var ring: some View {
        ZStack {
            Circle().stroke(Color.track, lineWidth: 10).frame(width: 204, height: 204)
            Circle().trim(from: 0, to: 1 - left / Double(goal))
                .stroke(Color.lime, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90)).frame(width: 204, height: 204)
            Circle().fill(Color.white.opacity(down ? 0.16 : 0.08)).frame(width: 180, height: 180)
                .scaleEffect(down ? 0.94 : 1).animation(.easeOut(duration: 0.08), value: down)
            VStack(spacing: 6) {
                Text("\(Int(left.rounded(.up)))").num(60)
                Text(done ? "Unlocked" : kind.unit).font(.system(size: 15)).opacity(0.6)
            }
        }
        .frame(width: 224, height: 224)
        .contentShape(Circle())
        .overlay(TouchPad(onDown: press, onUp: release).clipShape(Circle()))
        .onReceive(timer) { now in
            guard kind == .hold, down, !done, let t0 else { return }
            let held = now.timeIntervalSince(t0), v = Double(goal) - held
            if v <= 0 { win() } else { left = v; nag = Int(held / 2.2) }
        }
        .accessibilityElement()
        .accessibilityLabel(kind.name)
        .accessibilityAddTraits(.isButton)
    }

    private func press() {
        guard !done else { return }
        down = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if kind == .tap {
            left -= 1
            if left <= 0 { win() }
        } else {
            t0 = Date()
            nag = 0
        }
    }

    private func release() {
        down = false
        guard !done else { return }
        if kind == .hold { t0 = nil; nag = nil; left = Double(goal) }
    }

    private func win() {
        left = 0
        done = true
        down = false
        nag = nil
        onWin()
    }
}

/// Say it: type the sentence; the matched prefix turns lime.
private struct SayPad: View {
    let line: String
    let onWin: () -> Void
    @State private var text = ""
    @State private var matched = 0
    @State private var done = false
    @FocusState private var focus: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            (Text(String(line.prefix(matched))).foregroundColor(.lime)
             + Text(String(line.dropFirst(matched))).foregroundColor(.white.opacity(0.35)))
                .font(.system(size: 24, weight: .bold)).tracking(-0.5)
                .frame(maxWidth: .infinity, alignment: .leading)
            TextField("", text: $text, prompt: Text("Type here").foregroundStyle(Color.white.opacity(0.4)))
                .font(.system(size: 17))
                .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.asciiCapable)
                .focused($focus).disabled(done)
                .accessibilityLabel(GameKind.type.name)
                .padding(16)
                .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .onChange(of: text) { old, new in
            // No pasting: a change may add one character at most.
            if new.count > old.count + 1 { text = old; return }
            let a = Array(new.lowercased()), b = Array(line.lowercased())
            var n = 0
            while n < a.count && n < b.count && a[n] == b[n] { n += 1 }
            matched = n
            if n == b.count && a.count == b.count {
                done = true
                focus = false
                onWin()
            }
        }
    }
}

private struct ResultView: View {
    @Environment(AppModel.self) private var m
    let o: Outcome
    @State private var shown = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Image(systemName: "checkmark").font(.system(size: 34, weight: .heavy))
                    .foregroundStyle(o.skip ? Color.limeInk : .white)
                    .frame(width: 84, height: 84)
                    .background(o.skip ? Color.lime : Color.track, in: Circle())
                    .scaleEffect(shown ? 1 : (o.skip ? 0.4 : 0.9)).opacity(shown ? 1 : 0)
                    .padding(.bottom, 14)
                Text(o.skip ? "\(Logic.eur(o.amount)) saved" : "Paid \(Logic.eur(o.amount))").num(34)
                Text(o.line).font(.system(size: 17)).opacity(0.65)
                    .multilineTextAlignment(.center).frame(maxWidth: 250)
                if !o.skip {
                    Text("Card locked again.").sub().padding(.top, 2)
                }
                if let level = o.newLevel {
                    Pill(text: "New level: \(level)", kind: .lime).padding(.top, 6)
                }
            }
            .frame(maxHeight: .infinity)
            if o.skip {
                Button("How to save even more") { m.openChat() }
                    .buttonStyle(Btn(bg: Color.track, fg: .white)).padding(.bottom, 10)
            }
            Button(o.skip ? "Thanks, I'm the best" : "Done") { m.closeGame() }.buttonStyle(Btn())
        }
        .overlay { if o.skip { Confetti().ignoresSafeArea().allowsHitTesting(false) } }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: o.skip ? 0.4 : 0.6)) { shown = true }
            if o.skip { UINotificationFeedbackGenerator().notificationOccurred(.success) }
        }
    }
}

/// Raw touch-down and touch-up, so fast taps are never lost to gesture recognition.
private struct TouchPad: UIViewRepresentable {
    let onDown: () -> Void
    let onUp: () -> Void

    func makeUIView(context: Context) -> PadView { PadView() }
    func updateUIView(_ view: PadView, context: Context) {
        view.onDown = onDown
        view.onUp = onUp
    }

    final class PadView: UIView {
        var onDown: () -> Void = {}
        var onUp: () -> Void = {}
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { onDown() }
        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { onUp() }
        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { onUp() }
    }
}
