import SwiftUI
import SwiftData

@main
struct NutriTrackProApp: App {
    @State private var appState = AppState()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Meal.self,
            FoodItem.self,
            UserProfile.self,
            WeightEntry.self,
            WaterEntry.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Não foi possível criar o ModelContainer: \(error)")
        }
    }()

    init() {
        // Registra categorias de notificação (inclui botão "📸 Registrar agora")
        // Deve ser chamado antes de qualquer notificação ser agendada.
        NotificationService.shared.registerCategories()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
        .modelContainer(sharedModelContainer)
    }
}
