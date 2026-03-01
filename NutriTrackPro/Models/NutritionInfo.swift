import Foundation

/// Valores nutricionais calculados para uma porção de alimento.
struct NutritionInfo: Codable, Equatable {
    var calories: Double
    var protein: Double   // gramas
    var carbs: Double     // gramas
    var fat: Double       // gramas
    var fiber: Double     // gramas

    static let zero = NutritionInfo(calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0)

    /// Calorias calculadas matematicamente a partir dos macros (P*4 + C*4 + G*9).
    var calculatedCalories: Double {
        (protein * 4) + (carbs * 4) + (fat * 9)
    }

    /// Retorna true quando há divergência >10% entre calories e calculatedCalories.
    var hasCalorieMismatch: Bool {
        guard calories > 0 else { return false }
        let diff = abs(calories - calculatedCalories)
        return diff > calories * 0.10
    }

    /// Soma dois NutritionInfo.
    static func + (lhs: NutritionInfo, rhs: NutritionInfo) -> NutritionInfo {
        NutritionInfo(
            calories: lhs.calories + rhs.calories,
            protein: lhs.protein + rhs.protein,
            carbs: lhs.carbs + rhs.carbs,
            fat: lhs.fat + rhs.fat,
            fiber: lhs.fiber + rhs.fiber
        )
    }
}
