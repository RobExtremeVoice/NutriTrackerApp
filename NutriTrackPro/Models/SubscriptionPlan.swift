import Foundation

/// Plano de assinatura do usuário.
enum SubscriptionPlan: String, Codable, CaseIterable {
    case free
    case pro
    case elite

    /// Limite de análises por foto por dia.
    var dailyPhotoLimit: Int {
        switch self {
        case .free:  return 3
        case .pro:   return 30
        case .elite: return Int.max
        }
    }

    /// Nome localizado do plano.
    var displayName: String {
        switch self {
        case .free:  return "Gratuito"
        case .pro:   return "Pro"
        case .elite: return "Elite"
        }
    }

    /// Cor de destaque do plano.
    var badgeColorHex: String {
        switch self {
        case .free:  return "6B7280"
        case .pro:   return "22C55E"
        case .elite: return "F97316"
        }
    }

    /// Acesso ao chat com IA.
    var hasChatAccess: Bool {
        switch self {
        case .free:  return true   // limitado a 10 msg/dia
        case .pro:   return true
        case .elite: return true
        }
    }

    /// Mensagens de chat por dia.
    var dailyChatLimit: Int {
        switch self {
        case .free:  return 10
        case .pro:   return 100
        case .elite: return Int.max
        }
    }
}
