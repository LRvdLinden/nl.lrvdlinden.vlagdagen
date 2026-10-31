import Foundation
import UserNotifications

/// Plant lokale meldingen in voor alle komende vlagdagen.
///
/// Er is geen server nodig: iOS bezorgt de meldingen zelf op de ingestelde tijd,
/// ook als de app gesloten is. Bij elke start (en bij elke wijziging in de
/// instellingen) wordt het schema opnieuw opgebouwd, ruim twee jaar vooruit.
/// iOS staat maximaal 64 wachtende meldingen per app toe; we blijven daaronder.
enum NotificationScheduler {
    static let prefix = "vlagdag."
    private static let maxPending = 60

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    @discardableResult
    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func reschedule(_ prefs: NotificationPreferences, now: Date = .now) async {
        let center = UNUserNotificationCenter.current()

        // Alleen onze eigen meldingen weghalen
        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(prefix) })

        guard prefs.enabled else { return }
        let status = await authorizationStatus()
        guard status == .authorized || status == .provisional || status == .ephemeral else { return }

        let requests = makeRequests(prefs, now: now)
        for request in requests.prefix(maxPending) {
            try? await center.add(request)
        }
    }

    /// Bouwt de meldingen op (los te testen).
    static func makeRequests(_ prefs: NotificationPreferences, now: Date = .now) -> [UNNotificationRequest] {
        let days = FlagCalendar.upcoming(from: now, limit: 24).filter { prefs.enabledKinds.contains($0.kind) }
        var items: [(Date, UNNotificationRequest)] = []

        for day in days {
            // Ochtendmelding op de vlagdag zelf
            if let fire = time(on: day.date, hour: prefs.hour, minute: prefs.minute), fire > now {
                items.append((fire, request(id: "\(prefix)\(day.id).morning", fire: fire, content: morningContent(day))))
            }
            // Optioneel: avond ervoor om 20:00
            if prefs.eveningBefore,
               let fire = time(on: FlagCalendar.addDays(-1, to: day.date), hour: 20, minute: 0), fire > now {
                items.append((fire, request(id: "\(prefix)\(day.id).evening", fire: fire, content: eveningContent(day))))
            }
            // 4 mei: herinnering om 17:45 om de vlag halfstok te hijsen
            if day.kind.isHalfMast, prefs.halfMastReminder,
               let fire = time(on: day.date, hour: 17, minute: 45), fire > now {
                items.append((fire, request(id: "\(prefix)\(day.id).halfmast", fire: fire, content: halfMastContent(day))))
            }
        }
        return items.sorted { $0.0 < $1.0 }.map(\.1)
    }

    // MARK: - Inhoud

    static func morningContent(_ day: FlagDay) -> UNMutableNotificationContent {
        let c = UNMutableNotificationContent()
        if day.kind.isHalfMast {
            c.title = "🇳🇱 Vandaag: \(day.title)"
            var body = "Vanavond om 18:00 gaat de vlag halfstok"
            if let sunset = SunCalculator.sunset(on: day.date) {
                body += ", tot zonsondergang (\(FlagFormat.time.string(from: sunset)))"
            }
            c.body = body + ". Om 20:00 uur twee minuten stilte."
        } else if day.kind.isLocalOnly {
            c.title = "🇳🇱 Vandaag is het \(day.title)"
            c.body = "In Den Haag gaat de vlag uit. Elders hoeft dat niet."
        } else {
            c.title = "🇳🇱 Vlag uit! \(day.title)"
            c.body = day.kind.hasPennant
                ? "Vandaag mag de vlag uit, mét oranje wimpel. Hijs de vlag in top."
                : "Vandaag mag de vlag uit, zonder wimpel. Hijs de vlag in top."
        }
        c.sound = .default
        c.threadIdentifier = "vlagdagen"
        c.userInfo = ["flagDayID": day.id]
        if #available(iOS 15.0, *) { c.relevanceScore = 1 }
        return c
    }

    static func eveningContent(_ day: FlagDay) -> UNMutableNotificationContent {
        let c = UNMutableNotificationContent()
        c.title = "Morgen: \(day.title)"
        c.body = day.kind.isHalfMast
            ? "Morgen hangt de vlag vanaf 18:00 halfstok. Ligt de vlag klaar?"
            : (day.kind.hasPennant ? "Leg vlag én wimpel alvast klaar." : "Leg de vlag alvast klaar.")
        c.sound = .default
        c.threadIdentifier = "vlagdagen"
        c.userInfo = ["flagDayID": day.id]
        return c
    }

    static func halfMastContent(_ day: FlagDay) -> UNMutableNotificationContent {
        let c = UNMutableNotificationContent()
        c.title = "Over 15 minuten: vlag halfstok"
        c.body = "Hijs de vlag eerst in top en laat hem dan zakken tot één derde van de mast."
        c.sound = .default
        c.threadIdentifier = "vlagdagen"
        c.userInfo = ["flagDayID": day.id]
        return c
    }

    // MARK: - Helpers

    private static func time(on day: Date, hour: Int, minute: Int) -> Date? {
        FlagCalendar.calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)
    }

    private static func request(id: String, fire: Date, content: UNNotificationContent) -> UNNotificationRequest {
        var comps = FlagCalendar.calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
        comps.timeZone = FlagCalendar.timeZone
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        return UNNotificationRequest(identifier: id, content: content, trigger: trigger)
    }
}
