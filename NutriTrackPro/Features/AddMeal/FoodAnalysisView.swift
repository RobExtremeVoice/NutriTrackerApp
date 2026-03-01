import SwiftUI

/// Exibe o resultado da análise da IA com animações, edição por item e ajuste de porção.
struct FoodAnalysisView: View {
    @Binding var result: FoodAnalysisResult
    let onConfirm: () -> Void

    @State private var editingItem: FoodAnalysisItem?
    @State private var animatedCalories: Double = 0
    @State private var itemsAppeared: [Bool] = []
    @State private var selectedPortion = 0 // 0=Pequena 1=Média 2=Grande

    private let portionLabels = ["Pequena", "Média", "Grande"]

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
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {

                    // Header — nome + badge de confiança
                    VStack(alignment: .leading, spacing: 8) {
                        Text(result.mealName)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(AppColors.text)
                        ConfidenceBadge(confidence: result.confidence)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                    // Calorias totais com count-up
                    GlassCard(cornerRadius: AppConstants.largeCornerRadius) {
                        VStack(spacing: 4) {
                            Text("\(Int(animatedCalories))")
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundStyle(AppColors.primary)
                            Text("kcal totais")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(AppColors.textSecondary)
                                .textCase(.uppercase)
                                .tracking(0.5)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                    // Macros — 4 colunas
                    HStack(spacing: 8) {
                        macroCell("P", value: totalNutrition.protein, unit: "g", color: AppColors.protein)
                        macroCell("C", value: totalNutrition.carbs,   unit: "g", color: AppColors.carbs)
                        macroCell("G", value: totalNutrition.fat,     unit: "g", color: AppColors.fat)
                        macroCell("F", value: totalNutrition.fiber,   unit: "g", color: AppColors.fiber)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)

                    // Alimentos detectados
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Alimentos detectados")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(AppColors.text)
                            .padding(.horizontal, 16)

                        ForEach(Array(result.foods.enumerated()), id: \.element.id) { index, food in
                            foodItemCard(food: food, index: index)
                                .opacity(itemsAppeared.indices.contains(index) && itemsAppeared[index] ? 1 : 0)
                                .offset(y: itemsAppeared.indices.contains(index) && itemsAppeared[index] ? 0 : 20)
                                .animation(.spring().delay(Double(index) * 0.1), value: itemsAppeared.indices.contains(index) ? itemsAppeared[index] : false)
                        }
                    }
                    .padding(.bottom, 24)

                    // Ajuste de porção
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 0) {
                            ForEach(portionLabels.indices, id: \.self) { i in
                                Button {
                                    withAnimation(.spring(duration: 0.25)) { selectedPortion = i }
                                } label: {
                                    Text(portionLabels[i])
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(selectedPortion == i ? AppColors.text : AppColors.textSecondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(selectedPortion == i ? Color.white : Color.clear)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .shadow(color: selectedPortion == i ? .black.opacity(0.1) : .clear, radius: 3, y: 1)
                                }
                            }
                        }
                        .padding(3)
                        .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 16)

                    Spacer(minLength: 96) // espaço para botão fixo
                }
            }

            // Botão fixo no rodapé
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [AppColors.background.opacity(0), AppColors.background],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 24)

                Button {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    onConfirm()
                } label: {
                    HStack(spacing: 8) {
                        Text("Adicionar ao Diário")
                            .font(.system(size: 17, weight: .bold))
                        Image(systemName: "plus.circle.fill")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(AppColors.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: AppColors.primary.opacity(0.35), radius: 12, y: 4)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
                .background(AppColors.background)
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

    private func macroCell(_ label: String, value: Double, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(String(format: "%.0f\(unit)", value))
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppColors.textSecondary)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.white, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private func foodItemCard(food: FoodAnalysisItem, index: Int) -> some View {
        GlassCard {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(food.name)
                            .font(.system(size: 15, weight: .semibold))
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
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .padding(14)
        }
        .padding(.horizontal, 16)
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
