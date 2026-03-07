import Foundation

/// Constantes globais do aplicativo.
enum AppConstants {
    // MARK: – OpenAI proxy
    // API key lives server-side in AWS Lambda — never in the app.
    static let openAIEndpoint = "https://pm6ufkqebtpspekk6lfyud4l2a0rmozl.lambda-url.us-east-1.on.aws/"
    static let visionModel    = "gpt-4o"
    static let chatModel      = "gpt-4o"

    // MARK: – StoreKit Product IDs
    enum ProductID {
        static let proMonthly   = "com.nutritrack.pro.monthly"
        static let proAnnual    = "com.nutritrack.pro.annual"
        static let eliteMonthly = "com.nutritrack.elite.monthly"
        static let eliteAnnual  = "com.nutritrack.elite.annual"

        static var all: [String] {
            [proMonthly, proAnnual, eliteMonthly, eliteAnnual]
        }
    }

    // MARK: – UserDefaults keys
    enum Defaults {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let todayPhotoScanCount    = "todayPhotoScanCount"
        static let todayPhotoScanDate     = "todayPhotoScanDate"
        static let todayChatCount         = "todayChatCount"
        static let todayChatDate          = "todayChatDate"
    }

    // MARK: – Design
    static let cardCornerRadius: CGFloat  = 16
    static let largeCornerRadius: CGFloat = 24
    static let chipCornerRadius: CGFloat  = 12
    static let cardShadowRadius: CGFloat  = 12
    static let cardShadowY: CGFloat       = 4
    static let cardShadowOpacity: Double  = 0.06
}
