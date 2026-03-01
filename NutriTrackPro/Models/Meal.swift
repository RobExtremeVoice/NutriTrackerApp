import Foundation
import SwiftData

/// Tipo de refeição com emoji e nome em PT-BR.
enum MealType: String, CaseIterable, Codable {
    case breakfast = "breakfast"
    case lunch     = "lunch"
    case dinner    = "dinner"
    case snack     = "snack"

    var displayName: String {
        switch self {
        case .breakfast: return "Café da manhã"
        case .lunch:     return "Almoço"
        case .dinner:    return "Jantar"
        case .snack:     return "Lanche"
        }
    }

    var emoji: String {
        switch self {
        case .breakfast: return "🌅"
        case .lunch:     return "☀️"
        case .dinner:    return "🌙"
        case .snack:     return "🍎"
        }
    }

    var notificationId: String { "reminder_\(rawValue)" }

    /// Horário padrão do lembrete.
    var reminderHour: Int {
        switch self {
        case .breakfast: return 8
        case .lunch:     return 12
        case .dinner:    return 19
        case .snack:     return 15
        }
    }

    var reminderMinute: Int {
        switch self {
        case .lunch: return 30
        default:     return 0
        }
    }
}

/// Refeição registrada pelo usuário.
@Model
final class Meal {
    var id: UUID
    var type: String              // MealType.rawValue
    var name: String
    var imageData: Data?          // foto comprimida em JPEG
    var timestamp: Date
    @Relationship(deleteRule: .cascade) var foods: [FoodItem]

    init(type: MealType, name: String, imageData: Data? = nil, timestamp: Date = .now) {
        self.id = UUID()
        self.type = type.rawValue
        self.name = name
        self.imageData = imageData
        self.timestamp = timestamp
        self.foods = []
    }

    var mealType: MealType {
        MealType(rawValue: type) ?? .snack
    }

    // MARK: – Computed totals

    var totalCalories: Double { foods.reduce(0) { $0 + $1.nutrition.calories } }
    var totalProtein: Double  { foods.reduce(0) { $0 + $1.nutrition.protein } }
    var totalCarbs: Double    { foods.reduce(0) { $0 + $1.nutrition.carbs } }
    var totalFat: Double      { foods.reduce(0) { $0 + $1.nutrition.fat } }
    var totalFiber: Double    { foods.reduce(0) { $0 + $1.nutrition.fiber } }

    var totalNutrition: NutritionInfo {
        NutritionInfo(
            calories: totalCalories,
            protein:  totalProtein,
            carbs:    totalCarbs,
            fat:      totalFat,
            fiber:    totalFiber
        )
    }

    /// Verifica se a refeição foi registrada na data fornecida (ignorando hora).
    func isOnDay(_ date: Date) -> Bool {
        Calendar.current.isDate(timestamp, inSameDayAs: date)
    }
}
