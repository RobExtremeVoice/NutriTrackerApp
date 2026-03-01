import SwiftUI

/// Exibe o resultado da análise da IA com animações e edição por item.
struct FoodAnalysisView: View {
    @Binding var result: FoodAnalysisResult
    let onConfirm: () -> Void

    @State private var editingItem: FoodAnalysisItem?
    @State private var animatedCalories: Double = 0
    @State private var itemsAppeared: [Bool] = []

    private var totalNutrition: NutritionInfo {
        result.foods.reduce(.zero) { acc, food in
            NutritionInfo(
                calories: acc.calories + food.calories,
                protein:  acc.protein  + food.proteinG,
                carbs:    acc.carbs    + food.carbsG,
                fat:      acc.fat      + food.fatG,
                fiber:    acc.fiber    + food.fiberG
            )
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.mealName)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(AppColors.text)
                            ConfidenceBadge(confidence: result.confidence)
                        }
                        Spacer()
                    }

                    if let note = result.portionNote {
                        Text(note)
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(16)

                // Calorias totais com count-up
                GlassCard(cornerRadius: AppConstants.largeCornerRadius) {
                    VStack(spacing: 4) {
                        Text("\(Int(animatedCalories))")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundStyle(AppColors.primary)
                        Text("kcal totais")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.textSecondary)

                        HStack(spacing: 20) {
                            macroMini("P", value: totalNutrition.protein, color: AppColors.protein)
                            macroMini("C", value: totalNutrition.carbs,   color: AppColors.carbs)
                            macroMini("G", value: totalNutrition.fat,     color: AppColors.fat)
                            macroMini("F", value: totalNutrition.fiber,   color: AppColors.fiber)
                        }
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                }
                .padding(.horizontal, 16)

                // Lista de alimentos detectados
                VStack(alignment: .leading, spacing: 8) {
                    Text("Alimentos detectados")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColors.text)
                        .padding(.horizontal, 16)

                    ForEach(Array(result.foods.enumerated()), id: \.element.id) { index, food in
                        foodItemCard(food: food, index: index)
                            .opacity(itemsAppeared.indices.contains(index) && itemsAppeared[index] ? 1 : 0)
                            .offset(y: itemsAppeared.indices.contains(index) && itemsAppeared[index] ? 0 : 20)
                            .animation(.spring().delay(Double(index) * 0.1), value: itemsAppeared.indices.contains(index) ? itemsAppeared[index] : false)
                    }
                }

                // Botão confirmar
                PrimaryButton(title: "Adicionar ao Diário", icon: "plus.circle.fill") {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    onConfirm()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            startCountUp()
            animateItems()
        }
        .sheet(item: $editingItem) { food in
            if let idx = result.foods.firstIndex(where: { $0.id == food.id }) {
                FoodItemEditView(item: $result.foods[idx])
            }
        }
    }

    private func foodItemCard(food: FoodAnalysisItem, index: Int) -> some View {
        GlassCard {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(food.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppColors.text)
                        ConfidenceBadge(confidence: food.confidence)
                    }
                    Text("\(Int(food.estimatedWeightG))g · \(Int(food.calories)) kcal")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                Spacer()
                Button {
                    editingItem = food
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(AppColors.primary)
                }
            }
            .padding(14)
        }
        .padding(.horizontal, 16)
    }

    private func macroMini(_ label: String, value: Double, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(String(format: "%.0f g", value))
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private func startCountUp() {
        let target = totalNutrition.calories
        let steps = 40
        let interval = 0.8 / Double(steps)
        var current = 0
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            current += 1
            animatedCalories = target * Double(current) / Double(steps)
            if current >= steps {
                animatedCalories = target
                timer.invalidate()
            }
        }
    }

    private func animateItems() {
        itemsAppeared = Array(repeating: false, count: result.foods.count)
        for i in 0..<result.foods.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + Double(i) * 0.1) {
                itemsAppeared[i] = true
            }
        }
    }
}
