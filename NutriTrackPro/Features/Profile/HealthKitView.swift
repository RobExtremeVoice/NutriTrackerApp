import SwiftUI

/// Toggle para sincronização com o Apple Health.
struct HealthKitView: View {
    @State private var isEnabled = false
    @State private var showPermissionInfo = false
    @State private var status: String = "Não autorizado"

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                        .font(.system(size: 20))
                    Text("Apple Health")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColors.text)
                    Spacer()
                    Toggle("", isOn: $isEnabled)
                        .tint(AppColors.primary)
                        .onChange(of: isEnabled) { _, enabled in
                            if enabled { requestPermission() }
                        }
                }

                Text(status)
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)

                if isEnabled {
                    VStack(alignment: .leading, spacing: 4) {
                        featureRow("Registra calorias e macros")
                        featureRow("Lê passos e energia ativa")
                        featureRow("Sincroniza peso automaticamente")
                    }
                }
            }
            .padding(16)
        }
    }

    private func featureRow(_ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppColors.primary)
                .font(.system(size: 12))
            Text(text)
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private func requestPermission() {
        Task {
            do {
                try await HealthKitService.shared.requestAuthorization()
                await MainActor.run { status = "Autorizado" }
            } catch {
                await MainActor.run {
                    status = "Permissão negada — verifique em Ajustes > Saúde"
                    isEnabled = false
                }
            }
        }
    }
}
