import SwiftUI

/// Badge de streak com chama e contador de dias.
struct StreakBadge: View {
    let days: Int

    var body: some View {
        HStack(spacing: 4) {
            Text("🔥")
                .font(.system(size: 14))
            Text("\(days) dia\(days == 1 ? "" : "s")")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.accent)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(AppColors.accent.opacity(0.12), in: Capsule())
    }
}
