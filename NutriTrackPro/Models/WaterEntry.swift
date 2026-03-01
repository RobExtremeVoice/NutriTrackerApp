import Foundation
import SwiftData

/// Registro de consumo de água (em ml) para uma data.
@Model
final class WaterEntry {
    var id: UUID
    var date: Date
    var mlConsumed: Int

    init(date: Date = .now, mlConsumed: Int = 0) {
        self.id = UUID()
        self.date = date
        self.mlConsumed = mlConsumed
    }
}
