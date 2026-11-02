import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @State private var status: UNAuthorizationStatus = .notDetermined
    @State private var pendingCount = 0
    @State private var copied = false

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.0.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            Form {
                notificationsSection
                if settings.notificationsEnabled && status != .denied {
                    perDaySection
                }
                calendarSection
                aboutSection
                discoverSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Instellingen")
            .task { await refreshStatus() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { Task { await refreshStatus() } }
            }
            .onChange(of: settings.snapshot) { _, _ in
                Task {
                    try? await Task.sleep(for: .milliseconds(400))
                    await refreshStatus()
                }
            }
        }
    }

    // MARK: - Meldingen

    private var notificationsSection: some View {
        Section {
            if status == .denied {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Meldingen staan uit voor Vlagdagen", systemImage: "bell.slash.fill")
                        .foregroundStyle(Theme.flagRed)
                    Text("Zet meldingen aan in de iPhone-instellingen om op elke vlagdag een seintje te krijgen.")
                        .font(.footnote).foregroundStyle(Theme.muted)
                    Button("Open Instellingen") {
                        if let url = URL(string: UIApplication.openNotificationSettingsURLString) { openURL(url) }
                    }
                }
            } else {
                Toggle(isOn: Binding(get: { settings.notificationsEnabled }, set: { on in
                    settings.notificationsEnabled = on
                    if on && status == .notDetermined {
                        Task {
                            await NotificationScheduler.requestAuthorization()
                            await refreshStatus()
                            await NotificationScheduler.reschedule(settings.snapshot)
                        }
                    }
                })) {
                    Label("Ochtendmelding op vlagdagen", systemImage: "bell.badge.fill")
                }

                if settings.notificationsEnabled {
                    DatePicker(selection: Binding(get: { settings.notifyTime }, set: { settings.notifyTime = $0 }),
                               displayedComponents: .hourAndMinute) {
                        Label("Tijdstip", systemImage: "alarm.fill")
                    }
                    Toggle(isOn: $settings.eveningBefore) {
                        Label("Ook de avond ervoor (20:00)", systemImage: "moon.stars.fill")
                    }
                    Toggle(isOn: $settings.halfMastReminder) {
                        Label("4 mei: herinnering om 17:45", systemImage: "flame.fill")
                    }
                    Button {
                        Task { await sendTest() }
                    } label: {
                        Label("Stuur een testmelding", systemImage: "paperplane.fill")
                    }
                }
            }
        } header: {
            Text("Meldingen")
        } footer: {
            if settings.notificationsEnabled && status != .denied {
                Text("Je krijgt om \(settings.notifyTimeLabel) automatisch een melding op elke vlagdag, ook als de app gesloten is." + (pendingCount > 0 ? " \(pendingCount) meldingen ingepland." : ""))
            }
        }
    }

    private var perDaySection: some View {
        Section("Melding per vlagdag") {
            ForEach(FlagDayKind.allCases) { kind in
                Toggle(isOn: Binding(get: { settings.isEnabled(kind) }, set: { settings.setEnabled(kind, $0) })) {
                    HStack(spacing: 10) {
                        Image(systemName: kind.symbol).foregroundStyle(Theme.navy).frame(width: 22)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(kind.shortTitle)
                            if kind.isLocalOnly {
                                Text("Alleen in Den Haag").font(.caption).foregroundStyle(Theme.muted)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Agenda

    private var calendarSection: some View {
        Section {
            Button { openURL(CalendarSubscription.appleURL) } label: {
                Label("Abonneer in Apple Agenda", systemImage: "calendar.badge.plus")
            }
            Button { openURL(CalendarSubscription.googleURL) } label: {
                Label("Abonneer in Google Agenda", systemImage: "g.circle.fill")
            }
            Button { openURL(CalendarSubscription.outlookURL) } label: {
                Label("Abonneer in Outlook", systemImage: "envelope.fill")
            }
            Button {
                UIPasteboard.general.url = CalendarSubscription.httpsURL
                copied = true
            } label: {
                Label(copied ? "Link gekopieerd" : "Kopieer agenda-link", systemImage: copied ? "checkmark" : "doc.on.doc")
            }
        } header: {
            Text("Agenda-abonnement")
        } footer: {
            Text("Met een abonnement staan alle vlagdagen in je agenda en worden ze automatisch bijgewerkt.")
        }
    }

    // MARK: - Over

    private var aboutSection: some View {
        Section {
            LabeledContent("Versie", value: version)
            Link(destination: URL(string: "https://vlagdagen.nl")!) {
                Label("vlagdagen.nl", systemImage: "safari.fill")
            }
            ShareLink(item: URL(string: "https://vlagdagen.nl")!,
                      message: Text("Mag de vlag vandaag uit? Met de Vlagdagen-app weet je het altijd.")) {
                Label("Deel de app", systemImage: "square.and.arrow.up")
            }
            Button {
                settings.hasOnboarded = false
            } label: {
                Label("Toon welkomstscherm", systemImage: "sparkles")
            }
        } header: {
            Text("Over")
        } footer: {
            Text("Gebaseerd op de algemene vlaginstructie van de Rijksoverheid. Deze app verzamelt geen persoonsgegevens; meldingen worden lokaal op je iPhone ingepland. Weerdata: Open-Meteo.com.")
        }
    }

    // MARK: - Ontdekken

    private var discoverSection: some View {
        Section {
            MoreAppsCard()
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
        } header: {
            Text("Ontdekken")
        }
    }

    // MARK: - Helpers

    private func refreshStatus() async {
        status = await NotificationScheduler.authorizationStatus()
        pendingCount = await UNUserNotificationCenter.current().pendingNotificationRequests()
            .filter { $0.identifier.hasPrefix(NotificationScheduler.prefix) }.count
    }

    private func sendTest() async {
        guard let day = FlagCalendar.next(after: DemoMode.now) else { return }
        let content = NotificationScheduler.morningContent(day)
        content.subtitle = "Testmelding"
        let request = UNNotificationRequest(
            identifier: "test.\(UUID().uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        )
        try? await UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Welkomstscherm

struct OnboardingView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.heroTop, Theme.heroBottom], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()
                WavingTricolor(pennant: true, speed: 0.8)
                    .frame(width: 150, height: 120)
                VStack(spacing: 10) {
                    Text("Vlagdagen")
                        .font(Theme.display(44, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Mag de vlag vandaag uit? Je weet het altijd, met een seintje op de ochtend van elke vlagdag.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 16) {
                    feature("bell.badge.fill", "Ochtendmelding", "Automatisch op elke vlagdag, op een tijd die jij kiest.")
                    feature("calendar.badge.plus", "Agenda-abonnement", "Alle vlagdagen in Apple, Google of Outlook Agenda.")
                    feature("flag.2.crossed.fill", "Wimpel of halfstok", "Precies weten hoe de vlag vandaag hoort te hangen.")
                }
                .padding(.horizontal, 8)

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        Task {
                            _ = await NotificationScheduler.requestAuthorization()
                            settings.notificationsEnabled = true
                            settings.hasOnboarded = true
                            await NotificationScheduler.reschedule(settings.snapshot)
                        }
                    } label: {
                        Text("Meldingen aanzetten")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.gold, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .foregroundStyle(Theme.heroBottom)
                    }
                    Button("Later") {
                        settings.notificationsEnabled = false
                        settings.hasOnboarded = true
                    }
                    .foregroundStyle(.white.opacity(0.8))
                }
            }
            .padding(24)
        }
    }

    private func feature(_ symbol: String, _ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(Theme.gold)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline).foregroundStyle(.white)
                Text(text).font(.subheadline).foregroundStyle(.white.opacity(0.7))
            }
        }
    }
}

// MARK: - Meer apps van de ontwikkelaar

struct MoreAppsCard: View {
    static let url = URL(string: "https://lrvdlinden.app")!

    var body: some View {
        Link(destination: Self.url) {
            HStack(spacing: 14) {
                // Icoon in Vlagdagen-kleuren: navy naar Nederlands oranje
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LinearGradient(colors: [Theme.heroTop, Theme.orange],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(.white)
                    )
                    .shadow(color: Theme.orange.opacity(0.25), radius: 8, y: 4)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Meer apps van de ontwikkelaar")
                        .font(.headline)
                        .foregroundStyle(Theme.navy)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Apps voor iPhone, iPad, Apple TV en Homey")
                        .font(.subheadline)
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .multilineTextAlignment(.leading)

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Bekijk")
                        .font(.headline)
                        .foregroundStyle(Theme.orange)
                    Text("lrvdlinden.app")
                        .font(.caption)
                        .foregroundStyle(Theme.muted)
                }
            }
            .padding(16)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Theme.gold.opacity(0.35), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Meer apps van de ontwikkelaar, apps voor iPhone, iPad, Apple TV en Homey")
        .accessibilityHint("Opent lrvdlinden.app")
    }
}
