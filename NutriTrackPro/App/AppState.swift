import Foundation
import Observation

/// Estado global do aplicativo — injetado via environment.
@Observable
final class AppState {
    // MARK: – Subscription
    var currentPlan: SubscriptionPlan = .free

    // MARK: – Paywall gate
    var showPaywall: Bool = false

    // MARK: – In-app alert sheets
    var showHydrationAlert:  Bool     = false
    var showMealReminder:    Bool     = false
    var mealReminderType:    MealType = .lunch

    // MARK: – HealthKit integration
    // Persisted across launches — toggled in HealthKitView.
    var healthKitEnabled: Bool = UserDefaults.standard.bool(forKey: AppConstants.Defaults.healthKitEnabled) {
        didSet { UserDefaults.standard.set(healthKitEnabled, forKey: AppConstants.Defaults.healthKitEnabled) }
    }

    // MARK: – Selected date (Diary / Home)
    var selectedDate: Date = .now

    // MARK: – Daily photo scan counter (reset at midnight)
    private(set) var todayPhotoScans: Int = 0

    // MARK: – Daily chat message counter
    private(set) var todayChatMessages: Int = 0

    init() {
        loadDailyCounters()
    }

    // MARK: – Feature gating

    /// Verifica se o usuário pode usar mais uma análise por foto hoje.
    func canUsePhotoScan() -> Bool {
        return todayPhotoScans < currentPlan.dailyPhotoLimit
    }

    /// Verifica se o usuário pode enviar mais uma mensagem de chat hoje.
    func canUseChat() -> Bool {
        return todayChatMessages < currentPlan.dailyChatLimit
    }

    /// Incrementa o contador de scans (chamar após análise bem-sucedida).
    func incrementPhotoScan() {
        todayPhotoScans += 1
        saveCounter(todayPhotoScans, key: AppConstants.Defaults.todayPhotoScanCount,
                    dateKey: AppConstants.Defaults.todayPhotoScanDate)
    }

    /// Incrementa o contador de mensagens de chat.
    func incrementChatMessage() {
        todayChatMessages += 1
        saveCounter(todayChatMessages, key: AppConstants.Defaults.todayChatCount,
                    dateKey: AppConstants.Defaults.todayChatDate)
    }

    // MARK: – Private helpers

    private func loadDailyCounters() {
        todayPhotoScans = loadCounter(key: AppConstants.Defaults.todayPhotoScanCount,
                                      dateKey: AppConstants.Defaults.todayPhotoScanDate)
        todayChatMessages = loadCounter(key: AppConstants.Defaults.todayChatCount,
                                        dateKey: AppConstants.Defaults.todayChatDate)
    }

    /// Retorna contador se salvo hoje, senão 0.
    private func loadCounter(key: String, dateKey: String) -> Int {
        let defaults = UserDefaults.standard
        guard let savedDate = defaults.object(forKey: dateKey) as? Date,
              Calendar.current.isDateInToday(savedDate) else {
            return 0
        }
        return defaults.integer(forKey: key)
    }

    private func saveCounter(_ value: Int, key: String, dateKey: String) {
        UserDefaults.standard.set(value, forKey: key)
        UserDefaults.standard.set(Date.now, forKey: dateKey)
    }
}
