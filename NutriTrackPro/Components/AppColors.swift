import SwiftUI

/// Paleta de cores do NutriTrack Pro.
struct AppColors {
    static let primary       = Color(hex: "22C55E")
    static let primaryLight  = Color(hex: "4ADE80")
    static let primaryDark   = Color(hex: "16A34A")
    static let accent        = Color(hex: "F97316")
    static let background    = Color(hex: "F7F8FA")
    static let surface       = Color.white
    static let text          = Color(hex: "111827")
    static let textSecondary = Color(hex: "6B7280")
    static let protein       = Color(hex: "3B82F6")
    static let carbs         = Color(hex: "F59E0B")
    static let fat           = Color(hex: "EF4444")
    static let fiber         = Color(hex: "8B5CF6")
}

extension Color {
    /// Inicializa uma Color a partir de uma string hexadecimal (ex: "22C55E").
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hex.count {
        case 6:
            (r, g, b, a) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF, 255)
        case 8:
            (r, g, b, a) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }
        self.init(
            .sRGB,
            red:   Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
