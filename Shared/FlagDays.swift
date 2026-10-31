import Foundation

// MARK: - Soorten vlagdagen (bron: algemene vlaginstructie, rijksoverheid.nl)

enum FlagScope: String, Codable {
    /// Vlag uit op alle gebouwen van de Rijksoverheid
    case uitgebreid
    /// Vlag uit op enkele (hoofd)gebouwen van de Rijksoverheid
    case beperkt

    var label: String {
        switch self {
        case .uitgebreid: return "Uitgebreid vlaggen"
        case .beperkt: return "Beperkt vlaggen"
        }
    }
}

enum FlagDayKind: String, CaseIterable, Codable, Identifiable {
    case beatrix
    case koningsdag
    case dodenherdenking
    case bevrijdingsdag
    case maxima
    case veteranendag
    case eindeWO2 = "einde-wo2"
    case prinsjesdag
    case amalia
    case koninkrijksdag

    var id: String { rawValue }

    var title: String {
        switch self {
        case .beatrix: return "Verjaardag prinses Beatrix"
        case .koningsdag: return "Koningsdag"
        case .dodenherdenking: return "Dodenherdenking"
        case .bevrijdingsdag: return "Bevrijdingsdag"
        case .maxima: return "Verjaardag koningin Máxima"
        case .veteranendag: return "Veteranendag"
        case .eindeWO2: return "Formeel einde Tweede Wereldoorlog"
        case .prinsjesdag: return "Prinsjesdag"
        case .amalia: return "Verjaardag prinses Catharina-Amalia"
        case .koninkrijksdag: return "Koninkrijksdag"
        }
    }

    var shortTitle: String {
        switch self {
        case .beatrix: return "Prinses Beatrix"
        case .maxima: return "Koningin Máxima"
        case .amalia: return "Prinses Amalia"
        case .eindeWO2: return "Einde WOII"
        default: return title
        }
    }

    /// Oranje wimpel boven de vlag
    var hasPennant: Bool {
        switch self {
        case .koningsdag, .beatrix, .maxima, .amalia: return true
        default: return false
        }
    }

    /// Vlag halfstok (4 mei, van 18:00 tot zonsondergang)
    var isHalfMast: Bool { self == .dodenherdenking }

    /// Alleen lokaal van toepassing
    var isLocalOnly: Bool { self == .prinsjesdag }

    var scope: FlagScope {
        switch self {
        case .beatrix, .maxima, .amalia, .koninkrijksdag: return .beperkt
        default: return .uitgebreid
        }
    }

    /// 4 en 5 mei schuiven nooit op.
    var canShift: Bool {
        switch self {
        case .dodenherdenking, .bevrijdingsdag, .veteranendag, .prinsjesdag: return false
        default: return true
        }
    }

    var symbol: String {
        switch self {
        case .koningsdag: return "crown.fill"
        case .beatrix, .maxima, .amalia: return "gift.fill"
        case .dodenherdenking: return "flame.fill"
        case .bevrijdingsdag: return "sparkles"
        case .veteranendag: return "medal.fill"
        case .eindeWO2: return "bird.fill"
        case .prinsjesdag: return "building.columns.fill"
        case .koninkrijksdag: return "globe.europe.africa.fill"
        }
    }

    /// Korte instructie: hoe hang je de vlag vandaag
    var instruction: String {
        switch self {
        case .dodenherdenking:
            return "Vlag halfstok van 18:00 uur tot zonsondergang."
        case .prinsjesdag:
            return "Alleen in Den Haag wordt gevlagd."
        default:
            return hasPennant ? "Vlag in top, met oranje wimpel." : "Vlag in top, zonder wimpel."
        }
    }

    var about: String {
        switch self {
        case .beatrix:
            return "Prinses Beatrix werd geboren op 31 januari 1938. Zij was van 1980 tot 2013 koningin der Nederlanden."
        case .koningsdag:
            return "De verjaardag van koning Willem-Alexander (27 april 1967). Valt 27 april op een zondag, dan wordt Koningsdag op zaterdag 26 april gevierd."
        case .dodenherdenking:
            return "Op 4 mei herdenken we alle burgers en militairen die in het Koninkrijk der Nederlanden of waar ook ter wereld zijn omgekomen sinds het uitbreken van de Tweede Wereldoorlog. Om 20:00 uur twee minuten stilte."
        case .bevrijdingsdag:
            return "Op 5 mei vieren we de bevrijding van Nederland in 1945, en staan we stil bij vrijheid, democratie en rechtsstaat."
        case .maxima:
            return "Koningin Máxima werd geboren op 17 mei 1971."
        case .veteranendag:
            return "Op de laatste zaterdag van juni eren we veteranen die zich hebben ingezet voor vrede en veiligheid. Het nationale defilé is in Den Haag."
        case .eindeWO2:
            return "Op 15 augustus 1945 capituleerde Japan. Daarmee kwam formeel een einde aan de Tweede Wereldoorlog, ook in het voormalig Nederlands-Indië."
        case .prinsjesdag:
            return "Op de derde dinsdag van september opent de koning het parlementaire jaar met de Troonrede. Alleen in Den Haag wordt gevlagd."
        case .amalia:
            return "Prinses Catharina-Amalia, de Prinses van Oranje, werd geboren op 7 december 2003."
        case .koninkrijksdag:
            return "Op 15 december 1954 werd het Statuut voor het Koninkrijk der Nederlanden ondertekend."
        }
    }
}

// MARK: - Een concrete vlagdag in een jaar

struct FlagDay: Identifiable, Hashable {
    let kind: FlagDayKind
    /// De dag waarop gevlagd wordt (00:00 Europe/Amsterdam)
    let date: Date
    /// De dag volgens de vaste lijst, vóór een eventuele verschuiving
    let officialDate: Date

    var id: String { "\(kind.rawValue)-\(FlagCalendar.key(date))" }
    var isShifted: Bool { date != officialDate }
    var title: String { kind.title }
}

// MARK: - Berekening

enum FlagCalendar {
    static let timeZone = TimeZone(identifier: "Europe/Amsterdam")!

    static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        cal.locale = Locale(identifier: "nl_NL")
        return cal
    }()

    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    static func addDays(_ days: Int, to date: Date) -> Date {
        calendar.date(byAdding: .day, value: days, to: date)!
    }

    static func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    static func key(_ date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }

    /// Paaszondag (Gregoriaans, anonieme algoritme van Meeus/Jones/Butcher)
    static func easter(_ year: Int) -> Date {
        let a = year % 19
        let b = year / 100
        let c = year % 100
        let d = b / 4
        let e = b % 4
        let f = (b + 8) / 25
        let g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4
        let k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let month = (h + l - 7 * m + 114) / 31
        let day = ((h + l - 7 * m + 114) % 31) + 1
        return date(year, month, day)
    }

    /// Algemeen erkende christelijke feestdagen
    static func christianHolidays(_ year: Int) -> Set<Date> {
        let e = easter(year)
        return [
            e,                    // Eerste Paasdag
            addDays(1, to: e),    // Tweede Paasdag
            addDays(39, to: e),   // Hemelvaartsdag
            addDays(49, to: e),   // Eerste Pinksterdag
            addDays(50, to: e),   // Tweede Pinksterdag
            date(year, 12, 25),   // Eerste Kerstdag
            date(year, 12, 26),   // Tweede Kerstdag
        ]
    }

    static func isSundayOrHoliday(_ day: Date) -> Bool {
        let year = calendar.component(.year, from: day)
        return calendar.component(.weekday, from: day) == 1 || christianHolidays(year).contains(day)
    }

    /// Schuift door naar de eerstvolgende dag die geen zondag of christelijke feestdag is.
    static func shiftForward(_ day: Date) -> Date {
        var d = day
        while isSundayOrHoliday(d) { d = addDays(1, to: d) }
        return d
    }

    static func flagDays(in year: Int) -> [FlagDay] {
        func fixed(_ kind: FlagDayKind, _ month: Int, _ day: Int) -> FlagDay {
            let official = date(year, month, day)
            return FlagDay(kind: kind, date: kind.canShift ? shiftForward(official) : official, officialDate: official)
        }

        // Koningsdag: valt 27 april op zondag (of een christelijke feestdag), dan 26 april.
        let kingsOfficial = date(year, 4, 27)
        let kingsDay = isSundayOrHoliday(kingsOfficial) ? date(year, 4, 26) : kingsOfficial

        // Veteranendag: laatste zaterdag van juni
        var veterans = date(year, 6, 30)
        while calendar.component(.weekday, from: veterans) != 7 { veterans = addDays(-1, to: veterans) }

        // Prinsjesdag: derde dinsdag van september
        var tuesday = date(year, 9, 1)
        while calendar.component(.weekday, from: tuesday) != 3 { tuesday = addDays(1, to: tuesday) }
        let princes = addDays(14, to: tuesday)

        return [
            fixed(.beatrix, 1, 31),
            FlagDay(kind: .koningsdag, date: kingsDay, officialDate: kingsOfficial),
            fixed(.dodenherdenking, 5, 4),
            fixed(.bevrijdingsdag, 5, 5),
            fixed(.maxima, 5, 17),
            FlagDay(kind: .veteranendag, date: veterans, officialDate: veterans),
            fixed(.eindeWO2, 8, 15),
            FlagDay(kind: .prinsjesdag, date: princes, officialDate: princes),
            fixed(.amalia, 12, 7),
            fixed(.koninkrijksdag, 12, 15),
        ].sorted { $0.date < $1.date }
    }

    /// Vlagdag op deze dag, of nil
    static func flagDay(on day: Date) -> FlagDay? {
        let start = startOfDay(day)
        let year = calendar.component(.year, from: start)
        return flagDays(in: year).first { $0.date == start }
    }

    /// Vlagdagen vanaf (en inclusief) vandaag
    static func upcoming(from now: Date = .now, limit: Int = 12) -> [FlagDay] {
        let today = startOfDay(now)
        let year = calendar.component(.year, from: today)
        var result: [FlagDay] = []
        var y = year
        while result.count < limit && y <= year + 10 {
            result += flagDays(in: y).filter { $0.date >= today }
            y += 1
        }
        return Array(result.prefix(limit))
    }

    /// Eerstvolgende vlagdag ná vandaag
    static func next(after now: Date = .now) -> FlagDay? {
        let today = startOfDay(now)
        return upcoming(from: addDays(1, to: today), limit: 1).first
    }

    static func daysUntil(_ day: FlagDay, from now: Date = .now) -> Int {
        calendar.dateComponents([.day], from: startOfDay(now), to: day.date).day ?? 0
    }
}

// MARK: - Zonsondergang (voor halfstok op 4 mei)

enum SunCalculator {
    /// De Bilt, als centraal punt in Nederland
    static let defaultLatitude = 52.10
    static let defaultLongitude = 5.18

    /// Zonsondergang op de gegeven dag (NOAA-benadering, nauwkeurig tot ~1 minuut).
    static func sunset(on day: Date, latitude: Double = defaultLatitude, longitude: Double = defaultLongitude) -> Date? {
        let cal = FlagCalendar.calendar
        let comps = cal.dateComponents([.year, .month, .day], from: day)
        guard let n = cal.ordinality(of: .day, in: .year, for: day) else { return nil }

        func rad(_ d: Double) -> Double { d * .pi / 180 }
        func deg(_ r: Double) -> Double { r * 180 / .pi }
        func norm(_ v: Double, _ m: Double) -> Double { let r = v.truncatingRemainder(dividingBy: m); return r < 0 ? r + m : r }

        let lngHour = longitude / 15
        let t = Double(n) + ((18 - lngHour) / 24)
        let meanAnomaly = 0.9856 * t - 3.289
        let trueLong = norm(meanAnomaly + 1.916 * sin(rad(meanAnomaly)) + 0.020 * sin(rad(2 * meanAnomaly)) + 282.634, 360)
        var ra = norm(deg(atan(0.91764 * tan(rad(trueLong)))), 360)
        ra += floor(trueLong / 90) * 90 - floor(ra / 90) * 90
        ra /= 15
        let sinDec = 0.39782 * sin(rad(trueLong))
        let cosDec = cos(asin(sinDec))
        let cosH = (cos(rad(90.833)) - sinDec * sin(rad(latitude))) / (cosDec * cos(rad(latitude)))
        guard cosH >= -1, cosH <= 1 else { return nil }
        let h = deg(acos(cosH)) / 15
        let localMeanTime = h + ra - 0.06571 * t - 6.622
        let ut = norm(localMeanTime - lngHour, 24)

        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        guard let midnightUTC = utc.date(from: DateComponents(year: comps.year, month: comps.month, day: comps.day)) else { return nil }
        return midnightUTC.addingTimeInterval(ut * 3600)
    }
}

// MARK: - Opmaak

enum FlagFormat {
    static let dayMonth: DateFormatter = make("d MMMM")
    static let full: DateFormatter = make("EEEE d MMMM yyyy")
    static let weekday: DateFormatter = make("EEEE")
    static let shortWeekday: DateFormatter = make("EEE")
    static let time: DateFormatter = make("HH:mm")
    static let month: DateFormatter = make("MMM")

    private static func make(_ format: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "nl_NL")
        f.timeZone = FlagCalendar.timeZone
        f.dateFormat = format
        return f
    }

    static func relative(_ days: Int) -> String {
        switch days {
        case 0: return "Vandaag"
        case 1: return "Morgen"
        default: return "Over \(days) dagen"
        }
    }
}

extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}
