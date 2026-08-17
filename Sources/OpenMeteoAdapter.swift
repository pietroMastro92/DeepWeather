import Foundation

/// Decodes Open-Meteo API response and adapts it to DeepWeather's unified `WeatherResponse` domain model.
struct OpenMeteoAdapter: Sendable {
    // Open-Meteo API response schema
    struct OpenMeteoResponse: Decodable, Sendable {
        let latitude: Double
        let longitude: Double
        let timezone: String?
        let current: Current?
        let hourly: Hourly?
        let daily: Daily?

        struct Current: Decodable, Sendable {
            let time: String?
            let temperature_2m: Double?
            let relative_humidity_2m: Int?
            let apparent_temperature: Double?
            let precipitation: Double?
            let weather_code: Int?
            let cloud_cover: Int?
            let surface_pressure: Double?
            let wind_speed_10m: Double?
            let wind_direction_10m: Int?
        }

        struct Hourly: Decodable, Sendable {
            let time: [String]?
            let temperature_2m: [Double]?
            let relative_humidity_2m: [Int]?
            let apparent_temperature: [Double]?
            let precipitation_probability: [Int]?
            let weather_code: [Int]?
            let wind_speed_10m: [Double]?
        }

        struct Daily: Decodable, Sendable {
            let time: [String]?
            let weather_code: [Int]?
            let temperature_2m_max: [Double]?
            let temperature_2m_min: [Double]?
            let apparent_temperature_max: [Double]?
            let apparent_temperature_min: [Double]?
            let sunrise: [String]?
            let sunset: [String]?
            let precipitation_probability_max: [Int]?
        }
    }

    /// Maps WMO numeric weather code to wttr.in/WWO equivalent standard string code.
    static func mapWMOCodeToStandard(_ wmoCode: Int) -> String {
        switch wmoCode {
        case 0: return "113" // Sunny / Clear
        case 1, 2: return "116" // Partly cloudy
        case 3: return "119" // Overcast / Cloudy
        case 45, 48: return "248" // Fog
        case 51, 53, 55: return "266" // Drizzle
        case 56, 57: return "311" // Freezing drizzle
        case 61, 63: return "296" // Light / moderate rain
        case 65: return "308" // Heavy rain
        case 66, 67: return "314" // Freezing rain
        case 71, 73: return "326" // Light / moderate snow
        case 75: return "338" // Heavy snow
        case 77: return "323" // Snow grains
        case 80, 81: return "299" // Rain showers
        case 82: return "305" // Heavy rain showers
        case 85, 86: return "368" // Snow showers
        case 95: return "386" // Thunderstorm
        case 96, 99: return "389" // Thunderstorm with hail
        default: return "116"
        }
    }

    /// Converts an OpenMeteoResponse into a full DeepWeather `WeatherResponse`.
    static func adapt(
        _ om: OpenMeteoResponse,
        cityName: String? = nil,
        countryName: String? = nil
    ) -> WeatherResponse {
        // 1. Current Condition
        var currentConditions: [CurrentCondition] = []
        if let current = om.current {
            let tempC = current.temperature_2m ?? 20.0
            let tempF = tempC * 9.0 / 5.0 + 32.0
            let feelsC = current.apparent_temperature ?? tempC
            let feelsF = feelsC * 9.0 / 5.0 + 32.0
            let wCode = mapWMOCodeToStandard(current.weather_code ?? 0)
            let windKmph = current.wind_speed_10m ?? 10.0
            let windMiles = windKmph * 0.621371

            currentConditions.append(CurrentCondition(
                tempC: String(Int(round(tempC))),
                tempF: String(Int(round(tempF))),
                feelsLikeC: String(Int(round(feelsC))),
                feelsLikeF: String(Int(round(feelsF))),
                humidity: current.relative_humidity_2m.map { String($0) },
                cloudcover: current.cloud_cover.map { String($0) },
                pressure: current.surface_pressure.map { String(Int(round($0))) },
                pressureInches: nil,
                uvIndex: nil,
                visibility: nil,
                visibilityMiles: nil,
                precipMM: current.precipitation.map { String(format: "%.1f", $0) },
                precipInches: nil,
                windspeedKmph: String(Int(round(windKmph))),
                windspeedMiles: String(Int(round(windMiles))),
                winddirDegree: current.wind_direction_10m.map { String($0) },
                winddir16Point: nil,
                weatherCode: wCode,
                observationTime: current.time,
                weatherDesc: [TextValue(value: WeatherConditionFormatter.localizedDescription(for: wCode, isDay: true))]
            ))
        }

        // 2. Daily & Hourly Forecasts
        var dailyForecasts: [DayForecast] = []
        let dailyTimes = om.daily?.time ?? []
        let maxTemps = om.daily?.temperature_2m_max ?? []
        let minTemps = om.daily?.temperature_2m_min ?? []
        let sunrises = om.daily?.sunrise ?? []
        let sunsets = om.daily?.sunset ?? []

        let hourlyTimes = om.hourly?.time ?? []
        let hourlyTemps = om.hourly?.temperature_2m ?? []
        let hourlyProbs = om.hourly?.precipitation_probability ?? []
        let hourlyCodes = om.hourly?.weather_code ?? []
        let hourlyWinds = om.hourly?.wind_speed_10m ?? []
        let hourlyHumidities = om.hourly?.relative_humidity_2m ?? []
        let hourlyFeels = om.hourly?.apparent_temperature ?? []

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        for (i, dayDateString) in dailyTimes.prefix(3).enumerated() {
            let maxC = i < maxTemps.count ? maxTemps[i] : 20.0
            let minC = i < minTemps.count ? minTemps[i] : 15.0
            let maxF = maxC * 9.0 / 5.0 + 32.0
            let minF = minC * 9.0 / 5.0 + 32.0

            // Astronomy calculation via LunarPhaseEngine
            let parsedDate = dateFormatter.date(from: dayDateString) ?? Date()
            let moonState = LunarPhaseEngine.calculate(for: parsedDate)

            // Extract sunrise / sunset time components
            let rawSunrise = i < sunrises.count ? sunrises[i] : ""
            let rawSunset = i < sunsets.count ? sunsets[i] : ""
            let sunriseTime = rawSunrise.components(separatedBy: "T").last ?? "06:00"
            let sunsetTime = rawSunset.components(separatedBy: "T").last ?? "20:00"

            let astronomy = [Astronomy(
                sunrise: sunriseTime,
                sunset: sunsetTime,
                moonrise: nil,
                moonset: nil,
                moonPhase: moonState.phaseName,
                moonIllumination: String(moonState.illuminationPercent)
            )]

            // Filter hourly entries belonging to this date at 3-hour intervals (00:00, 03:00, 06:00, 09:00, 12:00, 15:00, 18:00, 21:00)
            var dayHourly: [HourlyForecast] = []
            for (hIdx, hTime) in hourlyTimes.enumerated() {
                if hTime.starts(with: dayDateString) {
                    let hourPart = hTime.components(separatedBy: "T").last?.components(separatedBy: ":").first ?? "00"
                    let hourInt = Int(hourPart) ?? 0
                    guard hourInt % 3 == 0 else { continue }
                    let hourString = hourInt == 0 ? "0" : "\(hourInt)00"

                    let hC = hIdx < hourlyTemps.count ? hourlyTemps[hIdx] : 20.0
                    let hF = hC * 9.0 / 5.0 + 32.0
                    let hFeelC = hIdx < hourlyFeels.count ? hourlyFeels[hIdx] : hC
                    let hFeelF = hFeelC * 9.0 / 5.0 + 32.0
                    let hProb = hIdx < hourlyProbs.count ? hourlyProbs[hIdx] : 0
                    let hCode = hIdx < hourlyCodes.count ? mapWMOCodeToStandard(hourlyCodes[hIdx]) : "116"
                    let hWindKmph = hIdx < hourlyWinds.count ? hourlyWinds[hIdx] : 10.0
                    let hWindMiles = hWindKmph * 0.621371
                    let hHumidity = hIdx < hourlyHumidities.count ? hourlyHumidities[hIdx] : 50

                    dayHourly.append(HourlyForecast(
                        time: hourString,
                        tempC: String(Int(round(hC))),
                        tempF: String(Int(round(hF))),
                        feelsLikeC: String(Int(round(hFeelC))),
                        feelsLikeF: String(Int(round(hFeelF))),
                        weatherCode: hCode,
                        weatherDesc: [TextValue(value: WeatherConditionFormatter.localizedDescription(for: hCode, isDay: (6...20).contains(hourInt)))],
                        windspeedKmph: String(Int(round(hWindKmph))),
                        windspeedMiles: String(Int(round(hWindMiles))),
                        winddirDegree: nil,
                        winddir16Point: nil,
                        precipMM: "0.0",
                        precipInches: nil,
                        humidity: String(hHumidity),
                        cloudcover: nil,
                        pressure: nil,
                        uvIndex: nil,
                        chanceofrain: String(hProb),
                        chanceofsnow: "0",
                        chanceofsunshine: nil,
                        visibility: nil
                    ))
                }
            }

            dailyForecasts.append(DayForecast(
                date: dayDateString,
                maxtempC: String(Int(round(maxC))),
                mintempC: String(Int(round(minC))),
                maxtempF: String(Int(round(maxF))),
                mintempF: String(Int(round(minF))),
                avgtempC: String(Int(round((maxC + minC) / 2.0))),
                avgtempF: String(Int(round((maxF + minF) / 2.0))),
                totalSnowCm: "0.0",
                sunHour: nil,
                uvIndex: nil,
                astronomy: astronomy,
                hourly: dayHourly
            ))
        }

        // 3. Nearest Area
        let nearestArea: [NearestArea] = [
            NearestArea(
                areaName: [TextValue(value: cityName ?? "Current Location")],
                country: [TextValue(value: countryName ?? "")],
                region: nil,
                latitude: String(format: "%.4f", om.latitude),
                longitude: String(format: "%.4f", om.longitude)
            )
        ]

        return WeatherResponse(
            currentCondition: currentConditions,
            nearestArea: nearestArea,
            weather: dailyForecasts
        )
    }
}
