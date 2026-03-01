import Foundation
import StoreKit

/// Serviço de assinaturas via StoreKit 2.
@Observable
final class SubscriptionService {
    static let shared = SubscriptionService()
    private init() {}

    var products: [Product] = []
    var purchasedProductIDs: Set<String> = []
    var currentPlan: SubscriptionPlan = .free

    private var updateListenerTask: Task<Void, Error>?

    // MARK: – Public

    func start() {
        updateListenerTask = listenForTransactions()
        Task { await loadProducts() }
        Task { await updateEntitlements() }
    }

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateEntitlements()
            await transaction.finish()
        case .userCancelled:
            break
        case .pending:
            break
        @unknown default:
            break
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
            await updateEntitlements()
        } catch {
            // Silently ignore restore errors
        }
    }

    // MARK: – Private

    private func loadProducts() async {
        do {
            products = try await Product.products(for: Set(AppConstants.ProductID.all))
        } catch {
            products = []
        }
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updateEntitlements()
                    await transaction.finish()
                } catch {
                    // Invalid transaction — ignore
                }
            }
        }
    }

    private func updateEntitlements() async {
        // Collect on background, then update on MainActor
        var collected: Set<String> = []
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.revocationDate == nil {
                    collected.insert(transaction.productID)
                }
            } catch {
                // Skip invalid transaction
            }
        }
        // Capture as a let before crossing to MainActor to satisfy Swift 6 concurrency
        let finalIDs = collected
        await MainActor.run {
            purchasedProductIDs = finalIDs
            currentPlan = determinePlan(from: finalIDs)
        }
    }

    private func determinePlan(from ids: Set<String>) -> SubscriptionPlan {
        if ids.contains(AppConstants.ProductID.eliteMonthly) ||
           ids.contains(AppConstants.ProductID.eliteAnnual) {
            return .elite
        } else if ids.contains(AppConstants.ProductID.proMonthly) ||
                  ids.contains(AppConstants.ProductID.proAnnual) {
            return .pro
        }
        return .free
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):   return value
        case .unverified(_, let error): throw error
        }
    }
}
