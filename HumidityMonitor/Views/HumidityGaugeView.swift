import SwiftUI

struct HumidityGaugeView: View {
    let value: Double
    let maxValue: Double
    let label: String
    let size: CGFloat

    init(value: Double, maxValue: Double = 100, label: String, size: CGFloat = 200) {
        self.value = value
        self.maxValue = maxValue
        self.label = label
        self.size = size
    }

    private var progress: Double {
        min(value / maxValue, 1.0)
    }

    private var color: Color {
        if value > 65 {
            return .red
        } else if value > 50 {
            return .yellow
        }
        return .green
    }

    private var gradientColors: [Color] {
        [color.opacity(0.6), color]
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: size * 0.08)

                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: gradientColors),
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360 * progress)
                        ),
                        style: StrokeStyle(
                            lineWidth: size * 0.08,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: progress)

                // Center content
                VStack(spacing: 4) {
                    Text(String(format: "%.1f%%", value))
                        .font(.system(size: size * 0.2, weight: .bold, design: .rounded))
                        .foregroundColor(color)

                    Image(systemName: "drop.fill")
                        .font(.system(size: size * 0.08))
                        .foregroundColor(color.opacity(0.7))
                }
            }
            .frame(width: size, height: size)

            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
