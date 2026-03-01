import SwiftUI

struct PlanFeature: Identifiable {
    let id = UUID()
    let icon: String
    let text: String
}

/// Card visual de um plano de assinatura.
struct PlanCardView: View {
    let plan: SubscriptionPlan
    let price: String
    let period: String
    let isSelected: Bool
    let features: [PlanFeature]
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                // Cabeçalho
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.displayName)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(isSelected ? .white : AppColors.text)
                        Text(price + "/" + period)
                            .font(.system(size: 14))
                            .foregroundStyle(isSelected ? .white.opacity(0.8) : AppColors.textSecondary)
                    }
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                    }
                }

                Divider()
                    .overlay(isSelected ? Color.white.opacity(0.3) : Color.gray.opacity(0.2))

                // Features
                ForEach(features) { feature in
                    HStack(spacing: 8) {
                        Image(systemName: feature.icon)
                            .font(.system(size: 13))
                            .foregroundStyle(isSelected ? .white.opacity(0.9) : AppColors.primary)
                            .frame(width: 16)
                        Text(feature.text)
                            .font(.system(size: 13))
                            .foregroundStyle(isSelected ? .white.opacity(0.9) : AppColors.text)
                    }
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: AppConstants.largeCornerRadius, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(AppColors.primary.gradient) : AnyShapeStyle(AppColors.surface))
                    .shadow(
                        color: isSelected ? AppColors.primary.opacity(0.3) : .black.opacity(0.06),
                        radius: isSelected ? 16 : 8,
                        y: isSelected ? 6 : 4
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppConstants.largeCornerRadius, style: .continuous)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(duration: 0.3), value: isSelected)
    }
}
