import Foundation
import SwiftData

/// Nível de atividade física — usado no cálculo do TDEE.
enum ActivityLevel: String, CaseIterable, Codable {
    case sedentary   = "sedentary"
    case light       = "light"
    case moderate    = "moderate"
    case active      = "active"
    case veryActive  = "veryActive"

    var displayName: String {
        switch self {
        case .sedentary:  return "Sedentário"
        case .light:      return "Levemente ativo"
        case .moderate:   return "Moderadamente ativo"
        case .active:     return "Ativo"
        case .veryActive: return "Muito ativo"
        }
    }

    /// Fator multiplicador do TDEE (Mifflin-St Jeor).
    var factor: Double {
        switch self {
        case .sedentary:  return 1.2
        case .light:      return 1.375
        case .moderate:   return 1.55
        case .active:     return 1.725
        case .veryActive: return 1.9
        }
    }
}

/// Objetivo de saúde do usuário.
enum HealthGoal: String, CaseIterable, Codable {
    case lose     = "lose"
    case maintain = "maintain"
    case gain     = "gain"

    var displayName: String {
        switch self {
        case .lose:     return "Perder peso"
        case .maintain: return "Manter peso"
        case .gain:     return "Ganhar músculo"
        }
    }

    /// Ajuste calórico em relação ao TDEE.
    var calorieAdjustment: Double {
        switch self {
        case .lose:     return -500
        case .maintain: return 0
        case .gain:     return 300
        }
    }
}

/// Gênero para fins de cálculo nutricional.
enum Gender: String, CaseIterable, Codable {
    case male   = "male"
    case female = "female"
    case other  = "other"

    var displayName: String {
        switch self {
        case .male:   return "Masculino"
        case .female: return "Feminino"
        case .other:  return "Outro"
        }
    }
}

/// Perfil do usuário armazenado no SwiftData.
@Model
final class UserProfile {
    var name: String
    var age: Int
    var gender: String            // Gender.rawValue
    var weightKg: Double
    var heightCm: Double
    var targetWeightKg: Double
    var activityLevel: String     // ActivityLevel.rawValue
    var goal: String              // HealthGoal.rawValue

    // Metas diárias (calculadas e armazenadas)
    var dailyCalorieGoal: Double
    var dailyProteinGoal: Double
    var dailyCarbsGoal: Double
    var dailyFatGoal: Double
    var dailyFiberGoal: Double
    var dailyWaterGoal: Int

    // Gamificação
    var streakDays: Int
    var lastLogDate: Date?

    init(
        name: String = "",
        age: Int = 25,
        gender: Gender = .male,
        weightKg: Double = 70,
        heightCm: Double = 170,
        targetWeightKg: Double = 70,
        activityLevel: ActivityLevel = .moderate,
        goal: HealthGoal = .maintain,
        dailyCalorieGoal: Double = 2000,
        dailyProteinGoal: Double = 120,
        dailyCarbsGoal: Double = 225,
        dailyFatGoal: Double = 65,
        dailyFiberGoal: Double = 30,
        dailyWaterGoal: Int = 2000
    ) {
        self.name = name
        self.age = age
        self.gender = gender.rawValue
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.targetWeightKg = targetWeightKg
        self.activityLevel = activityLevel.rawValue
        self.goal = goal.rawValue
        self.dailyCalorieGoal = dailyCalorieGoal
        self.dailyProteinGoal = dailyProteinGoal
        self.dailyCarbsGoal = dailyCarbsGoal
        self.dailyFatGoal = dailyFatGoal
        self.dailyFiberGoal = dailyFiberGoal
        self.dailyWaterGoal = dailyWaterGoal
        self.streakDays = 0
        self.lastLogDate = nil
    }

    var firstName: String {
        name.components(separatedBy: " ").first ?? name
    }

    var genderEnum: Gender     { Gender(rawValue: gender)             ?? .male }
    var activityEnum: ActivityLevel { ActivityLevel(rawValue: activityLevel) ?? .moderate }
    var goalEnum: HealthGoal   { HealthGoal(rawValue: goal)           ?? .maintain }
}
