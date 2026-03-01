import SwiftUI

/// Chips horizontais para selecionar o tipo de refeição.
struct MealTypeSelector: View {
    @Binding var selected: MealType

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MealType.allCases, id: \.self) { type in
                    chip(for: type)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private func chip(for type: MealType) -> some View {
        let isSelected = selected == type
        Button {
            withAnimation(.spring(duration: 0.25)) {
                selected = type
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 6) {
                Text(type.emoji)
                    .font(.system(size: 14))
                Text(type.displayName)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(isSelected ? .white : AppColors.text)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? AppColors.primary : AppColors.background)
                    .shadow(color: .black.opacity(isSelected ? 0.12 : 0.04), radius: 4, y: 2)
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.25), value: isSelected)
    }
}
