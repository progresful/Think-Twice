import SwiftUI

/// The savings coach chat. Opens over the skip result or the dashboard; the conversation is kept until the app restarts.
struct ChatView: View {
    @Environment(AppModel.self) private var m
    @State private var draft = ""
    @FocusState private var focused: Bool

    var body: some View {
        let c = m.chat
        VStack(spacing: 0) {
            header(c)
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(c.messages) { bubble($0).transition(.scale(scale: 0.9, anchor: $0.fromUser ? .bottomTrailing : .bottomLeading).combined(with: .opacity)) }
                        if c.typing {
                            TypingBubble().frame(maxWidth: .infinity, alignment: .leading).transition(.opacity)
                        }
                        if c.showChips { chips }
                        Color.clear.frame(height: 1).id("end")
                    }
                    .padding(.horizontal, 14).padding(.top, 12)
                    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: c.messages.count)
                    .animation(.easeInOut(duration: 0.2), value: c.typing)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: c.messages.count) { _, _ in withAnimation { proxy.scrollTo("end", anchor: .bottom) } }
                .onChange(of: c.typing) { _, _ in withAnimation { proxy.scrollTo("end", anchor: .bottom) } }
                .onChange(of: focused) { _, _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { withAnimation { proxy.scrollTo("end", anchor: .bottom) } }
                }
            }
            input(c)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gameBg.ignoresSafeArea())
        .onAppear { if c.focusOnOpen { focused = true } }
    }

    private func header(_ c: ChatStore) -> some View {
        HStack(spacing: 12) {
            Image("Mark").resizable().frame(width: 38, height: 38).clipShape(Circle()).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text("Savings coach").font(.system(size: 17, weight: .semibold))
                Text(c.live ? "Live model, grounded in your payments" : c.problem.map { "On-device reply. Model: \($0)" } ?? "Answers use your payment data")
                    .sub(12).lineLimit(2)
            }
            Spacer()
            Button { focused = false; m.chat.open = false } label: {
                Image(systemName: "xmark").font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
                    .frame(width: 34, height: 34).background(Color.track, in: Circle())
            }
            .accessibilityLabel("Close chat")
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .overlay(alignment: .bottom) { Rectangle().fill(Color.hairline).frame(height: 0.5) }
    }

    @ViewBuilder private func bubble(_ msg: ChatMessage) -> some View {
        text(msg)
        if let w = msg.whatIf { WhatIfCard(start: w).frame(maxWidth: .infinity, alignment: .leading) }
    }

    private func text(_ msg: ChatMessage) -> some View {
        Text(msg.text).font(.system(size: 16)).lineSpacing(2)
            .foregroundStyle(msg.fromUser ? Color.limeInk : .white)
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(msg.fromUser ? Color.lime : Color.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .frame(maxWidth: 310, alignment: msg.fromUser ? .trailing : .leading)
            .frame(maxWidth: .infinity, alignment: msg.fromUser ? .trailing : .leading)
    }

    private var chips: some View {
        VStack(alignment: .trailing, spacing: 8) {
            ForEach(ChatStore.chips, id: \.self) { q in
                Button { m.ask(q) } label: {
                    Text(q).font(.system(size: 15, weight: .medium)).foregroundStyle(Color.lime)
                        .padding(.horizontal, 14).padding(.vertical, 9)
                        .overlay(Capsule().stroke(Color.lime.opacity(0.5), lineWidth: 1))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing).padding(.top, 6)
        .transition(.opacity)
    }

    private func input(_ c: ChatStore) -> some View {
        let empty = draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return VStack(spacing: 6) {
            HStack(alignment: .bottom, spacing: 8) {
                TextField("Ask about your spending", text: $draft, axis: .vertical)
                    .font(.system(size: 16)).lineLimit(1...4).focused($focused)
                    .submitLabel(.send)
                    .onChange(of: draft) { _, v in if v.hasSuffix("\n") { draft = String(v.dropLast()); send() } }
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(Color.card, in: RoundedRectangle(cornerRadius: 21, style: .continuous))
                Button(action: send) {
                    Image(systemName: "arrow.up").font(.system(size: 16, weight: .heavy)).foregroundStyle(Color.limeInk)
                        .frame(width: 40, height: 40).background(Color.lime, in: Circle())
                }
                .disabled(empty || c.typing).opacity(empty || c.typing ? 0.35 : 1)
                .accessibilityLabel("Send")
            }
            Text("Figures are computed from your transactions. Not financial advice.").font(.system(size: 11)).foregroundStyle(Color.sub)
        }
        .padding(.horizontal, 12).padding(.top, 8).padding(.bottom, 6)
    }

    private func send() {
        guard !m.chat.typing else { return }
        m.ask(draft)
        draft = ""
    }
}

/// An answer the customer can keep adjusting: a slider for how much to cut, with the saving recomputed in code.
private struct WhatIfCard: View {
    let start: WhatIf
    @State private var percent: Double

    init(start: WhatIf) {
        self.start = start
        _percent = State(initialValue: start.percent)
    }

    var body: some View {
        let money = Money.bundled
        let w = money.whatIf(start.category, cut: percent)
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(start.category), cut by").font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.sub)
                Spacer()
                Text("\(Int(percent)) %").font(.system(size: 15, weight: .heavy)).foregroundStyle(Color.lime)
            }
            Slider(value: $percent, in: 0...100, step: 5).tint(.lime)
                .accessibilityLabel("Cut \(start.category) by")
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Kept a month").font(.system(size: 12)).foregroundStyle(Color.sub)
                    Text(Logic.eur(w.month)).font(.system(size: 24, weight: .heavy)).contentTransition(.numericText())
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("A year").font(.system(size: 12)).foregroundStyle(Color.sub)
                    Text(Logic.eur(w.year)).font(.system(size: 17, weight: .bold)).contentTransition(.numericText())
                }
            }
            Text(w.leftOver >= 0 ? "Safe to save: \(Logic.eur(w.leftOver)) a month" : "Still \(Logic.eur(-w.leftOver)) a month over")
                .font(.system(size: 13, weight: .semibold)).foregroundStyle(w.leftOver >= 0 ? Color.lime : Color.sub)
        }
        .animation(.snappy(duration: 0.2), value: percent)
        .padding(14).frame(maxWidth: 310)
        .background(Color.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.lime.opacity(0.35), lineWidth: 1))
    }
}

/// Three pulsing dots, as in Messages, while the coach is writing.
private struct TypingBubble: View {
    var body: some View {
        TimelineView(.animation) { t in
            let time = t.date.timeIntervalSinceReferenceDate
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    let wave = (sin(time * 5.5 - Double(i) * 0.9) + 1) / 2
                    Circle().fill(.white).frame(width: 8, height: 8)
                        .opacity(0.3 + 0.6 * wave).offset(y: -3 * wave)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 15)
            .background(Color.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .accessibilityLabel("The coach is writing")
    }
}

/// The dashboard entry to the chat: looks like a message field, with a lime light travelling around its border.
struct AskField: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles").font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.lime)
                Text("Ask how to grow your savings").font(.system(size: 16)).foregroundStyle(Color.sub)
                Spacer(minLength: 0)
                Image(systemName: "arrow.up").font(.system(size: 13, weight: .heavy)).foregroundStyle(Color.limeInk)
                    .frame(width: 30, height: 30).background(Color.lime, in: Circle())
            }
            .padding(.leading, 16).padding(.trailing, 8).frame(height: 48)
            .background(Color.card, in: Capsule())
            .overlay { GlowBorder().allowsHitTesting(false) }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Ask the savings coach how to grow your savings")
    }
}

/// The travelling light on the Ask field. The gradient is spun by a transform and shown through the capsule's outline,
/// and the soft glow is drawn once, so scrolling the list behind it stays smooth.
private struct GlowBorder: View {
    @State private var turn = false

    var body: some View {
        let light = AngularGradient(stops: [.init(color: .lime.opacity(0.15), location: 0), .init(color: .lime, location: 0.2),
                                            .init(color: .lime.opacity(0.15), location: 0.45), .init(color: .lime.opacity(0.15), location: 1)],
                                    center: .center)
        ZStack {
            Capsule().stroke(Color.lime.opacity(0.35), lineWidth: 4).blur(radius: 6).drawingGroup()
            GeometryReader { g in
                let side = max(g.size.width, g.size.height) * 1.3
                Rectangle().fill(light).frame(width: side, height: side)
                    .rotationEffect(.degrees(turn ? 360 : 0))
                    .position(x: g.size.width / 2, y: g.size.height / 2)
                    .mask(Capsule().strokeBorder(lineWidth: 1.5))
            }
        }
        .onAppear { withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) { turn = true } }
    }
}
