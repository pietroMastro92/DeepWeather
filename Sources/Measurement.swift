import Foundation

enum MeasurementID: String, CaseIterable, Identifiable {
    case feels
    case humidity
    case wind
    case uv
    case pressure
    case visibility
    case precipitation
    case cloudcover
    case sunrise
    case sunset
    case moonrise
    case moonset

    var id: String { rawValue }

    var title: String {
        switch self {
        case .feels: return "Feels like"
        case .humidity: return "Humidity"
        case .wind: return "Wind"
        case .uv: return "UV index"
        case .pressure: return "Pressure"
        case .visibility: return "Visibility"
        case .precipitation: return "Precipitation"
        case .cloudcover: return "Cloud cover"
        case .sunrise: return "Sunrise"
        case .sunset: return "Sunset"
        case .moonrise: return "Moonrise"
        case .moonset: return "Moonset"
        }
    }

    static let conditions: [MeasurementID] = [
        .feels, .humidity, .wind, .uv, .pressure, .visibility, .precipitation, .cloudcover
    ]

    static let sunAndMoonTimes: [MeasurementID] = [
        .sunrise, .sunset, .moonrise, .moonset
    ]
}
