import SwiftUI

/// Card branco com sombra suave — base visual do app.
struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat
    @ViewBuilder let content: Content

    init(cornerRadius: CGFloat = AppConstants.cardCornerRadius, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppColors.surface)
                    .shadow(
                        color: .black.opacity(AppConstants.cardShadowOpacity),
                        radius: AppConstants.cardShadowRadius,
                        y: AppConstants.cardShadowY
                    )
            )
    }
}
