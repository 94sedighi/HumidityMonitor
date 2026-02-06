import Foundation
import SwiftData

final class DataStore: ObservableObject {
    let modelContainer: ModelContainer
    let modelContext: ModelContext

    init() {
        let schema = Schema([HumidityReading.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
            modelContext = ModelContext(modelContainer)
        } catch {
            fatalError("ModelContainer konnte nicht erstellt werden: \(error)")
        }
    }

    func saveReading(
        indoorHumidity: Double?,
        outdoorHumidity: Double?,
        indoorTemperature: Double?,
        outdoorTemperature: Double?,
        source: ReadingSource,
        sensorName: String?
    ) {
        let reading = HumidityReading(
            indoorHumidity: indoorHumidity,
            outdoorHumidity: outdoorHumidity,
            indoorTemperature: indoorTemperature,
            outdoorTemperature: outdoorTemperature,
            source: source,
            sensorName: sensorName
        )
        modelContext.insert(reading)

        do {
            try modelContext.save()
        } catch {
            print("Fehler beim Speichern: \(error)")
        }
    }

    func fetchReadings(from startDate: Date, to endDate: Date = Date()) -> [HumidityReading] {
        let predicate = #Predicate<HumidityReading> {
            $0.timestamp >= startDate && $0.timestamp <= endDate
        }
        let sortDescriptor = SortDescriptor<HumidityReading>(\.timestamp, order: .forward)
        let descriptor = FetchDescriptor<HumidityReading>(
            predicate: predicate,
            sortBy: [sortDescriptor]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Fehler beim Laden: \(error)")
            return []
        }
    }

    func fetchReadings(last hours: Int) -> [HumidityReading] {
        let startDate = Calendar.current.date(byAdding: .hour, value: -hours, to: Date()) ?? Date()
        return fetchReadings(from: startDate)
    }

    func purgeOldData(olderThanDays days: Int = 30) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let predicate = #Predicate<HumidityReading> {
            $0.timestamp < cutoffDate
        }
        let descriptor = FetchDescriptor<HumidityReading>(predicate: predicate)

        do {
            let oldReadings = try modelContext.fetch(descriptor)
            for reading in oldReadings {
                modelContext.delete(reading)
            }
            try modelContext.save()
        } catch {
            print("Fehler beim Bereinigen: \(error)")
        }
    }
}
