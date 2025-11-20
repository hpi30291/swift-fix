import Foundation
import StoreKit
import Combine

/// Manages in-app purchases using StoreKit 2
@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    // MARK: - Product IDs
    private enum ProductID {
        static let lifetimeAccess = "com.trafficsafetyinstitute.dmvprep.lifetime"
    }

    // MARK: - Published Properties
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isPurchasing = false
    @Published var errorMessage: String?

    private var updateListenerTask: Task<Void, Error>?

    private init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()

        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products
    func loadProducts() async {
        do {
            // Load products from App Store Connect
            // NOTE: Replace with actual product ID once Apple account is approved
            let productIDs: Set<String> = [ProductID.lifetimeAccess]
            products = try await Product.products(for: productIDs)

            #if DEBUG
            print("✅ Loaded \(products.count) products")
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to load products: \(error)")
            #endif
            errorMessage = "Failed to load products: \(error.localizedDescription)"
        }
    }

    // MARK: - Purchase Product
    func purchase(_ product: Product) async throws {
        isPurchasing = true
        errorMessage = nil

        do {
            // Attempt purchase
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // Verify transaction
                let transaction = try checkVerified(verification)

                // Update purchased products
                await updatePurchasedProducts()

                // Unlock full access
                UserAccessManager.shared.unlockFullAccess()

                // Finish transaction
                await transaction.finish()

                isPurchasing = false
                return

            case .userCancelled:
                isPurchasing = false
                throw StoreKitError.userCancelled

            case .pending:
                isPurchasing = false
                throw StoreKitError.pending

            @unknown default:
                isPurchasing = false
                throw StoreKitError.unknown
            }
        } catch {
            isPurchasing = false
            errorMessage = error.localizedDescription

            // Report purchase error to Crashlytics
            CrashlyticsManager.shared.recordPurchaseError(error, productID: product.id)

            throw error
        }
    }

    // MARK: - Restore Purchases
    func restorePurchases() async throws {
        do {
            // Sync with App Store
            try await AppStore.sync()

            // Update purchased products
            await updatePurchasedProducts()

            // If user has purchased, unlock access
            if !purchasedProductIDs.isEmpty {
                UserAccessManager.shared.unlockFullAccess()
            } else {
                throw StoreKitError.noPurchasesToRestore
            }
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    // MARK: - Update Purchased Products
    func updatePurchasedProducts() async {
        var purchasedIDs: Set<String> = []

        // Iterate through all transactions
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                // Add to purchased set
                purchasedIDs.insert(transaction.productID)
            } catch {
                #if DEBUG
                print("❌ Transaction verification failed: \(error)")
                #endif
            }
        }

        purchasedProductIDs = purchasedIDs

        // If user has purchased, unlock access
        if !purchasedProductIDs.isEmpty {
            UserAccessManager.shared.unlockFullAccess()
        }
    }

    // MARK: - Listen for Transactions
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            // Listen for transaction updates
            for await result in Transaction.updates {
                do {
                    let transaction = try await MainActor.run {
                        try self.checkVerified(result)
                    }

                    // Update purchased products
                    await self.updatePurchasedProducts()

                    // Finish transaction
                    await transaction.finish()
                } catch {
                    #if DEBUG
                    print("❌ Transaction update failed: \(error)")
                    #endif
                }
            }
        }
    }

    // MARK: - Verify Transaction
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            // Transaction is unverified
            throw StoreKitError.failedVerification
        case .verified(let safe):
            // Transaction is verified
            return safe
        }
    }

    // MARK: - Get Product
    func getLifetimeProduct() -> Product? {
        return products.first { $0.id == ProductID.lifetimeAccess }
    }

    // MARK: - Price
    func lifetimePrice() -> String {
        guard let product = getLifetimeProduct() else {
            return "$14.99" // Fallback price
        }
        return product.displayPrice
    }
}

// MARK: - Store Errors
enum StoreKitError: LocalizedError {
    case userCancelled
    case pending
    case failedVerification
    case noPurchasesToRestore
    case unknown

    var errorDescription: String? {
        switch self {
        case .userCancelled:
            return "Purchase was cancelled"
        case .pending:
            return "Purchase is pending approval"
        case .failedVerification:
            return "Transaction verification failed"
        case .noPurchasesToRestore:
            return "No previous purchases found"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
