import SwiftUI

/// Entrada de texto como fallback quando câmera não está disponível.
struct BarcodeView: View {
    @Binding var foodDescription: String
    let onAnalyze: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "text.cursor")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.primary.opacity(0.6))

            Text("Descreva o alimento")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppColors.text)

            Text("Informe o nome e quantidade (ex: \"200g de frango grelhado\")")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            TextField("Ex: 1 prato de arroz com feijão", text: $foodDescription, axis: .vertical)
                .lineLimit(3...6)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius, style: .continuous)
                        .fill(AppColors.background)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius, style: .continuous)
                                .stroke(AppColors.primary.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal)

            PrimaryButton(
                title: "Analisar com IA",
                icon: "sparkles",
                isLoading: false
            ) {
                onAnalyze()
            }
            .padding(.horizontal)
            .disabled(foodDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.vertical, 24)
    }
}
