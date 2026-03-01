import SwiftUI

/// 3 slides de introdução com TabView page style.
struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var showUserSetup = false

    private let slides: [OnboardingSlideData] = [
        OnboardingSlideData(
            emoji: "📸",
            title: "Fotografe sua refeição",
            subtitle: "Tire uma foto de qualquer refeição e deixe a inteligência artificial fazer o resto.",
            backgroundColor: AppColors.background
        ),
        OnboardingSlideData(
            emoji: "✨",
            title: "IA identifica os nutrientes",
            subtitle: "O GPT-4o analisa cada alimento e calcula calorias, proteínas, carboidratos e gorduras automaticamente.",
            backgroundColor: AppColors.background
        ),
        OnboardingSlideData(
            emoji: "🎯",
            title: "Atinja seus objetivos",
            subtitle: "Acompanhe seu progresso diário, mantenha sua sequência e alcance suas metas de saúde.",
            backgroundColor: AppColors.background
        ),
    ]

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Logo
                HStack {
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(AppColors.primary)
                    Text("NutriTrack Pro")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppColors.text)
                }
                .padding(.top, 56)

                // Slides
                TabView(selection: $currentPage) {
                    ForEach(Array(slides.enumerated()), id: \.element.id) { index, slide in
                        OnboardingSlideView(data: slide)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<slides.count, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage ? AppColors.primary : AppColors.primary.opacity(0.2))
                            .frame(width: i == currentPage ? 20 : 8, height: 8)
                            .animation(.spring(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 24)

                // Botões
                VStack(spacing: 12) {
                    if currentPage == slides.count - 1 {
                        PrimaryButton(title: "Começar agora", icon: "arrow.right") {
                            showUserSetup = true
                        }
                    } else {
                        PrimaryButton(title: "Próximo") {
                            withAnimation { currentPage += 1 }
                        }

                        Button("Pular") {
                            withAnimation { currentPage = slides.count - 1 }
                        }
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.textSecondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .fullScreenCover(isPresented: $showUserSetup) {
            UserSetupView()
        }
    }
}
