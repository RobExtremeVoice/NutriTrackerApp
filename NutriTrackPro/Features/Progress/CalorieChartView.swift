import SwiftUI
import Charts

struct DayCalorieData: Identifiable {
    let id = UUID()
    let date: Date
    let calories: Double
    var shortLabel: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "pt_BR")
        fmt.dateFormat = "EEE"
        return fmt.string(from: date).prefix(3).capitalized
    }
}

/// Gráfico de barras de calorias com Swift Charts.
struct CalorieChartView: View {
    let data: [DayCalorieData]
    let goal: Double

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Calorias por dia")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppColors.text)

                Chart(data) { day in
                    BarMark(
                        x: .value("Dia", day.shortLabel),
                        y: .value("Kcal", day.calories)
                    )
                    .foregroundStyle(day.calories > goal ? AppColors.accent : AppColors.primary)
                    .cornerRadius(6)

                    RuleMark(y: .value("Meta", goal))
                        .foregroundStyle(AppColors.textSecondary.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                        .annotation(position: .top, alignment: .leading) {
                            Text("Meta")
                                .font(.caption2)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                }
                .frame(height: 160)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v))")
                                    .font(.caption2)
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let s = value.as(String.self) {
                                Text(s).font(.caption2).foregroundStyle(AppColors.textSecondary)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
    }
}
