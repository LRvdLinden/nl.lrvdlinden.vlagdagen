import XCTest
import UserNotifications
@testable import Vlagdagen

final class FlagCalendarTests: XCTestCase {
    private func keys(_ year: Int) -> [String: String] {
        Dictionary(uniqueKeysWithValues: FlagCalendar.flagDays(in: year).map { ($0.kind.rawValue, FlagCalendar.key($0.date)) })
    }

    func testEaster() {
        XCTAssertEqual(FlagCalendar.key(FlagCalendar.easter(2025)), "2025-04-20")
        XCTAssertEqual(FlagCalendar.key(FlagCalendar.easter(2026)), "2026-04-05")
        XCTAssertEqual(FlagCalendar.key(FlagCalendar.easter(2027)), "2027-03-28")
    }

    func test2026() {
        XCTAssertEqual(keys(2026), [
            "beatrix": "2026-01-31",
            "koningsdag": "2026-04-27",
            "dodenherdenking": "2026-05-04",
            "bevrijdingsdag": "2026-05-05",
            "maxima": "2026-05-18",        // 17 mei = zondag
            "veteranendag": "2026-06-27",  // laatste zaterdag van juni
            "einde-wo2": "2026-08-15",
            "prinsjesdag": "2026-09-15",   // derde dinsdag van september
            "amalia": "2026-12-07",
            "koninkrijksdag": "2026-12-15",
        ])
    }

    func test2027() {
        XCTAssertEqual(keys(2027), [
            "beatrix": "2027-02-01",       // 31 januari = zondag
            "koningsdag": "2027-04-27",
            "dodenherdenking": "2027-05-04",
            "bevrijdingsdag": "2027-05-05",
            "maxima": "2027-05-18",        // 17 mei = Tweede Pinksterdag
            "veteranendag": "2027-06-26",
            "einde-wo2": "2027-08-16",     // 15 augustus = zondag
            "prinsjesdag": "2027-09-21",
            "amalia": "2027-12-07",
            "koninkrijksdag": "2027-12-15",
        ])
    }

    func testKingsDayMovesToSaturday() {
        // 27 april 2025 was een zondag
        XCTAssertEqual(keys(2025)["koningsdag"], "2025-04-26")
    }

    func testShiftedFlag() {
        let maxima = FlagCalendar.flagDays(in: 2026).first { $0.kind == .maxima }!
        XCTAssertTrue(maxima.isShifted)
        XCTAssertEqual(FlagCalendar.key(maxima.officialDate), "2026-05-17")
    }

    func testFlagDayOnAndNext() {
        let d = FlagCalendar.date(2026, 12, 7)
        XCTAssertEqual(FlagCalendar.flagDay(on: d.addingTimeInterval(9 * 3600))?.kind, .amalia)
        XCTAssertNil(FlagCalendar.flagDay(on: FlagCalendar.date(2026, 10, 31)))
        XCTAssertEqual(FlagCalendar.next(after: FlagCalendar.date(2026, 10, 31))?.kind, .amalia)
        XCTAssertEqual(FlagCalendar.next(after: d)?.kind, .koninkrijksdag)
        XCTAssertEqual(FlagCalendar.next(after: FlagCalendar.date(2026, 12, 20)).map { FlagCalendar.key($0.date) }, "2027-02-01")
    }

    func testPennant() {
        XCTAssertEqual(Set(FlagDayKind.allCases.filter(\.hasPennant)), [.koningsdag, .beatrix, .maxima, .amalia])
    }

    func testSunsetOnRemembranceDay() {
        let sunset = SunCalculator.sunset(on: FlagCalendar.date(2026, 5, 4))!
        let c = FlagCalendar.calendar.dateComponents([.hour, .minute], from: sunset)
        XCTAssertEqual(c.hour, 21)
        XCTAssertTrue((5...12).contains(c.minute!), "Zonsondergang 4 mei rond 21:09, kreeg \(c)")
    }

    func testNotificationRequestsStayUnderLimit() {
        let prefs = NotificationPreferences(enabled: true, hour: 8, minute: 0, eveningBefore: true,
                                            halfMastReminder: true, enabledKinds: Set(FlagDayKind.allCases))
        let requests = NotificationScheduler.makeRequests(prefs, now: FlagCalendar.date(2026, 10, 31))
        XCTAssertLessThanOrEqual(requests.count, 64)
        let first = requests.first!.trigger as! UNCalendarNotificationTrigger
        XCTAssertEqual(first.dateComponents.day, 6)   // avond ervoor
        XCTAssertEqual(first.dateComponents.hour, 20)
        XCTAssertTrue(requests.contains { $0.identifier.hasSuffix(".halfmast") })
    }
}

@MainActor
final class AppSettingsTests: XCTestCase {
    func testNotifyTimeRoundTrip() {
        let settings = AppSettings()
        settings.notifyHour = 8
        settings.notifyMinute = 0
        let c = FlagCalendar.calendar.dateComponents([.hour, .minute], from: settings.notifyTime)
        XCTAssertEqual(c.hour, 8)
        XCTAssertEqual(c.minute, 0)
        settings.notifyTime = FlagCalendar.calendar.date(bySettingHour: 7, minute: 30, second: 0, of: Date())!
        XCTAssertEqual(settings.notifyHour, 7)
        XCTAssertEqual(settings.notifyMinute, 30)
        settings.notifyHour = 8
        settings.notifyMinute = 0
    }
}
