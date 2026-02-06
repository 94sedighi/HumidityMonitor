import SwiftUI
import Charts

enum TimeRange: String, CaseIterable {
    case day = "24h"
    case week = "7 Tage"
    case month = "30 Tage"

    var hours: Int {
        switch self {
        case .day: return 24
        case .week: return 168
        case .month: return 720
        }
    }
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let value: Double
    let series: String
}

struct HistoryChartView: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    @State private var selectedRange: TimeRange = .day

    private var chartData: [ChartDataPoint] {
        let readings = viewModel.readings(for: selectedRange)
        var points: [ChartDataPoint] = []

        for reading in readings {
            if let indoor = reading.indoorHumidity {
                points.append(ChartDataPoint(timestamp: reading.timestamp, value: indoor, series: "Innen"))
            }
            if let outdoor = reading.outdoorHumidity {
                points.append(ChartDataPoint(timestamp: reading.timestamp, value: outdoor, series: "Außen"))
            }
        }
        return points
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Time range picker
                Picker("Zeitraum", selection: $selectedRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if chartData.isEmpty {
                    ContentUnavailableView(
                        "Keine Daten",
                        systemImage: "chart.xyaxis.line",
                        description: Text("Es liegen noch keine Messwerte für diesen Zeitraum vor.")
                    )
                } else {
                    Chart {
                        ForEach(chartData) { point in
                            LineMark(
                                x: .value("Zeit", point.timestamp),
                                y: .value("Feuchtigkeit", point.value)
                            )
                            .foregroundStyle(by: .value("Quelle", point.series))
                            .interpolationMethod(.catmullRom)
                        }

                        // Warning threshold line
                        RuleMark(y: .value("Warnung", viewModel.warningThreshold))
                            .foregroundStyle(.yellow.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                            .annotation(position: .trailing, alignment: .leading) {
                                Text("Warnung")
                                    .font(.caption2)
                                    .foregroundColor(.yellow)
                            }

                        // Alarm threshold line
                        RuleMark(y: .value("Alarm", viewModel.alarmThreshold))
                            .foregroundStyle(.red.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                            .annotation(position: .trailing, alignment: .leading) {
                                Text("Alarm")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                            }
                    }
                    .chartForegroundStyleScale([
                        "Innen": Color.blue,
                        "Außen": Color.orange
                    ])
                    .chartYScale(domain: 0...100)
                    .chartYAxis {
                        AxisMarks(values: .stride(by: 10)) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text("\(Int(v))%")
                                }
                            }
                        }
                    }
                    .frame(height: 300)
                    .padding()
                }

                Spacer()
            }
            .navigationTitle("Verlauf")
        }
    }
}
