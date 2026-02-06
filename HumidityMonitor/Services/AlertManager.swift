import Foundation
import UserNotifications

final class AlertManager: ObservableObject {
    @Published var threshold: AlertThreshold {
        didSet {
            saveThreshold()
        }
    }
    @Published var notificationsAuthorized = false
    @Published var currentLevel: HumidityLevel = .normal

    private var lastNotificationTime: Date?
    private let userDefaultsKey = "alertThreshold"

    init() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let saved = try? JSONDecoder().decode(AlertThreshold.self, from: data) {
            threshold = saved
        } else {
            threshold = .default
        }
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.notificationsAuthorized = granted
            }
            if let error = error {
                print("Benachrichtigungsfehler: \(error)")
            }
        }
    }

    func checkHumidity(_ humidity: Double) {
        guard threshold.isEnabled else { return }

        let newLevel = HumidityLevel.level(for: humidity, threshold: threshold)
        currentLevel = newLevel

        guard newLevel != .normal else { return }

        // Check repeat interval
        if let lastTime = lastNotificationTime {
            let elapsed = Date().timeIntervalSince(lastTime)
            if elapsed < Double(threshold.repeatIntervalMinutes * 60) {
                return
            }
        }

        sendNotification(level: newLevel, humidity: humidity)
        lastNotificationTime = Date()
    }

    private func sendNotification(level: HumidityLevel, humidity: Double) {
        let content = UNMutableNotificationContent()

        switch level {
        case .warning:
            content.title = "Feuchtigkeitswarnung"
            content.body = String(format: "Luftfeuchtigkeit bei %.1f%% – Lüften empfohlen!", humidity)
            content.sound = .default
        case .alarm:
            content.title = "Feuchtigkeitsalarm!"
            content.body = String(format: "Luftfeuchtigkeit bei %.1f%% – Sofort lüften!", humidity)
            content.sound = .defaultCritical
        case .normal:
            return
        }

        content.badge = 1

        let request = UNNotificationRequest(
            identifier: "humidity-\(level)-\(UUID().uuidString)",
            content: content,
            trigger: nil // Immediate delivery
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Benachrichtigungsfehler: \(error)")
            }
        }
    }

    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0) { _ in }
    }

    private func saveThreshold() {
        if let data = try? JSONEncoder().encode(threshold) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
}
