import SwiftUI

/// Anel animado de calorias desenhado com Canvas.
struct CalorieRingView: View {
    let consumed: Double
    let goal: Double

    @State private var animatedProgress: Double = 0

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(consumed / goal, 1.0)
    }

    private var remaining: Double { max(goal - consumed, 0) }
    private var percentText: String { "\(Int(progress * 100))%" }

    // Muda para laranja quando >90% da meta
    private var ringColor: Color {
        progress > 0.9 ? AppColors.accent : AppColors.primary
    }

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let radius = min(size.width, size.height) / 2 - 12
                    let lineWidth: CGFloat = 18
                    let startAngle = Angle.degrees(-90)

                    // Arco de fundo
                    var bgPath = Path()
                    bgPath.addArc(center: center, radius: radius,
                                  startAngle: startAngle,
                                  endAngle: startAngle + .degrees(360),
                                  clockwise: false)
                    context.stroke(bgPath, with: .color(.gray.opacity(0.12)), lineWidth: lineWidth)

                    // Arco de progresso
                    if animatedProgress > 0 {
                        var fgPath = Path()
                        fgPath.addArc(center: center, radius: radius,
                                      startAngle: startAngle,
                                      endAngle: startAngle + .degrees(360 * animatedProgress),
                                      clockwise: false)
                        context.stroke(fgPath,
                                       with: .color(ringColor),
                                       style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    }
                }
                .frame(width: 200, height: 200)
                .animation(.easeInOut(duration: 1.2), value: animatedProgress)

                // Texto central
                VStack(spacing: 2) {
                    Text("\(Int(consumed))")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.text)
                    Text("consumidas")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            // Rodapé: Meta | Restante | %
            HStack {
                ringFooterItem(label: "Meta", value: "\(Int(goal)) kcal")
                Divider().frame(height: 30)
                ringFooterItem(label: "Restante", value: "\(Int(remaining)) kcal")
                Divider().frame(height: 30)
                ringFooterItem(label: "Progresso", value: percentText)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2)) {
                animatedProgress = progress
            }
        }
        .onChange(of: consumed) {
            withAnimation(.spring(duration: 0.8)) {
                animatedProgress = progress
            }
        }
    }

    private func ringFooterItem(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.text)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
