import Foundation

/// Dados compartilhados entre o app principal e o Widget via App Groups.
/// Ambos os targets lêem/escrevem o mesmo UserDefaults suite.
struct NutriWidgetEntry: Codable {
    var caloriesConsumed: Double
    var calorieGoal: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var streakDays: Int
    var updatedAt: Date
}

extension NutriWidgetEntry {
    /// Entrada vazia usada quando nenhum dado foi registrado ainda hoje.
    static let empty = NutriWidgetEntry(
        caloriesConsumed: 0, calorieGoal: 2000,
        protein: 0, carbs: 0, fat: 0,
        streakDays: 0, updatedAt: .distantPast
    )

    /// Entrada de demonstração para previews do widget.
    static let preview = NutriWidgetEntry(
        caloriesConsumed: 1_247, calorieGoal: 2_000,
        protein: 86, carbs: 148, fat: 42,
        streakDays: 12, updatedAt: .now
    )

    /// Calorias restantes para a meta do dia.
    var caloriesRemaining: Int { max(Int(calorieGoal - caloriesConsumed), 0) }

    /// Progresso calórico de 0.0 a 1.0.
    var progress: Double {
        guard calorieGoal > 0 else { return 0 }
        return min(caloriesConsumed / calorieGoal, 1.0)
    }

    /// Retorna `true` se os dados são do dia de hoje.
    var isToday: Bool { Calendar.current.isDateInToday(updatedAt) }
}

/// Ponte de dados entre o app e a extensão widget via App Groups.
final class WidgetDataStore {
    static let shared = WidgetDataStore()
    private init() {}

    private let suiteName = "group.com.extremeresults.nutripackproapp"
    private let entryKey  = "nutriWidgetEntry"

    /// Persiste um snapshot do progresso diário no contêiner compartilhado.
    func write(_ entry: NutriWidgetEntry) {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = try? JSONEncoder().encode(entry) else { return }
        defaults.set(data, forKey: entryKey)
    }

    /// Lê o snapshot mais recente. Retorna `nil` se não houver dados ou se for de outro dia.
    func read() -> NutriWidgetEntry? {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data    = defaults.data(forKey: entryKey),
              let entry   = try? JSONDecoder().decode(NutriWidgetEntry.self, from: data),
              entry.isToday else { return nil }
        return entry
    }
}
