import WidgetKit
import SwiftUI

// MARK: – Timeline Provider

struct NutriProvider: TimelineProvider {
    func placeholder(in context: Context) -> NutriEntry {
        NutriEntry(date: .now, data: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (NutriEntry) -> Void) {
        completion(NutriEntry(date: .now, data: WidgetDataStore.shared.read() ?? .preview))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NutriEntry>) -> Void) {
        let entry = NutriEntry(date: .now, data: WidgetDataStore.shared.read() ?? .empty)
        // Atualiza à meia-noite para resetar o progresso do dia
        let tomorrow = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: .now)!
        )
        completion(Timeline(entries: [entry], policy: .after(tomorrow)))
    }
}

struct NutriEntry: TimelineEntry {
    let date: Date
    let data: NutriWidgetEntry
}

// MARK: – Colors (inline — widget target doesn't share AppColors)

private extension Color {
    static let nutriGreen  = Color(red: 0.13, green: 0.77, blue: 0.37)
    static let nutriBlue   = Color(red: 0.23, green: 0.51, blue: 0.96)
    static let nutriOrange = Color(red: 0.98, green: 0.58, blue: 0.09)
    static let nutriRed    = Color(red: 0.94, green: 0.35, blue: 0.22)
}

// MARK: – Small Widget (84 × 84pt usable area)

struct NutriSmallView: View {
    let data: NutriWidgetEntry

    var body: some View {
        VStack(spacing: 8) {
            // Anel de calorias
            ZStack {
                Circle()
                    .stroke(Color.nutriGreen.opacity(0.18), lineWidth: 9)
                Circle()
                    .trim(from: 0, to: data.progress)
                    .stroke(Color.nutriGreen,
                            style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.6), value: data.progress)

                VStack(spacing: 1) {
                    Text("\(data.caloriesRemaining)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .minimumScaleFactor(0.7)
                    Text("kcal")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 76, height: 76)

            // Sequência
            if data.streakDays > 0 {
                Label("\(data.streakDays)d", systemImage: "flame.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.nutriGreen)
                    .labelStyle(.titleAndIcon)
            }
        }
        .padding(10)
        .containerBackground(.white, for: .widget)
    }
}

// MARK: – Medium Widget (~320 × 155pt usable area)

struct NutriMediumView: View {
    let data: NutriWidgetEntry

    var body: some View {
        HStack(spacing: 18) {
            // Anel + calorias
            ZStack {
                Circle()
                    .stroke(Color.nutriGreen.opacity(0.18), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: data.progress)
                    .stroke(Color.nutriGreen,
                            style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.6), value: data.progress)

                VStack(spacing: 2) {
                    Text("\(Int(data.caloriesConsumed))")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.7)
                    Text("de \(Int(data.calorieGoal))")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                    Text("kcal")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 88, height: 88)

            // Macros + sequência
            VStack(alignment: .leading, spacing: 7) {
                macroRow("Proteína", value: data.protein, color: .nutriBlue)
                macroRow("Carbos",   value: data.carbs,   color: .nutriOrange)
                macroRow("Gordura",  value: data.fat,     color: .nutriRed)

                if data.streakDays > 0 {
                    Divider()
                    Label("\(data.streakDays) dias seguidos", systemImage: "flame.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.nutriGreen)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .containerBackground(.white, for: .widget)
    }

    private func macroRow(_ label: String, value: Double, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(Int(value))g")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.primary)
        }
    }
}

// MARK: – Entry View (selects layout by family)

struct NutriWidgetEntryView: View {
    let entry: NutriEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemSmall:  NutriSmallView(data: entry.data)
        case .systemMedium: NutriMediumView(data: entry.data)
        default:            NutriSmallView(data: entry.data)
        }
    }
}

// MARK: – Widget Configuration

@main
struct NutriTrackProWidget: Widget {
    let kind = "NutriTrackProWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NutriProvider()) { entry in
            NutriWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("NutriPack Pro")
        .description("Acompanhe suas calorias e sequência direto na tela inicial.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: – Previews

#Preview("Small", as: .systemSmall) {
    NutriTrackProWidget()
} timeline: {
    NutriEntry(date: .now, data: .preview)
    NutriEntry(date: .now, data: .empty)
}

#Preview("Medium", as: .systemMedium) {
    NutriTrackProWidget()
} timeline: {
    NutriEntry(date: .now, data: .preview)
}
