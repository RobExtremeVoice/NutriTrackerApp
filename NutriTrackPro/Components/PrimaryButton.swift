import SwiftUI

/// Botão principal verde com texto branco e haptic feedback.
struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var isLoading: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.85)
                } else {
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius, style: .continuous)
                    .fill(isLoading ? AppColors.primary.opacity(0.7) : AppColors.primary)
            )
        }
        .disabled(isLoading)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}
