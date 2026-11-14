import SwiftUI

struct DashboardView: View {
    @Environment(AppModel.self) private var m

    var body: some View {
        let s = m.session, d = m.data, cur = s.level
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Think Twice").font(.system(size: 19, weight: .heavy)).tracking(-0.4)
                        Spacer()
                        Pill(text: d.month)
                    }
                    .padding(.horizontal, 4)
                    Text(cur < 5 ? "\(s.need) more \(s.need == 1 ? "skip" : "skips") to move up." : "Top level reached.")
                        .sub().padding(.horizontal, 4).padding(.top, 8)
                    ladder(cur)
                    if s.skipped > 0 {
                        Button { m.layer = .skipped } label: {
                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Saved by skipping").font(.system(size: 13, weight: .semibold)).opacity(0.75)
                                Text(Logic.eur(s.saved)).num(28)
                            }
                            Spacer()
                            Text("\(s.skipped) \(s.skipped == 1 ? "purchase" : "purchases") skipped")
                                .font(.system(size: 13, weight: .semibold)).opacity(0.75)
                        }
                        .foregroundStyle(Color.limeInk)
                        .padding(16)
                        .background(Color.lime, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                    Button { m.openChat(focus: false) } label: { MoneyCard(money: .bundled) }.buttonStyle(.plain)
                    sec("Locked")
                    Button { m.openNoNo() } label: {
                        card {
                            HStack(spacing: 10) {
                                Row(title: d.type, small: Logic.limitText(s.tier, d),
                                    value: "\(s.paid.count) paid", valueSmall: Logic.eur(Logic.sum(s.paid)), skip: false)
                                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color.sub)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    if !s.log.isEmpty {
                        sec(d.month)
                        card {
                            ForEach(Array(s.log.reversed().enumerated()), id: \.element.id) { i, e in
                                if i > 0 { Rectangle().fill(Color.hairline).frame(height: 0.5) }
                                Row(title: e.payment.label, small: "\(e.payment.shortDate), \(e.payment.time)",
                                    value: Logic.eur(e.payment.amount), valueSmall: e.skipped ? "Saved" : "Paid",
                                    skip: e.skipped)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 215)
            }
            .scrollIndicators(.hidden)
            dock(s, d)
        }
    }

    private func ladder(_ cur: Int) -> some View {
        HStack(alignment: .top, spacing: 14) {
            GeometryReader { g in
                ZStack(alignment: .bottom) {
                    Capsule().fill(Color.track)
                    Capsule().fill(Color.lime).frame(height: g.size.height * CGFloat(cur * 44 + 27) / 274)
                }
            }
            .frame(width: 10).padding(.vertical, 11).frame(width: 22)
            VStack(spacing: 0) {
                ForEach([5, 4, 3, 2, 1, 0], id: \.self) { i in
                    HStack(spacing: 8) {
                        if i == cur {
                            Text(Tier.all[i].name).font(.system(size: 30, weight: .heavy)).tracking(-0.9)
                                .foregroundStyle(Color.lime).lineSpacing(-4)
                        } else {
                            Text(Tier.all[i].name).font(.system(size: 17))
                        }
                        Spacer(minLength: 0)
                        if i != cur {
                            Text("\(Logic.levels[i]) \(Logic.levels[i] == 1 ? "skip" : "skips")").sub(13)
                        }
                        if i == 5 { Pill(text: "Goal", kind: .line) }
                        if i == cur { Pill(text: "You", kind: .lime) }
                    }
                    .frame(height: i == cur ? 76 : 44)
                    .opacity(i > cur ? 0.45 : 1)
                }
            }
        }
        .padding(16)
        .background(Color.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .animation(.easeInOut(duration: 0.5), value: cur)
    }

    private func sec(_ t: String) -> some View {
        Text(t).font(.system(size: 13)).tracking(0.4).textCase(.uppercase).foregroundStyle(Color.sub)
            .padding(.horizontal, 16).padding(.top, 12)
    }

    private func card<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        VStack(spacing: 0) { content() }
            .padding(.horizontal, 18).padding(.vertical, 4)
            .background(Color.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func dock(_ s: Session, _ d: DemoData) -> some View {
        VStack(spacing: 0) {
            AskField { m.openChat(focus: true) }.padding(.bottom, 12)
            if s.ended {
                Button("Start over") { m.restart() }.buttonStyle(Btn(bg: .white, fg: .black))
                Demo(text: s.queue.isEmpty ? "No locked payments at this setting."
                                           : "\(d.month) complete. \(Logic.eur(s.saved)) saved.")
            } else {
                Button("Next payment") { m.nextPayment() }.buttonStyle(Btn(bg: .white, fg: .black))
                Demo(text: "Replays this customer's real card payments.")
            }
        }
        .padding(.horizontal, 16).padding(.top, 30).padding(.bottom, 4)
        .background(
            LinearGradient(stops: [.init(color: .black, location: 0), .init(color: .black, location: 0.68),
                                   .init(color: .clear, location: 1)], startPoint: .bottom, endPoint: .top)
                .ignoresSafeArea()
                .allowsHitTesting(false)      // the fade must not swallow drags meant for the list underneath
        )
    }
}

/// One number and the three baskets: what is safe to spend on everyday things, and where a typical month goes.
struct MoneyCard: View {
    let money: Money

    var body: some View {
        let parts = Basket.allCases.map { ($0, money.average($0)) }
        let all = max(parts.reduce(0) { $0 + $1.1 }, 1)
        let tones: [Color] = [.white.opacity(0.85), .white.opacity(0.45), .lime]
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Safe to spend a week").font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.sub)
                    Text(Logic.eur(money.safeToSpendWeek)).num(28)
                }
                Spacer()
                Text(money.leftOver >= 0 ? "\(Logic.eur(money.safeToSave)) a month safe to save" : "\(Logic.eur(-money.leftOver)) a month over")
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(money.leftOver >= 0 ? Color.lime : Color.sub)
            }
            GeometryReader { g in
                HStack(spacing: 3) {
                    ForEach(Array(parts.enumerated()), id: \.offset) { i, p in
                        Capsule().fill(tones[i]).frame(width: max(4, (g.size.width - 6) * p.1 / all))
                    }
                }
            }
            .frame(height: 8)
            HStack(alignment: .top, spacing: 8) {
                ForEach(Array(parts.enumerated()), id: \.offset) { i, p in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 5) {
                            Circle().fill(tones[i]).frame(width: 7, height: 7)
                            Text(p.0.name).font(.system(size: 12)).foregroundStyle(Color.sub).lineLimit(1).minimumScaleFactor(0.8)
                        }
                        Text(Logic.eur(p.1)).font(.system(size: 15, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(16)
        .background(Color.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the savings coach")
    }
}

struct Row: View {
    let title, small, value, valueSmall: String
    let skip: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                Text(title).font(.system(size: 17))
                Text(small).sub(13)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 3) {
                Text(value).num(17, weight: .semibold).foregroundStyle(skip ? Color.lime : .white)
                Text(valueSmall).font(.system(size: 13)).foregroundStyle(skip ? Color.lime : Color.sub)
            }
        }
        .padding(.vertical, 13)
    }
}
