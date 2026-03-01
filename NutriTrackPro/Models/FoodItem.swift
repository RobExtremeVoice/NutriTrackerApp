import Foundation
import SwiftData

/// Alimento individual detectado pela IA em uma refeição.
@Model
final class FoodItem {
    var id: UUID
    var name: String
    var weightG: Double          // gramas — editável pelo usuário
    var caloriesPer100g: Double
    var proteinPer100g: Double
    var carbsPer100g: Double
    var fatPer100g: Double
    var fiberPer100g: Double
    var aiConfidence: String     // "high" | "medium" | "low"

    init(
        name: String,
        weightG: Double = 100,
        caloriesPer100g: Double,
        proteinPer100g: Double,
        carbsPer100g: Double,
        fatPer100g: Double,
        fiberPer100g: Double,
        aiConfidence: String = "medium"
    ) {
        self.id = UUID()
        self.name = name
        self.weightG = weightG
        self.caloriesPer100g = caloriesPer100g
        self.proteinPer100g = proteinPer100g
        self.carbsPer100g = carbsPer100g
        self.fatPer100g = fatPer100g
        self.fiberPer100g = fiberPer100g
        self.aiConfidence = aiConfidence
    }

    /// Valores nutricionais calculados para o peso especificado.
    var nutrition: NutritionInfo {
        let factor = weightG / 100
        return NutritionInfo(
            calories: caloriesPer100g * factor,
            protein:  proteinPer100g  * factor,
            carbs:    carbsPer100g    * factor,
            fat:      fatPer100g      * factor,
            fiber:    fiberPer100g    * factor
        )
    }
}
