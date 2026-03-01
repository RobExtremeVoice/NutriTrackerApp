import SwiftUI
import SwiftData

/// Alerta in-app de hidratação — apresentado quando o usuário deve beber água.
struct HydrationAlertView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WaterEntry.date, order: .reverse) private var allEntries: [WaterEntry]

    let goal: Int // ml

    private var mlToday: Int {
        allEntries.first { Calendar.current.isDateInToday($0.date) }?.mlConsumed ?? 0
    }
    private var progress: Double { min(1.0, Double(mlToday) / Double(max(1, goal))) }

    var body: some View {
        ZStack {
            // Fundo degradê azul
            LinearGradient(
                colors: [Color(hex: "1E3A8A"), Color(hex: "2563EB"), Color(hex: "60A5FA")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Ícone animado
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.08))
                        .frame(width: 160, height: 160)
                    Circle()
                        .fill(.white.opacity(0.12))
                        .frame(width: 120, height: 120)
                    Image(systemName: "drop.fill")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.bottom, 32)

                // Texto
                VStack(spacing: 12) {
                    Text("Hora de Hidratar! 💧")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("Seu corpo precisa de água para funcionar bem.\nVocê já bebeu \(mlToday)ml hoje.")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 36)

                // Barra de progresso
                VStack(spacing: 8) {
                    HStack {
                        Text("\(mlToday)ml")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.75))
                        Spacer()
                        Text("\(goal)ml")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.white.opacity(0.2))
                                .frame(height: 10)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.white)
                                .frame(width: geo.size.width * CGFloat(progress), height: 10)
                                .animation(.spring(duration: 0.6), value: mlToday)
                        }
                    }
                    .frame(height: 10)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 48)

                // Botões
                VStack(spacing: 14) {
                    Button { drinkWater(); dismiss() } label: {
                        Text("Beber Água 💧")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color(hex: "1E3A8A"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    }

                    Button { dismiss() } label: {
                        Text("Lembrar em 15 min")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                .padding(.horizontal, 32)

                Spacer()

                // Indicadores de passo (decoração)
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        Capsule()
                            .fill(.white.opacity(i == 1 ? 1.0 : 0.35))
                            .frame(width: i == 1 ? 24 : 8, height: 8)
                    }
                }
                .padding(.bottom, 48)
            }
        }
    }

    private func drinkWater() {
        let amount = 250
        if let entry = allEntries.first(where: { Calendar.current.isDateInToday($0.date) }) {
            entry.mlConsumed += amount
        } else {
            modelContext.insert(WaterEntry(mlConsumed: amount))
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
