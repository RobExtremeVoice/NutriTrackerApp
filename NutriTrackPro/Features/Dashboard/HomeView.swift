import SwiftUI
import SwiftData

/// Tela principal — ring de calorias, macros, água e refeições do dia.
struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \UserProfile.name) private var profiles: [UserProfile]
    @Query(sort: \Meal.timestamp, order: .reverse) private var allMeals: [Meal]
    @Query(filter: #Predicate<Meal> { $0.isFavorite },
           sort: \Meal.timestamp, order: .reverse) private var favoriteMeals: [Meal]

    @State private var showAddMeal    = false
    @State private var showProfile    = false
    @State private var stepsToday:  Int = 0

    private var profile: UserProfile? { profiles.first }

    private var profilePhoto: UIImage? {
        guard let data = UserDefaults.standard.data(forKey: "userProfilePhotoData") else { return nil }
        return UIImage(data: data)
    }

    private var initials: String {
        guard let name = profile?.name, !name.isEmpty else { return "U" }
        let parts = name.components(separatedBy: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last  = parts.count > 1 ? (parts.last?.first.map(String.init) ?? "") : ""
        return (first + last).uppercased()
    }

    private var todayMeals: [Meal] {
        allMeals.filter { $0.isOnDay(.now) }
    }

    private var todayNutrition: NutritionInfo {
        todayMeals.reduce(.zero) { $0 + $1.totalNutrition }
    }

    private var goalNutrition: NutritionInfo {
        guard let p = profile else {
            return NutritionInfo(calories: 2000, protein: 120, carbs: 225, fat: 65, fiber: 30)
        }
        return NutritionInfo(
            calories: p.dailyCalorieGoal,
            protein:  p.dailyProteinGoal,
            carbs:    p.dailyCarbsGoal,
            fat:      p.dailyFatGoal,
            fiber:    p.dailyFiberGoal
        )
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12:  return "Bom dia"
        case 12..<18: return "Boa tarde"
        default:      return "Boa noite"
        }
    }

    private var todayDateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEEE, d 'de' MMMM"
        return formatter.string(from: .now).capitalized
    }

    private var mealsByType: [(MealType, [Meal])] {
        MealType.allCases.compactMap { type in
            let meals = todayMeals.filter { $0.type == type.rawValue }
            return meals.isEmpty ? nil : (type, meals)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // Header: saudação + streak inline
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(greeting), \(profile?.firstName ?? "usuário") 👋")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(AppColors.text)
                            Text(todayDateText)
                                .font(.system(size: 14))
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        Spacer()
                        if let p = profile, p.streakDays > 0 {
                            StreakBadge(days: p.streakDays)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)

                    // Resumo nutricional unificado (ring + macros)
                    GlassCard(cornerRadius: AppConstants.largeCornerRadius) {
                        VStack(spacing: 0) {
                            CalorieRingView(
                                consumed: todayNutrition.calories,
                                goal: goalNutrition.calories
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .padding(.bottom, 16)

                            Divider()
                                .padding(.horizontal, 16)

                            MacrosSectionView(
                                nutrition: todayNutrition,
                                goals: goalNutrition
                            )
                        }
                    }
                    .padding(.horizontal, 16)

                    // Quick-relog: refeições favoritas
                    if !favoriteMeals.isEmpty {
                        favoritesSection
                    }

                    // Água
                    WaterTrackerView(goal: profile?.dailyWaterGoal ?? 2000)
                        .padding(.horizontal, 16)

                    // Passos (Apple Health — exibido apenas quando autorizado)
                    if appState.healthKitEnabled {
                        stepsCard
                            .padding(.horizontal, 16)
                    }

                    // Refeições
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Refeições de hoje")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(AppColors.text)
                            Spacer()
                            if !todayMeals.isEmpty {
                                Button("Ver todas") {}
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(AppColors.primary)
                            }
                        }
                        .padding(.horizontal, 16)

                        if todayMeals.isEmpty {
                            emptyStateView
                        } else {
                            ForEach(mealsByType, id: \.0) { type, meals in
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(type.emoji + " " + type.displayName)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(AppColors.textSecondary)
                                        .padding(.horizontal, 16)
                                        .padding(.bottom, 4)

                                    GlassCard {
                                        VStack(spacing: 0) {
                                            ForEach(meals) { meal in
                                                MealRowView(meal: meal)
                                                if meal.id != meals.last?.id {
                                                    Divider().padding(.leading, 76)
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                    }

                    Spacer(minLength: 80)
                }
                .padding(.top, 8)
            }
            .background(Color(.systemGray6).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showProfile = true } label: {
                        ZStack {
                            if let photo = profilePhoto {
                                Image(uiImage: photo)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [AppColors.primary, AppColors.primaryDark],
                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 36, height: 36)
                                Text(initials)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .shadow(color: AppColors.primary.opacity(0.3), radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddMeal = true
                    } label: {
                        Image(systemName: "camera.fill")
                            .foregroundStyle(AppColors.primary)
                            .frame(width: 36, height: 36)
                            .background(.white, in: Circle())
                            .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                fab
            }
            .sheet(isPresented: $showAddMeal) {
                AddMealView()
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
            }
            .task {
                await refreshSteps()
            }
        }
    }

    // MARK: – Steps card

    private var stepsCard: some View {
        let goal = 10_000
        let progress = min(Double(stepsToday) / Double(goal), 1.0)
        return GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "34D399").opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "figure.walk")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color(hex: "34D399"))
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(stepsToday)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(AppColors.text)
                        Text("/ \(goal) passos")
                            .font(.system(size: 12))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: "34D399").opacity(0.12))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: "34D399"))
                                .frame(width: geo.size.width * progress)
                                .animation(.spring(duration: 0.8), value: stepsToday)
                        }
                    }
                    .frame(height: 6)
                }

                Spacer()

                Text("\(Int(progress * 100))%")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(hex: "34D399"))
            }
            .padding(14)
        }
    }

    private func refreshSteps() async {
        guard appState.healthKitEnabled else { return }
        let steps = (try? await HealthKitService.shared.fetchStepsToday()) ?? 0
        await MainActor.run { stepsToday = steps }
    }

    // MARK: – Favorites quick-relog

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "F59E0B"))
                Text("Favoritas")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppColors.text)
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(favoriteMeals.prefix(6)) { meal in
                        favoriteChip(meal)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func favoriteChip(_ meal: Meal) -> some View {
        Button {
            relogMeal(meal)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } label: {
            VStack(spacing: 6) {
                if let data = meal.imageData, let ui = UIImage(data: data) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.primary.opacity(0.1))
                            .frame(width: 64, height: 64)
                        Text(meal.mealType.emoji)
                            .font(.system(size: 28))
                    }
                }
                Text(meal.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppColors.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 72)
                Text("\(Int(meal.totalCalories)) kcal")
                    .font(.system(size: 10))
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }

    /// Recria a refeição favorita como novo registro de hoje.
    private func relogMeal(_ source: Meal) {
        let newMeal = Meal(type: source.mealType, name: source.name)
        for food in source.foods {
            let copy = FoodItem(
                name: food.name,
                weightG: food.weightG,
                caloriesPer100g: food.caloriesPer100g,
                proteinPer100g:  food.proteinPer100g,
                carbsPer100g:    food.carbsPer100g,
                fatPer100g:      food.fatPer100g,
                fiberPer100g:    food.fiberPer100g,
                aiConfidence:    food.aiConfidence
            )
            newMeal.foods.append(copy)
            modelContext.insert(copy)
        }
        modelContext.insert(newMeal)
        Task { await NotificationService.shared.scheduleReEngagementReminder() }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.primary.opacity(0.4))
            Text("Nenhuma refeição hoje")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)
            Text("Toque no botão + para registrar sua primeira refeição")
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }

    private var fab: some View {
        Button {
            showAddMeal = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(AppColors.primary, in: Circle())
                .shadow(color: AppColors.primary.opacity(0.4), radius: 12, y: 4)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }
}
