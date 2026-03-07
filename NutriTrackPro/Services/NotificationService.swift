import Foundation
import UserNotifications

/// Serviço de notificações de lembrete de refeição.
final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    // MARK: – Category registration

    /// Categoria com botão de ação — deve ser chamada uma vez na inicialização do app.
    func registerCategories() {
        let logAction = UNNotificationAction(
            identifier: "LOG_MEAL",
            title: "📸 Registrar agora",
            options: .foreground   // abre o app direto na tela de registro
        )
        let mealCategory = UNNotificationCategory(
            identifier: "MEAL_REMINDER",
            actions: [logAction],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([mealCategory])
    }

    // MARK: – Permission

    func requestAuthorization() async throws {
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        guard granted else { throw NotificationError.denied }
    }

    // MARK: – Schedule

    /// Agenda lembretes para todos os tipos de refeição.
    func scheduleAll() async throws {
        try await requestAuthorization()
        for mealType in MealType.allCases {
            try await scheduleMealReminder(for: mealType)
        }
        // Lembrete de fim do dia se nada foi registrado
        try await scheduleDailyCheckReminder()
        // Resumo semanal todo domingo às 20h
        try await scheduleWeeklySummary()
    }

    func scheduleMealReminder(for mealType: MealType) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Hora de registrar!"
        content.body = "Você já tomou \(mealType.displayName.lowercased()) hoje? Registre agora 📸"
        content.sound = .default
        content.interruptionLevel = .timeSensitive   // banner persistente ~30s, passa por Focus
        content.categoryIdentifier = "MEAL_REMINDER" // exibe botão "📸 Registrar agora"

        var dateComponents = DateComponents()
        dateComponents.hour   = mealType.reminderHour
        dateComponents.minute = mealType.reminderMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: mealType.notificationId,
            content: content,
            trigger: trigger
        )
        try await center.add(request)
    }

    private func scheduleDailyCheckReminder() async throws {
        let content = UNMutableNotificationContent()
        content.title = "Você não registrou nada hoje 😕"
        content.body = "Mantenha sua sequência! Registre pelo menos uma refeição."
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        content.categoryIdentifier = "MEAL_REMINDER"

        var dateComponents = DateComponents()
        dateComponents.hour   = 21
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily_check",
            content: content,
            trigger: trigger
        )
        try await center.add(request)
    }

    // MARK: – Weekly Summary

    /// Agenda (ou reaplica) um resumo semanal todo domingo às 20h.
    /// Mostra progresso da semana e incentiva a manter o ritmo.
    func scheduleWeeklySummary() async throws {
        center.removePendingNotificationRequests(withIdentifiers: ["weekly_summary"])
        let content = UNMutableNotificationContent()
        content.title = "Seu resumo semanal chegou! 📊"
        content.body = "Veja como foi sua semana e planeje a próxima. Abra o app para conferir."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.weekday = 1  // domingo (1 = domingo no calendário iOS)
        dateComponents.hour   = 20
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly_summary", content: content, trigger: trigger)
        try await center.add(request)
    }

    // MARK: – Re-engagement

    /// Agenda (ou reaplica) um lembrete condicional 26h após o último registro.
    /// Cancela qualquer lembrete anterior antes de agendar o novo.
    /// Se o usuário logar antes das 26h, o timer recomeça do zero.
    func scheduleReEngagementReminder() async {
        center.removePendingNotificationRequests(withIdentifiers: ["re_engagement"])
        let content = UNMutableNotificationContent()
        content.title = "Você não registrou hoje 🔥"
        content.body = "Sua sequência está em risco! Registre uma refeição agora."
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        content.categoryIdentifier = "MEAL_REMINDER"
        // Dispara 26 horas após o último log — se não houver novo log até lá
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 26 * 3600, repeats: false)
        let request = UNNotificationRequest(identifier: "re_engagement", content: content, trigger: trigger)
        try? await center.add(request)
    }

    // MARK: – Cancel

    /// Cancela o lembrete de uma refeição específica (quando o usuário já logou).
    func cancelMealReminder(for mealType: MealType) {
        center.removePendingNotificationRequests(withIdentifiers: [mealType.notificationId])
    }

    /// Cancela todos os lembretes programados.
    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }
}

// MARK: – Error

enum NotificationError: LocalizedError {
    case denied

    var errorDescription: String? {
        "Permissão de notificação negada. Habilite em Ajustes > NutriPack Pro > Notificações."
    }
}
