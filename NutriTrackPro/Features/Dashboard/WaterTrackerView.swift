import SwiftUI
import SwiftData

/// Tracker de copos de água com animação tap.
struct WaterTrackerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<WaterEntry> { _ in true },
        sort: \WaterEntry.date, order: .reverse
    ) private var allEntries: [WaterEntry]

    let goal: Int

    @State private var tappedCup: Int? = nil

    private var todayEntry: WaterEntry? {
        allEntries.first { Calendar.current.isDateInToday($0.date) }
    }

    private var cupsToday: Int { todayEntry?.cups ?? 0 }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Água", systemImage: "drop.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(hex: "3B82F6"))
                    Spacer()
                    Text("\(cupsToday)/\(goal) copos")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                HStack(spacing: 8) {
                    ForEach(1...goal, id: \.self) { cup in
                        cupButton(index: cup)
                    }
                }
            }
            .padding(16)
        }
    }

    @ViewBuilder
    private func cupButton(index: Int) -> some View {
        let filled = index <= cupsToday
        let tapped = tappedCup == index
        Image(systemName: filled ? "drop.fill" : "drop")
            .font(.system(size: 22))
            .foregroundStyle(filled ? Color(hex: "3B82F6") : Color.gray.opacity(0.3))
            .scaleEffect(tapped ? 1.4 : 1.0)
            .animation(.spring(duration: 0.3, bounce: 0.5), value: tapped)
            .onTapGesture {
                tappedCup = index
                updateWater(to: index == cupsToday ? index - 1 : index)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    tappedCup = nil
                }
            }
    }

    private func updateWater(to cups: Int) {
        if let entry = todayEntry {
            entry.cups = max(0, cups)
        } else if cups > 0 {
            let entry = WaterEntry(cups: cups)
            modelContext.insert(entry)
        }
    }
}
