import SwiftUI
import SwiftData

@main
struct HumidityMonitorApp: App {
    @StateObject private var bleManager = BLEManager()
    @StateObject private var weatherService = WeatherService()
    @StateObject private var alertManager = AlertManager()
    @StateObject private var dataStore = DataStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dashboardViewModel)
                .environmentObject(settingsViewModel)
                .onAppear {
                    setupApp()
                }
        }
        .modelContainer(dataStore.modelContainer)
    }

    private var dashboardViewModel: DashboardViewModel {
        DashboardViewModel(
            bleManager: bleManager,
            weatherService: weatherService,
            alertManager: alertManager,
            dataStore: dataStore
        )
    }

    private var settingsViewModel: SettingsViewModel {
        SettingsViewModel(
            alertManager: alertManager,
            dataStore: dataStore
        )
    }

    private func setupApp() {
        // Request permissions
        alertManager.requestPermission()
        weatherService.requestLocationPermission()

        // Start services
        weatherService.startUpdating()

        // Purge old data on launch
        dataStore.purgeOldData()

        // Clear badge
        alertManager.clearBadge()
    }
}
