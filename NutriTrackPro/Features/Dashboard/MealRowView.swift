import SwiftUI

/// Linha de refeição na lista do Home com dados nutricionais e botão de favorito.
struct MealRowView: View {
    let meal: Meal

    var body: some View {
        HStack(spacing: 12) {
            // Ícone/foto
            if let data = meal.imageData, let ui = UIImage(data: data) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppColors.primary.opacity(0.1))
                    Text(meal.mealType.emoji)
                        .font(.system(size: 24))
                }
                .frame(width: 52, height: 52)
            }

            // Nome e macros
            VStack(alignment: .leading, spacing: 3) {
                Text(meal.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.text)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    macroTag("\(Int(meal.totalProtein))g P", color: AppColors.protein)
                    macroTag("\(Int(meal.totalCarbs))g C", color: AppColors.carbs)
                    macroTag("\(Int(meal.totalFat))g G", color: AppColors.fat)
                }
            }

            Spacer()

            // Calorias
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(meal.totalCalories))")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColors.text)
                Text("kcal")
                    .font(.caption2)
                    .foregroundStyle(AppColors.textSecondary)
            }

            // Botão favorito
            Button {
                withAnimation(.spring(duration: 0.3)) { meal.isFavorite.toggle() }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image(systemName: meal.isFavorite ? "star.fill" : "star")
                    .font(.system(size: 16))
                    .foregroundStyle(meal.isFavorite ? Color(hex: "F59E0B") : AppColors.textSecondary.opacity(0.5))
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
    }

    private func macroTag(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12), in: Capsule())
    }
}
