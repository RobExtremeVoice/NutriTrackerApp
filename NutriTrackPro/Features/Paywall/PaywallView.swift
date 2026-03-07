import SwiftUI
import StoreKit

/// Tela de paywall com 7 dias grátis, feature list e planos Pro/Elite.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    @State private var isAnnual = false
    @State private var selectedPlan: SubscriptionPlan = .pro
    @State private var isPurchasing = false
    @State private var purchaseError: String?
    @State private var showError = false

    private let subscriptionService = SubscriptionService.shared

    private let highlights: [(icon: String, text: String)] = [
        ("camera.fill",   "Scans de comida ilimitados"),
        ("cpu",           "Chat Nutri IA exclusivo"),
        ("drop.fill",     "Alertas de Hidratação Inteligentes"),
        ("chart.bar.fill","Relatórios de progresso detalhados"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // Ícone + título
                    VStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(AppColors.primary.opacity(0.12))
                                .frame(width: 72, height: 72)
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(AppColors.primary)
                        }

                        Text("Experimente o Premium\npor nossa conta!")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(AppColors.text)
                            .multilineTextAlignment(.center)

                        Text("Não perca a chance de transformar sua saúde. Comece agora seu teste de 7 dias e desbloqueie todas as ferramentas de IA.")
                            .font(.system(size: 15))
                            .foregroundStyle(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                    .padding(.top, 8)

                    // Feature list — glass card
                    VStack(spacing: 16) {
                        ForEach(highlights, id: \.text) { item in
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(AppColors.primary.opacity(0.15))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: item.icon)
                                        .font(.system(size: 16))
                                        .foregroundStyle(AppColors.primary)
                                }
                                Text(item.text)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(AppColors.text)
                                Spacer()
                            }
                        }
                    }
                    .padding(20)
                    .background(.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
                    .padding(.horizontal, 16)

                    // Toggle Mensal / Anual
                    HStack(spacing: 0) {
                        periodButton("Mensal",  isAnual: false)
                        periodButton("Anual",   isAnual: true, badge: "-33%")
                    }
                    .background(Color(.systemGray5), in: Capsule())
                    .padding(.horizontal, 48)

                    // Planos
                    VStack(spacing: 12) {
                        // Plano Gratuito
                        planCard(
                            title: "Plano Gratuito",
                            price: "R$ 0,00",
                            period: "sempre",
                            features: ["3 scans de comida por dia"],
                            isHighlighted: false,
                            icon: "leaf"
                        )

                        // Botão 7 dias grátis
                        Button {
                            purchase()
                        } label: {
                            HStack(spacing: 8) {
                                Text("Começar 7 dias grátis")
                                    .font(.system(size: 18, weight: .bold))
                                Text("✨")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(AppColors.primary)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: AppColors.primary.opacity(0.3), radius: 12, y: 4)
                        }
                        .padding(.horizontal, 16)

                        // Plano PRO — destacado
                        ZStack(alignment: .top) {
                            planCard(
                                title: "PRO",
                                price: isAnnual ? "R$ 16,58" : "R$ 19,90",
                                period: "mês",
                                features: [
                                    "30 scans de comida por dia",
                                    "100 mensagens no chat IA/dia",
                                    "Histórico de progresso detalhado",
                                    "Sincronização com Apple Health",
                                ],
                                isHighlighted: true,
                                icon: "star.fill"
                            )

                            Text("Mais Popular")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(AppColors.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(.white, in: Capsule())
                                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                                .offset(y: -12)
                        }

                        // PRO + Hidratação
                        planCard(
                            title: "PRO + HIDRATAÇÃO",
                            price: isAnnual ? "R$ 24,90" : "R$ 29,90",
                            period: "mês",
                            features: [
                                "Tudo do plano PRO",
                                "Controle de Água",
                                "Alertas de Hidratação Inteligentes",
                            ],
                            isHighlighted: false,
                            icon: "drop.fill"
                        )

                        // ELITE
                        planCard(
                            title: "ELITE 👑",
                            price: isAnnual ? "R$ 33,25" : "R$ 39,90",
                            period: "mês",
                            features: [
                                "Tudo dos planos anteriores",
                                "AI Health Coach",
                                "Relatórios avançados em PDF",
                                "Suporte prioritário 24/7",
                            ],
                            isHighlighted: false,
                            icon: "crown.fill",
                            accentBorder: true
                        )
                    }
                    .padding(.horizontal, 16)

                    // Rodapé
                    VStack(spacing: 10) {
                        Button("Restaurar compras") {
                            Task { await subscriptionService.restore() }
                        }
                        .font(.system(size: 13))
                        .foregroundStyle(AppColors.textSecondary)

                        HStack(spacing: 16) {
                            Button("Termos de Uso") {}
                            Button("Privacidade") {}
                        }
                        .font(.system(size: 11))
                        .foregroundStyle(AppColors.textSecondary)
                        .underline()

                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10))
                            Text("Pagamento Seguro & Cancelamento Fácil")
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(0.5)
                        }
                        .foregroundStyle(AppColors.textSecondary.opacity(0.6))
                        .textCase(.uppercase)
                    }
                    .padding(.bottom, 32)
                }
            }
            .background(Color(.systemGray6).ignoresSafeArea())
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

    // MARK: - Subviews

    private func periodButton(_ title: String, isAnual: Bool, badge: String? = nil) -> some View {
        let selected = self.isAnnual == isAnual
        return Button {
            withAnimation(.spring(duration: 0.25)) { self.isAnnual = isAnual }
        } label: {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
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
            .padding(.horizontal, 22)
            .padding(.vertical, 10)
            .background(selected ? AppColors.primary : Color.clear, in: Capsule())
        }
        .animation(.spring(duration: 0.25), value: selected)
    }

    private func planCard(
        title: String, price: String, period: String,
        features: [String], isHighlighted: Bool, icon: String,
        accentBorder: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(isHighlighted ? .white.opacity(0.8) : AppColors.textSecondary)
                        .tracking(1)
                        .textCase(.uppercase)
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(price)
                            .font(.system(size: 22, weight: .black))
                            .foregroundStyle(isHighlighted ? .white : AppColors.text)
                        Text("/\(period)")
                            .font(.system(size: 13))
                            .foregroundStyle(isHighlighted ? .white.opacity(0.6) : AppColors.textSecondary)
                    }
                }
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(isHighlighted ? .white : AppColors.primary)
            }

            Divider()
                .background(isHighlighted ? .white.opacity(0.25) : Color(.separator))

            ForEach(features, id: \.self) { feat in
                HStack(spacing: 10) {
                    Image(systemName: isHighlighted ? "checkmark.circle.fill" : "checkmark.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(isHighlighted ? .white : AppColors.primary)
                    Text(feat)
                        .font(.system(size: 14))
                        .foregroundStyle(isHighlighted ? .white : AppColors.text)
                }
            }
        }
        .padding(20)
        .background(
            isHighlighted
                ? AnyShapeStyle(LinearGradient(
                    colors: [AppColors.primary, Color(red: 0.08, green: 0.64, blue: 0.28)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                  ))
                : AnyShapeStyle(.white.opacity(0.85))
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    accentBorder ? AppColors.primary.opacity(0.4) : Color.clear,
                    lineWidth: accentBorder ? 2 : 0
                )
        )
        .shadow(
            color: isHighlighted ? AppColors.primary.opacity(0.3) : .black.opacity(0.06),
            radius: isHighlighted ? 20 : 8,
            y: isHighlighted ? 8 : 2
        )
        .scaleEffect(isHighlighted ? 1.02 : 1.0)
    }

    // MARK: - Logic

    private func purchase() {
        isPurchasing = true
        Task {
            do {
                // Resolve the correct StoreKit product from loaded catalog
                let productID = resolveProductID()
                guard let product = subscriptionService.products.first(where: { $0.id == productID }) else {
                    throw PurchaseError.productNotFound
                }
                try await subscriptionService.purchase(product)
                // Sync plan from SubscriptionService → AppState so gating stays consistent
                await MainActor.run {
                    appState.currentPlan = subscriptionService.currentPlan
                    isPurchasing = false
                    dismiss()
                }
            } catch PurchaseError.productNotFound {
                await MainActor.run {
                    purchaseError = "Produto não encontrado. Verifique sua conexão e tente novamente."
                    showError = true
                    isPurchasing = false
                }
            } catch {
                await MainActor.run {
                    purchaseError = error.localizedDescription
                    showError = true
                    isPurchasing = false
                }
            }
        }
    }

    private func resolveProductID() -> String {
        switch (selectedPlan, isAnnual) {
        case (.elite, false): return AppConstants.ProductID.eliteMonthly
        case (.elite, true):  return AppConstants.ProductID.eliteAnnual
        case (.pro, true):    return AppConstants.ProductID.proAnnual
        default:              return AppConstants.ProductID.proMonthly
        }
    }
}

private enum PurchaseError: LocalizedError {
    case productNotFound
    var errorDescription: String? { "Produto não encontrado." }
}
