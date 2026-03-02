import SwiftUI

/// Card de estatística com ícone colorido, valor grande e labels.
struct StatsCardView: View {
    let icon: String
    let label: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(color)
                }

                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColors.text)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
    }
}
