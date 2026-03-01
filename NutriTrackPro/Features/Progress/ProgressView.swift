import SwiftUI
import SwiftData
import Charts

enum ProgressPeriod: String, CaseIterable {
    case week  = "7 dias"
    case month = "30 dias"
    case quarter = "90 dias"

    var days: Int {
        switch self {
        case .week:    return 7
        case .month:   return 30
        case .quarter: return 90
        }
    }
}

/// Tela de progresso com gráficos de calorias e peso.
struct ProgressView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Meal.timestamp, order: .reverse)    private var allMeals: [Meal]
    @Query(sort: \WeightEntry.date, order: .reverse)  private var weightEntries: [WeightEntry]
    @Query(sort: \UserProfile.name)                   private var profiles: [UserProfile]

    @State private var selectedPeriod: ProgressPeriod = .week
    @State private var showWeightEntry = false
    @State private var weightInput = ""

    private var profile: UserProfile? { profiles.first }
    private var calorieGoal: Double { profile?.dailyCalorieGoal ?? 2000 }

    private var periodStart: Date {
        Calendar.current.date(byAdding: .day, value: -selectedPeriod.days, to: .now) ?? .now
    }

    private var calorieData: [DayCalorieData] {
        let calendar = Calendar.current
        return (0..<selectedPeriod.days).compactMap { offset -> DayCalorieData? in
            guard let day = calendar.date(byAdding: .day, value: -(selectedPeriod.days - 1 - offset), to: calendar.startOfDay(for: .now)) else { return nil }
            let cals = allMeals
                .filter { calendar.isDate($0.timestamp, inSameDayAs: day) }
                .reduce(0.0) { $0 + $1.totalCalories }
            return DayCalorieData(date: day, calories: cals)
        }
    }

    private var filteredWeightEntries: [WeightEntry] {
        weightEntries.filter { $0.date >= periodStart }
    }

    // Stats
    private var avgCalories: Double {
        let data = calorieData.filter { $0.calories > 0 }
        guard !data.isEmpty else { return 0 }
        return data.reduce(0) { $0 + $1.calories } / Double(data.count)
    }

    private var loggedDays: Int {
        calorieData.filter { $0.calories > 0 }.count
    }

    private var streakDays: Int { profile?.streakDays ?? 0 }

    private var weightChange: String {
        guard filteredWeightEntries.count >= 2 else { return "–" }
        let sorted = filteredWeightEntries.sorted { $0.date < $1.date }
        let diff = sorted.last!.weightKg - sorted.first!.weightKg
        return String(format: "%+.1f kg", diff)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Period selector
                    Picker("Período", selection: $selectedPeriod) {
                        ForEach(ProgressPeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)

                    // Stats cards (2x2 grid)
                    LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
                        StatsCardView(
                            icon: "flame.fill",
                            label: "Média calórica",
                            value: "\(Int(avgCalories)) kcal",
                            subtitle: "por dia",
                            color: AppColors.accent
                        )
                        StatsCardView(
                            icon: "checkmark.seal.fill",
                            label: "Dias registrados",
                            value: "\(loggedDays)",
                            subtitle: "de \(selectedPeriod.days) dias",
                            color: AppColors.primary
                        )
                        StatsCardView(
                            icon: "flame.circle.fill",
                            label: "Sequência",
                            value: "\(streakDays) dias",
                            subtitle: "consecutivos",
                            color: .orange
                        )
                        StatsCardView(
                            icon: "scalemass.fill",
                            label: "Variação de peso",
                            value: weightChange,
                            subtitle: "no período",
                            color: AppColors.protein
                        )
                    }
                    .padding(.horizontal, 16)

                    // Gráfico de calorias
                    CalorieChartView(data: calorieData, goal: calorieGoal)
                        .padding(.horizontal, 16)

                    // Gráfico de peso
                    WeightChartView(entries: filteredWeightEntries)
                        .padding(.horizontal, 16)

                    Spacer(minLength: 80)
                }
                .padding(.top, 16)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Progresso")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showWeightEntry = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(AppColors.primary)
                    }
                }
            }
            .alert("Registrar peso", isPresented: $showWeightEntry) {
                TextField("Peso em kg (ex: 70.5)", text: $weightInput)
                    .keyboardType(.decimalPad)
                Button("Salvar") { saveWeight() }
                Button("Cancelar", role: .cancel) { weightInput = "" }
            } message: {
                Text("Informe seu peso atual em quilogramas.")
            }
        }
    }

    private func saveWeight() {
        guard let kg = Double(weightInput.replacingOccurrences(of: ",", with: ".")),
              kg > 0 else { return }
        let entry = WeightEntry(weightKg: kg)
        modelContext.insert(entry)
        weightInput = ""
    }
}
