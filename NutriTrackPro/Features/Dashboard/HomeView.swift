import SwiftUI
import SwiftData

/// Tela principal — ring de calorias, macros, água e refeições do dia.
struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \UserProfile.name) private var profiles: [UserProfile]
    @Query(sort: \Meal.timestamp, order: .reverse) private var allMeals: [Meal]

    @State private var showAddMeal = false

    private var profile: UserProfile? { profiles.first }

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

                    // Calorie Ring
                    GlassCard(cornerRadius: AppConstants.largeCornerRadius) {
                        CalorieRingView(
                            consumed: todayNutrition.calories,
                            goal: goalNutrition.calories
                        )
                        .padding(20)
                    }
                    .padding(.horizontal, 16)

                    // Macros
                    MacrosSectionView(
                        nutrition: todayNutrition,
                        goals: goalNutrition
                    )
                    .padding(.horizontal, 16)

                    // Água
                    WaterTrackerView(goal: profile?.dailyWaterGoal ?? 8)
                        .padding(.horizontal, 16)

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
                    Text("NutriTrack Pro")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(AppColors.text)
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
        }
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
