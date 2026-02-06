import SwiftUI
import CoreBluetooth

struct SensorListView: View {
    @EnvironmentObject var viewModel: DashboardViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    bluetoothStatusRow
                } header: {
                    Text("Bluetooth Status")
                }

                if let connected = viewModel.bleManager.connectedSensor {
                    Section {
                        connectedSensorRow(connected)
                    } header: {
                        Text("Verbundener Sensor")
                    }
                }

                Section {
                    if viewModel.bleManager.discoveredSensors.isEmpty && !viewModel.bleManager.isScanning {
                        ContentUnavailableView(
                            "Keine Sensoren gefunden",
                            systemImage: "sensor",
                            description: Text("Tippen Sie auf \"Scannen\" um BLE-Sensoren in der Nähe zu suchen.")
                        )
                    }

                    ForEach(viewModel.bleManager.discoveredSensors) { sensor in
                        sensorRow(sensor)
                    }
                } header: {
                    HStack {
                        Text("Gefundene Sensoren")
                        Spacer()
                        if viewModel.bleManager.isScanning {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                    }
                }
            }
            .navigationTitle("Sensoren")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if viewModel.bleManager.isScanning {
                            viewModel.bleManager.stopScanning()
                        } else {
                            viewModel.bleManager.startScanning()
                        }
                    } label: {
                        Text(viewModel.bleManager.isScanning ? "Stopp" : "Scannen")
                    }
                    .disabled(viewModel.bleManager.bluetoothState != .poweredOn)
                }
            }
        }
    }

    private var bluetoothStatusRow: some View {
        HStack {
            Image(systemName: bluetoothIcon)
                .foregroundColor(bluetoothColor)
            Text(bluetoothStatusText)
            Spacer()
        }
    }

    private var bluetoothIcon: String {
        switch viewModel.bleManager.bluetoothState {
        case .poweredOn: return "antenna.radiowaves.left.and.right"
        case .poweredOff: return "antenna.radiowaves.left.and.right.slash"
        default: return "questionmark.circle"
        }
    }

    private var bluetoothColor: Color {
        switch viewModel.bleManager.bluetoothState {
        case .poweredOn: return .green
        case .poweredOff: return .red
        default: return .gray
        }
    }

    private var bluetoothStatusText: String {
        switch viewModel.bleManager.bluetoothState {
        case .poweredOn: return "Bluetooth aktiv"
        case .poweredOff: return "Bluetooth deaktiviert"
        case .unauthorized: return "Bluetooth nicht autorisiert"
        case .unsupported: return "Bluetooth nicht unterstützt"
        default: return "Bluetooth Status unbekannt"
        }
    }

    private func connectedSensorRow(_ sensor: DiscoveredSensor) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(sensor.name)
                    .font(.headline)

                if let humidity = viewModel.bleManager.currentHumidity {
                    Text(String(format: "Feuchtigkeit: %.1f%%", humidity))
                        .font(.caption)
                        .foregroundColor(.blue)
                }

                if let temp = viewModel.bleManager.currentTemperature {
                    Text(String(format: "Temperatur: %.1f°C", temp))
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            Spacer()

            Button("Trennen") {
                viewModel.bleManager.disconnect()
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
    }

    private func sensorRow(_ sensor: DiscoveredSensor) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(sensor.name)
                    .font(.body)
                Text("RSSI: \(sensor.rssi) dBm")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            rssiIndicator(sensor.rssi)

            if !sensor.isConnected {
                Button("Verbinden") {
                    viewModel.bleManager.connect(to: sensor)
                }
                .buttonStyle(.bordered)
                .tint(.blue)
            }
        }
    }

    private func rssiIndicator(_ rssi: Int) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<4) { bar in
                RoundedRectangle(cornerRadius: 1)
                    .fill(rssiBarColor(bar: bar, rssi: rssi))
                    .frame(width: 4, height: CGFloat(6 + bar * 4))
            }
        }
        .padding(.trailing, 8)
    }

    private func rssiBarColor(bar: Int, rssi: Int) -> Color {
        let strength: Int
        if rssi > -50 { strength = 4 }
        else if rssi > -60 { strength = 3 }
        else if rssi > -70 { strength = 2 }
        else { strength = 1 }

        return bar < strength ? .green : .gray.opacity(0.3)
    }
}
