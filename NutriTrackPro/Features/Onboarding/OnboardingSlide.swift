import SwiftUI

struct OnboardingSlideData: Identifiable {
    let id = UUID()
    let iconName: String
    let title: String
    let subtitle: String
    let backgroundColors: [Color]
    /// Nome do asset em Assets.xcassets usado como fundo do slide (opcional).
    /// Se nil ou não encontrado, usa o gradiente de cor.
    var imageName: String? = nil
}

/// Conteúdo de cada slide: ícone em glass card + título + subtítulo.
struct OnboardingSlideView: View {
    let data: OnboardingSlideData
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Ícone em glass card
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.white.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(AppColors.primary.opacity(0.4), lineWidth: 1)
                    )

                Image(systemName: data.iconName)
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(.white.opacity(0.92))
            }
            .frame(width: 100, height: 100)
            .scaleEffect(appeared ? 1 : 0.7)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(duration: 0.7, bounce: 0.3), value: appeared)

            // Textos
            VStack(spacing: 16) {
                Text(data.title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .offset(y: appeared ? 0 : 20)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: appeared)

                Text(data.subtitle)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.88))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .offset(y: appeared ? 0 : 20)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: appeared)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .onAppear { withAnimation { appeared = true } }
        .onDisappear { appeared = false }
    }
}
