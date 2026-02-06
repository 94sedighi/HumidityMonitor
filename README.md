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


   Sensors:

  - Xiaomi LYWSD03MMC (~$5-8) — Very cheap. Needs custom firmware (ATC/pvvx) flashed to broadcast standard GATT services. Huge
  community support.

  Enthusiast / Reliable

  - SensorPush HT1 (~$25) — Dedicated humidity sensor, good accuracy. Uses a proprietary BLE protocol though — would need app
  modifications.
  - Inkbird IBS-TH2 (~$15-20) — Temperature + humidity, reasonably standard BLE.

  DIY (Best Compatibility)

  - ESP32 + DHT22/BME280 (~$8-15 total) — This is the guaranteed option. You flash the ESP32 to advertise the exact standard
  Environmental Sensing Service (0x181A) with the correct characteristics. Full control.
    - ESP32 dev board: ~$5
    - BME280 sensor (humidity + temp + pressure): ~$3-5
    - Tons of Arduino/PlatformIO tutorials for this exact setup

  My Recommendation

  If you want plug-and-play: Xiaomi LYWSD03MMC with https://github.com/atc1441/ATC_MiThermometer — it's cheap and the custom firmware
   broadcasts standard GATT services that match exactly what the app expects.

  If you want guaranteed compatibility: ESP32 + BME280 — you control the BLE service UUIDs exactly, so it's a perfect match with zero
   guesswork.
