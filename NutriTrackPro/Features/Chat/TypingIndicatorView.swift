import SwiftUI

/// Animação de 3 pontos que "pulsam" indicando digitação da IA.
struct TypingIndicatorView: View {
    @State private var phase: Int = 0

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(AppColors.textSecondary)
                    .frame(width: 8, height: 8)
                    .scaleEffect(phase == i ? 1.4 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.4).repeatForever(autoreverses: true).delay(Double(i) * 0.15),
                        value: phase
                    )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        .onAppear {
            withAnimation { phase = 0 }
            // Cicla entre os 3 pontos para simular salto
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                withAnimation { phase = (phase + 1) % 3 }
            }
        }
    }
}
