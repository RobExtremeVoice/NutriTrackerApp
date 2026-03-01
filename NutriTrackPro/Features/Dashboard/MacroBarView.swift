import SwiftUI

/// Barra de progresso de um macronutriente com valor colorido e animação spring.
struct MacroBarView: View {
    let label: String
    let current: Double
    let goal: Double
    let unit: String
    let color: Color

    @State private var animatedProgress: Double = 0

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(current / goal, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
                Spacer()
                Text("\(Int(current))/\(Int(goal))\(unit)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(color)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.gray.opacity(0.12))

                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(color)
                        .frame(width: geo.size.width * animatedProgress)
                        .animation(.spring(duration: 0.8, bounce: 0.2), value: animatedProgress)
                }
            }
            .frame(height: 8)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.8)) { animatedProgress = progress }
        }
        .onChange(of: current) {
            withAnimation(.spring(duration: 0.6)) { animatedProgress = progress }
        }
    }
}

/// Seção de macronutrientes com título e 4 barras coloridas.
struct MacrosSectionView: View {
    let nutrition: NutritionInfo
    let goals: NutritionInfo

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Macronutrientes")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColors.text)

                VStack(spacing: 14) {
                    MacroBarView(label: "Proteína",     current: nutrition.protein, goal: goals.protein, unit: "g", color: AppColors.protein)
                    MacroBarView(label: "Carboidratos", current: nutrition.carbs,   goal: goals.carbs,   unit: "g", color: AppColors.carbs)
                    MacroBarView(label: "Gordura",      current: nutrition.fat,     goal: goals.fat,     unit: "g", color: AppColors.fat)
                    MacroBarView(label: "Fibras",       current: nutrition.fiber,   goal: goals.fiber,   unit: "g", color: AppColors.fiber)
                }
            }
            .padding(16)
        }
    }
}
