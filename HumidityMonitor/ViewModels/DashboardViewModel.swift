import Foundation
import Combine
import SwiftData

final class DashboardViewModel: ObservableObject {
    let bleManager: BLEManager
    let weatherService: WeatherService
    let alertManager: AlertManager
    let dataStore: DataStore

    @Published var indoorHumidity: Double?
    @Published var indoorTemperature: Double?
    @Published var outdoorHumidity: Double?
    @Published var outdoorTemperature: Double?
    @Published var weatherDescription: String?
    @Published var sensorConnected = false
    @Published var alertLevel: HumidityLevel?
    @Published var ventilationRecommendation: String?

    var warningThreshold: Double { alertManager.threshold.warningLevel }
    var alarmThreshold: Double { alertManager.threshold.alarmLevel }

    private var cancellables = Set<AnyCancellable>()
    private var saveTimer: Timer?

    init(
        bleManager: BLEManager,
        weatherService: WeatherService,
        alertManager: AlertManager,
        dataStore: DataStore
    ) {
        self.bleManager = bleManager
        self.weatherService = weatherService
        self.alertManager = alertManager
        self.dataStore = dataStore

        setupBindings()
        startPeriodicSave()
    }

    private func setupBindings() {
        // BLE humidity updates
        bleManager.$currentHumidity
            .receive(on: DispatchQueue.main)
            .sink { [weak self] humidity in
                self?.indoorHumidity = humidity
                if let h = humidity {
                    self?.alertManager.checkHumidity(h)
                    self?.updateAlertLevel()
                    self?.updateVentilationRecommendation()
                }
            }
            .store(in: &cancellables)

        // BLE temperature updates
        bleManager.$currentTemperature
            .receive(on: DispatchQueue.main)
            .assign(to: &$indoorTemperature)

        // BLE connection status
        bleManager.$connectedSensor
            .receive(on: DispatchQueue.main)
            .map { $0 != nil }
            .assign(to: &$sensorConnected)

        // Weather updates
        weatherService.$currentWeather
            .receive(on: DispatchQueue.main)
            .sink { [weak self] weather in
                self?.outdoorHumidity = weather?.humidity
                self?.outdoorTemperature = weather?.temperature
                self?.weatherDescription = weather?.description
                self?.updateVentilationRecommendation()
            }
            .store(in: &cancellables)

        // Alert level updates
        alertManager.$currentLevel
            .receive(on: DispatchQueue.main)
            .map { level -> HumidityLevel? in
                level == .normal ? nil : level
            }
            .assign(to: &$alertLevel)
    }

    private func updateAlertLevel() {
        if let humidity = indoorHumidity {
            let level = HumidityLevel.level(for: humidity, threshold: alertManager.threshold)
            alertLevel = level == .normal ? nil : level
        }
    }

    private func updateVentilationRecommendation() {
        guard let indoor = indoorHumidity, let outdoor = outdoorHumidity else {
            ventilationRecommendation = nil
            return
        }

        if indoor > alertManager.threshold.warningLevel && outdoor < indoor {
            let difference = indoor - outdoor
            ventilationRecommendation = String(
                format: "Lüften empfohlen! Außen %.0f%% weniger Feuchtigkeit.",
                difference
            )
        } else if indoor > alertManager.threshold.warningLevel && outdoor >= indoor {
            ventilationRecommendation = "Hohe Feuchtigkeit – Außenluft ist aktuell nicht trockener."
        } else {
            ventilationRecommendation = nil
        }
    }

    func refreshWeather() {
        weatherService.fetchWeather()
    }

    func readings(for range: TimeRange) -> [HumidityReading] {
        dataStore.fetchReadings(last: range.hours)
    }

    private func startPeriodicSave() {
        saveTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.saveCurrentReading()
        }
    }

    private func saveCurrentReading() {
        guard indoorHumidity != nil || outdoorHumidity != nil else { return }

        let source: ReadingSource
        if indoorHumidity != nil && outdoorHumidity != nil {
            source = .combined
        } else if indoorHumidity != nil {
            source = .ble
        } else {
            source = .weatherAPI
        }

        dataStore.saveReading(
            indoorHumidity: indoorHumidity,
            outdoorHumidity: outdoorHumidity,
            indoorTemperature: indoorTemperature,
            outdoorTemperature: outdoorTemperature,
            source: source,
            sensorName: bleManager.connectedSensor?.name
        )
    }

    deinit {
        saveTimer?.invalidate()
    }
}
