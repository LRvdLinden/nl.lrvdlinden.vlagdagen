import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var router: Router
    @State private var advice: WeatherAdvice?
    @State private var adviceFailed = false

    var body: some View {
        NavigationStack {
            TimelineView(.everyMinute) { context in
                let now = DemoMode.adjust(context.date)
                let today = FlagCalendar.flagDay(on: now)
                ScrollView {
                    VStack(spacing: 20) {
                        answer(today: today, now: now)
                        if let next = FlagCalendar.next(after: now) {
                            NextFlagDayCard(day: next)
                        }
                        adviceCard
                        upcoming(now: now)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                    .frame(maxWidth: 720)
                    .frame(maxWidth: .infinity)
                }
                .background(Theme.background.ignoresSafeArea())
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        FlagGlyph(size: 22)
                        Text("Vlagdagen").font(Theme.display(18))
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .task { await loadAdvice() }
            .refreshable { await loadAdvice() }
        }
    }

    // MARK: - "Mag de vlag vandaag uit?"

    @ViewBuilder
    private func answer(today: FlagDay?, now: Date) -> some View {
        let yes = today != nil && today?.kind.isLocalOnly == false
        VStack(spacing: 10) {
            Text("Mag de vlag vandaag uit?")
                .font(Theme.display(17, weight: .regular))
                .foregroundStyle(Theme.muted)
                .padding(.top, 12)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(yes ? "Ja" : (today?.kind.isLocalOnly == true ? "In Den Haag" : "Nee"))
                    .font(Theme.display(today?.kind.isLocalOnly == true ? 56 : 104, weight: .bold))
                    .foregroundStyle(Theme.gold)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Circle().fill(Theme.flagRed).frame(width: 14, height: 14).padding(.bottom, 18)
            }
            .accessibilityElement(children: .combine)
            .contentTransition(.numericText())

            if let today {
                VStack(spacing: 8) {
                    if yes { FlagGlyph(pennant: today.kind.hasPennant, halfMast: today.kind.isHalfMast, size: 64) }
                    Text(today.title).font(Theme.display(22)).foregroundStyle(Theme.ink).multilineTextAlignment(.center)
                    Text(today.kind.instruction).font(.subheadline).foregroundStyle(Theme.muted)
                    if today.kind.isHalfMast, let sunset = SunCalculator.sunset(on: today.date) {
                        Text("Zonsondergang vandaag: \(FlagFormat.time.string(from: sunset))")
                            .font(.footnote).foregroundStyle(Theme.muted)
                    }
                    today.kind.badges
                }
                .onTapGesture { router.openFlagDayID = today.id }
            } else {
                Text("Vandaag is het \(FlagFormat.full.string(from: now)). Geen officiële vlagdag.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 4)
    }

    // MARK: - Vlagadvies

    @ViewBuilder
    private var adviceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("VLAGADVIES").font(Theme.eyebrow).foregroundStyle(Theme.muted)
            if let advice {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: advice.symbol)
                        .font(.title2)
                        .foregroundStyle(color(for: advice.level))
                        .frame(width: 32)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(advice.title).font(Theme.display(20)).foregroundStyle(Theme.ink)
                        Text(advice.detail).font(.subheadline).foregroundStyle(Theme.muted)
                        Text("Wind \(Int(advice.windKmh)) km/u · stoten \(Int(advice.gustKmh)) km/u · \(Int(advice.temperature.rounded()))°C")
                            .font(.caption).foregroundStyle(Theme.muted)
                    }
                }
            } else if adviceFailed {
                Text("Het weer kon niet worden opgehaald. Trek omlaag om het opnieuw te proberen.")
                    .font(.subheadline).foregroundStyle(Theme.muted)
            } else {
                ProgressView().frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func color(for level: WeatherAdvice.Level) -> Color {
        switch level {
        case .good: return .green
        case .caution: return Theme.orange
        case .no: return Theme.flagRed
        }
    }

    private func loadAdvice() async {
        if DemoMode.isActive {
            advice = .evaluate(wind: 14, gust: 27, precipitation: 0, code: 1, temperature: 17)
            return
        }
        do {
            advice = try await WeatherService.fetch()
            adviceFailed = false
        } catch {
            adviceFailed = advice == nil
        }
    }

    // MARK: - Binnenkort

    @ViewBuilder
    private func upcoming(now: Date) -> some View {
        let days = FlagCalendar.upcoming(from: FlagCalendar.addDays(1, to: now), limit: 4).dropFirst()
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("DAARNA").font(Theme.eyebrow).foregroundStyle(Theme.muted)
                Spacer()
                Button("Hele agenda") { router.tab = .agenda }.font(.subheadline.weight(.semibold))
            }
            .padding(.bottom, 6)
            ForEach(Array(days)) { day in
                Button { router.openFlagDayID = day.id } label: {
                    FlagDayRow(day: day, now: now)
                }
                .buttonStyle(.plain)
                if day.id != days.last?.id { Divider() }
            }
        }
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

// MARK: - Volgende vlagdag + aftelklok

struct NextFlagDayCard: View {
    let day: FlagDay
    @EnvironmentObject private var router: Router
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("VOLGENDE VLAGDAG").font(Theme.eyebrow).foregroundStyle(Theme.gold)
            VStack(alignment: .leading, spacing: 4) {
                Text(day.title).font(Theme.display(26)).foregroundStyle(.white)
                Text(FlagFormat.full.string(from: day.date).capitalizedFirst)
                    .font(.subheadline).foregroundStyle(.white.opacity(0.75))
                day.kind.badges.padding(.top, 2)
            }

            TimelineView(.periodic(from: .now, by: 1)) { context in
                let remaining = max(0, day.date.timeIntervalSince(DemoMode.adjust(context.date)))
                let d = Int(remaining) / 86_400
                let h = Int(remaining) % 86_400 / 3_600
                let m = Int(remaining) % 3_600 / 60
                let s = Int(remaining) % 60
                HStack(spacing: 8) {
                    CountdownBox(value: d, label: "dagen")
                    CountdownBox(value: h, label: "uren")
                    CountdownBox(value: m, label: "min")
                    CountdownBox(value: s, label: "sec")
                }
            }

            HStack(spacing: 10) {
                Menu {
                    Button { openURL(CalendarSubscription.appleURL) } label: { Label("Apple Agenda", systemImage: "calendar") }
                    Button { openURL(CalendarSubscription.googleURL) } label: { Label("Google Agenda", systemImage: "g.circle") }
                    Button { openURL(CalendarSubscription.outlookURL) } label: { Label("Outlook", systemImage: "envelope") }
                } label: {
                    Label("Abonneer in agenda", systemImage: "calendar.badge.plus")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(Theme.gold, in: Capsule())
                        .foregroundStyle(Theme.heroBottom)
                }
                Button { router.openFlagDayID = day.id } label: {
                    Text("Meer info")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(.white.opacity(0.12), in: Capsule())
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [Theme.heroTop, Theme.heroBottom], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay(alignment: .topTrailing) {
            FlagGlyph(pennant: day.kind.hasPennant, halfMast: day.kind.isHalfMast, size: 54)
                .padding(18)
                .opacity(0.95)
        }
    }
}

struct CountdownBox: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(Theme.display(28, weight: .semibold))
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(value)))
                .foregroundStyle(.white)
            Text(label.uppercased()).font(.system(size: 10, weight: .semibold)).foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Rij in een lijst

struct FlagDayRow: View {
    let day: FlagDay
    var now: Date = DemoMode.now

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 0) {
                Text(FlagCalendar.calendar.component(.day, from: day.date).description)
                    .font(Theme.display(22, weight: .bold))
                    .foregroundStyle(Theme.navy)
                Text(FlagFormat.month.string(from: day.date).uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.muted)
            }
            .frame(width: 48, height: 52)
            .background(Theme.navy.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(day.title).font(.body.weight(.semibold)).foregroundStyle(Theme.ink)
                HStack(spacing: 6) {
                    Text("\(FlagFormat.weekday.string(from: day.date).capitalizedFirst) · \(FlagFormat.relative(FlagCalendar.daysUntil(day, from: now)))")
                        .font(.caption).foregroundStyle(Theme.muted)
                    day.kind.badges
                }
                if day.isShifted {
                    Text("Verschoven van \(FlagFormat.dayMonth.string(from: day.officialDate))")
                        .font(.caption2).foregroundStyle(Theme.orange)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Theme.muted.opacity(0.6))
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}
