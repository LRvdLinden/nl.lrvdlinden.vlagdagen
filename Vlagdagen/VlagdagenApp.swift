import SwiftUI
import UserNotifications
import WidgetKit

@main
struct VlagdagenApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var settings = AppSettings()
    @StateObject private var router = Router.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .environmentObject(router)
                .tint(Theme.navy)
                .task { await refresh() }
                .onChange(of: settings.snapshot) { _, _ in
                    Task { await refresh() }
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { Task { await refresh() } }
                }
        }
    }

    private func refresh() async {
        await NotificationScheduler.reschedule(settings.snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

/// Eenvoudige navigatie, zodat een tik op een melding de juiste vlagdag opent.
@MainActor
final class Router: ObservableObject {
    static let shared = Router()

    enum Tab: Hashable { case today, agenda, guide, faq, settings }

    @Published var tab: Tab = DemoMode.tab ?? .today
    @Published var openFlagDayID: String?
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Info.plist geeft alle vier de standen op (vereist voor iPad-multitasking);
    // op de iPhone houden we de app hier staand.
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        UIDevice.current.userInterfaceIdiom == .pad ? .all : .portrait
    }

    // Toon de melding ook als de app open staat
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    // Tik op melding: open de vlagdag
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let id = response.notification.request.content.userInfo["flagDayID"] as? String
        await MainActor.run {
            Router.shared.tab = .today
            Router.shared.openFlagDayID = id
        }
    }
}
