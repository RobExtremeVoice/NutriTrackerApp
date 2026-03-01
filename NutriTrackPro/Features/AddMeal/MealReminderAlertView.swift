import SwiftUI

/// Alerta in-app de lembrete para fotografar/registrar uma refeição.
struct MealReminderAlertView: View {
    @Environment(\.dismiss) private var dismiss

    let mealType:      MealType
    let onTakePhoto:   () -> Void
    let onTypeManually: () -> Void

    private var mealIcon: String {
        switch mealType {
        case .breakfast: return "cup.and.saucer.fill"
        case .lunch:     return "fork.knife"
        case .dinner:    return "moon.stars.fill"
        case .snack:     return "apple.logo"
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Fundo esmaecido + ilustração no topo
            VStack(spacing: 0) {
                ZStack {
                    LinearGradient(
                        colors: [AppColors.primary.opacity(0.15), AppColors.primary.opacity(0.04)],
                        startPoint: .top, endPoint: .bottom
                    )
                    VStack(spacing: 16) {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(AppColors.primary.opacity(0.1))
                                .frame(width: 130, height: 130)
                            Circle()
                                .fill(AppColors.primary.opacity(0.06))
                                .frame(width: 100, height: 100)
                            Image(systemName: mealIcon)
                                .font(.system(size: 48, weight: .medium))
                                .foregroundStyle(AppColors.primary.opacity(0.75))
                        }
                        Text(mealType.emoji + " " + mealType.displayName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(AppColors.text)
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 280)
                .background(Color(.systemGray6))

                // Espaço para o bottom sheet (preenchido pelo sheet real)
                Color.white
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .ignoresSafeArea()

            // Bottom sheet
            VStack(spacing: 0) {
                // Handle
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.systemGray4))
                    .frame(width: 36, height: 5)
                    .padding(.top, 12)
                    .padding(.bottom, 20)

                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text("Não esqueça da foto! 📸")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(AppColors.text)

                        Text("Registre sua \(mealType.displayName.lowercased()) com a câmera.\nA IA identifica e calcula os nutrientes automaticamente.")
                            .font(.system(size: 15))
                            .foregroundStyle(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    // Botão câmera
                    Button {
                        onTakePhoto()
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 16))
                            Text("Tirar Foto")
                                .font(.system(size: 17, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(AppColors.primary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: AppColors.primary.opacity(0.35), radius: 12, y: 4)
                    }

                    // Botão digitar manualmente
                    Button {
                        onTypeManually()
                        dismiss()
                    } label: {
                        Text("Digitar Refeição Manualmente")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(AppColors.primary)
                    }

                    // Dispensar
                    Button { dismiss() } label: {
                        Text("Agora não")
                            .font(.system(size: 14))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .padding(.bottom, 16)
                }
                .padding(.horizontal, 28)
            }
            .frame(maxWidth: .infinity)
            .background(.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .ignoresSafeArea(edges: .bottom)
        }
        .ignoresSafeArea()
    }
}
