import SwiftUI

#if DEBUG

@MainActor
private enum WeatherPreviewData {
    static let milan = SavedLocation(
        id: "milan",
        name: "Milan",
        detail: "Lombardy, Italy",
        latitude: 45.46,
        longitude: 9.19
    )
    static let rome = SavedLocation(
        id: "rome",
        name: "Rome",
        detail: "Lazio, Italy",
        latitude: 41.90,
        longitude: 12.50
    )
    static let london = SavedLocation(
        id: "london",
        name: "London",
        detail: "England, United Kingdom",
        latitude: 51.51,
        longitude: -0.13
    )
    static let tokyo = SavedLocation(
        id: "tokyo",
        name: "Tokyo",
        detail: "Tokyo, Japan",
        latitude: 35.68,
        longitude: 139.69
    )

    static var locations: [SavedLocation] { [milan, rome, london, tokyo] }

    static func loadedStore() -> WeatherStore {
        WeatherStore(
            previewWeather: forecast,
            locations: locations,
            selectedID: milan.id,
            lastUpdated: Date()
        )
    }

    static func alertStore() -> WeatherStore {
        WeatherStore(
            previewWeather: heatwaveForecast,
            locations: locations,
            selectedID: rome.id,
            lastUpdated: Date()
        )
    }

    static func loadingStore() -> WeatherStore {
        WeatherStore(previewWeather: nil, locations: locations, isLoading: true)
    }

    static func errorStore() -> WeatherStore {
        WeatherStore(
            previewWeather: forecast,
            locations: locations,
            selectedID: milan.id,
            errorMessage: "No internet connection.",
            lastUpdated: Date()
        )
    }

    static var forecast: WeatherResponse {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let days = (0..<3).compactMap { offset -> DayForecast? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { return nil }
            return dayForecast(date: date, offset: offset)
        }
        return WeatherResponse(
            currentCondition: [current],
            nearestArea: [
                NearestArea(
                    areaName: [TextValue(value: "Milan")],
                    country: [TextValue(value: "Italy")],
                    region: [TextValue(value: "Lombardy")],
                    latitude: "45.46",
                    longitude: "9.19"
                )
            ],
            weather: days
        )
    }

    static var heatwaveForecast: WeatherResponse {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let days = (0..<3).compactMap { offset -> DayForecast? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { return nil }
            return dayForecast(date: date, offset: offset, isHeatwave: true)
        }
        return WeatherResponse(
            currentCondition: [heatCurrent],
            nearestArea: [
                NearestArea(
                    areaName: [TextValue(value: "Rome")],
                    country: [TextValue(value: "Italy")],
                    region: [TextValue(value: "Lazio")],
                    latitude: "41.90",
                    longitude: "12.50"
                )
            ],
            weather: days
        )
    }

    private static var current: CurrentCondition {
        CurrentCondition(
            tempC: "18",
            tempF: "64",
            feelsLikeC: "16",
            feelsLikeF: "61",
            humidity: "62",
            cloudcover: "40",
            pressure: "1016",
            pressureInches: "30.0",
            uvIndex: "4",
            visibility: "10",
            visibilityMiles: "6",
            precipMM: "0.2",
            precipInches: "0.01",
            windspeedKmph: "14",
            windspeedMiles: "9",
            winddirDegree: "240",
            winddir16Point: "SW",
            weatherCode: "116",
            observationTime: "10:00 AM",
            weatherDesc: [TextValue(value: "Partly cloudy")]
        )
    }

    private static var heatCurrent: CurrentCondition {
        CurrentCondition(
            tempC: "38",
            tempF: "100",
            feelsLikeC: "41",
            feelsLikeF: "106",
            humidity: "45",
            cloudcover: "10",
            pressure: "1012",
            pressureInches: "29.9",
            uvIndex: "9",
            visibility: "10",
            visibilityMiles: "6",
            precipMM: "0.0",
            precipInches: "0.0",
            windspeedKmph: "8",
            windspeedMiles: "5",
            winddirDegree: "180",
            winddir16Point: "S",
            weatherCode: "113",
            observationTime: "02:00 PM",
            weatherDesc: [TextValue(value: "Sunny")]
        )
    }

    private static func dayForecast(date: Date, offset: Int, isHeatwave: Bool = false) -> DayForecast {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        let phases = ["Waxing Crescent", "First Quarter", "Waxing Gibbous"]
        let maxC = isHeatwave ? (offset == 0 ? "39" : "38") : (offset == 0 ? "20" : "22")
        let minC = isHeatwave ? "25" : "11"
        return DayForecast(
            date: formatter.string(from: date),
            maxtempC: maxC,
            mintempC: minC,
            maxtempF: isHeatwave ? "102" : "70",
            mintempF: isHeatwave ? "77" : "52",
            avgtempC: isHeatwave ? "32" : "16",
            avgtempF: isHeatwave ? "90" : "61",
            totalSnowCm: "0",
            sunHour: "12",
            uvIndex: isHeatwave ? "9" : "4",
            astronomy: [
                Astronomy(
                    sunrise: "06:21 AM",
                    sunset: "08:04 PM",
                    moonrise: "03:12 PM",
                    moonset: "02:40 AM",
                    moonPhase: phases[offset],
                    moonIllumination: "\(35 + offset * 20)"
                )
            ],
            hourly: (0...7).map { index in
                hourly(slot: index * 3, offset: offset, isHeatwave: isHeatwave)
            }
        )
    }

    private static func hourly(slot: Int, offset: Int, isHeatwave: Bool = false) -> HourlyForecast {
        let temp = isHeatwave ? (28 + slot + offset) : (12 + slot / 2 + offset)
        return HourlyForecast(
            time: "\(slot * 100)",
            tempC: "\(temp)",
            tempF: "\(temp * 2 + 32)",
            feelsLikeC: "\(temp - 1)",
            feelsLikeF: "\(temp * 2 + 30)",
            weatherCode: slot < 6 ? "116" : "176",
            weatherDesc: [TextValue(value: slot < 6 ? "Partly cloudy" : "Light rain")],
            windspeedKmph: "12",
            windspeedMiles: "7",
            winddirDegree: "220",
            winddir16Point: "SW",
            precipMM: slot < 6 ? "0" : "0.4",
            precipInches: "0",
            humidity: "60",
            cloudcover: "40",
            pressure: "1015",
            uvIndex: "3",
            chanceofrain: slot < 6 ? "10" : "40",
            chanceofsnow: "0",
            chanceofsunshine: "70",
            visibility: "10"
        )
    }
}

#Preview("13-inch loaded") {
    MenuView(
        store: WeatherPreviewData.loadedStore(),
        updateChecker: UpdateChecker(),
        metricsOverride: .compact
    )
}

#Preview("13-inch weather alert") {
    MenuView(
        store: WeatherPreviewData.alertStore(),
        updateChecker: UpdateChecker(),
        metricsOverride: .compact
    )
}

#Preview("14/15-inch loaded") {
    MenuView(
        store: WeatherPreviewData.loadedStore(),
        updateChecker: UpdateChecker(),
        metricsOverride: .regular
    )
}

#Preview("16-inch loaded") {
    MenuView(
        store: WeatherPreviewData.loadedStore(),
        updateChecker: UpdateChecker(),
        metricsOverride: .roomy
    )
}

#Preview("13-inch loading") {
    MenuView(
        store: WeatherPreviewData.loadingStore(),
        updateChecker: UpdateChecker(),
        metricsOverride: .compact
    )
}

#Preview("13-inch error") {
    MenuView(
        store: WeatherPreviewData.errorStore(),
        updateChecker: UpdateChecker(),
        metricsOverride: .compact
    )
}

#Preview("13-inch settings") {
    MenuView(
        store: WeatherPreviewData.loadedStore(),
        updateChecker: UpdateChecker(),
        metricsOverride: .compact,
        showSettings: true
    )
}

#endif
