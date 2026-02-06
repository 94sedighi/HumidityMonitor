import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dashboardVM: DashboardViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "humidity")
                }

            HistoryChartView()
                .tabItem {
                    Label("Verlauf", systemImage: "chart.xyaxis.line")
                }

            SensorListView()
                .tabItem {
                    Label("Sensoren", systemImage: "sensor")
                }

            SettingsView()
                .tabItem {
                    Label("Einstellungen", systemImage: "gearshape")
                }
        }
    }
}
