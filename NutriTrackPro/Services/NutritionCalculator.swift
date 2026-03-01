import Foundation

/// Resultado do cálculo de TDEE e metas de macros.
struct TDEEResult {
    let bmr: Double
    let tdee: Double
    let targetCalories: Double
    let proteinGoal: Double
    let carbsGoal: Double
    let fatGoal: Double
    let fiberGoal: Double
}

/// Calcula TDEE via fórmula Mifflin-St Jeor e distribui macros.
enum NutritionCalculator {

    static func calculate(profile: UserProfile) -> TDEEResult {
        let bmr = calcBMR(
            weightKg: profile.weightKg,
            heightCm: profile.heightCm,
            age: profile.age,
            gender: profile.genderEnum
        )
        let activity = profile.activityEnum
        let goal     = profile.goalEnum
        return buildResult(bmr: bmr, activity: activity, goal: goal, weightKg: profile.weightKg)
    }

    static func calculate(
        weightKg: Double,
        heightCm: Double,
        age: Int,
        gender: Gender,
        activity: ActivityLevel,
        goal: HealthGoal
    ) -> TDEEResult {
        let bmr = calcBMR(weightKg: weightKg, heightCm: heightCm, age: age, gender: gender)
        return buildResult(bmr: bmr, activity: activity, goal: goal, weightKg: weightKg)
    }

    // MARK: – Private helpers

    private static func calcBMR(weightKg: Double, heightCm: Double, age: Int, gender: Gender) -> Double {
        // Mifflin-St Jeor
        let base = 10 * weightKg + 6.25 * heightCm - 5 * Double(age)
        switch gender {
        case .male:   return base + 5
        case .female: return base - 161
        case .other:  return base - 78  // média entre masculino e feminino
        }
    }

    private static func buildResult(
        bmr: Double,
        activity: ActivityLevel,
        goal: HealthGoal,
        weightKg: Double
    ) -> TDEEResult {
        let tdee           = bmr * activity.factor
        let targetCalories = max(1200, tdee + goal.calorieAdjustment)

        // Proteína: 2g/kg para ganho/manutenção, 1.6g/kg para perda
        let proteinMultiplier: Double = goal == .lose ? 1.6 : 2.0
        let proteinGoal = weightKg * proteinMultiplier

        // Gordura: 25% das calorias alvo
        let fatGoal = (targetCalories * 0.25) / 9

        // Carboidratos: calorias restantes
        let proteinCals = proteinGoal * 4
        let fatCals     = fatGoal * 9
        let carbsGoal   = max(50, (targetCalories - proteinCals - fatCals) / 4)

        // Fibras: 14g por 1000 kcal (recomendação OMS)
        let fiberGoal = (targetCalories / 1000) * 14

        return TDEEResult(
            bmr: bmr,
            tdee: tdee,
            targetCalories: targetCalories,
            proteinGoal: proteinGoal,
            carbsGoal: carbsGoal,
            fatGoal: fatGoal,
            fiberGoal: fiberGoal
        )
    }
}
