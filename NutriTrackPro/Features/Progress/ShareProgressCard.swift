import SwiftUI
import UniformTypeIdentifiers

// MARK: - Transferable wrapper

/// Permite compartilhar UIImage via ShareLink (iOS 16+).
struct ShareableImage: Transferable {
    let image: UIImage

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { item in
            item.image.pngData() ?? Data()
        }
    }
}

// MARK: - Card view (renderizável via ImageRenderer)

/// Card visual fixo (390×220pt) gerado pelo ImageRenderer e compartilhado via ShareLink.
struct ProgressShareCard: View {
    let calories: Double
    let calorieGoal: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let streakDays: Int

    private var progress: Double { calorieGoal > 0 ? min(calories / calorieGoal, 1.0) : 0 }

    var body: some View {
        ZStack {
            // Fundo gradiente
            LinearGradient(
                colors: [Color(hex: "0F172A"), Color(hex: "1E3A5F")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 0) {
                // Cabeçalho
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("NutriPack Pro")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white.opacity(0.9))
                        Text(Date.now.formatted(date: .long, time: .omitted))
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    Spacer()
                    // Streak badge
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "F59E0B"))
                        Text("\(streakDays) dias")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.1), in: Capsule())
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)

                Spacer()

                HStack(alignment: .center, spacing: 24) {
                    // Anel de calorias
                    ZStack {
                        Circle()
                            .stroke(.white.opacity(0.1), lineWidth: 10)
                            .frame(width: 100, height: 100)
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                LinearGradient(
                                    colors: [Color(hex: "34D399"), Color(hex: "10B981")],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 10, lineCap: .round)
                            )
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                        VStack(spacing: 1) {
                            Text("\(Int(calories))")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("kcal")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }

                    // Macros
                    VStack(alignment: .leading, spacing: 10) {
                        macroRow("Proteína",    value: protein, color: Color(hex: "818CF8"))
                        macroRow("Carboidratos",value: carbs,   color: Color(hex: "F59E0B"))
                        macroRow("Gordura",     value: fat,     color: Color(hex: "F472B6"))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 20)

                Spacer()

                // Meta de calorias
                Text("Meta: \(Int(calorieGoal)) kcal  ·  \(Int(progress * 100))% atingido")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.45))
                    .padding(.bottom, 14)
            }
        }
        .frame(width: 390, height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func macroRow(_ label: String, value: Double, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            Text("\(Int(value))g")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Share sheet

/// Sheet que pré-visualiza o card e oferece o botão Compartilhar.
struct ShareProgressSheet: View {
    let calories: Double
    let calorieGoal: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let streakDays: Int

    @State private var shareableImage: ShareableImage? = nil
    @State private var isRendering = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Pré-visualização do card
                ProgressShareCard(
                    calories: calories,
                    calorieGoal: calorieGoal,
                    protein: protein,
                    carbs: carbs,
                    fat: fat,
                    streakDays: streakDays
                )
                .shadow(color: .black.opacity(0.3), radius: 20, y: 8)
                .padding(.horizontal, 16)

                Text("Compartilhe seu progresso de hoje!")
                    .font(.system(size: 15))
                    .foregroundStyle(AppColors.textSecondary)

                // Botão de compartilhar — renderiza na hora do tap
                Group {
                    if let img = shareableImage {
                        ShareLink(
                            item: img,
                            preview: SharePreview(
                                "Meu progresso — NutriPack Pro",
                                image: Image(uiImage: img.image)
                            )
                        ) {
                            shareButtonLabel
                        }
                    } else {
                        Button {
                            renderCard()
                        } label: {
                            if isRendering {
                                ProgressView()
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(AppColors.primary, in: RoundedRectangle(cornerRadius: 16))
                            } else {
                                shareButtonLabel
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .padding(.top, 24)
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Compartilhar Progresso")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
    }

    private var shareButtonLabel: some View {
        Label("Compartilhar", systemImage: "square.and.arrow.up")
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(AppColors.primary, in: RoundedRectangle(cornerRadius: 16))
    }

    @MainActor
    private func renderCard() {
        isRendering = true
        let card = ProgressShareCard(
            calories: calories,
            calorieGoal: calorieGoal,
            protein: protein,
            carbs: carbs,
            fat: fat,
            streakDays: streakDays
        )
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0 // retina-quality
        guard let uiImage = renderer.uiImage else { isRendering = false; return }
        shareableImage = ShareableImage(image: uiImage)
        isRendering = false
    }
}
