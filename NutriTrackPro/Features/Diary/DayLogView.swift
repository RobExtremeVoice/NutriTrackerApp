import SwiftUI
import SwiftData

/// Lista de refeições de um dia agrupadas por tipo.
struct DayLogView: View {
    let meals: [Meal]
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
            // Resumo do dia
            if !meals.isEmpty {
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
            }

            // Grupos de refeições
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

            if meals.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 36))
                        .foregroundStyle(AppColors.primary.opacity(0.4))
                    Text("Nenhuma refeição neste dia")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .padding(32)
            }
        }
    }

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
