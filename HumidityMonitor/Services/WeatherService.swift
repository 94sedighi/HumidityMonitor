import Foundation
import CoreLocation
import Combine

struct WeatherData {
    let humidity: Double
    let temperature: Double
    let description: String
    let timestamp: Date
}

final class WeatherService: NSObject, ObservableObject {
    @Published var currentWeather: WeatherData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var locationAuthorized = false

    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    private var apiKey: String {
        UserDefaults.standard.string(forKey: "weatherAPIKey") ?? ""
    }
    private var updateTimer: Timer?
    private var lastFetchTime: Date?
    private let minimumFetchInterval: TimeInterval = 15 * 60 // 15 minutes

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        locationManager.requestLocation()
        updateTimer = Timer.scheduledTimer(withTimeInterval: minimumFetchInterval, repeats: true) { [weak self] _ in
            self?.locationManager.requestLocation()
        }
    }

    func stopUpdating() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    func fetchWeather() {
        guard let location = currentLocation else {
            errorMessage = "Standort nicht verfügbar"
            return
        }

        // Cache check
        if let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < minimumFetchInterval,
           currentWeather != nil {
            return
        }

        guard !apiKey.isEmpty else {
            errorMessage = "API-Key nicht konfiguriert"
            return
        }

        isLoading = true
        errorMessage = nil

        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric&lang=de"

        guard let url = URL(string: urlString) else {
            errorMessage = "Ungültige URL"
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    self?.errorMessage = "Netzwerkfehler: \(error.localizedDescription)"
                    return
                }

                guard let data = data else {
                    self?.errorMessage = "Keine Daten empfangen"
                    return
                }

                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

                    guard let main = json?["main"] as? [String: Any],
                          let humidity = main["humidity"] as? Double,
                          let temp = main["temp"] as? Double else {
                        self?.errorMessage = "Ungültiges Datenformat"
                        return
                    }

                    let weatherArray = json?["weather"] as? [[String: Any]]
                    let description = weatherArray?.first?["description"] as? String ?? "Unbekannt"

                    self?.currentWeather = WeatherData(
                        humidity: humidity,
                        temperature: temp,
                        description: description,
                        timestamp: Date()
                    )
                    self?.lastFetchTime = Date()
                } catch {
                    self?.errorMessage = "Parsing-Fehler: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

// MARK: - CLLocationManagerDelegate
extension WeatherService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
        fetchWeather()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Standortfehler: \(error.localizedDescription)"
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationAuthorized = true
            locationManager.requestLocation()
        case .denied, .restricted:
            locationAuthorized = false
            errorMessage = "Standortzugriff verweigert"
        case .notDetermined:
            locationAuthorized = false
        @unknown default:
            break
        }
    }
}
