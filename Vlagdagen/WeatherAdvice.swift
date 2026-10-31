import Foundation

/// Vlagadvies op basis van het actuele weer (Open-Meteo, geen API-sleutel nodig).
struct WeatherAdvice: Equatable {
    enum Level { case good, caution, no }

    let level: Level
    let title: String
    let detail: String
    let windKmh: Double
    let gustKmh: Double
    let temperature: Double

    var symbol: String {
        switch level {
        case .good: return "flag.fill"
        case .caution: return "wind"
        case .no: return "exclamationmark.triangle.fill"
        }
    }

    static func evaluate(wind: Double, gust: Double, precipitation: Double, code: Int, temperature: Double) -> WeatherAdvice {
        let thunder = (95...99).contains(code)
        if gust >= 75 || thunder {
            return WeatherAdvice(level: .no, title: "Liever niet vlaggen",
                                 detail: thunder ? "Er is onweer. Haal de vlag binnen." : "Zware windstoten (\(Int(gust)) km/u). Een vlag kan scheuren of de mast belasten.",
                                 windKmh: wind, gustKmh: gust, temperature: temperature)
        }
        if precipitation >= 0.5 || gust >= 55 {
            return WeatherAdvice(level: .caution, title: "Vlaggen kan, let op",
                                 detail: precipitation >= 0.5 ? "Het regent. Een natte vlag wordt zwaar; haal hem bij aanhoudende regen binnen." : "Stevige wind (\(Int(gust)) km/u). Controleer of de vlag goed vastzit.",
                                 windKmh: wind, gustKmh: gust, temperature: temperature)
        }
        return WeatherAdvice(level: .good, title: "Goed weer om te vlaggen",
                             detail: "Een vlag hoort fier in de wind. Haal hem bij storm, regen of schemering bij voorkeur binnen.",
                             windKmh: wind, gustKmh: gust, temperature: temperature)
    }
}

enum WeatherService {
    private struct Response: Decodable {
        struct Current: Decodable {
            let temperature_2m: Double
            let wind_speed_10m: Double
            let wind_gusts_10m: Double
            let precipitation: Double
            let weather_code: Int
        }
        let current: Current
    }

    static func fetch(latitude: Double = SunCalculator.defaultLatitude,
                      longitude: Double = SunCalculator.defaultLongitude) async throws -> WeatherAdvice {
        var c = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        c.queryItems = [
            .init(name: "latitude", value: String(latitude)),
            .init(name: "longitude", value: String(longitude)),
            .init(name: "current", value: "temperature_2m,wind_speed_10m,wind_gusts_10m,precipitation,weather_code"),
            .init(name: "wind_speed_unit", value: "kmh"),
            .init(name: "timezone", value: "Europe/Amsterdam"),
        ]
        let (data, _) = try await URLSession.shared.data(from: c.url!)
        let r = try JSONDecoder().decode(Response.self, from: data).current
        return .evaluate(wind: r.wind_speed_10m, gust: r.wind_gusts_10m, precipitation: r.precipitation,
                         code: r.weather_code, temperature: r.temperature_2m)
    }
}
