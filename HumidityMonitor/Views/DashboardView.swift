import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var viewModel: DashboardViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Status banner
                    statusBanner

                    // Indoor humidity gauge
                    HumidityGaugeView(
                        value: viewModel.indoorHumidity ?? 0,
                        label: "Innen-Luftfeuchtigkeit",
                        size: 220
                    )
                    .opacity(viewModel.indoorHumidity != nil ? 1 : 0.3)
                    .overlay {
                        if viewModel.indoorHumidity == nil {
                            Text("Kein Sensor verbunden")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Outdoor weather card
                    outdoorCard

                    // Temperature row
                    temperatureRow

                    // Ventilation recommendation
                    if let recommendation = viewModel.ventilationRecommendation {
                        ventilationCard(recommendation)
                    }
                }
                .padding()
            }
            .navigationTitle("Feuchtigkeits-Monitor")
            .refreshable {
                viewModel.refreshWeather()
            }
        }
    }

    private var statusBanner: some View {
        HStack {
            Circle()
                .fill(viewModel.sensorConnected ? Color.green : Color.red)
                .frame(width: 10, height: 10)

            Text(viewModel.sensorConnected ? "Sensor verbunden" : "Sensor getrennt")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            if let level = viewModel.alertLevel {
                Label(level.label, systemImage: level == .alarm ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(level == .alarm ? .red : .yellow)
            }
        }
        .padding(.horizontal)
    }

    private var outdoorCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Außen")
                    .font(.headline)
                Spacer()
                if let weather = viewModel.weatherDescription {
                    Text(weather)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            HStack(spacing: 24) {
                HumidityGaugeView(
                    value: viewModel.outdoorHumidity ?? 0,
                    label: "Feuchtigkeit",
                    size: 100
                )
                .opacity(viewModel.outdoorHumidity != nil ? 1 : 0.3)

                if let temp = viewModel.outdoorTemperature {
                    VStack {
                        Text(String(format: "%.1f°C", temp))
                            .font(.title2.bold())
                        Text("Temperatur")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private var temperatureRow: some View {
        HStack(spacing: 16) {
            if let indoor = viewModel.indoorTemperature {
                temperatureCard(value: indoor, label: "Innen", icon: "house.fill")
            }
            if let outdoor = viewModel.outdoorTemperature {
                temperatureCard(value: outdoor, label: "Außen", icon: "cloud.fill")
            }
        }
    }

    private func temperatureCard(value: Double, label: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            Text(String(format: "%.1f°C", value))
                .font(.title3.bold())
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func ventilationCard(_ recommendation: String) -> some View {
        HStack {
            Image(systemName: "wind")
                .font(.title2)
                .foregroundColor(.blue)

            Text(recommendation)
                .font(.subheadline)

            Spacer()
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}
