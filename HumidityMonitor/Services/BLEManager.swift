import Foundation
import CoreBluetooth
import Combine

struct DiscoveredSensor: Identifiable, Equatable {
    let id: UUID
    let peripheral: CBPeripheral
    let name: String
    var rssi: Int
    var isConnected: Bool

    static func == (lhs: DiscoveredSensor, rhs: DiscoveredSensor) -> Bool {
        lhs.id == rhs.id && lhs.rssi == rhs.rssi && lhs.isConnected == rhs.isConnected
    }
}

final class BLEManager: NSObject, ObservableObject {
    // Environmental Sensing Service
    static let environmentalSensingServiceUUID = CBUUID(string: "181A")
    // Humidity Characteristic
    static let humidityCharacteristicUUID = CBUUID(string: "2A6F")
    // Temperature Characteristic
    static let temperatureCharacteristicUUID = CBUUID(string: "2A6E")

    @Published var isScanning = false
    @Published var discoveredSensors: [DiscoveredSensor] = []
    @Published var connectedSensor: DiscoveredSensor?
    @Published var currentHumidity: Double?
    @Published var currentTemperature: Double?
    @Published var bluetoothState: CBManagerState = .unknown

    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var reconnectPeripheralID: UUID?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        isScanning = true
        discoveredSensors.removeAll()
        centralManager.scanForPeripherals(
            withServices: [Self.environmentalSensingServiceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }

    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
    }

    func connect(to sensor: DiscoveredSensor) {
        stopScanning()
        centralManager.connect(sensor.peripheral, options: nil)
    }

    func disconnect() {
        guard let peripheral = connectedPeripheral else { return }
        centralManager.cancelPeripheralConnection(peripheral)
    }
}

// MARK: - CBCentralManagerDelegate
extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bluetoothState = central.state
        if central.state == .poweredOn {
            if let id = reconnectPeripheralID {
                let peripherals = central.retrievePeripherals(withIdentifiers: [id])
                if let peripheral = peripherals.first {
                    central.connect(peripheral, options: nil)
                }
            }
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let name = peripheral.name ?? "Unbekannter Sensor"
        let sensor = DiscoveredSensor(
            id: peripheral.identifier,
            peripheral: peripheral,
            name: name,
            rssi: RSSI.intValue,
            isConnected: false
        )

        if let index = discoveredSensors.firstIndex(where: { $0.id == sensor.id }) {
            discoveredSensors[index] = sensor
        } else {
            discoveredSensors.append(sensor)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        reconnectPeripheralID = peripheral.identifier
        peripheral.delegate = self
        peripheral.discoverServices([Self.environmentalSensingServiceUUID])

        if let index = discoveredSensors.firstIndex(where: { $0.id == peripheral.identifier }) {
            discoveredSensors[index].isConnected = true
            connectedSensor = discoveredSensors[index]
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectedPeripheral = nil
        currentHumidity = nil
        currentTemperature = nil

        if let index = discoveredSensors.firstIndex(where: { $0.id == peripheral.identifier }) {
            discoveredSensors[index].isConnected = false
        }
        connectedSensor = nil

        // Auto-reconnect
        if let id = reconnectPeripheralID {
            let peripherals = central.retrievePeripherals(withIdentifiers: [id])
            if let peripheral = peripherals.first {
                central.connect(peripheral, options: nil)
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        connectedPeripheral = nil
        connectedSensor = nil
    }
}

// MARK: - CBPeripheralDelegate
extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(
                [Self.humidityCharacteristicUUID, Self.temperatureCharacteristicUUID],
                for: service
            )
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
            if characteristic.properties.contains(.read) {
                peripheral.readValue(for: characteristic)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }

        DispatchQueue.main.async {
            switch characteristic.uuid {
            case Self.humidityCharacteristicUUID:
                // BLE Humidity is uint16, value = raw / 100
                if data.count >= 2 {
                    let rawValue = data.withUnsafeBytes { $0.load(as: UInt16.self) }
                    self.currentHumidity = Double(rawValue) / 100.0
                }
            case Self.temperatureCharacteristicUUID:
                // BLE Temperature is sint16, value = raw / 100
                if data.count >= 2 {
                    let rawValue = data.withUnsafeBytes { $0.load(as: Int16.self) }
                    self.currentTemperature = Double(rawValue) / 100.0
                }
            default:
                break
            }
        }
    }
}
