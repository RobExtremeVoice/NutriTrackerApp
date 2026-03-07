import SwiftUI
import UIKit

/// Onboarding com 4 slides, fundo foto real + overlay escuro, logo e botão verde.
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
            ],
            imageName: "onboarding_1"
        ),
        OnboardingSlideData(
            iconName: "sparkles",
            title: "IA identifica os nutrientes",
            subtitle: "O AI analisa cada alimento e calcula calorias, proteínas, carboidratos e gorduras automaticamente.",
            backgroundColors: [
                Color(red: 0.30, green: 0.14, blue: 0.04),
                Color(red: 0.12, green: 0.06, blue: 0.01)
            ],
            imageName: "onboarding_2"
        ),
        OnboardingSlideData(
            iconName: "scope",
            title: "Atinja seus objetivos",
            subtitle: "Acompanhe seu progresso diário e alcance suas metas de saúde com precisão.",
            backgroundColors: [
                Color(red: 0.06, green: 0.10, blue: 0.32),
                Color(red: 0.02, green: 0.04, blue: 0.15)
            ],
            imageName: "onboarding_3"
        ),
        OnboardingSlideData(
            iconName: "drop.fill",
            title: "Mantenha-se hidratado",
            subtitle: "Ajudamos você a ficar hidratado todos os dias com alertas inteligentes e acompanhamento em tempo real.",
            backgroundColors: [
                Color(red: 0.04, green: 0.20, blue: 0.36),
                Color(red: 0.02, green: 0.08, blue: 0.18)
            ],
            imageName: "onboarding_4"
        ),
    ]

    var body: some View {
        ZStack {
            // Fundo: foto real quando disponível, senão gradiente de cor
            if let name = slides[currentPage].imageName,
               UIImage(named: name) != nil {
                Image(name)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.5), value: currentPage)
            } else {
                LinearGradient(
                    colors: slides[currentPage].backgroundColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: currentPage)
            }

            // Overlay escuro para legibilidade (igual ao design HTML)
            LinearGradient(
                colors: [Color.black.opacity(0.40), Color.black.opacity(0.70)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Logo
                HStack(spacing: 8) {
                    LeafShape()
                        .fill(AppColors.primary)
                        .frame(width: 28, height: 28)

                    HStack(spacing: 0) {
                        Text("NutriPack ")
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

/// Leaf shape matching the app icon SVG path (24×24 coordinate space).
private struct LeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width / 24
        let h = rect.height / 24
        var p = Path()
        p.move(to: CGPoint(x: 17*w, y: 8*h))
        p.addCurve(to: CGPoint(x: 3.82*w, y: 21.34*h),
                   control1: CGPoint(x: 8*w, y: 10*h),
                   control2: CGPoint(x: 5.9*w, y: 16.17*h))
        p.addLine(to: CGPoint(x: 5.71*w, y: 22*h))
        p.addLine(to: CGPoint(x: 6.66*w, y: 19.7*h))
        p.addCurve(to: CGPoint(x: 8*w, y: 20*h),
                   control1: CGPoint(x: 7.14*w, y: 19.87*h),
                   control2: CGPoint(x: 7.64*w, y: 20*h))
        p.addCurve(to: CGPoint(x: 22*w, y: 3*h),
                   control1: CGPoint(x: 19*w, y: 20*h),
                   control2: CGPoint(x: 22*w, y: 3*h))
        p.addCurve(to: CGPoint(x: 9*w, y: 6.25*h),
                   control1: CGPoint(x: 21*w, y: 5*h),
                   control2: CGPoint(x: 14*w, y: 5.25*h))
        p.addCurve(to: CGPoint(x: 2*w, y: 13.5*h),
                   control1: CGPoint(x: 4*w, y: 7.25*h),
                   control2: CGPoint(x: 2*w, y: 11.5*h))
        p.addCurve(to: CGPoint(x: 3.75*w, y: 17.25*h),
                   control1: CGPoint(x: 2*w, y: 15.5*h),
                   control2: CGPoint(x: 3.75*w, y: 17.25*h))
        p.addCurve(to: CGPoint(x: 17*w, y: 8*h),
                   control1: CGPoint(x: 7*w, y: 8*h),
                   control2: CGPoint(x: 17*w, y: 8*h))
        p.closeSubpath()
        return p
    }
}
