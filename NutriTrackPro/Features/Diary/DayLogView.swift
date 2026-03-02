import SwiftUI
import SwiftData

/// Lista de refeições de um dia agrupadas por tipo.
struct DayLogView: View {
    let meals: [Meal]
    let onAddMeal: () -> Void
    let onDelete: (Meal) -> Void

    private var grouped: [(MealType, [Meal])] {
        MealType.allCases.compactMap { type in
            let m = meals.filter { $0.type == type.rawValue }
            return m.isEmpty ? nil : (type, m)
        }
    }

    private var dayTotal: NutritionInfo {
        meals.reduce(.zero) { $0 + $1.totalNutrition }
    }

    var body: some View {
        VStack(spacing: 12) {
            if meals.isEmpty {
                emptyState
            } else {
                // Daily summary card
                GlassCard {
                    HStack {
                        statMini("Calorias", value: "\(Int(dayTotal.calories))", unit: "kcal", color: AppColors.accent)
                        Divider().frame(height: 36)
                        statMini("Proteína",  value: "\(Int(dayTotal.protein))", unit: "g", color: AppColors.protein)
                        Divider().frame(height: 36)
                        statMini("Carbos",    value: "\(Int(dayTotal.carbs))",   unit: "g", color: AppColors.carbs)
                        Divider().frame(height: 36)
                        statMini("Gordura",   value: "\(Int(dayTotal.fat))",     unit: "g", color: AppColors.fat)
                    }
                    .padding(16)
                }

                // Meal groups with swipe-to-delete
                ForEach(grouped, id: \.0) { type, typeMeals in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(type.emoji + " " + type.displayName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppColors.textSecondary)

                        GlassCard {
                            ForEach(typeMeals) { meal in
                                VStack(spacing: 0) {
                                    MealRowView(meal: meal)
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                onDelete(meal)
                                            } label: {
                                                Label("Excluir", systemImage: "trash")
                                            }
                                        }
                                    if meal.id != typeMeals.last?.id {
                                        Divider().padding(.leading, 76)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: – Empty state

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.08))
                    .frame(width: 96, height: 96)
                Image(systemName: "fork.knife")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(AppColors.primary.opacity(0.5))
            }

            VStack(spacing: 6) {
                Text("Nenhuma refeição registrada")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.text)
                Text("Registre o que você comeu neste dia")
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button { onAddMeal() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                    Text("Adicionar refeição")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 13)
                .background(AppColors.primary, in: Capsule())
                .shadow(color: AppColors.primary.opacity(0.35), radius: 8, y: 3)
            }
        }
        .padding(.vertical, 48)
        .frame(maxWidth: .infinity)
    }

    // MARK: – Stat cell

    private func statMini(_ label: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 2) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(color)
                Text(unit)
                    .font(.system(size: 10))
                    .foregroundStyle(AppColors.textSecondary)
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
