import SwiftUI
import SwiftData

/// Perfil do usuário com configurações do app.
struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \UserProfile.name) private var profiles: [UserProfile]

    @State private var showEditProfile  = false
    @State private var showPaywall      = false
    @State private var notificationsOn  = UserDefaults.standard.bool(forKey: "notificationsEnabled")

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            List {
                // Avatar + info
                profileHeaderSection

                // Assinatura
                Section {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundStyle(AppColors.accent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Minha Assinatura")
                                    .foregroundStyle(AppColors.text)
                                Text(appState.currentPlan.displayName)
                                    .font(.caption)
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                } header: {
                    Text("Plano")
                }

                // Dados pessoais
                Section("Meus dados") {
                    Button {
                        showEditProfile = true
                    } label: {
                        settingsRow(icon: "person.fill", label: "Editar perfil", color: AppColors.primary)
                    }
                }

                // App
                Section("App") {
                    HealthKitView()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)

                    Toggle(isOn: $notificationsOn) {
                        settingsRow(icon: "bell.fill", label: "Notificações", color: .orange)
                    }
                    .tint(AppColors.primary)
                    .onChange(of: notificationsOn) { _, on in
                        UserDefaults.standard.set(on, forKey: "notificationsEnabled")
                        if on {
                            Task { try? await NotificationService.shared.scheduleAll() }
                        } else {
                            NotificationService.shared.cancelAll()
                        }
                    }
                }

                // Alertas (preview das notificações in-app)
                Section("Notificações") {
                    Button {
                        appState.showHydrationAlert = true
                    } label: {
                        settingsRow(icon: "drop.fill", label: "Preview — Alerta de Hidratação", color: Color(hex: "3B82F6"))
                    }
                    Button {
                        appState.mealReminderType = .lunch
                        appState.showMealReminder  = true
                    } label: {
                        settingsRow(icon: "camera.fill", label: "Preview — Lembrete de Foto", color: AppColors.primary)
                    }
                }

                // Suporte
                Section("Suporte") {
                    settingsLink(icon: "envelope.fill",      label: "Enviar feedback",         color: AppColors.primary)
                    settingsLink(icon: "doc.text.fill",      label: "Política de privacidade",  color: AppColors.textSecondary)
                    settingsLink(icon: "doc.plaintext.fill", label: "Termos de uso",            color: AppColors.textSecondary)
                    HStack {
                        settingsRow(icon: "info.circle.fill", label: "Versão do app", color: AppColors.textSecondary)
                        Spacer()
                        Text("1.0.0")
                            .font(.system(size: 14))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showEditProfile) {
                if let p = profile {
                    EditProfileView(profile: p)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private var profileHeaderSection: some View {
        Section {
            HStack(spacing: 16) {
                // Avatar com iniciais
                ZStack {
                    Circle()
                        .fill(AppColors.primary.gradient)
                        .frame(width: 60, height: 60)
                    Text(initials)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(profile?.name ?? "Usuário")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AppColors.text)

                    // Plan badge
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: appState.currentPlan.badgeColorHex))
                            .frame(width: 6, height: 6)
                        Text(appState.currentPlan.displayName)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color(hex: appState.currentPlan.badgeColorHex))
                    }
                }

                Spacer()
            }
            .padding(.vertical, 8)
        }
    }

    private var initials: String {
        guard let name = profile?.name, !name.isEmpty else { return "U" }
        let parts = name.components(separatedBy: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last  = parts.count > 1 ? (parts.last?.first.map(String.init) ?? "") : ""
        return (first + last).uppercased()
    }

    private func settingsRow(icon: String, label: String, color: Color) -> some View {
        Label {
            Text(label).foregroundStyle(AppColors.text)
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(color)
        }
    }

    private func settingsLink(icon: String, label: String, color: Color) -> some View {
        HStack {
            settingsRow(icon: icon, label: label, color: color)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
    }
}
