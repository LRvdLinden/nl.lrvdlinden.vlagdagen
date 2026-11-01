import Foundation

/// Bepaalt wanneer we om een App Store-beoordeling vragen.
///
/// - Eerste keer: 4 uur na het eerste gebruik op dit apparaat.
/// - Daarna: hoogstens één keer per week.
/// - Alleen op een rustig moment (dat bewaakt RootView): een paar seconden na
///   het openen, niet tijdens het openings- of welkomstscherm en niet terwijl
///   er een venster open staat.
///
/// iOS beperkt het systeemvenster daarnaast zelf tot maximaal 3 keer per jaar.
enum ReviewPrompter {
    static let firstDelay: TimeInterval = 4 * 3600
    static let repeatInterval: TimeInterval = 7 * 24 * 3600
    static let settleDelay: Duration = .seconds(3)

    private static let firstUseKey = "review.firstUse"
    private static let lastPromptKey = "review.lastPrompt"

    /// Leg het eerste gebruik op dit apparaat vast (eenmalig).
    static func registerFirstUse(now: Date = Date(), defaults: UserDefaults = .standard) {
        if defaults.object(forKey: firstUseKey) == nil {
            defaults.set(now, forKey: firstUseKey)
        }
    }

    static func isDue(now: Date = Date(), defaults: UserDefaults = .standard) -> Bool {
        isDue(now: now,
              firstUse: defaults.object(forKey: firstUseKey) as? Date,
              lastPrompt: defaults.object(forKey: lastPromptKey) as? Date)
    }

    /// Pure beslisregel (los te testen).
    static func isDue(now: Date, firstUse: Date?, lastPrompt: Date?) -> Bool {
        guard let firstUse, now.timeIntervalSince(firstUse) >= firstDelay else { return false }
        guard let lastPrompt else { return true }
        return now.timeIntervalSince(lastPrompt) >= repeatInterval
    }

    static func markPrompted(now: Date = Date(), defaults: UserDefaults = .standard) {
        defaults.set(now, forKey: lastPromptKey)
    }
}
