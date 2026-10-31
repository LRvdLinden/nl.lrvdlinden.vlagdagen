import SwiftUI

/// Wapperende Nederlandse driekleur (live geanimeerd), optioneel met oranje wimpel.
struct WavingTricolor: View {
    var pennant: Bool = false
    var speed: Double = 1
    var amplitude: Double = 0.07

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate * speed
            Canvas { ctx, size in
                draw(in: &ctx, size: size, time: t)
            }
        }
        .accessibilityHidden(true)
    }

    private func draw(in ctx: inout GraphicsContext, size: CGSize, time t: Double) {
        let w = Double(size.width)
        let pennantHeight = pennant ? Double(size.height) * 0.12 : 0
        let gap = pennant ? Double(size.height) * 0.05 : 0
        let flagTop = pennantHeight + gap
        let flagHeight = Double(size.height) - flagTop
        let amp = flagHeight * amplitude
        let steps = 48

        // Uitwijking: groeit vanaf de mast, golft naar rechts
        func dy(_ x: Double) -> Double {
            let k = x / w
            return sin(k * 2.4 * .pi - t * 4.2) * amp * (0.25 + k)
        }
        func slope(_ x: Double) -> Double {
            cos((x / w) * 2.4 * .pi - t * 4.2)
        }

        // Wimpel
        if pennant {
            var p = Path()
            let mid = pennantHeight / 2
            p.move(to: CGPoint(x: 0, y: dy(0) * 0.7))
            for s in 0...steps {
                let x = w * 1.04 * Double(s) / Double(steps)
                let half = mid * (1 - Double(s) / Double(steps) * 0.94)
                p.addLine(to: CGPoint(x: x, y: mid - half + dy(x) * 0.7))
            }
            for s in stride(from: steps, through: 0, by: -1) {
                let x = w * 1.04 * Double(s) / Double(steps)
                let half = mid * (1 - Double(s) / Double(steps) * 0.94)
                p.addLine(to: CGPoint(x: x, y: mid + half + dy(x) * 0.7))
            }
            p.closeSubpath()
            ctx.fill(p, with: .color(Theme.orange))
        }

        // Drie banen
        let colors = [Theme.flagRed, Theme.flagWhite, Theme.flagBlue]
        var outline = Path()
        for (i, color) in colors.enumerated() {
            let top = flagTop + flagHeight * Double(i) / 3
            let bottom = flagTop + flagHeight * Double(i + 1) / 3 + (i < 2 ? 0.6 : 0)
            var p = Path()
            p.move(to: CGPoint(x: 0, y: top + dy(0)))
            for s in 0...steps {
                let x = w * Double(s) / Double(steps)
                p.addLine(to: CGPoint(x: x, y: top + dy(x)))
            }
            for s in stride(from: steps, through: 0, by: -1) {
                let x = w * Double(s) / Double(steps)
                p.addLine(to: CGPoint(x: x, y: bottom + dy(x)))
            }
            p.closeSubpath()
            ctx.fill(p, with: .color(color))
            outline.addPath(p)
        }

        // Licht en schaduw in de plooien
        var shaded = ctx
        shaded.clip(to: outline)
        let stripe = w / Double(steps)
        for s in 0..<steps {
            let x = w * Double(s) / Double(steps)
            let sl = slope(x + stripe / 2)
            let rect = CGRect(x: x, y: flagTop - amp * 2, width: stripe + 0.5, height: flagHeight + amp * 4)
            if sl < 0 {
                shaded.fill(Path(rect), with: .color(.black.opacity(-sl * 0.22)))
            } else {
                shaded.fill(Path(rect), with: .color(.white.opacity(sl * 0.12)))
            }
        }
    }
}

/// Geanimeerd openingsscherm: de vlag wordt gehesen en gaat wapperen.
struct SplashView: View {
    var onFinish: () -> Void

    @State private var hoisted = false
    @State private var showPennant = false
    @State private var showTitle = false
    @State private var showTagline = false
    @State private var glow = false

    var body: some View {
        GeometryReader { geo in
            let mastHeight = min(geo.size.height * 0.36, 320)
            let flagWidth = mastHeight * 0.78
            ZStack {
                LinearGradient(colors: [Theme.heroTop, Theme.heroBottom], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                // Zachte gouden gloed
                Circle()
                    .fill(Theme.gold.opacity(0.22))
                    .frame(width: mastHeight * 1.4)
                    .blur(radius: 60)
                    .scaleEffect(glow ? 1.1 : 0.6)
                    .opacity(glow ? 1 : 0)
                    .offset(y: -mastHeight * 0.25)

                VStack(spacing: 28) {
                    ZStack(alignment: .topLeading) {
                        // Mast + knop
                        RoundedRectangle(cornerRadius: 3)
                            .fill(LinearGradient(colors: [.white, Color(hex: 0xC9D1DE)], startPoint: .leading, endPoint: .trailing))
                            .frame(width: 6, height: mastHeight)
                            .offset(x: -3)
                        Circle()
                            .fill(Theme.gold)
                            .frame(width: 16, height: 16)
                            .offset(x: -8, y: -12)

                        // Vlag die omhoog gaat
                        WavingTricolor(pennant: showPennant)
                            .frame(width: flagWidth, height: flagWidth * (showPennant ? 0.78 : 0.66))
                            .offset(x: 3, y: hoisted ? 4 : mastHeight - flagWidth * 0.66)
                            .opacity(hoisted ? 1 : 0.85)
                    }
                    .frame(width: flagWidth + 6, height: mastHeight, alignment: .topLeading)

                    VStack(spacing: 8) {
                        Text("Vlagdagen")
                            .font(Theme.display(44, weight: .bold))
                            .foregroundStyle(.white)
                            .opacity(showTitle ? 1 : 0)
                            .offset(y: showTitle ? 0 : 14)
                        Text("Mag de vlag vandaag uit?")
                            .font(Theme.display(18, weight: .regular))
                            .foregroundStyle(Theme.gold)
                            .opacity(showTagline ? 1 : 0)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            withAnimation(.easeOut(duration: 0.6)) { glow = true }
            withAnimation(.spring(response: 1.1, dampingFraction: 0.82).delay(0.15)) { hoisted = true }
            try? await Task.sleep(for: .milliseconds(900))
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { showPennant = true }
            withAnimation(.easeOut(duration: 0.5)) { showTitle = true }
            try? await Task.sleep(for: .milliseconds(350))
            withAnimation(.easeOut(duration: 0.5)) { showTagline = true }
            try? await Task.sleep(for: .milliseconds(1200))
            onFinish()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Vlagdagen")
    }
}
