import SwiftUI
import SwiftData

private let waterBlue = Color(hex: "3B82F6")

/// Tela completa de registro de água — anel circular, botões rápidos e slider.
struct WaterLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WaterEntry.date, order: .reverse) private var allEntries: [WaterEntry]

    let goal: Int // ml

    @State private var customAmount: Double = 300
    @State private var selectedQuick: Int? = nil

    private let quickAmounts = [200, 300, 500, 750]
    private let quickIcons   = ["drop", "drop.fill", "waterbottle", "waterbottle.fill"]
    private let quickLabels  = ["Copo", "Dose", "Garrafa", "Garrafa\nGrande"]

    private var todayEntry: WaterEntry? {
        allEntries.first { Calendar.current.isDateInToday($0.date) }
    }
    private var mlToday: Int { todayEntry?.mlConsumed ?? 0 }
    private var progress: Double { min(1.0, Double(mlToday) / Double(max(1, goal))) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {

                    // Anel circular principal
                    ZStack {
                        Circle()
                            .stroke(waterBlue.opacity(0.1), lineWidth: 20)
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                LinearGradient(
                                    colors: [waterBlue, Color(hex: "60A5FA")],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 20, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(duration: 0.8), value: mlToday)

                        VStack(spacing: 4) {
                            Text("\(mlToday)")
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .foregroundStyle(waterBlue)
                            Text("de \(goal)ml")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                    .frame(width: 200, height: 200)
                    .padding(.top, 8)

                    // Botões rápidos 2×2
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(quickAmounts.indices, id: \.self) { i in
                            let amt = quickAmounts[i]
                            quickButton(amount: amt, icon: quickIcons[i], label: quickLabels[i])
                        }
                    }
                    .padding(.horizontal, 20)

                    // Slider personalizado
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Quantidade personalizada")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(AppColors.textSecondary)
                            Spacer()
                            Text("\(Int(customAmount))ml")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(waterBlue)
                        }
                        Slider(value: $customAmount, in: 50...1000, step: 50)
                            .tint(waterBlue)
                            .onChange(of: customAmount) { _, _ in
                                selectedQuick = nil
                            }
                    }
                    .padding(.horizontal, 20)

                    // Botão registrar
                    Button { register(ml: Int(customAmount)) } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "drop.fill")
                                .font(.system(size: 16))
                            Text("Registrar Água")
                                .font(.system(size: 17, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(waterBlue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: waterBlue.opacity(0.35), radius: 12, y: 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .background(Color(.systemGray6).ignoresSafeArea())
            .navigationTitle("Registrar Água")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") { dismiss() }
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
    }

    // MARK: - Subviews

    private func quickButton(amount: Int, icon: String, label: String) -> some View {
        let selected = selectedQuick == amount
        return Button {
            withAnimation(.spring(duration: 0.2)) {
                selectedQuick = amount
                customAmount = Double(amount)
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 26))
                    .foregroundStyle(selected ? .white : waterBlue)
                Text("\(amount)ml")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(selected ? .white : AppColors.text)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 84)
            .background(
                selected ? waterBlue : waterBlue.opacity(0.08),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(waterBlue.opacity(selected ? 0 : 0.25), lineWidth: 1)
            }
        }
        .animation(.spring(duration: 0.2), value: selected)
    }

    // MARK: - Logic

    private func register(ml: Int) {
        guard ml > 0 else { return }
        if let entry = todayEntry {
            entry.mlConsumed += ml
        } else {
            modelContext.insert(WaterEntry(mlConsumed: ml))
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}
