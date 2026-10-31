import Foundation

/// Agenda-abonnement op alle vlagdagen (iCal-feed van vlagdagen.nl).
enum CalendarSubscription {
    /// Pad van de feed op vlagdagen.nl (Base44 backend function).
    static let feedPath = "vlagdagen.nl/api/functions/generateFlagDaysICS"

    /// Opent op iPhone het systeemvenster "Abonneer op agenda".
    static var appleURL: URL { URL(string: "webcal://\(feedPath)")! }

    /// Opent Google Agenda met het abonnement voorgevuld.
    static var googleURL: URL {
        var c = URLComponents(string: "https://calendar.google.com/calendar/render")!
        c.queryItems = [URLQueryItem(name: "cid", value: "webcal://\(feedPath)")]
        return c.url!
    }

    /// Outlook.com
    static var outlookURL: URL {
        var c = URLComponents(string: "https://outlook.live.com/calendar/0/addfromweb")!
        c.queryItems = [
            URLQueryItem(name: "url", value: "https://\(feedPath)"),
            URLQueryItem(name: "name", value: "Nederlandse Vlagdagen"),
        ]
        return c.url!
    }

    static var httpsURL: URL { URL(string: "https://\(feedPath)")! }
}
