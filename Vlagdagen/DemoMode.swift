import Foundation

/// Demo-modus voor App Store-screenshots, via launch-argumenten:
///   -demoDate 2027-04-27T09:41   doe alsof het die datum/tijd is
///   -demoTab today|agenda|guide|faq|settings
///   -demoFlagDay <id>             open een vlagdag (bv. dodenherdenking-2027-05-04)
///   -demoGuide hijsen|halfstok|wimpel
///   -skipSplash YES
/// In gewone builds zonder deze argumenten verandert er niets.
enum DemoMode {
    private static let args = ProcessInfo.processInfo.arguments

    static func value(_ key: String) -> String? {
        guard let i = args.firstIndex(of: "-\(key)"), i + 1 < args.count else { return nil }
        return args[i + 1]
    }

    static let isActive = value("demoDate") != nil

    private static let offset: TimeInterval = {
        guard let raw = value("demoDate") else { return 0 }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = FlagCalendar.timeZone
        f.dateFormat = raw.contains("T") ? "yyyy-MM-dd'T'HH:mm" : "yyyy-MM-dd"
        guard let target = f.date(from: raw) else { return 0 }
        return target.timeIntervalSinceNow
    }()

    /// "Nu", eventueel verschoven naar de demo-datum
    static var now: Date { Date().addingTimeInterval(offset) }

    static func adjust(_ date: Date) -> Date { date.addingTimeInterval(offset) }

    static var skipSplash: Bool { value("skipSplash") == "YES" }

    static var tab: Router.Tab? {
        switch value("demoTab") {
        case "today": return .today
        case "agenda": return .agenda
        case "guide": return .guide
        case "faq": return .faq
        case "settings": return .settings
        default: return nil
        }
    }

    static var flagDayID: String? { value("demoFlagDay") }
    static var guide: String? { value("demoGuide") }
}
