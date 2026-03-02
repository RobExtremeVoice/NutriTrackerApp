import SwiftUI
import Charts

/// Gráfico de linha de peso com área preenchida e estado vazio melhorado.
struct WeightChartView: View {
    let entries: [WeightEntry]
    let onAddWeight: () -> Void

    private var sortedEntries: [WeightEntry] {
        entries.sorted { $0.date < $1.date }
    }

    private var currentWeight: Double? { sortedEntries.last?.weightKg }

    private var weightDelta: Double? {
        guard sortedEntries.count >= 2 else { return nil }
        return sortedEntries.last!.weightKg - sortedEntries.first!.weightKg
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                // Header row — always visible, add button always present
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Evolução do peso")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(AppColors.text)
                        if let w = currentWeight {
                            Text("Atual: \(String(format: "%.1f", w)) kg")
                                .font(.system(size: 12))
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        if let delta = weightDelta {
                            HStack(spacing: 3) {
                                Image(systemName: delta >= 0 ? "arrow.up" : "arrow.down")
                                    .font(.system(size: 10, weight: .bold))
                                Text(String(format: "%+.1f kg", delta))
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .foregroundStyle(delta > 0 ? AppColors.accent : AppColors.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                (delta > 0 ? AppColors.accent : AppColors.primary).opacity(0.1),
                                in: Capsule()
                            )
                        }
                        // Always-visible add button
                        Button { onAddWeight() } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.system(size: 10, weight: .bold))
                                Text("Registrar")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundStyle(AppColors.protein)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(AppColors.protein.opacity(0.1), in: Capsule())
                            .overlay(Capsule().stroke(AppColors.protein.opacity(0.25), lineWidth: 1))
                        }
                    }
                }

                if sortedEntries.count < 2 {
                    emptyState
                } else {
                    Chart(sortedEntries) { entry in
                        AreaMark(
                            x: .value("Data", entry.date),
                            y: .value("Peso", entry.weightKg)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppColors.protein.opacity(0.25), AppColors.protein.opacity(0.02)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Data", entry.date),
                            y: .value("Peso", entry.weightKg)
                        )
                        .foregroundStyle(AppColors.protein)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Data", entry.date),
                            y: .value("Peso", entry.weightKg)
                        )
                        .foregroundStyle(AppColors.protein)
                        .symbolSize(25)
                    }
                    .frame(height: 150)
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text("\(Int(v))kg")
                                        .font(.caption2)
                                        .foregroundStyle(AppColors.textSecondary)
                                }
                            }
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(Color(.systemGray5))
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: max(1, sortedEntries.count / 4))) { value in
                            AxisValueLabel(
                                format: .dateTime.day().month(.abbreviated)
                                    .locale(Locale(identifier: "pt_BR"))
                            )
                            .font(.system(size: 10))
                            .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                    .chartPlotStyle { plot in
                        plot.background(Color.clear)
                    }
                }
            }
            .padding(16)
        }
    }

    private var emptyState: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppColors.protein.opacity(0.08))
                    .frame(width: 48, height: 48)
                Image(systemName: "scalemass.fill")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(AppColors.protein.opacity(0.6))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(sortedEntries.isEmpty ? "Sem medições ainda" : "Precisa de 2 medições")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.text)
                Text(sortedEntries.isEmpty
                     ? "Toque em \"Registrar\" para começar"
                     : "Adicione mais uma para ver o gráfico")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textSecondary)
            }
            Spacer()
        }
        .padding(.vertical, 12)
    }
}
