import SwiftUI

extension Color {
    static let lime = Color(red: 0x9B / 255, green: 0xF0 / 255, blue: 0x5C / 255)
    static let limeInk = Color(red: 0x06 / 255, green: 0x14 / 255, blue: 0x0A / 255)
    static let card = Color(red: 0x1C / 255, green: 0x1C / 255, blue: 0x1E / 255)
    static let sub = Color.white.opacity(0.55)
    static let hairline = Color.white.opacity(0.1)
    static let track = Color.white.opacity(0.14)
    static let gameBg = Color(red: 0x0B / 255, green: 0x0B / 255, blue: 0x0D / 255)
    static let bankBg = Color(red: 0xF2 / 255, green: 0xF2 / 255, blue: 0xF7 / 255)
    static let bankInk = Color(red: 0x0B / 255, green: 0x0B / 255, blue: 0x0F / 255)
    static let bankSub = Color(red: 0x6C / 255, green: 0x6C / 255, blue: 0x74 / 255)
    static let bankGreen = Color(red: 0x0A / 255, green: 0x7F / 255, blue: 0x52 / 255)
}

extension View {
    /// .num in the HTML: rounded, tabular digits, tight tracking.
    func num(_ size: CGFloat, weight: Font.Weight = .bold) -> some View {
        font(.system(size: size, weight: weight, design: .rounded))
            .monospacedDigit()
            .tracking(-0.03 * size)
    }

    func sub(_ size: CGFloat = 15) -> some View {
        font(.system(size: size)).foregroundStyle(Color.sub)
    }

    func h1() -> some View {
        font(.system(size: 34, weight: .heavy)).tracking(-1)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// .btn in the HTML.
struct Btn: ButtonStyle {
    var bg: Color = .lime
    var fg: Color = .limeInk
    var pad: CGFloat = 16

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, pad)
            .background(bg, in: Capsule())
            .foregroundStyle(fg)
            .contentShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct Pill: View {
    enum Kind { case plain, lime, line }
    let text: String
    var kind: Kind = .plain

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(kind == .lime ? Color.limeInk : kind == .line ? Color.sub : .white)
            .padding(.horizontal, kind == .line ? 11 : 13)
            .padding(.vertical, kind == .line ? 4 : 6)
            .background(kind == .lime ? Color.lime : kind == .line ? .clear : Color.card, in: Capsule())
            .overlay { if kind == .line { Capsule().strokeBorder(Color.sub, lineWidth: 1.5) } }
            .fixedSize()
    }
}

/// .facts in the HTML: rows with a check, hairlines between.
struct Facts: View {
    let items: [String]
    var bg: Color = .card
    var line: Color = .hairline
    var icon: Color = .lime

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { i, s in
                if i > 0 { Rectangle().fill(line).frame(height: 0.5) }
                HStack(spacing: 12) {
                    Image(systemName: "checkmark").font(.system(size: 17, weight: .bold)).foregroundStyle(icon)
                        .frame(width: 22, height: 22)
                    Text(s).font(.system(size: 17))
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 14)
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 6)
        .background(bg, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

struct Demo: View {
    let text: String
    var color: Color = .sub
    var body: some View {
        Text(text).font(.system(size: 12)).foregroundStyle(color)
            .multilineTextAlignment(.center).padding(.top, 10)
    }
}
