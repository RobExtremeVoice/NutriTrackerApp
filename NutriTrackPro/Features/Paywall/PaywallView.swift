import SwiftUI
import StoreKit

/// Tela de paywall com planos Pro e Elite.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    @State private var isAnnual = true
    @State private var selectedPlan: SubscriptionPlan = .pro
    @State private var isPurchasing = false
    @State private var purchaseError: String?
    @State private var showError = false

    private let subscriptionService = SubscriptionService.shared

    private let proFeatures: [PlanFeature] = [
        PlanFeature(icon: "camera.fill",      text: "30 análises por foto/dia"),
        PlanFeature(icon: "bubble.left.fill", text: "100 mensagens de chat/dia"),
        PlanFeature(icon: "chart.bar.fill",   text: "Histórico completo"),
        PlanFeature(icon: "heart.fill",       text: "Sincronização com Apple Health"),
    ]

    private let eliteFeatures: [PlanFeature] = [
        PlanFeature(icon: "camera.fill",      text: "Análises ilimitadas"),
        PlanFeature(icon: "bubble.left.fill", text: "Chat ilimitado"),
        PlanFeature(icon: "chart.xyaxis.line",text: "Relatórios avançados"),
        PlanFeature(icon: "bell.fill",        text: "Lembretes inteligentes"),
        PlanFeature(icon: "star.fill",        text: "Suporte prioritário"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("🚀")
                            .font(.system(size: 56))
                        Text("Desbloqueie seu Potencial")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(AppColors.text)
                            .multilineTextAlignment(.center)
                        Text("Análises ilimitadas, chat com IA e muito mais")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)

                    // Toggle Mensal/Anual
                    HStack(spacing: 0) {
                        periodButton("Mensal",  isAnual: false)
                        periodButton("Anual",   isAnual: true,  badge: "Economize 33%")
                    }
                    .background(AppColors.background, in: Capsule())
                    .padding(.horizontal, 32)

                    // Cards de plano
                    VStack(spacing: 12) {
                        PlanCardView(
                            plan: .pro,
                            price: isAnnual ? "R$16,58" : "R$24,90",
                            period: isAnnual ? "mês" : "mês",
                            isSelected: selectedPlan == .pro,
                            features: proFeatures
                        ) {
                            selectedPlan = .pro
                        }

                        PlanCardView(
                            plan: .elite,
                            price: isAnnual ? "R$33,25" : "R$49,90",
                            period: isAnnual ? "mês" : "mês",
                            isSelected: selectedPlan == .elite,
                            features: eliteFeatures
                        ) {
                            selectedPlan = .elite
                        }
                    }
                    .padding(.horizontal, 16)

                    // Preço anual note
                    if isAnnual {
                        Text(selectedPlan == .pro
                            ? "Cobrado R$199,00/ano · 7 dias grátis"
                            : "Cobrado R$399,00/ano · 7 dias grátis")
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    // CTA
                    PrimaryButton(
                        title: "Começar 7 dias grátis",
                        icon: "sparkles",
                        isLoading: isPurchasing
                    ) {
                        purchase()
                    }
                    .padding(.horizontal, 16)

                    // Restaurar
                    Button("Restaurar compras") {
                        Task { await subscriptionService.restore() }
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.primary)

                    Text("Ao assinar, você concorda com os Termos de Uso.\nCancelável a qualquer momento.")
                        .font(.caption2)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 32)
                }
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppColors.textSecondary)
                            .font(.system(size: 22))
                    }
                }
            }
            .alert("Erro na compra", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(purchaseError ?? "Tente novamente mais tarde.")
            }
        }
    }

    private func periodButton(_ title: String, isAnual: Bool, badge: String? = nil) -> some View {
        let selected = self.isAnnual == isAnual
        return Button {
            withAnimation(.spring(duration: 0.25)) { self.isAnnual = isAnual }
        } label: {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                if let badge {
                    Text(badge)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(AppColors.accent, in: Capsule())
                }
            }
            .foregroundStyle(selected ? .white : AppColors.textSecondary)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(selected ? AppColors.primary : Color.clear, in: Capsule())
        }
        .animation(.spring(duration: 0.25), value: selected)
    }

    private func purchase() {
        // Em produção, busca o produto correto do StoreKit
        // Por ora, simula a atualização do plano
        isPurchasing = true
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            await MainActor.run {
                appState.currentPlan = selectedPlan
                isPurchasing = false
                dismiss()
            }
        }
    }
}
