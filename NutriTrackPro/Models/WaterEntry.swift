import Foundation
import SwiftData

/// Registro de consumo de água (em copos) para uma data.
@Model
final class WaterEntry {
    var id: UUID
    var date: Date
    var cups: Int

    init(date: Date = .now, cups: Int = 1) {
        self.id = UUID()
        self.date = date
        self.cups = cups
    }
}
