import SwiftUI

/// Kleuren en typografie, afgeleid van vlagdagen.nl (navy, goud, rood-wit-blauw).
enum Theme {
    static let navy = Color(light: 0x1D3863, dark: 0x8FB0E8)
    static let ink = Color(light: 0x0F1829, dark: 0xF2F4F8)
    static let muted = Color(light: 0x576175, dark: 0xA3ACBD)
    static let gold = Color(hex: 0xFFBD14)
    static let orange = Color(hex: 0xFF6600)   // Nederlands oranje (wimpel)
    static let background = Color(light: 0xF2F4F8, dark: 0x0B1220)
    static let card = Color(light: 0xFFFFFF, dark: 0x16213A)
    static let heroTop = Color(hex: 0x1D3863)
    static let heroBottom = Color(hex: 0x0F1829)

    // Nederlandse driekleur
    static let flagRed = Color(hex: 0xAE1C28)
    static let flagWhite = Color(hex: 0xFFFFFF)
    static let flagBlue = Color(hex: 0x21468B)

    static func display(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static let eyebrow = Font.system(size: 12, weight: .semibold).width(.expanded)
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }

    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1
            )
        })
    }
}

/// Kleine wapperende Nederlandse vlag, optioneel met wimpel of halfstok.
struct FlagGlyph: View {
    var pennant: Bool = false
    var halfMast: Bool = false
    var size: CGFloat = 44

    var body: some View {
        let w = size, h = size * 0.95
        ZStack(alignment: .topLeading) {
            // Mast
            RoundedRectangle(cornerRadius: 1)
                .fill(Theme.muted.opacity(0.8))
                .frame(width: max(2, w * 0.05), height: h)
            VStack(spacing: 0) {
                if pennant {
                    PennantShape()
                        .fill(Theme.orange)
                        .frame(width: w * 0.85, height: h * 0.1)
                        .padding(.bottom, h * 0.03)
                }
                VStack(spacing: 0) {
                    Theme.flagRed
                    Theme.flagWhite
                    Theme.flagBlue
                }
                .frame(width: w * 0.8, height: h * 0.45)
                .clipShape(WaveShape())
                .overlay(WaveShape().stroke(Theme.ink.opacity(0.08), lineWidth: 0.5))
            }
            .offset(x: max(2, w * 0.05), y: halfMast ? h * 0.33 : h * 0.02)
        }
        .frame(width: w, height: h, alignment: .topLeading)
        .accessibilityHidden(true)
    }
}

struct WaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let a = rect.height * 0.06
        p.move(to: CGPoint(x: 0, y: 0))
        p.addCurve(to: CGPoint(x: rect.maxX, y: 0),
                   control1: CGPoint(x: rect.width * 0.35, y: -a), control2: CGPoint(x: rect.width * 0.65, y: a * 2))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addCurve(to: CGPoint(x: 0, y: rect.maxY),
                   control1: CGPoint(x: rect.width * 0.65, y: rect.maxY + a * 2), control2: CGPoint(x: rect.width * 0.35, y: rect.maxY - a))
        p.closeSubpath()
        return p
    }
}

struct PennantShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: 0))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.addLine(to: CGPoint(x: 0, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// Labeltje zoals WIMPEL / HALFSTOK
struct Badge: View {
    let text: String
    var color: Color = Theme.orange

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold))
            .tracking(0.8)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .foregroundStyle(color)
            .background(color.opacity(0.14), in: Capsule())
    }
}

extension FlagDayKind {
    @ViewBuilder var badges: some View {
        HStack(spacing: 6) {
            if hasPennant { Badge(text: "Wimpel") }
            if isHalfMast { Badge(text: "Halfstok", color: Theme.muted) }
            if isLocalOnly { Badge(text: "Den Haag", color: Theme.navy) }
        }
    }
}
