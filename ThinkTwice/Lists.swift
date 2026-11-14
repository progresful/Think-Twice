import SwiftUI

/// Opened from the "Saved by skipping" tile: the payments the user chose not to complete.
struct SkippedView: View {
    @Environment(AppModel.self) private var m

    var body: some View {
        let s = m.session, skipped = s.log.filter(\.skipped)
        VStack(alignment: .leading, spacing: 0) {
            Text("Saved by skipping").sub()
            Text(Logic.eur(s.saved)).num(56).foregroundStyle(Color.lime).padding(.top, 8).padding(.bottom, 6)
            Text("\(s.skipped) \(s.skipped == 1 ? "purchase" : "purchases") skipped in \(m.data.month).").sub()
            ScrollView {
                ListCard {
                    ForEach(Array(skipped.reversed().enumerated()), id: \.element.id) { i, e in
                        if i > 0 { Rectangle().fill(Color.hairline).frame(height: 0.5) }
                        Row(title: e.payment.label, small: "\(e.payment.shortDate), \(e.payment.time)",
                            value: Logic.eur(e.payment.amount), valueSmall: "Saved", skip: true)
                    }
                }
            }
            .scrollIndicators(.hidden).padding(.top, 22)
            Button("Done") { m.layer = .none }.buttonStyle(Btn()).padding(.top, 12)
        }
        .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gameBg.ignoresSafeArea())
    }
}

/// The no-no list: groups of spending, then the kinds of places inside a group, each with a switch.
struct NoNoView: View {
    @Environment(AppModel.self) private var m
    @State private var open: Category?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let c = open { detail(c) } else { groups }
            Button("Done") { m.closeNoNo() }.buttonStyle(Btn()).padding(.top, 12)
        }
        .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gameBg.ignoresSafeArea())
        .animation(.easeOut(duration: 0.25), value: open?.name)
    }

    private var groups: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("No-no list").h1()
            Text("We picked what stacks up, from your \(m.data.beforeMonth) payments. Change it any time.").sub().padding(.top, 8)
            ScrollView {
                ListCard {
                    ForEach(Array(m.data.categories.enumerated()), id: \.element.id) { i, c in
                        if i > 0 { Rectangle().fill(Color.hairline).frame(height: 0.5) }
                        HStack(spacing: 12) {
                            Button { open = c } label: {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text(c.name).font(.system(size: 17))
                                        Text("\(c.count) \(c.count == 1 ? "payment" : "payments"), \(Logic.eur(c.total))").sub(13)
                                    }
                                    Spacer(minLength: 0)
                                    Text("\(m.onCount(c)) of \(c.items.count)").sub(13)
                                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color.sub)
                                }
                                .foregroundStyle(.white).contentShape(Rectangle())
                            }
                            Toggle("", isOn: Binding(get: { m.onCount(c) > 0 }, set: { m.set(c, on: $0) }))
                                .labelsHidden().tint(.lime).accessibilityLabel(c.name)
                        }
                        .padding(.vertical, 13)
                    }
                }
            }
            .scrollIndicators(.hidden).padding(.top, 22)
        }
        .transition(.opacity)
    }

    private func detail(_ c: Category) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { open = nil } label: {
                Image(systemName: "chevron.left").font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                    .frame(width: 34, height: 34).background(Color.card, in: Circle())
            }
            .accessibilityLabel("Back").padding(.bottom, 14)
            Text(c.name).h1()
            Text("Your \(m.data.beforeMonth) payments. Switch off the places you want to keep paying freely.").sub().padding(.top, 8)
            ScrollView {
                ListCard {
                    ForEach(Array(c.items.enumerated()), id: \.element.id) { i, item in
                        if i > 0 { Rectangle().fill(Color.hairline).frame(height: 0.5) }
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 0) {
                                Text(item.label).font(.system(size: 17))
                                Text("\(item.count) \(item.count == 1 ? "payment" : "payments"), \(Logic.eur(item.total))").sub(13)
                            }
                            Spacer(minLength: 0)
                            Toggle("", isOn: Binding(get: { m.isOn(c, item) }, set: { m.set(c, item, on: $0) }))
                                .labelsHidden().tint(.lime).accessibilityLabel(item.label)
                        }
                        .padding(.vertical, 13)
                    }
                }
            }
            .scrollIndicators(.hidden).padding(.top, 22)
        }
        .transition(.offset(x: 18).combined(with: .opacity))
    }
}

struct ListCard<C: View>: View {
    @ViewBuilder let content: () -> C
    var body: some View {
        VStack(spacing: 0) { content() }
            .padding(.horizontal, 18).padding(.vertical, 4)
            .background(Color.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

/// One soft burst of small confetti from the centre of the screen, for a skipped payment.
struct Confetti: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        let bounds = UIScreen.main.bounds
        let emitter = CAEmitterLayer()
        emitter.emitterShape = .point
        emitter.emitterPosition = CGPoint(x: bounds.midX, y: bounds.height * 0.43)   // behind the check mark
        let colors: [UIColor] = [UIColor(Color.lime), .white, UIColor(red: 1, green: 0.88, blue: 0.23, alpha: 1),
                                 UIColor(red: 0.36, green: 0.78, blue: 1, alpha: 1)]
        emitter.emitterCells = colors.flatMap { color in
            [CGSize(width: 9, height: 6), CGSize(width: 6, height: 6)].map { size in
                let cell = CAEmitterCell()
                cell.contents = UIGraphicsImageRenderer(size: size).image { ctx in
                    color.setFill()
                    ctx.fill(CGRect(origin: .zero, size: size))
                }.cgImage
                cell.contentsScale = UIScreen.main.scale      // keep the pieces at their point size
                cell.birthRate = 30
                cell.lifetime = 3.2
                cell.velocity = 190
                cell.velocityRange = 110
                cell.emissionRange = .pi * 2                  // outwards in every direction
                cell.spin = 2
                cell.spinRange = 4
                cell.scale = 0.9
                cell.scaleRange = 0.3
                cell.yAcceleration = 140
                cell.alphaSpeed = -0.2
                return cell
            }
        }
        view.layer.addSublayer(emitter)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { emitter.birthRate = 0 }
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {}
}
