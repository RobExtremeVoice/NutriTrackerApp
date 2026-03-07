import SwiftUI

/// Toggle para sincronização com o Apple Health.
struct HealthKitView: View {
    @Environment(AppState.self) private var appState
    @State private var status: String = ""
    @State private var isRequesting = false

    var body: some View {
        @Bindable var appState = appState
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
                    if isRequesting {
                        ProgressView().scaleEffect(0.8)
                    } else {
                        Toggle("", isOn: $appState.healthKitEnabled)
                            .tint(AppColors.primary)
                            .onChange(of: appState.healthKitEnabled) { _, enabled in
                                if enabled { requestPermission() }
                                else { status = "" }
                            }
                    }
                }

                if !status.isEmpty {
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(appState.healthKitEnabled ? AppColors.primary : .red)
                }

                if appState.healthKitEnabled {
                    VStack(alignment: .leading, spacing: 4) {
                        featureRow("Sincroniza calorias e macros automaticamente")
                        featureRow("Lê passos e energia ativa do dia")
                        featureRow("Sincroniza peso automaticamente")
                    }
                    .padding(.top, 2)
                }
            }
            .padding(16)
        }
        .onAppear {
            if appState.healthKitEnabled { status = "Autorizado" }
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
        isRequesting = true
        Task {
            do {
                try await HealthKitService.shared.requestAuthorization()
                await MainActor.run {
                    status = "Autorizado"
                    isRequesting = false
                }
            } catch {
                await MainActor.run {
                    status = "Permissão negada — verifique em Ajustes > Saúde"
                    appState.healthKitEnabled = false
                    isRequesting = false
                }
            }
        }
    }
}
