import SwiftUI
import SwiftData

/// Ponto de entrada da UI — decide entre Onboarding e TabView principal.
struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Query private var profiles:     [UserProfile]
    @Query(sort: \WaterEntry.date, order: .reverse) private var waterEntries: [WaterEntry]

    @AppStorage(AppConstants.Defaults.hasCompletedOnboarding)
    private var hasCompletedOnboarding: Bool = false

    @State private var selectedTab: Int = 0

    var body: some View {
        if hasCompletedOnboarding && !profiles.isEmpty {
            mainTabView
        } else {
            OnboardingView()
        }
    }

    // MARK: – Tab bar principal

    private var mainTabView: some View {
        @Bindable var state = appState
        return TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Início", systemImage: "house.fill")
                }
                .tag(0)

            DiaryView()
                .tabItem {
                    Label("Diário", systemImage: "calendar")
                }
                .tag(1)

            ChatView()
                .tabItem {
                    Label("Chat IA", systemImage: "bubble.left.and.bubble.right.fill")
                }
                .tag(2)

            ProgressView()
                .tabItem {
                    Label("Progresso", systemImage: "chart.bar.fill")
                }
                .tag(3)

            ProfileView()
                .tabItem {
                    Label("Perfil", systemImage: "person.fill")
                }
                .tag(4)
        }
        .tint(AppColors.primary)
        .sheet(isPresented: $state.showPaywall) {
            PaywallView()
        }
        .fullScreenCover(isPresented: $state.showHydrationAlert) {
            HydrationAlertView(goal: profiles.first?.dailyWaterGoal ?? 2000)
        }
        .sheet(isPresented: $state.showMealReminder) {
            MealReminderAlertView(
                mealType: state.mealReminderType,
                onTakePhoto: { selectedTab = 0; state.showMealReminder = false },
                onTypeManually: { selectedTab = 0; state.showMealReminder = false }
            )
            .presentationDetents([.fraction(0.72)])
            .presentationDragIndicator(.visible)
        }
    }
}
