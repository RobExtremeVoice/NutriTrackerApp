import SwiftUI

/// Card de estatística com ícone, valor e label.
struct StatsCardView: View {
    let icon: String
    let label: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)

                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.text)

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppColors.text)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
    }
}
