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

/// Gráfico de barras de calorias diárias com linha de meta.
struct CalorieChartView: View {
    let data: [DayCalorieData]
    let goal: Double

    private var loggedDays: [DayCalorieData] { data.filter { $0.calories > 0 } }

    private var avgCalories: Double {
        guard !loggedDays.isEmpty else { return 0 }
        return loggedDays.reduce(0) { $0 + $1.calories } / Double(loggedDays.count)
    }

    private var daysOnTarget: Int {
        loggedDays.filter { abs($0.calories - goal) / goal <= 0.15 }.count
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Calorias por dia")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(AppColors.text)
                        if loggedDays.isEmpty {
                            Text("Nenhum dado no período")
                                .font(.system(size: 12))
                                .foregroundStyle(AppColors.textSecondary)
                        } else {
                            Text("Média \(Int(avgCalories)) kcal · \(daysOnTarget) dias na meta")
                                .font(.system(size: 12))
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                    Spacer()
                    // Goal badge
                    HStack(spacing: 3) {
                        Circle()
                            .fill(AppColors.textSecondary.opacity(0.5))
                            .frame(width: 6, height: 6)
                        Text("Meta \(Int(goal))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }

                Chart(data) { day in
                    BarMark(
                        x: .value("Dia", day.shortLabel),
                        y: .value("Kcal", day.calories)
                    )
                    .foregroundStyle(
                        day.calories == 0
                            ? AnyShapeStyle(Color(.systemGray5))
                            : day.calories > goal * 1.15
                                ? AnyShapeStyle(AppColors.accent)
                                : AnyShapeStyle(
                                    LinearGradient(
                                        colors: [AppColors.primaryLight, AppColors.primary],
                                        startPoint: .top, endPoint: .bottom
                                    )
                                )
                    )
                    .cornerRadius(6)

                    RuleMark(y: .value("Meta", goal))
                        .foregroundStyle(AppColors.textSecondary.opacity(0.45))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                }
                .frame(height: 180)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v))")
                                    .font(.caption2)
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color(.systemGray5))
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let s = value.as(String.self) {
                                Text(s)
                                    .font(.system(size: 10))
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                    }
                }
                .chartPlotStyle { plot in
                    plot.background(Color.clear)
                }
            }
            .padding(16)
        }
    }
}
