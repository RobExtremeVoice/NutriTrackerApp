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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
        .modelContainer(sharedModelContainer)
    }
}
