import Foundation
import SwiftData

/// Registro de peso do usuário em uma data específica.
@Model
final class WeightEntry {
    var id: UUID
    var date: Date
    var weightKg: Double

    init(date: Date = .now, weightKg: Double) {
        self.id = UUID()
        self.date = date
        self.weightKg = weightKg
    }

    /// Data formatada em pt-BR (ex: "03/03").
    var shortDateLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "dd/MM"
        return formatter.string(from: date)
    }
}
