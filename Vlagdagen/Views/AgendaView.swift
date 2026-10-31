import SwiftUI

struct AgendaView: View {
    @State private var showPast = false
    @State private var selected: FlagDay?
    @Environment(\.openURL) private var openURL

    private var years: [Int] {
        let y = FlagCalendar.calendar.component(.year, from: .now)
        return Array(y...(y + 2))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    subscribeBanner
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))

                ForEach(years, id: \.self) { year in
                    let today = FlagCalendar.startOfDay(.now)
                    let days = FlagCalendar.flagDays(in: year).filter { showPast || $0.date >= today }
                    if !days.isEmpty {
                        Section {
                            ForEach(days) { day in
                                Button { selected = day } label: {
                                    FlagDayRow(day: day).opacity(day.date < today ? 0.45 : 1)
                                }
                                .buttonStyle(.plain)
                            }
                        } header: {
                            Text(String(year)).font(Theme.display(20)).foregroundStyle(Theme.ink).textCase(nil)
                        }
                    }
                }

                Section {
                    Text("Valt een datum (behalve 4 en 5 mei) op een zondag of een algemeen erkende christelijke feestdag, dan wordt op de eerstvolgende dag gevlagd. Koningsdag gaat dan naar zaterdag 26 april.")
                        .font(.footnote)
                        .foregroundStyle(Theme.muted)
                } footer: {
                    Text("Bron: algemene vlaginstructie, rijksoverheid.nl")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Agenda")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Toggle(isOn: $showPast.animation()) {
                        Label("Toon voorbije", systemImage: "clock.arrow.circlepath")
                    }
                    .toggleStyle(.button)
                }
            }
            .sheet(item: $selected) { day in
                NavigationStack { FlagDayDetailView(day: day) }
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private var subscribeBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.title2)
                .foregroundStyle(Theme.gold)
            VStack(alignment: .leading, spacing: 2) {
                Text("Alle vlagdagen in je agenda").font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                Text("Werkt automatisch bij, elk jaar opnieuw.").font(.caption).foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
            Menu {
                Button { openURL(CalendarSubscription.appleURL) } label: { Label("Apple Agenda", systemImage: "calendar") }
                Button { openURL(CalendarSubscription.googleURL) } label: { Label("Google Agenda", systemImage: "g.circle") }
                Button { openURL(CalendarSubscription.outlookURL) } label: { Label("Outlook", systemImage: "envelope") }
                Button { UIPasteboard.general.url = CalendarSubscription.httpsURL } label: { Label("Kopieer link", systemImage: "doc.on.doc") }
            } label: {
                Text("Abonneer")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Theme.gold, in: Capsule())
                    .foregroundStyle(Theme.heroBottom)
            }
        }
        .padding(14)
        .background(
            LinearGradient(colors: [Theme.heroTop, Theme.heroBottom], startPoint: .leading, endPoint: .trailing),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
    }
}

// MARK: - Detail

struct FlagDayDetailView: View {
    let day: FlagDay
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(FlagFormat.relative(FlagCalendar.daysUntil(day)).uppercased())
                            .font(Theme.eyebrow).foregroundStyle(Theme.orange)
                        Text(day.title).font(Theme.display(28)).foregroundStyle(Theme.ink)
                        Text(FlagFormat.full.string(from: day.date).capitalizedFirst)
                            .font(.subheadline).foregroundStyle(Theme.muted)
                    }
                    Spacer()
                    FlagGlyph(pennant: day.kind.hasPennant, halfMast: day.kind.isHalfMast, size: 60)
                }

                infoCard(title: "Zo hang je de vlag", symbol: "flag.fill") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(day.kind.instruction)
                        if day.kind.isHalfMast, let sunset = SunCalculator.sunset(on: day.date) {
                            Text("Zonsondergang: \(FlagFormat.time.string(from: sunset)) (De Bilt)")
                                .foregroundStyle(Theme.muted)
                        }
                        if day.isShifted {
                            Text("Officieel \(FlagFormat.dayMonth.string(from: day.officialDate)), maar die dag valt op een zondag of christelijke feestdag.")
                                .foregroundStyle(Theme.orange)
                        }
                        day.kind.badges
                    }
                }

                infoCard(title: "Over deze dag", symbol: day.kind.symbol) {
                    Text(day.kind.about)
                }

                infoCard(title: "Rijksgebouwen", symbol: "building.2.fill") {
                    Text(day.kind.scope == .uitgebreid
                         ? "Uitgebreid vlaggen: de vlag gaat uit op alle gebouwen van de Rijksoverheid."
                         : "Beperkt vlaggen: de vlag gaat alleen uit op enkele hoofdgebouwen van de Rijksoverheid.")
                }

                Toggle(isOn: Binding(get: { settings.isEnabled(day.kind) },
                                     set: { settings.setEnabled(day.kind, $0) })) {
                    Label("Melding voor \(day.kind.shortTitle)", systemImage: "bell.badge.fill")
                }
                .padding(16)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                ShareLink(item: URL(string: "https://vlagdagen.nl")!,
                          message: Text("\(day.title): \(FlagFormat.full.string(from: day.date)). \(day.kind.instruction)")) {
                    Label("Deel deze vlagdag", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(20)
        }
        .background(Theme.background.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Klaar") { dismiss() }
            }
        }
    }

    private func infoCard<Content: View>(title: String, symbol: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.navy)
            content().font(.subheadline).foregroundStyle(Theme.ink)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
