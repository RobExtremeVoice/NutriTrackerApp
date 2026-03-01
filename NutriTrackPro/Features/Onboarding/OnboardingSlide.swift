import SwiftUI

struct OnboardingSlideData: Identifiable {
    let id = UUID()
    let emoji: String
    let title: String
    let subtitle: String
    let backgroundColor: Color
}

/// Slide de onboarding com emoji animado e textos.
struct OnboardingSlideView: View {
    let data: OnboardingSlideData
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Emoji principal com bounce
            Text(data.emoji)
                .font(.system(size: 100))
                .scaleEffect(appeared ? 1 : 0.5)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(duration: 0.7, bounce: 0.4), value: appeared)

            // Textos
            VStack(spacing: 12) {
                Text(data.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(AppColors.text)
                    .multilineTextAlignment(.center)
                    .offset(y: appeared ? 0 : 20)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: appeared)

                Text(data.subtitle)
                    .font(.system(size: 16))
                    .foregroundStyle(AppColors.textSecondary)
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
        .onAppear {
            withAnimation { appeared = true }
        }
        .onDisappear {
            appeared = false
        }
    }
}
