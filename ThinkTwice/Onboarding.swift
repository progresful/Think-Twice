import SwiftUI

struct OnboardingView: View {
    @Environment(AppModel.self) private var m

    var body: some View {
        VStack(spacing: 0) {
            if m.step > 0 { nav }
            Group {
                switch m.step {
                case 0: WelcomeStep()
                case 1: BankStep()
                case 2: ApproveStep()
                case 3: ReadingStep()
                case 4: StrictStep()
                default: CardStep()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .id(m.step)
            .transition(.asymmetric(insertion: .offset(x: 18).combined(with: .opacity), removal: .identity))
        }
        .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 4)
        .background(Color.black.ignoresSafeArea())
        .animation(.easeOut(duration: 0.35), value: m.step)
    }

    private var nav: some View {
        HStack(spacing: 0) {
            Button { m.back() } label: {
                Image(systemName: "chevron.left").font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                    .frame(width: 34, height: 34).background(Color.card, in: Circle())
            }
            .accessibilityLabel("Back")
            .opacity(m.step == 3 ? 0 : 1).disabled(m.step == 3)
            HStack(spacing: 5) {
                // Without the bank picker there is one step fewer.
                ForEach(1...(m.bankPicker ? 5 : 4), id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2).fill(i <= (m.bankPicker ? m.step : m.step - 1) ? Color.lime : Color.track)
                        .frame(width: 22, height: 4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.trailing, 34)
        }
        .frame(height: 34).padding(.bottom, 14)
    }
}

private struct WelcomeStep: View {
    @Environment(AppModel.self) private var m
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                Image("Mark").resizable().frame(width: 96, height: 96).clipShape(Circle()).padding(.bottom, 14)
                    .accessibilityHidden(true)
                Text("Think Twice").font(.system(size: 52, weight: .heavy)).tracking(-2)
                Text("A moment before you pay.").sub(19)
            }
            .frame(maxHeight: .infinity)
            Text("A reminder on the spending that stacks up. Pay after a short game, or skip and save.")
                .sub().multilineTextAlignment(.center).padding(.bottom, 22)
            Button("Start") { m.next() }.buttonStyle(Btn())
        }
    }
}

private struct BankStep: View {
    @Environment(AppModel.self) private var m
    @State private var q = ""

    var body: some View {
        let found = Logic.banks.filter { q.isEmpty || $0.lowercased().contains(q.lowercased()) }
        VStack(spacing: 0) {
            Text("Pick your bank").h1()
            TextField("", text: $q, prompt: Text("Search").foregroundStyle(Color.white.opacity(0.4)))
                .font(.system(size: 17)).autocorrectionDisabled().textInputAutocapitalization(.never)
                .accessibilityLabel("Search banks")
                .padding(.horizontal, 16).padding(.vertical, 13)
                .background(Color.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.top, 16).padding(.bottom, 10)
            ScrollView {
                VStack(spacing: 0) {
                    if found.isEmpty {
                        Text("No bank found. Check the spelling.").sub()
                            .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 14)
                    }
                    ForEach(Array(found.enumerated()), id: \.element) { i, b in
                        if i > 0 { Rectangle().fill(Color.hairline).frame(height: 0.5) }
                        Button { m.pick(bank: b) } label: {
                            HStack(spacing: 12) {
                                Text(String(b.prefix(1))).font(.system(size: 15, weight: .bold))
                                    .frame(width: 36, height: 36)
                                    .background(Color.track, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                Text(b).font(.system(size: 17, weight: .medium))
                                Spacer(minLength: 0)
                            }
                            .foregroundStyle(.white).padding(.vertical, 13).contentShape(Rectangle())
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
            .frame(maxHeight: .infinity)
            .background(Color.card)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }
}

private struct ApproveStep: View {
    @Environment(AppModel.self) private var m
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Approve at \(m.bank ?? "")").h1()
            Text("You sign in on their page, not here.").sub().padding(.top, 8)
            Facts(items: ["Reads accounts, balances and payments", "Cannot move money", "Access ends after 180 days"])
                .padding(.top, 22)
            Spacer(minLength: 0)
            Button("Continue to bank") { m.bankSheet = true }.buttonStyle(Btn())
        }
    }
}

struct BankSheet: View {
    @Environment(AppModel.self) private var m
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(m.bank ?? "").font(.system(size: 13, weight: .semibold)).tracking(0.4)
                .textCase(.uppercase).foregroundStyle(Color.bankSub)
            Text("Share payment data").font(.system(size: 28, weight: .bold)).tracking(-0.5)
                .padding(.top, 4).padding(.bottom, 6)
            Text("Think Twice asks to read your account.").font(.system(size: 15)).foregroundStyle(Color.bankSub)
            Facts(items: ["Accounts, balances and payments", "Read only", "Until May 13, 2027"],
                  bg: .white, line: .black.opacity(0.1), icon: .bankGreen)
                .padding(.top, 22)
            Spacer(minLength: 0)
            Button("Approve") { m.approve() }
                .buttonStyle(Btn(bg: Color(white: 0x11 / 255.0), fg: .white))
            Button("Decline") { m.bankSheet = false }
                .buttonStyle(Btn(bg: .clear, fg: Color.bankInk.opacity(0.6), pad: 13))
            Demo(text: "Demo: no bank is contacted.", color: .bankSub).frame(maxWidth: .infinity)
        }
        .foregroundStyle(Color.bankInk)
        .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bankBg.ignoresSafeArea())
    }
}

private struct ReadingStep: View {
    @Environment(AppModel.self) private var m
    @State private var count = 0
    @State private var sorted = false
    @State private var spin = false

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().stroke(Color.track, lineWidth: 8)
                Circle().trim(from: 0, to: 0.25).stroke(Color.lime, lineWidth: 8)
                    .rotationEffect(.degrees(spin ? 225 : -135))
            }
            .frame(width: 112, height: 112).padding(4).padding(.bottom, 22)
            Text("\(count)").num(56)
            Text(sorted ? "payments sorted" : "payments read").sub()
        }
        .frame(maxHeight: .infinity)
        .onAppear { withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) { spin = true } }
        .task {
            let speed = min(m.ease, 4), dur = 1.8 / speed, t0 = Date()
            while true {
                let k = min(1, Date().timeIntervalSince(t0) / dur)
                count = Logic.round(Double(m.data.read) * k)
                if k >= 1 { break }
                try? await Task.sleep(nanoseconds: 30_000_000)
            }
            sorted = true
            try? await Task.sleep(nanoseconds: UInt64(0.7 / speed * 1e9))
            if !Task.isCancelled, m.step == 3 { m.step = 4 }
        }
    }
}

private struct StrictStep: View {
    @Environment(AppModel.self) private var m

    var body: some View {
        let d = m.data, t = m.tier
        VStack(alignment: .leading, spacing: 0) {
            Text("You could save up to").sub()
            Text(Logic.eur(Logic.couldSave(t, d))).num(76).foregroundStyle(Color.lime)
                .lineLimit(1).minimumScaleFactor(0.6)
                .padding(.top, 8).padding(.bottom, 6)
            Text("a month on \(d.type.lowercased()). \(d.before.count) payments in \(d.beforeMonth): \(Logic.eur(Logic.sum(d.before))).").sub()
            Text("How hard to pay?").sub().padding(.top, 36)
            Text(t.name).font(.system(size: 38, weight: .heavy)).tracking(-1.1).foregroundStyle(Color.lime)
                .frame(maxWidth: .infinity, minHeight: 82, alignment: .topLeading).padding(.top, 6)
            TierSlider().padding(.top, 8).padding(.bottom, 2)
            HStack {
                Text(Tier.all[0].name)
                Spacer()
                Text(Tier.all[5].name)
            }
            .sub(12).padding(.bottom, 18)
            Text(Logic.limitText(t, d) + (t.len > 0 ? " Games: \(t.games.lowercased())." : "")).sub()
            Spacer(minLength: 0)
            Button("Save") { m.next() }.buttonStyle(Btn())
        }
    }
}

private struct TierSlider: View {
    @Environment(AppModel.self) private var m

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, x = 17 + (w - 34) * CGFloat(m.tierIndex) / 5
            ZStack(alignment: .leading) {
                Capsule().fill(Color.track).frame(height: 10)
                Capsule().fill(Color.lime).frame(width: x, height: 10)
                Circle().fill(.white).frame(width: 34, height: 34)
                    .shadow(color: .black.opacity(0.5), radius: 5, y: 2)
                    .offset(x: x - 17)
            }
            .frame(height: 44)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { v in
                let t = Int(((v.location.x - 17) / (w - 34) * 5).rounded())
                m.tierIndex = min(5, max(0, t))
            })
        }
        .frame(height: 44)
        .accessibilityElement()
        .accessibilityLabel("How hard to pay")
        .accessibilityValue(m.tier.name)
        .accessibilityAdjustableAction { dir in
            m.tierIndex = min(5, max(0, m.tierIndex + (dir == .increment ? 1 : -1)))
        }
    }
}

private struct CardStep: View {
    @Environment(AppModel.self) private var m
    @State private var shown = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Add your card").h1()
            Text("Payments on this card can trigger a reminder. Your bank card stays as it is.").sub().padding(.top, 8)
            VStack(alignment: .leading) {
                HStack {
                    Text("Think Twice").font(.system(size: 20, weight: .heavy)).tracking(-0.4)
                    Spacer()
                    Image(systemName: "bell").font(.system(size: 19, weight: .semibold))
                }
                Spacer()
                Text("•••• •••• •••• \(String(m.data.customer.suffix(4)))")
                    .font(.system(size: 15, design: .monospaced)).tracking(1.8).opacity(0.7)
            }
            .foregroundStyle(Color.limeInk)
            .padding(20)
            .frame(maxWidth: .infinity).aspectRatio(1.586, contentMode: .fit)
            .background(Color.lime, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Color.lime.opacity(0.18), radius: 25, y: 20)
            .scaleEffect(shown ? 1 : 0.9).offset(y: shown ? 0 : 14).opacity(shown ? 1 : 0)
            .padding(.top, 24)
            Spacer(minLength: 0)
            Button("Add to Wallet") { m.addToWallet() }.buttonStyle(Btn(bg: .white, fg: .black))
            Demo(text: "Demo: no card is issued.").frame(maxWidth: .infinity)
        }
        .onAppear { withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { shown = true } }
    }
}
