import SwiftUI

/// Badge colorido indicando nível de confiança da IA (Alta / Média / Baixa).
struct ConfidenceBadge: View {
    let confidence: String  // "high" | "medium" | "low"

    private var label: String {
        switch confidence {
        case "high":   return "Alta"
        case "medium": return "Média"
        default:       return "Baixa"
        }
    }

    private var color: Color {
        switch confidence {
        case "high":   return AppColors.primary
        case "medium": return AppColors.carbs
        default:       return AppColors.fat
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text("Confiança \(label)")
                .font(.caption2.weight(.medium))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12), in: Capsule())
    }
}
