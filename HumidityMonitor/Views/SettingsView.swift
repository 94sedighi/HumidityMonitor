import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel

    var body: some View {
        NavigationStack {
            Form {
                // Alarm thresholds
                Section {
                    Toggle("Alarme aktiviert", isOn: $settingsVM.alertsEnabled)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Warnung ab")
                            Spacer()
                            Text(String(format: "%.0f%%", settingsVM.warningLevel))
                                .foregroundColor(.yellow)
                                .bold()
                        }
                        Slider(value: $settingsVM.warningLevel, in: 40...80, step: 5)
                            .tint(.yellow)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Alarm ab")
                            Spacer()
                            Text(String(format: "%.0f%%", settingsVM.alarmLevel))
                                .foregroundColor(.red)
                                .bold()
                        }
                        Slider(value: $settingsVM.alarmLevel, in: 50...90, step: 5)
                            .tint(.red)
                    }

                    Picker("Wiederholung", selection: $settingsVM.repeatInterval) {
                        Text("15 Minuten").tag(15)
                        Text("30 Minuten").tag(30)
                        Text("60 Minuten").tag(60)
                        Text("2 Stunden").tag(120)
                    }
                } header: {
                    Text("Alarm-Schwellenwerte")
                } footer: {
                    Text("Benachrichtigungen werden gesendet wenn die Innen-Luftfeuchtigkeit die eingestellten Werte überschreitet.")
                }

                // Weather API
                Section {
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundColor(.secondary)
                        SecureField("API Key", text: $settingsVM.weatherAPIKey)
                            .textContentType(.password)
                            .autocorrectionDisabled()
                    }
                } header: {
                    Text("OpenWeatherMap API")
                } footer: {
                    Text("Kostenloser API-Key von openweathermap.org für Außen-Feuchtigkeitsdaten.")
                }

                // Units
                Section {
                    Picker("Temperatur", selection: $settingsVM.useCelsius) {
                        Text("°C").tag(true)
                        Text("°F").tag(false)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Einheiten")
                }

                // Data management
                Section {
                    Button("Alte Daten bereinigen") {
                        settingsVM.purgeOldData()
                    }

                    Button("Alle Daten löschen", role: .destructive) {
                        settingsVM.showDeleteConfirmation = true
                    }
                } header: {
                    Text("Datenverwaltung")
                } footer: {
                    Text("Messdaten älter als 30 Tage werden automatisch bereinigt.")
                }

                // About
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Info")
                }
            }
            .navigationTitle("Einstellungen")
            .alert("Alle Daten löschen?", isPresented: $settingsVM.showDeleteConfirmation) {
                Button("Abbrechen", role: .cancel) { }
                Button("Löschen", role: .destructive) {
                    settingsVM.deleteAllData()
                }
            } message: {
                Text("Alle gespeicherten Messwerte werden unwiderruflich gelöscht.")
            }
        }
    }
}
