import SwiftUI
import Charts

/// Gráfico de linha de peso com Swift Charts.
struct WeightChartView: View {
    let entries: [WeightEntry]

    private var sortedEntries: [WeightEntry] {
        entries.sorted { $0.date < $1.date }
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Evolução do peso")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppColors.text)

                if sortedEntries.count < 2 {
                    Text("Adicione pelo menos 2 medições de peso para ver o gráfico.")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .frame(height: 120)
                } else {
                    Chart(sortedEntries) { entry in
                        LineMark(
                            x: .value("Data", entry.date),
                            y: .value("Peso", entry.weightKg)
                        )
                        .foregroundStyle(AppColors.protein)
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Data", entry.date),
                            y: .value("Peso", entry.weightKg)
                        )
                        .foregroundStyle(AppColors.protein)
                        .symbolSize(30)
                    }
                    .frame(height: 140)
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text("\(Int(v))kg")
                                        .font(.caption2)
                                        .foregroundStyle(AppColors.textSecondary)
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: max(1, sortedEntries.count / 4))) { value in
                            AxisValueLabel(format: .dateTime.day().month(.abbreviated).locale(Locale(identifier: "pt_BR")))
                                .font(.caption2)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                }
            }
            .padding(16)
        }
    }
}
