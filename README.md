 1. BLEManager — Scans for Bluetooth sensors broadcasting the standard Environmental Sensing Service (UUID 181A). Reads humidity
  (2A6F) and temperature (2A6E) characteristics. Auto-reconnects if disconnected.
  2. WeatherService — Gets your GPS location, calls OpenWeatherMap every 15 minutes, caches results. Returns outdoor humidity,
  temperature, and weather description in German.
  3. AlertManager — When indoor humidity exceeds your thresholds (default: 60% warning, 70% alarm), it fires a push notification.
  Won't spam you — respects a repeat interval (default 30 min).
  4. DataStore — Saves a reading every 5 minutes to SwiftData. Auto-deletes data older than 30 days.

  The 4 Screens (Tabs)

  1. Dashboard — Big circular gauge for indoor humidity (green/yellow/red), outdoor weather card, temperature comparison, and a
  ventilation recommendation ("Lüften empfohlen!" if outdoor air is drier)
  2. Verlauf (History) — Line chart showing indoor (blue) and outdoor (orange) humidity over time with 24h/7d/30d picker. Warning and
   alarm thresholds drawn as dashed lines.
  3. Sensoren (Sensors) — Bluetooth status, list of discovered BLE sensors with RSSI signal bars, connect/disconnect buttons.
  4. Einstellungen (Settings) — Sliders for warning/alarm thresholds, notification repeat interval, OpenWeatherMap API key input,
  °C/°F toggle, data management.

  Wiring

  The HumidityMonitorApp entry point creates all 4 services, injects them into two ViewModels (DashboardViewModel +
  SettingsViewModel), and passes those to the views via @EnvironmentObject. Combine subscriptions keep everything reactive — when the
   BLE sensor pushes a new value, the gauge updates, the alert system checks thresholds, and a reading gets queued for storage.
