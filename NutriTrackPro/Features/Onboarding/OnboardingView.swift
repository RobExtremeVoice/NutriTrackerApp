import SwiftUI

/// Onboarding com 4 slides, fundo gradiente escuro, logo e botão verde.
struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var showUserSetup = false

    private let slides: [OnboardingSlideData] = [
        OnboardingSlideData(
            iconName: "camera.fill",
            title: "Fotografe sua refeição",
            subtitle: "Tire uma foto de qualquer refeição e deixe a inteligência artificial fazer o resto.",
            backgroundColors: [
                Color(red: 0.06, green: 0.28, blue: 0.14),
                Color(red: 0.02, green: 0.10, blue: 0.06)
            ]
        ),
        OnboardingSlideData(
            iconName: "sparkles",
            title: "IA identifica os nutrientes",
            subtitle: "O AI analisa cada alimento e calcula calorias, proteínas, carboidratos e gorduras automaticamente.",
            backgroundColors: [
                Color(red: 0.30, green: 0.14, blue: 0.04),
                Color(red: 0.12, green: 0.06, blue: 0.01)
            ]
        ),
        OnboardingSlideData(
            iconName: "scope",
            title: "Atinja seus objetivos",
            subtitle: "Acompanhe seu progresso diário e alcance suas metas de saúde com precisão.",
            backgroundColors: [
                Color(red: 0.06, green: 0.10, blue: 0.32),
                Color(red: 0.02, green: 0.04, blue: 0.15)
            ]
        ),
        OnboardingSlideData(
            iconName: "drop.fill",
            title: "Mantenha-se hidratado",
            subtitle: "Ajudamos você a ficar hidratado todos os dias com alertas inteligentes e acompanhamento em tempo real.",
            backgroundColors: [
                Color(red: 0.04, green: 0.20, blue: 0.36),
                Color(red: 0.02, green: 0.08, blue: 0.18)
            ]
        ),
    ]

    var body: some View {
        ZStack {
            // Fundo gradiente animado conforme o slide
            LinearGradient(
                colors: slides[currentPage].backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: currentPage)

            // Overlay escuro para legibilidade
            LinearGradient(
                colors: [Color.black.opacity(0.25), Color.black.opacity(0.65)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Logo
                HStack(spacing: 8) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(AppColors.primary)

                    HStack(spacing: 0) {
                        Text("NutriTrack ")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Pro")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(AppColors.primary)
                    }
                }
                .padding(.top, 60)

                // Slides
                TabView(selection: $currentPage) {
                    ForEach(Array(slides.enumerated()), id: \.element.id) { index, slide in
                        OnboardingSlideView(data: slide)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<slides.count, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage ? AppColors.primary : .white.opacity(0.35))
                            .frame(width: i == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 24)

                // Botão principal
                Button {
                    if currentPage == slides.count - 1 {
                        showUserSetup = true
                    } else {
                        withAnimation { currentPage += 1 }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(currentPage == slides.count - 1 ? "Começar agora" : "Próximo")
                            .font(.system(size: 18, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(AppColors.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: AppColors.primary.opacity(0.35), radius: 12, y: 4)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 52)
                .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
        .fullScreenCover(isPresented: $showUserSetup) {
            UserSetupView()
        }
    }
}
