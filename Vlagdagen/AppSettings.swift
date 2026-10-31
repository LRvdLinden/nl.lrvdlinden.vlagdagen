import Foundation
import SwiftUI

/// Gebruikersinstellingen, opgeslagen in UserDefaults.
@MainActor
final class AppSettings: ObservableObject {
    private let defaults = UserDefaults.standard

    @Published var notificationsEnabled: Bool { didSet { save(notificationsEnabled, "notificationsEnabled") } }
    @Published var notifyHour: Int { didSet { save(notifyHour, "notifyHour") } }
    @Published var notifyMinute: Int { didSet { save(notifyMinute, "notifyMinute") } }
    @Published var eveningBefore: Bool { didSet { save(eveningBefore, "eveningBefore") } }
    @Published var halfMastReminder: Bool { didSet { save(halfMastReminder, "halfMastReminder") } }
    @Published var includePrinsjesdag: Bool { didSet { save(includePrinsjesdag, "includePrinsjesdag") } }
    @Published var hasOnboarded: Bool { didSet { save(hasOnboarded, "hasOnboarded") } }
    @Published private(set) var mutedKinds: Set<String> { didSet { defaults.set(Array(mutedKinds), forKey: "mutedKinds") } }

    init() {
        defaults.register(defaults: [
            "notificationsEnabled": true,
            "notifyHour": 8,
            "notifyMinute": 0,
            "eveningBefore": false,
            "halfMastReminder": true,
            "includePrinsjesdag": false,
            "hasOnboarded": false,
        ])
        notificationsEnabled = defaults.bool(forKey: "notificationsEnabled")
        notifyHour = defaults.integer(forKey: "notifyHour")
        notifyMinute = defaults.integer(forKey: "notifyMinute")
        eveningBefore = defaults.bool(forKey: "eveningBefore")
        halfMastReminder = defaults.bool(forKey: "halfMastReminder")
        includePrinsjesdag = defaults.bool(forKey: "includePrinsjesdag")
        hasOnboarded = defaults.bool(forKey: "hasOnboarded")
        mutedKinds = Set(defaults.stringArray(forKey: "mutedKinds") ?? [])
    }

    private func save(_ value: Any, _ key: String) { defaults.set(value, forKey: key) }

    /// Tijd van de ochtendmelding, als Date (alleen uur en minuut tellen).
    var notifyTime: Date {
        get {
            Calendar.current.date(bySettingHour: notifyHour, minute: notifyMinute, second: 0, of: Date()) ?? Date()
        }
        set {
            let c = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            notifyHour = c.hour ?? 8
            notifyMinute = c.minute ?? 0
        }
    }

    var notifyTimeLabel: String { String(format: "%02d:%02d", notifyHour, notifyMinute) }

    func isEnabled(_ kind: FlagDayKind) -> Bool {
        if kind == .prinsjesdag { return includePrinsjesdag }
        return !mutedKinds.contains(kind.rawValue)
    }

    func setEnabled(_ kind: FlagDayKind, _ enabled: Bool) {
        if kind == .prinsjesdag {
            includePrinsjesdag = enabled
            return
        }
        if enabled { mutedKinds.remove(kind.rawValue) } else { mutedKinds.insert(kind.rawValue) }
    }

    /// Momentopname voor de planner (niet gebonden aan de main actor).
    var snapshot: NotificationPreferences {
        NotificationPreferences(
            enabled: notificationsEnabled,
            hour: notifyHour,
            minute: notifyMinute,
            eveningBefore: eveningBefore,
            halfMastReminder: halfMastReminder,
            enabledKinds: Set(FlagDayKind.allCases.filter { isEnabled($0) })
        )
    }
}

struct NotificationPreferences: Equatable, Sendable {
    var enabled: Bool
    var hour: Int
    var minute: Int
    var eveningBefore: Bool
    var halfMastReminder: Bool
    var enabledKinds: Set<FlagDayKind>
}
