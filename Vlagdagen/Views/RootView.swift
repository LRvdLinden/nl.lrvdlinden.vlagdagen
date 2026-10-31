import SwiftUI

struct RootView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var router: Router

    var body: some View {
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
        .fullScreenCover(isPresented: Binding(
            get: { !settings.hasOnboarded },
            set: { if !$0 { settings.hasOnboarded = true } }
        )) {
            OnboardingView()
        }
        .sheet(item: Binding(
            get: { router.openFlagDayID.flatMap(flagDay(for:)) },
            set: { router.openFlagDayID = $0?.id }
        )) { day in
            NavigationStack { FlagDayDetailView(day: day) }
                .presentationDetents([.medium, .large])
        }
    }

    private func flagDay(for id: String) -> FlagDay? {
        let year = FlagCalendar.calendar.component(.year, from: .now)
        return (year - 1...year + 3).flatMap { FlagCalendar.flagDays(in: $0) }.first { $0.id == id }
    }
}
