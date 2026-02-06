import Foundation
import SwiftData

@Model
final class HumidityReading {
    var id: UUID
    var timestamp: Date
    var indoorHumidity: Double?
    var outdoorHumidity: Double?
    var indoorTemperature: Double?
    var outdoorTemperature: Double?
    var source: ReadingSource
    var sensorName: String?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        indoorHumidity: Double? = nil,
        outdoorHumidity: Double? = nil,
        indoorTemperature: Double? = nil,
        outdoorTemperature: Double? = nil,
        source: ReadingSource = .ble,
        sensorName: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.indoorHumidity = indoorHumidity
        self.outdoorHumidity = outdoorHumidity
        self.indoorTemperature = indoorTemperature
        self.outdoorTemperature = outdoorTemperature
        self.source = source
        self.sensorName = sensorName
    }
}

enum ReadingSource: String, Codable {
    case ble
    case weatherAPI
    case combined
}
