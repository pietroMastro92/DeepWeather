import Foundation
import Observation
import ServiceManagement

@MainActor
@Observable
final class WeatherStore {

    // MARK: - View models

    struct DetailItem: Identifiable, Equatable {
        let id: String
        let symbol: String
        let title: String
        let value: String
    }

    struct HourlyItem: Identifiable, Equatable {
        let id: String
        let dayTitle: String
        let hourText: String
        let symbol: String
        let tempText: String
        let precipChance: Int
    }

    struct DayItem: Identifiable, Equatable {
        let id: String
        let title: String
        let symbol: String
        let minText: String
        let maxText: String
        let precipChance: Int
    }

    struct ChartPoint: Identifiable, Equatable {
        let id: Date
        let date: Date
        let temperature: Double?
        let precipChance: Int
    }

    struct MoonItem: Identifiable, Equatable {
        let id: String
        let title: String
        let phaseSymbol: String
        let phaseName: String
        let illuminationText: String
    }

    // MARK: - State

    private(set) var weather: WeatherResponse?
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var lastUpdated: Date?

    var weatherProvider: WeatherProvider = .auto {
        didSet {
            persistSettings()
            guard !isHydrating else { return }
            Task { await refresh() }
        }
    }

    private(set) var savedLocations: [SavedLocation] = [] {
        didSet { persistSettings() }
    }

    var selectedLocationID: String? = nil {
        didSet { persistSettings() }
    }

    var useMetric: Bool = true {
        didSet {
            persistSettings()
            guard !isHydrating else { return }
            recomputeViewModels()
        }
    }

    private(set) var detailItems: [DetailItem] = []
    private(set) var alerts: [WeatherAlert] = []
    private(set) var chartMidnights: [Date] = []
    private(set) var chartPoints: [ChartPoint] = []
    private(set) var moonItems: [MoonItem] = []
    private(set) var upcomingHours: [HourlyItem] = []
    private(set) var dayItems: [DayItem] = []
    /// Hour-aligned clock used by charts so `body` never constructs `Date()`.
    private(set) var referenceNow = Date()

    var refreshIntervalMinutes: Int = 15 {
        didSet {
            persistSettings()
            guard !isHydrating else { return }
            scheduleAutoRefresh()
        }
    }

    /// IDs the user hid in Display. Missing ID means the Measurement is shown.
    private(set) var hiddenMeasurementIDs: Set<String> = []

    /// Actual login-item status. User intent is stored separately so a failed
    /// register() cannot clobber the saved-locations payload during init.
    private(set) var launchAtLogin = false
    private(set) var launchAtLoginError: String?

    var selectedLocation: SavedLocation? {
        savedLocations.first { $0.id == selectedLocationID }
    }

    private let client: WeatherClient
    private let persistEnabled: Bool
    private let defaults: UserDefaults
    private var autoRefreshTask: Task<Void, Never>?
    private let dateParser: DateFormatter
    private let weekdayFormatter: DateFormatter
    /// Blocks didSet persistence while init restores UserDefaults. Without this,
    /// assigning useMetric/refreshInterval writes an empty locations array and
    /// wipes cities the user added in a previous session.
    private var isHydrating = true

    // MARK: - Init

    init(client: WeatherClient = WeatherClient()) {
        self.client = client
        self.persistEnabled = true
        self.defaults = .standard

        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.dateFormat = "yyyy-MM-dd"
        self.dateParser = parser

        let weekday = DateFormatter()
        weekday.locale = Locale(identifier: "en_US")
        weekday.dateFormat = "EEE"
        self.weekdayFormatter = weekday

        let restored = Self.restoreSettings(from: defaults)
        self.weatherProvider = restored.weatherProvider
        self.useMetric = restored.useMetric
        self.refreshIntervalMinutes = restored.refreshIntervalMinutes
        self.savedLocations = restored.locations
        self.selectedLocationID = restored.selectedLocationID
        self.hiddenMeasurementIDs = restored.hiddenMeasurementIDs

        isHydrating = false

        if restored.migratedLegacyLocation {
            persistSettings()
        }

        reconcileLaunchAtLogin(preferred: restored.preferredLaunchAtLogin)
    }

#if DEBUG
    /// Seeds a store without touching the user's real UserDefaults.
    init(
        previewWeather: WeatherResponse?,
        locations: [SavedLocation] = [],
        selectedID: String? = nil,
        provider: WeatherProvider = .auto,
        isLoading: Bool = false,
        errorMessage: String? = nil,
        lastUpdated: Date? = nil
    ) {
        self.client = WeatherClient()
        self.persistEnabled = false
        self.defaults = UserDefaults(suiteName: "DeepWeather.previews") ?? .standard

        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.dateFormat = "yyyy-MM-dd"
        self.dateParser = parser

        let weekday = DateFormatter()
        weekday.locale = Locale(identifier: "en_US")
        weekday.dateFormat = "EEE"
        self.weekdayFormatter = weekday

        self.savedLocations = locations
        self.selectedLocationID = selectedID
        self.weatherProvider = provider
        self.weather = previewWeather
        self.isLoading = isLoading
        self.errorMessage = errorMessage
        self.lastUpdated = lastUpdated
        self.referenceNow = Self.hourAlignedNow()
        self.isHydrating = false
        recomputeViewModels()
    }
#endif

    private static let weatherProviderKey = "weatherbar.weatherProvider"
    private static let useMetricKey = "weatherbar.useMetric"
    private static let savedLocationsKey = "weatherbar.savedLocations"
    private static let selectedLocationKey = "weatherbar.selectedLocationID"
    private static let legacySavedLocationKey = "weatherbar.savedLocation"
    private static let refreshIntervalKey = "weatherbar.refreshIntervalMinutes"
    private static let launchAtLoginKey = "weatherbar.launchAtLogin"
    private static let hiddenMeasurementsKey = "weatherbar.hiddenMeasurementIDs"

    // MARK: - Lifecycle

    @MainActor
    func startAutoRefresh() {
        guard autoRefreshTask == nil else { return }
        scheduleAutoRefresh()
        Task { await refresh() }
    }

    private func scheduleAutoRefresh() {
        autoRefreshTask?.cancel()
        let interval = TimeInterval(refreshIntervalMinutes * 60)
        autoRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(Int(interval * 1000)))
                guard !Task.isCancelled else { break }
                await self?.refresh()
            }
        }
    }

    @MainActor
    func applySettings() {
        scheduleAutoRefresh()
        Task { await refresh() }
    }

    func isMeasurementVisible(_ id: MeasurementID) -> Bool {
        !hiddenMeasurementIDs.contains(id.rawValue)
    }

    @MainActor
    func setMeasurementVisible(_ id: MeasurementID, _ visible: Bool) {
        if visible {
            hiddenMeasurementIDs.remove(id.rawValue)
        } else {
            hiddenMeasurementIDs.insert(id.rawValue)
        }
        persistSettings()
        recomputeViewModels()
    }

    @MainActor
    func setLaunchAtLogin(_ enabled: Bool) {
        defaults.set(enabled, forKey: Self.launchAtLoginKey)
        applyLaunchAtLogin(enabled)
        persistSettings()
    }

    // MARK: - Locations

    @MainActor
    func selectLocation(_ result: GeoResult) {
        if let existing = savedLocations.first(where: {
            abs($0.latitude - result.latitude) < 0.001 && abs($0.longitude - result.longitude) < 0.001
        }) {
            selectedLocationID = existing.id
        } else {
            let newLocation = SavedLocation(
                id: UUID().uuidString,
                name: result.name,
                detail: result.detail,
                latitude: result.latitude,
                longitude: result.longitude
            )
            savedLocations.append(newLocation)
            selectedLocationID = newLocation.id
        }
        applySettings()
    }

    @MainActor
    func selectSavedLocation(_ id: String?) {
        guard selectedLocationID != id else { return }
        selectedLocationID = id
        applySettings()
    }

    @MainActor
    func removeLocation(id: String) {
        savedLocations.removeAll { $0.id == id }
        if selectedLocationID == id {
            selectedLocationID = savedLocations.first?.id
        }
        applySettings()
    }

    @MainActor
    func resetToAutomaticLocation() {
        selectSavedLocation(nil)
    }

    // MARK: - Fetching

    @MainActor
    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let query: String?
            let lat: Double?
            let lon: Double?
            let city: String?
            let country: String?

            if let selected = selectedLocation {
                query = String(format: "%.5f,%.5f", selected.latitude, selected.longitude)
                lat = selected.latitude
                lon = selected.longitude
                city = selected.name
                country = selected.detail
            } else {
                query = nil
                lat = nil
                lon = nil
                city = nil
                country = nil
            }
            weather = try await client.fetch(
                location: query,
                latitude: lat,
                longitude: lon,
                cityName: city,
                countryName: country,
                provider: weatherProvider
            )
            lastUpdated = Date()
            referenceNow = Self.hourAlignedNow()
            recomputeViewModels()
        } catch {
            errorMessage = friendlyMessage(for: error)
        }
    }

    private func friendlyMessage(for error: Error) -> String {
        if let clientError = error as? WeatherClient.ClientError {
            return clientError.localizedDescription
        }
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return "No internet connection."
            case .timedOut:
                return "Request timed out."
            default:
                break
            }
        }
        return "Couldn't read the weather data."
    }

    // MARK: - Persistence

    private struct RestoredSettings {
        var weatherProvider: WeatherProvider
        var useMetric: Bool
        var refreshIntervalMinutes: Int
        var locations: [SavedLocation]
        var selectedLocationID: String?
        var preferredLaunchAtLogin: Bool?
        var migratedLegacyLocation: Bool
        var hiddenMeasurementIDs: Set<String>
    }

    private static func restoreSettings(from defaults: UserDefaults) -> RestoredSettings {
        var migratedLegacyLocation = false
        let locations: [SavedLocation]
        if let data = defaults.data(forKey: savedLocationsKey),
           let decoded = try? JSONDecoder().decode([SavedLocation].self, from: data) {
            locations = decoded
        } else if let data = defaults.data(forKey: legacySavedLocationKey),
                  let legacy = SavedLocationMigration.legacy(from: data) {
            locations = [legacy]
            defaults.removeObject(forKey: legacySavedLocationKey)
            migratedLegacyLocation = true
        } else {
            locations = []
        }

        let selectedID = defaults.string(forKey: selectedLocationKey)
        let validSelectedID: String?
        if let selectedID, locations.contains(where: { $0.id == selectedID }) {
            validSelectedID = selectedID
        } else {
            defaults.removeObject(forKey: selectedLocationKey)
            validSelectedID = nil
        }

        let providerRaw = defaults.string(forKey: weatherProviderKey) ?? ""
        let provider = WeatherProvider(rawValue: providerRaw) ?? .auto

        return RestoredSettings(
            weatherProvider: provider,
            useMetric: defaults.object(forKey: useMetricKey) as? Bool ?? true,
            refreshIntervalMinutes: defaults.object(forKey: refreshIntervalKey) as? Int ?? 15,
            locations: locations,
            selectedLocationID: validSelectedID,
            preferredLaunchAtLogin: defaults.object(forKey: launchAtLoginKey) as? Bool,
            migratedLegacyLocation: migratedLegacyLocation,
            hiddenMeasurementIDs: Set(defaults.stringArray(forKey: hiddenMeasurementsKey) ?? [])
        )
    }

    private func persistSettings() {
        guard persistEnabled, !isHydrating else { return }
        defaults.set(weatherProvider.rawValue, forKey: Self.weatherProviderKey)
        defaults.set(useMetric, forKey: Self.useMetricKey)
        defaults.set(refreshIntervalMinutes, forKey: Self.refreshIntervalKey)
        if let data = try? JSONEncoder().encode(savedLocations) {
            defaults.set(data, forKey: Self.savedLocationsKey)
        } else {
            defaults.removeObject(forKey: Self.savedLocationsKey)
        }
        if let selectedLocationID {
            defaults.set(selectedLocationID, forKey: Self.selectedLocationKey)
        } else {
            defaults.removeObject(forKey: Self.selectedLocationKey)
        }
        defaults.set(Array(hiddenMeasurementIDs).sorted(), forKey: Self.hiddenMeasurementsKey)
    }

    private func reconcileLaunchAtLogin(preferred: Bool?) {
        if preferred == true {
            applyLaunchAtLogin(true)
        } else {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    private func applyLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            }
            launchAtLoginError = nil
        } catch {
            launchAtLoginError = friendlyLaunchAtLoginMessage(for: error)
        }
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    private func friendlyLaunchAtLoginMessage(for error: Error) -> String {
        let nsError = error as NSError
        if nsError.domain == "SMAppServiceErrorDomain" {
            return "Couldn't update login item. Move DeepWeather to the Applications folder and try again."
        }
        return "Couldn't update launch at login: \(error.localizedDescription)"
    }

    // MARK: - Menu bar label

    var menuBarIcon: String {
        WeatherIconMapper.symbol(
            for: weather?.currentCondition?.first?.weatherCode,
            isDay: isDay
        )
    }

    var menuBarAnimationKind: WeatherAnimationKind {
        WeatherIconMapper.animationKind(
            for: weather?.currentCondition?.first?.weatherCode,
            isDay: isDay
        )
    }

    var menuBarTemp: String { currentTempText }

    var currentTempText: String {
        guard let c = weather?.currentCondition?.first else { return "--°" }
        return tempString(c.tempC, c.tempF)
    }

    var temperatureUnitSymbol: String {
        useMetric ? "°C" : "°F"
    }

    var currentTempValue: Double? {
        let raw = useMetric
            ? weather?.currentCondition?.first?.tempC
            : weather?.currentCondition?.first?.tempF
        return raw.flatMap { Double($0) }
    }

    // MARK: - Current conditions

    var locationName: String {
        if let selected = selectedLocation {
            return selected.name
        }
        return weather?.nearestArea?.first?.areaName?.first?.value ?? "Current location"
    }

    var locationDetail: String {
        if let selected = selectedLocation, !selected.detail.isEmpty {
            return selected.detail
        }
        guard let area = weather?.nearestArea?.first else { return "" }
        return [area.region?.first?.value, area.country?.first?.value]
            .compactMap { $0 }.joined(separator: ", ")
    }

    var currentConditionText: String {
        weather?.currentCondition?.first?.conditionDescription ?? ""
    }

    var isDay: Bool {
        guard let astro = weather?.weather?.first?.astronomy?.first,
              let sunrise = Self.minutes(from12h: astro.sunrise),
              let sunset = Self.minutes(from12h: astro.sunset)
        else {
            return (6..<21).contains(Calendar.current.component(.hour, from: Date()))
        }
        let calendar = Calendar.current
        let minutes = calendar.component(.hour, from: Date()) * 60 + calendar.component(.minute, from: Date())
        return minutes >= sunrise && minutes < sunset
    }

    // MARK: - Derived snapshots

    private func recomputeViewModels() {
        detailItems = makeDetailItems()
        alerts = WeatherAlert.detectAlerts(from: weather, useMetric: useMetric)
        chartMidnights = makeChartMidnights()
        chartPoints = makeChartPoints()
        moonItems = makeMoonItems()
        upcomingHours = makeUpcomingHours()
        dayItems = makeDayItems()
    }

    private func makeDetailItems() -> [DetailItem] {
        guard let c = weather?.currentCondition?.first else { return [] }
        let astro = weather?.weather?.first?.astronomy?.first
        var items = [
            DetailItem(id: "feels", symbol: "thermometer.medium", title: "Feels like", value: tempString(c.feelsLikeC, c.feelsLikeF)),
            DetailItem(id: "humidity", symbol: "humidity", title: "Humidity", value: c.humidity.map { "\($0)%" } ?? "—"),
            DetailItem(id: "wind", symbol: "wind", title: "Wind", value: windString(c.windspeedKmph, c.windspeedMiles, dir: c.winddir16Point)),
            DetailItem(id: "uv", symbol: "sun.max", title: "UV index", value: c.uvIndex ?? "—"),
            DetailItem(id: "pressure", symbol: "gauge", title: "Pressure", value: pressureString(c)),
            DetailItem(id: "visibility", symbol: "eye", title: "Visibility", value: visibilityString(c)),
            DetailItem(id: "precipitation", symbol: "drop", title: "Precipitation", value: precipString(c)),
            DetailItem(id: "cloudcover", symbol: "cloud", title: "Cloud cover", value: c.cloudcover.map { "\($0)%" } ?? "—")
        ]
        if let sunrise = astro?.sunrise {
            items.append(DetailItem(id: "sunrise", symbol: "sunrise", title: "Sunrise", value: sunrise))
        }
        if let sunset = astro?.sunset {
            items.append(DetailItem(id: "sunset", symbol: "sunset", title: "Sunset", value: sunset))
        }
        if let moonrise = astro?.moonrise {
            items.append(DetailItem(id: "moonrise", symbol: "moonrise", title: "Moonrise", value: moonrise))
        }
        if let moonset = astro?.moonset {
            items.append(DetailItem(id: "moonset", symbol: "moonset", title: "Moonset", value: moonset))
        }
        return items.filter { !hiddenMeasurementIDs.contains($0.id) }
    }

    private func makeChartMidnights() -> [Date] {
        guard let days = weather?.weather else { return [] }
        return days.compactMap { day in
            day.date.flatMap { dateParser.date(from: $0) }
        }
    }

    private func makeChartPoints() -> [ChartPoint] {
        guard let days = weather?.weather else { return [] }
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: referenceNow)
        let observedTemp = currentTempValue
        var points: [ChartPoint] = []
        for (dayIndex, day) in days.enumerated() {
            guard let dateString = day.date, let baseDate = dateParser.date(from: dateString) else { continue }
            for entry in day.hourly ?? [] {
                guard let hour = entry.hour,
                      let date = calendar.date(byAdding: .hour, value: hour, to: baseDate)
                else { continue }
                let forecastTemp = (useMetric ? entry.tempC : entry.tempF).flatMap { Double($0) }
                let temperature: Double?
                if dayIndex == 0 && hour == currentHour, let observedTemp {
                    temperature = observedTemp
                } else {
                    temperature = forecastTemp
                }
                points.append(ChartPoint(
                    id: date,
                    date: date,
                    temperature: temperature,
                    precipChance: Int(entry.chanceofrain ?? "") ?? 0
                ))
            }
        }
        return points
    }

    private func makeMoonItems() -> [MoonItem] {
        guard let days = weather?.weather else { return [] }
        return days.prefix(3).enumerated().map { index, day in
            let astro = day.astronomy?.first
            let dateString = day.date
            let title = dayTitle(index: index, dateString: dateString)
            let date = day.date.flatMap { dateParser.date(from: $0) } ?? Date()
            let moonState = LunarPhaseEngine.calculate(for: date)
            let rawPhaseName = (astro?.moonPhase?.isEmpty == false) ? (astro?.moonPhase ?? moonState.phaseName) : moonState.phaseName
            let localizedPhase = WeatherIconMapper.localizedMoonPhaseName(for: rawPhaseName)
            let symbol = WeatherIconMapper.moonPhaseSymbol(for: rawPhaseName)
            let illum = (astro?.moonIllumination?.isEmpty == false) ? (astro?.moonIllumination ?? "\(moonState.illuminationPercent)") : "\(moonState.illuminationPercent)"

            return MoonItem(
                id: dateString ?? "day-\(index)",
                title: title,
                phaseSymbol: symbol,
                phaseName: localizedPhase,
                illuminationText: "\(illum)%"
            )
        }
    }

    private func makeUpcomingHours() -> [HourlyItem] {
        guard let days = weather?.weather, let today = days.first else { return [] }

        let dayLabel = dayTitle(index: 0, dateString: today.date)
        var result: [HourlyItem] = []
        for entry in today.hourly ?? [] {
            guard let hour = entry.hour else { continue }
            result.append(HourlyItem(
                id: "0-\(hour)",
                dayTitle: dayLabel,
                hourText: String(format: "%02d:00", hour),
                symbol: WeatherIconMapper.symbol(for: entry.weatherCode, isDay: (6..<21).contains(hour)),
                tempText: tempString(entry.tempC, entry.tempF),
                precipChance: Int(entry.chanceofrain ?? "") ?? 0
            ))
        }
        return result
    }

    private func makeDayItems() -> [DayItem] {
        guard let days = weather?.weather else { return [] }
        return days.enumerated().map { index, day in
            let dateString = day.date
            let title = dayTitle(index: index, dateString: dateString)
            let precip = (day.hourly ?? []).compactMap { Int($0.chanceofrain ?? "") }.max() ?? 0
            let representative = (day.hourly ?? []).first { $0.hour == 12 }
                ?? (day.hourly ?? []).first

            return DayItem(
                id: dateString ?? "day-\(index)",
                title: title,
                symbol: WeatherIconMapper.symbol(for: representative?.weatherCode, isDay: true),
                minText: tempString(day.mintempC, day.mintempF),
                maxText: tempString(day.maxtempC, day.maxtempF),
                precipChance: precip
            )
        }
    }

    static func hourAlignedNow(_ date: Date = Date()) -> Date {
        let calendar = Calendar.current
        let parts = calendar.dateComponents([.year, .month, .day, .hour], from: date)
        return calendar.date(from: parts) ?? date
    }

    // MARK: - Helpers

    private func dayTitle(index: Int, dateString: String?) -> String {
        if index == 0 {
            return "Today"
        }
        if let dateString, let date = dateParser.date(from: dateString) {
            return weekdayFormatter.string(from: date)
        }
        return dateString ?? "Day \(index + 1)"
    }

    // MARK: - Formatting helpers

    private func tempString(_ c: String?, _ f: String?) -> String {
        guard let value = useMetric ? c : f, !value.isEmpty else { return "--°" }
        return "\(value)°"
    }

    private func windString(_ kmph: String?, _ mph: String?, dir: String?) -> String {
        let speed = useMetric ? kmph.map { "\($0) km/h" } : mph.map { "\($0) mph" }
        return [speed, dir].compactMap { $0 }.joined(separator: " ")
    }

    private func pressureString(_ c: CurrentCondition) -> String {
        useMetric
            ? c.pressure.map { "\($0) hPa" } ?? "—"
            : c.pressureInches.map { "\($0) inHg" } ?? "—"
    }

    private func visibilityString(_ c: CurrentCondition) -> String {
        useMetric
            ? c.visibility.map { "\($0) km" } ?? "—"
            : c.visibilityMiles.map { "\($0) mi" } ?? "—"
    }

    private func precipString(_ c: CurrentCondition) -> String {
        useMetric
            ? c.precipMM.map { "\($0) mm" } ?? "—"
            : c.precipInches.map { "\($0) in" } ?? "—"
    }

    private static func minutes(from12h string: String?) -> Int? {
        guard let string else { return nil }
        let parts = string.split(separator: " ")
        guard parts.count == 2 else { return nil }
        let hm = parts[0].split(separator: ":")
        guard hm.count == 2, let h = Int(hm[0]), let m = Int(hm[1]) else { return nil }
        let isPM = parts[1].uppercased() == "PM"
        return ((h % 12) + (isPM ? 12 : 0)) * 60 + m
    }
}
