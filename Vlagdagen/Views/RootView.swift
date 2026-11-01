import StoreKit
import SwiftUI

struct RootView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var router: Router
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.requestReview) private var requestReview
    @State private var showSplash = !DemoMode.skipSplash

    var body: some View {
        ZStack {
            tabs
                .fullScreenCover(isPresented: Binding(
                    get: { !settings.hasOnboarded && !showSplash },
                    set: { if !$0 { settings.hasOnboarded = true } }
                )) {
                    OnboardingView()
                }
                .sheet(item: Binding(
                    get: { showSplash ? nil : router.openFlagDayID.flatMap(flagDay(for:)) },
                    set: { router.openFlagDayID = $0?.id }
                )) { day in
                    NavigationStack { FlagDayDetailView(day: day) }
                        .presentationDetents(DemoMode.isActive ? [.large] : [.medium, .large])
                }

            if showSplash {
                SplashView {
                    withAnimation(.easeInOut(duration: 0.45)) { showSplash = false }
                }
                .transition(.opacity.combined(with: .scale(scale: 1.04)))
                .zIndex(1)
            }
        }
        .task {
            if let id = DemoMode.flagDayID { router.openFlagDayID = id }
            ReviewPrompter.registerFirstUse()
        }
        // Beoordelingsverzoek: alleen op een rustig moment, een paar seconden na het openen
        .task(id: "\(scenePhase)-\(showSplash)-\(settings.hasOnboarded)") {
            await askForReviewIfDue()
        }
    }

    private func askForReviewIfDue() async {
        guard !DemoMode.isActive,
              scenePhase == .active,
              !showSplash,
              settings.hasOnboarded,
              ReviewPrompter.isDue() else { return }
        // Wacht even; als de app intussen naar de achtergrond gaat, wordt deze taak geannuleerd.
        guard (try? await Task.sleep(for: ReviewPrompter.settleDelay)) != nil else { return }
        guard scenePhase == .active, router.openFlagDayID == nil, ReviewPrompter.isDue() else { return }
        ReviewPrompter.markPrompted()
        requestReview()
    }

    private var tabs: some View {
        TabView(selection: $router.tab) {
            TodayView()
                .tabItem { Label("Vandaag", systemImage: "flag.fill") }
                .tag(Router.Tab.today)
            AgendaView()
                .tabItem { Label("Agenda", systemImage: "calendar") }
                .tag(Router.Tab.agenda)
            GuideView()
                .tabItem { Label("Handleiding", systemImage: "book.fill") }
                .tag(Router.Tab.guide)
            FAQView()
                .tabItem { Label("FAQ", systemImage: "questionmark.circle.fill") }
                .tag(Router.Tab.faq)
            SettingsView()
                .tabItem { Label("Instellingen", systemImage: "gearshape.fill") }
                .tag(Router.Tab.settings)
        }
    }

    private func flagDay(for id: String) -> FlagDay? {
        let year = FlagCalendar.calendar.component(.year, from: DemoMode.now)
        return (year - 1...year + 3).flatMap { FlagCalendar.flagDays(in: $0) }.first { $0.id == id }
    }
}
