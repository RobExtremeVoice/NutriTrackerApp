import SwiftUI
import SwiftData
import Charts

enum ProgressPeriod: String, CaseIterable {
    case week    = "7 dias"
    case month   = "30 dias"
    case quarter = "90 dias"

    var days: Int {
        switch self {
        case .week:    return 7
        case .month:   return 30
        case .quarter: return 90
        }
    }
}

/// Tela de progresso com gráficos de calorias, macros e peso.
struct ProgressView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Meal.timestamp, order: .reverse)   private var allMeals: [Meal]
    @Query(sort: \WeightEntry.date, order: .reverse) private var weightEntries: [WeightEntry]
    @Query(sort: \UserProfile.name)                  private var profiles: [UserProfile]

    @State private var selectedPeriod: ProgressPeriod = .week
    @State private var showWeightSheet = false
    @State private var weightInput = ""
    @Namespace private var periodNS

    private var profile: UserProfile? { profiles.first }
    private var calorieGoal: Double { profile?.dailyCalorieGoal ?? 2000 }

    private var periodStart: Date {
        Calendar.current.date(byAdding: .day, value: -selectedPeriod.days, to: .now) ?? .now
    }

    private var calorieData: [DayCalorieData] {
        let calendar = Calendar.current
        return (0..<selectedPeriod.days).compactMap { offset -> DayCalorieData? in
            guard let day = calendar.date(
                byAdding: .day,
                value: -(selectedPeriod.days - 1 - offset),
                to: calendar.startOfDay(for: .now)
            ) else { return nil }
            let cals = allMeals
                .filter { calendar.isDate($0.timestamp, inSameDayAs: day) }
                .reduce(0.0) { $0 + $1.totalCalories }
            return DayCalorieData(date: day, calories: cals)
        }
    }

    private var filteredWeightEntries: [WeightEntry] {
        weightEntries.filter { $0.date >= periodStart }
    }

    // MARK: – Stats

    private var avgCalories: Double {
        let data = calorieData.filter { $0.calories > 0 }
        guard !data.isEmpty else { return 0 }
        return data.reduce(0) { $0 + $1.calories } / Double(data.count)
    }

    private var loggedDays: Int { calorieData.filter { $0.calories > 0 }.count }
    private var streakDays: Int { profile?.streakDays ?? 0 }

    private var weightChange: String {
        let sorted = filteredWeightEntries.sorted { $0.date < $1.date }
        guard sorted.count >= 2 else { return "–" }
        let diff = sorted.last!.weightKg - sorted.first!.weightKg
        return String(format: "%+.1f kg", diff)
    }

    // Average macros over logged days in the period
    private var avgMacros: (protein: Double, carbs: Double, fat: Double) {
        let mealsInPeriod = allMeals.filter { $0.timestamp >= periodStart }
        let days = max(1, loggedDays)
        return (
            protein: mealsInPeriod.reduce(0) { $0 + $1.totalProtein } / Double(days),
            carbs:   mealsInPeriod.reduce(0) { $0 + $1.totalCarbs }   / Double(days),
            fat:     mealsInPeriod.reduce(0) { $0 + $1.totalFat }     / Double(days)
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Period selector (pill style)
                    periodPicker
                        .padding(.horizontal, 16)

                    // Stats 2×2 grid
                    LazyVGrid(
                        columns: [.init(.flexible()), .init(.flexible())],
                        spacing: 12
                    ) {
                        StatsCardView(
                            icon: "flame.fill",
                            label: "Média calórica",
                            value: avgCalories > 0 ? "\(Int(avgCalories)) kcal" : "– kcal",
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
                            icon: "bolt.fill",
                            label: "Sequência",
                            value: "\(streakDays) dias",
                            subtitle: "consecutivos",
                            color: Color(hex: "F59E0B")
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

                    // Calorie bar chart
                    CalorieChartView(data: calorieData, goal: calorieGoal)
                        .padding(.horizontal, 16)

                    // Macro breakdown card
                    macroSummaryCard
                        .padding(.horizontal, 16)

                    // Weight line chart
                    WeightChartView(
                        entries: filteredWeightEntries,
                        onAddWeight: { showWeightSheet = true }
                    )
                    .padding(.horizontal, 16)

                    Spacer(minLength: 80)
                }
                .padding(.top, 16)
            }
            .background(Color(.systemGray6).ignoresSafeArea())
            .navigationTitle("Progresso")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showWeightSheet = true } label: {
                        ZStack {
                            Circle()
                                .fill(AppColors.protein.opacity(0.12))
                                .frame(width: 34, height: 34)
                            Image(systemName: "scalemass.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(AppColors.protein)
                        }
                    }
                }
            }
            .sheet(isPresented: $showWeightSheet) {
                weightEntrySheet
            }
        }
    }

    // MARK: – Period picker (pill style)

    private var periodPicker: some View {
        HStack(spacing: 4) {
            ForEach(ProgressPeriod.allCases, id: \.self) { period in
                Button {
                    withAnimation(.spring(duration: 0.3)) { selectedPeriod = period }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Text(period.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .foregroundStyle(selectedPeriod == period ? .white : AppColors.textSecondary)
                        .background {
                            if selectedPeriod == period {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(AppColors.primary)
                                    .shadow(color: AppColors.primary.opacity(0.3), radius: 6, y: 2)
                                    .matchedGeometryEffect(id: "period", in: periodNS)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 14))
        .animation(.spring(duration: 0.3), value: selectedPeriod)
    }

    // MARK: – Macro summary card

    private var macroSummaryCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Médias de macros")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AppColors.text)
                    Spacer()
                    Text("por dia registrado")
                        .font(.system(size: 11))
                        .foregroundStyle(AppColors.textSecondary)
                }

                macroBar(
                    "Proteína",
                    current: avgMacros.protein,
                    goal: profile?.dailyProteinGoal ?? 120,
                    color: AppColors.protein
                )
                macroBar(
                    "Carboidratos",
                    current: avgMacros.carbs,
                    goal: profile?.dailyCarbsGoal ?? 225,
                    color: AppColors.carbs
                )
                macroBar(
                    "Gordura",
                    current: avgMacros.fat,
                    goal: profile?.dailyFatGoal ?? 65,
                    color: AppColors.fat
                )
            }
            .padding(16)
        }
    }

    private func macroBar(_ label: String, current: Double, goal: Double, color: Color) -> some View {
        VStack(spacing: 5) {
            HStack {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
                Spacer()
                Text("\(Int(current))g / \(Int(goal))g")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.1))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.7), color],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * min(goal > 0 ? current / goal : 0, 1.0))
                        .animation(.spring(duration: 0.8), value: current)
                }
            }
            .frame(height: 7)
        }
    }

    // MARK: – Weight entry sheet

    private var weightEntrySheet: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 20)

            Text("Registrar Peso")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppColors.text)

            Text("Informe seu peso atual em quilogramas")
                .font(.system(size: 14))
                .foregroundStyle(AppColors.textSecondary)
                .padding(.top, 4)
                .padding(.bottom, 28)

            // Weight input
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.systemGray6))
                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    TextField("0.0", text: $weightInput)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.text)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 160)
                    Text("kg")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary)
                        .padding(.bottom, 6)
                }
            }
            .frame(height: 90)
            .padding(.horizontal, 24)

            Spacer()

            Button {
                saveWeight()
                showWeightSheet = false
            } label: {
                Text("Salvar")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        weightInput.isEmpty
                            ? AnyShapeStyle(AppColors.primary.opacity(0.4))
                            : AnyShapeStyle(AppColors.primary),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
            }
            .disabled(weightInput.isEmpty)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .presentationDetents([.height(340)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(28)
    }

    // MARK: – Logic

    private func saveWeight() {
        guard let kg = Double(weightInput.replacingOccurrences(of: ",", with: ".")),
              kg > 0 else { return }
        let entry = WeightEntry(weightKg: kg)
        modelContext.insert(entry)
        weightInput = ""
    }
}
