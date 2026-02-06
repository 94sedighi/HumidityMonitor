import Foundation

struct AlertThreshold: Codable, Equatable {
    var warningLevel: Double
    var alarmLevel: Double
    var repeatIntervalMinutes: Int
    var isEnabled: Bool

    static let `default` = AlertThreshold(
        warningLevel: 60.0,
        alarmLevel: 70.0,
        repeatIntervalMinutes: 30,
        isEnabled: true
    )
}

enum HumidityLevel {
    case normal
    case warning
    case alarm

    var label: String {
        switch self {
        case .normal: return "Normal"
        case .warning: return "Warnung"
        case .alarm: return "Alarm"
        }
    }

    static func level(for humidity: Double, threshold: AlertThreshold) -> HumidityLevel {
        if humidity >= threshold.alarmLevel {
            return .alarm
        } else if humidity >= threshold.warningLevel {
            return .warning
        }
        return .normal
    }
}
