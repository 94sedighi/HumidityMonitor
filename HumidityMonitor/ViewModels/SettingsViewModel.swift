import Foundation
import Combine

final class SettingsViewModel: ObservableObject {
    private let alertManager: AlertManager
    private let dataStore: DataStore

    @Published var warningLevel: Double {
        didSet { alertManager.threshold.warningLevel = warningLevel }
    }
    @Published var alarmLevel: Double {
        didSet { alertManager.threshold.alarmLevel = alarmLevel }
    }
    @Published var repeatInterval: Int {
        didSet { alertManager.threshold.repeatIntervalMinutes = repeatInterval }
    }
    @Published var alertsEnabled: Bool {
        didSet { alertManager.threshold.isEnabled = alertsEnabled }
    }
    @Published var weatherAPIKey: String {
        didSet { UserDefaults.standard.set(weatherAPIKey, forKey: "weatherAPIKey") }
    }
    @Published var useCelsius: Bool {
        didSet { UserDefaults.standard.set(useCelsius, forKey: "useCelsius") }
    }
    @Published var showDeleteConfirmation = false

    init(alertManager: AlertManager, dataStore: DataStore) {
        self.alertManager = alertManager
        self.dataStore = dataStore

        self.warningLevel = alertManager.threshold.warningLevel
        self.alarmLevel = alertManager.threshold.alarmLevel
        self.repeatInterval = alertManager.threshold.repeatIntervalMinutes
        self.alertsEnabled = alertManager.threshold.isEnabled
        self.weatherAPIKey = UserDefaults.standard.string(forKey: "weatherAPIKey") ?? ""
        self.useCelsius = UserDefaults.standard.bool(forKey: "useCelsius")

        // Default to Celsius if never set
        if UserDefaults.standard.object(forKey: "useCelsius") == nil {
            self.useCelsius = true
            UserDefaults.standard.set(true, forKey: "useCelsius")
        }
    }

    func purgeOldData() {
        dataStore.purgeOldData()
    }

    func deleteAllData() {
        let readings = dataStore.fetchReadings(from: .distantPast)
        for reading in readings {
            dataStore.modelContext.delete(reading)
        }
        try? dataStore.modelContext.save()
    }
}
