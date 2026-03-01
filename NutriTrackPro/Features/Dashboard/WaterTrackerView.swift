import SwiftUI
import SwiftData

private let waterBlue = Color(hex: "3B82F6")

/// Card compacto de hidratação — anel mini + botão que abre WaterLogView.
struct WaterTrackerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WaterEntry.date, order: .reverse) private var allEntries: [WaterEntry]

    let goal: Int // ml

    @State private var showLog = false

    private var todayEntry: WaterEntry? {
        allEntries.first { Calendar.current.isDateInToday($0.date) }
    }

    private var mlToday: Int { todayEntry?.mlConsumed ?? 0 }
    private var progress: Double { min(1.0, Double(mlToday) / Double(max(1, goal))) }

    var body: some View {
        GlassCard {
            HStack(spacing: 16) {
                // Mini anel circular
                ZStack {
                    Circle()
                        .stroke(waterBlue.opacity(0.15), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(waterBlue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(duration: 0.6), value: mlToday)
                }
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(waterBlue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Água")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColors.textSecondary)
                    Text("\(mlToday)ml")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(waterBlue)
                    Text("de \(goal)ml")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                Button { showLog = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                        Text("Registrar")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(waterBlue, in: Capsule())
                }
            }
            .padding(16)
        }
        .sheet(isPresented: $showLog) {
            WaterLogView(goal: goal)
                .presentationDetents([.fraction(0.72), .large])
                .presentationDragIndicator(.visible)
        }
    }
}
