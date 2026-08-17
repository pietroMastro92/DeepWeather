import Testing
import Foundation
import AppKit
@testable import DeepWeather

@Suite("DeepWeather Unit Tests")
struct DeepWeatherTests {

    @Test("WeatherClient URL and Provider configurations")
    func testWeatherClientProviders() {
        let client = WeatherClient()
        #expect(WeatherProvider.allCases.count == 3)
        #expect(WeatherProvider.auto.displayName == "Auto (Smart Fallback)")
        #expect(WeatherProvider.openMeteo.displayName == "Open-Meteo (Official Models)")
        #expect(WeatherProvider.wttrIn.displayName == "wttr.in (Classic)")
    }

    @Test("LunarPhaseEngine Astronomical Moon Calculation")
    func testLunarPhaseEngine() {
        let date = Date()
        let moonState = LunarPhaseEngine.calculate(for: date)
        #expect(!moonState.phaseName.isEmpty)
        #expect(!moonState.phaseSymbol.isEmpty)
        #expect((0...100).contains(moonState.illuminationPercent))
        #expect(moonState.ageDays >= 0.0 && moonState.ageDays <= LunarPhaseEngine.synodicMonth)
    }

    @Test("WeatherConditionFormatter and Moon Phase Formatter")
    func testFormatters() {
        let sunnyDay = WeatherConditionFormatter.localizedDescription(for: "113", isDay: true)
        #expect(sunnyDay == "Sunny")

        let clearNight = WeatherConditionFormatter.localizedDescription(for: "113", isDay: false)
        #expect(clearNight == "Clear")

        let rainDesc = WeatherConditionFormatter.localizedDescription(for: "308", isDay: true)
        #expect(rainDesc == "Rain")

        let fullMoon = WeatherIconMapper.localizedMoonPhaseName(for: "Full Moon")
        #expect(fullMoon == "Full Moon")
    }

    @Test("SF Symbols Validity Test")
    func testSFSymbolValidity() {
        let codes = ["113", "116", "119", "122", "143", "176", "179", "182", "185", "200", "227", "230", "248", "260", "263", "266", "281", "284", "293", "296", "299", "302", "305", "308", "311", "314", "317", "320", "323", "326", "329", "332", "335", "338", "350", "353", "356", "359", "362", "365", "368", "371", "374", "377", "386", "389", "392", "395", "invalid"]

        for code in codes {
            let daySymbol = WeatherIconMapper.symbol(for: code, isDay: true)
            #expect(!daySymbol.isEmpty)
            #expect(NSImage(systemSymbolName: daySymbol, accessibilityDescription: nil) != nil, "Invalid SF Symbol for day code \(code): \(daySymbol)")

            let nightSymbol = WeatherIconMapper.symbol(for: code, isDay: false)
            #expect(!nightSymbol.isEmpty)
            #expect(NSImage(systemSymbolName: nightSymbol, accessibilityDescription: nil) != nil, "Invalid SF Symbol for night code \(code): \(nightSymbol)")
        }

        let moonPhases = ["New Moon", "Waxing Crescent", "First Quarter", "Waxing Gibbous", "Full Moon", "Waning Gibbous", "Last Quarter", "Waning Crescent"]
        for phase in moonPhases {
            let sym = WeatherIconMapper.moonPhaseSymbol(for: phase)
            #expect(NSImage(systemSymbolName: sym, accessibilityDescription: nil) != nil, "Invalid SF Symbol for moon phase \(phase): \(sym)")
        }
    }

    @Test("Issue #1290 Summer Blizzard Anomaly Detection")
    func testIssue1290AnomalyDetection() throws {
        // 1. Issue #1290 Corrupted wttr.in Data (-2°C Blizzard in London during August)
        let corruptedWttrJSON = """
        {
            "current_condition": [{
                "temp_C": "-2",
                "temp_F": "28",
                "weatherCode": "227",
                "windspeedKmph": "55"
            }],
            "weather": [{
                "date": "2026-08-17",
                "maxtempC": "0",
                "mintempC": "-4"
            }]
        }
        """
        let corruptedWeather = try JSONDecoder().decode(WeatherResponse.self, from: Data(corruptedWttrJSON.utf8))
        let sanityResult = WeatherSanityValidator.validate(corruptedWeather, latitude: 51.5074)
        #expect(!sanityResult.isValid)

        // 2. Normal reasonable weather should pass sanity
        let normalJSON = """
        {
            "current_condition": [{
                "temp_C": "24",
                "temp_F": "75",
                "weatherCode": "113",
                "windspeedKmph": "10"
            }]
        }
        """
        let normalWeather = try JSONDecoder().decode(WeatherResponse.self, from: Data(normalJSON.utf8))
        let normalSanity = WeatherSanityValidator.validate(normalWeather, latitude: 51.5074)
        #expect(normalSanity.isValid)

        // 3. Out-of-bounds planetary temperature should fail
        let extremeJSON = """
        {
            "current_condition": [{
                "temp_C": "85",
                "temp_F": "185",
                "weatherCode": "113"
            }]
        }
        """
        let extremeWeather = try JSONDecoder().decode(WeatherResponse.self, from: Data(extremeJSON.utf8))
        let extremeSanity = WeatherSanityValidator.validate(extremeWeather, latitude: 51.5074)
        #expect(!extremeSanity.isValid)
    }

    @Test("Open-Meteo Adapter Transformation Verification")
    func testOpenMeteoAdapterTransformation() throws {
        let sampleOpenMeteoJSON = """
        {
            "latitude": 51.5,
            "longitude": -0.12,
            "current": {
                "temperature_2m": 25.4,
                "relative_humidity_2m": 45,
                "apparent_temperature": 25.8,
                "precipitation": 0.0,
                "weather_code": 0,
                "cloud_cover": 10,
                "surface_pressure": 1015.0,
                "wind_speed_10m": 12.0
            },
            "hourly": {
                "time": ["2026-08-17T00:00", "2026-08-17T01:00", "2026-08-17T02:00", "2026-08-17T03:00", "2026-08-17T06:00", "2026-08-17T09:00", "2026-08-17T12:00", "2026-08-17T15:00", "2026-08-17T18:00", "2026-08-17T21:00"],
                "temperature_2m": [20.0, 21.0, 22.0, 23.0, 24.0, 25.0, 26.0, 25.0, 23.0, 21.0],
                "relative_humidity_2m": [50, 50, 50, 48, 45, 45, 45, 50, 55, 60],
                "apparent_temperature": [20.0, 21.0, 22.0, 23.0, 24.5, 25.8, 26.5, 25.5, 23.5, 21.5],
                "precipitation_probability": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                "weather_code": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                "wind_speed_10m": [10.0, 10.0, 10.0, 11.0, 11.0, 12.0, 12.0, 11.0, 10.0, 9.0]
            },
            "daily": {
                "time": ["2026-08-17", "2026-08-18", "2026-08-19"],
                "weather_code": [0, 1, 3],
                "temperature_2m_max": [26.5, 25.0, 23.0],
                "temperature_2m_min": [18.0, 17.0, 16.0],
                "sunrise": ["2026-08-17T05:48", "2026-08-18T05:50", "2026-08-19T05:52"],
                "sunset": ["2026-08-17T20:20", "2026-08-18T20:18", "2026-08-19T20:16"],
                "precipitation_probability_max": [0, 10, 20]
            }
        }
        """
        let omDecoded = try JSONDecoder().decode(OpenMeteoAdapter.OpenMeteoResponse.self, from: Data(sampleOpenMeteoJSON.utf8))
        let adapted = OpenMeteoAdapter.adapt(omDecoded, cityName: "London", countryName: "United Kingdom")

        #expect(adapted.currentCondition?.first?.tempC == "25")
        #expect(adapted.currentCondition?.first?.weatherCode == "113")
        #expect(adapted.weather?.count == 3)
        #expect(adapted.weather?.first?.maxtempC == "27")
        #expect(adapted.weather?.first?.mintempC == "18")
        #expect(adapted.weather?.first?.hourly?.count == 8)
        #expect(adapted.nearestArea?.first?.areaName?.first?.value == "London")

        let validSanity = WeatherSanityValidator.validate(adapted, latitude: 51.5074)
        #expect(validSanity.isValid)
    }

    @Test("Weather Alert Detection (Heat, Freeze, Gale, Storm)")
    func testWeatherAlertDetection() throws {
        // 1. Extreme Heat Alert
        let heatJSON = """
        {
            "current_condition": [{
                "temp_C": "39",
                "temp_F": "102",
                "FeelsLikeC": "41",
                "FeelsLikeF": "106",
                "weatherCode": "113"
            }],
            "nearest_area": [{
                "country": [{"value": "Italy"}]
            }],
            "weather": [{
                "date": "2026-08-17",
                "maxtempC": "39",
                "mintempC": "26"
            }]
        }
        """
        let heatWeather = try JSONDecoder().decode(WeatherResponse.self, from: Data(heatJSON.utf8))
        let heatAlerts = WeatherAlert.detectAlerts(from: heatWeather, useMetric: true)
        #expect(!heatAlerts.isEmpty)
        #expect(heatAlerts.first?.category == .highHeat)
        #expect(heatAlerts.first?.severity == .warning)
        #expect(heatAlerts.first?.source.contains("Protezione Civile") == true)

        // 2. Severe Storm Alert
        let stormJSON = """
        {
            "current_condition": [{
                "temp_C": "18",
                "temp_F": "64",
                "weatherCode": "389"
            }],
            "weather": [{
                "date": "2026-08-17",
                "maxtempC": "20",
                "mintempC": "14"
            }]
        }
        """
        let stormWeather = try JSONDecoder().decode(WeatherResponse.self, from: Data(stormJSON.utf8))
        let stormAlerts = WeatherAlert.detectAlerts(from: stormWeather, useMetric: true)
        #expect(!stormAlerts.isEmpty)
        #expect(stormAlerts.first?.category == .severeStorm)

        // 3. Mild weather should have 0 alerts
        let mildJSON = """
        {
            "current_condition": [{
                "temp_C": "22",
                "temp_F": "72",
                "FeelsLikeC": "22",
                "FeelsLikeF": "72",
                "weatherCode": "116",
                "windspeedKmph": "10"
            }],
            "weather": [{
                "date": "2026-08-17",
                "maxtempC": "24",
                "mintempC": "16"
            }]
        }
        """
        let mildWeather = try JSONDecoder().decode(WeatherResponse.self, from: Data(mildJSON.utf8))
        let mildAlerts = WeatherAlert.detectAlerts(from: mildWeather, useMetric: true)
        #expect(mildAlerts.isEmpty)
    }

    @Test("WeatherStore Settings, Provider Switching, and Units")
    @MainActor
    func testWeatherStoreSettings() {
        let store = WeatherStore()

        store.weatherProvider = .openMeteo
        #expect(store.weatherProvider == .openMeteo)

        store.weatherProvider = .auto
        #expect(store.weatherProvider == .auto)

        store.refreshIntervalMinutes = 30
        #expect(store.refreshIntervalMinutes == 30)

        store.useMetric = true
        #expect(store.useMetric == true)
        #expect(store.temperatureUnitSymbol == "°C")

        store.useMetric = false
        #expect(store.temperatureUnitSymbol == "°F")
    }
}
