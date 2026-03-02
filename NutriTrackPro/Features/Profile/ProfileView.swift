import SwiftUI
import SwiftData

/// Tela de perfil do usuário.
struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \UserProfile.name) private var profiles: [UserProfile]

    @State private var showEditProfile = false
    @State private var showPaywall     = false
    @State private var showAPIKeySheet = false
    @State private var notificationsOn = UserDefaults.standard.bool(forKey: "notificationsEnabled")

    private var profile: UserProfile? { profiles.first }

    private var profilePhoto: UIImage? {
        guard let data = UserDefaults.standard.data(forKey: "userProfilePhotoData") else { return nil }
        return UIImage(data: data)
    }

    private var initials: String {
        guard let name = profile?.name, !name.isEmpty else { return "U" }
        let parts = name.components(separatedBy: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last  = parts.count > 1 ? (parts.last?.first.map(String.init) ?? "") : ""
        return (first + last).uppercased()
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    heroCard
                    if appState.currentPlan == .free { upgradeBanner }
                    accountSection
                    appSection
                    supportSection
                    Spacer(minLength: 80)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .background(Color(.systemGray6).ignoresSafeArea())
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showEditProfile) {
                if let p = profile { EditProfileView(profile: p) }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showAPIKeySheet) {
                APIKeySheet()
            }
        }
    }

    // MARK: – Hero card

    private var heroCard: some View {
        GlassCard {
            VStack(spacing: 16) {
                // Avatar
                ZStack {
                    if let photo = profilePhoto {
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 88, height: 88)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [AppColors.primary, AppColors.primaryDark],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 88, height: 88)
                        Text(initials)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    // Edit badge
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 26, height: 26)
                        .overlay(
                            Image(systemName: "pencil")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(AppColors.textSecondary)
                        )
                        .offset(x: 30, y: 30)
                }
                .onTapGesture { showEditProfile = true }
                .shadow(color: AppColors.primary.opacity(0.25), radius: 10, y: 4)

                // Name + plan badge
                VStack(spacing: 6) {
                    Text(profile?.name ?? "Usuário")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(AppColors.text)

                    HStack(spacing: 5) {
                        Image(systemName: appState.currentPlan == .free ? "person.fill" : "crown.fill")
                            .font(.system(size: 10, weight: .semibold))
                        Text(appState.currentPlan.displayName)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(Color(hex: appState.currentPlan.badgeColorHex))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(
                        Color(hex: appState.currentPlan.badgeColorHex).opacity(0.1),
                        in: Capsule()
                    )
                    .overlay(
                        Capsule().stroke(Color(hex: appState.currentPlan.badgeColorHex).opacity(0.25), lineWidth: 1)
                    )
                }

                // Stats row
                if let p = profile {
                    Divider()
                    HStack(spacing: 0) {
                        statCell(value: "\(Int(p.weightKg))", unit: "kg", label: "Peso")
                        statDivider
                        statCell(value: "\(Int(p.heightCm))", unit: "cm", label: "Altura")
                        statDivider
                        statCell(value: "\(p.age)", unit: "anos", label: "Idade")
                        statDivider
                        goalCell(p.goalEnum)
                    }
                }
            }
            .padding(20)
        }
    }

    private func statCell(value: String, unit: String, label: String) -> some View {
        VStack(spacing: 3) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.text)
                Text(unit)
                    .font(.system(size: 10))
                    .foregroundStyle(AppColors.textSecondary)
            }
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func goalCell(_ goal: HealthGoal) -> some View {
        VStack(spacing: 3) {
            Image(systemName: goal == .lose ? "arrow.down.circle.fill"
                             : goal == .gain ? "arrow.up.circle.fill"
                             : "equal.circle.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(
                    goal == .lose ? AppColors.primary
                    : goal == .gain ? AppColors.protein
                    : AppColors.carbs
                )
            Text(goal == .lose ? "Perder" : goal == .gain ? "Ganhar" : "Manter")
                .font(.system(size: 11))
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .frame(width: 1, height: 32)
    }

    // MARK: – Upgrade banner (free plan only)

    private var upgradeBanner: some View {
        Button { showPaywall = true } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 44, height: 44)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Desbloqueie o NutriTrack Pro")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Scans ilimitados · Chat sem limites · Sem anúncios")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .shadow(color: AppColors.primary.opacity(0.35), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: – Account section

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Minha Conta")
            GlassCard {
                VStack(spacing: 0) {
                    profileRow(
                        icon: "person.crop.circle.fill",
                        label: "Editar perfil",
                        color: AppColors.primary,
                        showChevron: true
                    ) { showEditProfile = true }

                    rowDivider

                    profileRow(
                        icon: "crown.fill",
                        label: "Assinatura",
                        subtitle: appState.currentPlan.displayName,
                        color: Color(hex: "F59E0B"),
                        showChevron: true
                    ) { showPaywall = true }
                }
            }
        }
    }

    // MARK: – App section

    private var appSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("App")
            GlassCard {
                VStack(spacing: 0) {
                    // Apple Health inline
                    HealthKitRow()

                    rowDivider

                    // Notifications toggle
                    HStack(spacing: 14) {
                        iconCircle("bell.fill", color: .orange)
                        Text("Notificações")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(AppColors.text)
                        Spacer()
                        Toggle("", isOn: $notificationsOn)
                            .tint(AppColors.primary)
                            .labelsHidden()
                            .onChange(of: notificationsOn) { _, on in
                                UserDefaults.standard.set(on, forKey: "notificationsEnabled")
                                if on {
                                    Task { try? await NotificationService.shared.scheduleAll() }
                                } else {
                                    NotificationService.shared.cancelAll()
                                }
                            }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
            }
        }
    }

    // MARK: – Support section

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Configurações")
            GlassCard {
                VStack(spacing: 0) {
                    // OpenAI API Key
                    profileRow(
                        icon: "key.fill",
                        label: "Chave API OpenAI",
                        subtitle: AppConstants.openAIKey.isEmpty ? "Não configurada" : "Configurada ✓",
                        color: AppConstants.openAIKey.isEmpty ? AppColors.accent : AppColors.primary,
                        showChevron: true
                    ) { showAPIKeySheet = true }

                    rowDivider
                }
            }

            sectionHeader("Suporte")
            GlassCard {
                VStack(spacing: 0) {
                    profileRow(
                        icon: "envelope.fill",
                        label: "Enviar feedback",
                        color: AppColors.primary,
                        showChevron: true
                    ) {}

                    rowDivider

                    profileRow(
                        icon: "lock.shield.fill",
                        label: "Política de privacidade",
                        color: Color(hex: "6366F1"),
                        showChevron: true
                    ) {}

                    rowDivider

                    profileRow(
                        icon: "doc.text.fill",
                        label: "Termos de uso",
                        color: AppColors.textSecondary,
                        showChevron: true
                    ) {}

                    rowDivider

                    HStack(spacing: 14) {
                        iconCircle("info.circle.fill", color: AppColors.textSecondary)
                        Text("Versão do app")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(AppColors.text)
                        Spacer()
                        Text("1.0.0")
                            .font(.system(size: 14))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
            }
        }
    }

    // MARK: – Reusable helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(AppColors.textSecondary)
            .padding(.leading, 4)
    }

    private func iconCircle(_ icon: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(color.opacity(0.12))
                .frame(width: 34, height: 34)
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(color)
        }
    }

    private func profileRow(
        icon: String,
        label: String,
        subtitle: String? = nil,
        color: Color,
        showChevron: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                iconCircle(icon, color: color)
                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppColors.text)
                    if let sub = subtitle {
                        Text(sub)
                            .font(.system(size: 12))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                Spacer()
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(.systemGray3))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    private var rowDivider: some View {
        Divider().padding(.leading, 64)
    }
}

// MARK: – API Key Sheet

private struct APIKeySheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var keyText = AppConstants.openAIKey
    @State private var isSaved = false

    private var isValid: Bool {
        keyText.trimmingCharacters(in: .whitespaces).hasPrefix("sk-")
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Info card
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(AppColors.primary.opacity(0.1))
                                .frame(width: 44, height: 44)
                            Image(systemName: "key.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(AppColors.primary)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Chave API OpenAI")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(AppColors.text)
                            Text("Necessária para Chat IA e análise de fotos")
                                .font(.system(size: 12))
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                    .padding(16)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Cole sua chave abaixo")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppColors.textSecondary)
                            .padding(.leading, 4)

                        SecureField("sk-...", text: $keyText)
                            .font(.system(size: 14, design: .monospaced))
                            .padding(14)
                            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(isValid ? AppColors.primary.opacity(0.4) : Color(.systemGray4), lineWidth: 1)
                            )
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }

                    if !keyText.isEmpty && !isValid {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12))
                            Text("A chave deve começar com \"sk-\"")
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(AppColors.accent)
                    }

                    Button {
                        let trimmed = keyText.trimmingCharacters(in: .whitespaces)
                        AppConstants.openAIKey = trimmed
                        isSaved = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { dismiss() }
                    } label: {
                        HStack {
                            Spacer()
                            if isSaved {
                                Label("Salvo!", systemImage: "checkmark.circle.fill")
                            } else {
                                Text("Salvar chave")
                            }
                            Spacer()
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.vertical, 14)
                        .background(
                            isValid ? AppColors.primary : Color(.systemGray4),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                    }
                    .disabled(!isValid || isSaved)
                    .animation(.easeInOut(duration: 0.2), value: isSaved)

                    if !keyText.isEmpty {
                        Button {
                            keyText = ""
                            AppConstants.openAIKey = ""
                        } label: {
                            HStack {
                                Spacer()
                                Text("Remover chave")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(AppColors.accent)
                                Spacer()
                            }
                        }
                    }

                    Spacer(minLength: 20)
                }
                .padding(20)
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            .navigationTitle("API OpenAI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") { dismiss() }
                        .font(.system(size: 15, weight: .medium))
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: – Inline HealthKit row (no GlassCard wrapper)

private struct HealthKitRow: View {
    @State private var isEnabled = false
    @State private var status    = "Não autorizado"

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.red.opacity(0.12))
                        .frame(width: 34, height: 34)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.red)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("Apple Health")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppColors.text)
                    Text(status)
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.textSecondary)
                }
                Spacer()
                Toggle("", isOn: $isEnabled)
                    .tint(AppColors.primary)
                    .labelsHidden()
                    .onChange(of: isEnabled) { _, on in
                        if on { requestPermission() }
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            if isEnabled {
                VStack(alignment: .leading, spacing: 6) {
                    featureRow("Registra calorias e macros")
                    featureRow("Lê passos e energia ativa")
                    featureRow("Sincroniza peso automaticamente")
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
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
