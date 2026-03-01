import Foundation
import HealthKit

/// Serviço de integração com o Apple Health.
final class HealthKitService {
    static let shared = HealthKitService()
    private init() {}

    private let store = HKHealthStore()

    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = []
        if let stepCount       = HKQuantityType.quantityType(forIdentifier: .stepCount)       { types.insert(stepCount) }
        if let activeEnergy    = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) { types.insert(activeEnergy) }
        if let weight          = HKQuantityType.quantityType(forIdentifier: .bodyMass)         { types.insert(weight) }
        if let height          = HKQuantityType.quantityType(forIdentifier: .height)           { types.insert(height) }
        return types
    }

    private var writeTypes: Set<HKSampleType> {
        var types: Set<HKSampleType> = []
        if let energy   = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) { types.insert(energy) }
        if let protein  = HKQuantityType.quantityType(forIdentifier: .dietaryProtein)        { types.insert(protein) }
        if let carbs    = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)  { types.insert(carbs) }
        if let fat      = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)       { types.insert(fat) }
        return types
    }

    // MARK: – Authorization

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        try await store.requestAuthorization(toShare: writeTypes, read: readTypes)
    }

    // MARK: – Write

    func syncNutrition(meal: Meal) async throws {
        let date = meal.timestamp
        var samples: [HKQuantitySample] = []

        if let energyType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) {
            let qty = HKQuantity(unit: .kilocalorie(), doubleValue: meal.totalCalories)
            samples.append(HKQuantitySample(type: energyType, quantity: qty, start: date, end: date))
        }
        if let proteinType = HKQuantityType.quantityType(forIdentifier: .dietaryProtein) {
            let qty = HKQuantity(unit: .gram(), doubleValue: meal.totalProtein)
            samples.append(HKQuantitySample(type: proteinType, quantity: qty, start: date, end: date))
        }
        if let carbsType = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates) {
            let qty = HKQuantity(unit: .gram(), doubleValue: meal.totalCarbs)
            samples.append(HKQuantitySample(type: carbsType, quantity: qty, start: date, end: date))
        }
        if let fatType = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal) {
            let qty = HKQuantity(unit: .gram(), doubleValue: meal.totalFat)
            samples.append(HKQuantitySample(type: fatType, quantity: qty, start: date, end: date))
        }

        try await store.save(samples)
    }

    // MARK: – Read

    func fetchStepsToday() async throws -> Int {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw HealthKitError.typeNotAvailable
        }
        let start = Calendar.current.startOfDay(for: .now)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let steps = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(steps))
            }
            store.execute(query)
        }
    }
}

// MARK: – Errors

enum HealthKitError: LocalizedError {
    case notAvailable
    case typeNotAvailable

    var errorDescription: String? {
        switch self {
        case .notAvailable:     return "Apple Health não está disponível neste dispositivo."
        case .typeNotAvailable: return "Tipo de dado de saúde não disponível."
        }
    }
}
