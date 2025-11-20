import Foundation
import Combine

/// Manages user access levels (free vs paid) and usage tracking
class UserAccessManager: ObservableObject {
    static let shared = UserAccessManager()

    // MARK: - Published Properties
    @Published var hasPurchased: Bool = false
    @Published var diagnosticTestTaken: Bool = false
    @Published var weeklyTestsTaken: Int = 0
    @Published var lastWeekResetDate: Date = Date()
    @Published var currentTestQuestionCount: Int = 0  // Track questions in current test

    // MARK: - Debug Mode
    #if DEBUG
    @Published var debugPremiumEnabled: Bool = false
    #endif

    // MARK: - Constants
    private let freeTestsPerWeek = 5          // 5 practice tests per week
    private let freeDiagnosticTestLimit = 1   // Only 1 diagnostic test for free

    // MARK: - UserDefaults Keys
    private let hasPurchasedKey = "hasPurchased"
    private let diagnosticTestTakenKey = "diagnosticTestTaken"
    private let weeklyTestsTakenKey = "weeklyTestsTaken"
    private let lastWeekResetDateKey = "lastWeekResetDate"
    private let legacyTestsRemainingKey = "testsRemainingThisWeek"
    private let legacyLastResetKey = "lastTestResetDate"
    private let legacyHasActiveSubscriptionKey = "hasActiveSubscription"

    private init() {
        loadUserAccess()
        // Defer the check to avoid publishing changes in init
        DispatchQueue.main.async { [weak self] in
            self?.checkAndResetWeeklyLimit()
        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleDefaultsChanged),
                                               name: UserDefaults.didChangeNotification,
                                               object: nil)
    }

    // MARK: - Computed Properties

    var hasActiveSubscription: Bool {
        if UserDefaults.standard.object(forKey: legacyHasActiveSubscriptionKey) != nil {
            return UserDefaults.standard.bool(forKey: legacyHasActiveSubscriptionKey)
        }
        #if DEBUG
        return hasPurchased || debugPremiumEnabled
        #else
        return hasPurchased
        #endif
    }

    var testsRemainingThisWeek: Int {
        if hasActiveSubscription {
            return Int.max
        }
        if let remaining = UserDefaults.standard.object(forKey: legacyTestsRemainingKey) as? Int {
            return remaining
        }
        return max(0, freeTestsPerWeek - weeklyTestsTaken)
    }

    var canTakePracticeTest: Bool {
        return hasActiveSubscription || weeklyTestsTaken < freeTestsPerWeek
    }

    var canTakeFullPracticeTest: Bool {
        // 46-question exam simulator is PAID only
        return hasActiveSubscription
    }

    var canAccessCategoryPractice: Bool {
        // Category-specific practice is PAID only
        return hasActiveSubscription
    }

    var canAccessWeakAreasPractice: Bool {
        // Weak areas focused practice is PAID only
        return hasActiveSubscription
    }

    var canAccessLearnMode: Bool {
        // Learn (45 lessons total, 1 module free)
        return hasActiveSubscription
    }

    var canAccessAITutor: Bool {
        // AI Tutor is PAID only
        return hasActiveSubscription
    }

    var canAccessAdvancedReadiness: Bool {
        // Advanced readiness gauge (detailed by category) is PAID only
        return hasActiveSubscription
    }

    var canAccessDetailedAnalytics: Bool {
        // Detailed analytics is PAID only
        return hasActiveSubscription
    }

    var canAccessMistakeReview: Bool {
        // Mistake review mode is PAID only
        return hasActiveSubscription
    }

    var needsDiagnosticTest: Bool {
        return !diagnosticTestTaken
    }

    var canTakeDiagnosticTest: Bool {
        // Free users get 1 diagnostic test, paid users unlimited
        return hasPurchased || !diagnosticTestTaken
    }

    // MARK: - Public Methods

    /// Record that a practice test was started
    func recordPracticeTestStarted() {
        if !hasPurchased {
            weeklyTestsTaken += 1
            currentTestQuestionCount = 0
            saveUserAccess()
        }
    }

    /// Record that diagnostic test was completed
    func recordDiagnosticTestCompleted() {
        diagnosticTestTaken = true
        saveUserAccess()
    }

    /// Decrement available tests for free users
    func decrementTests() {
        guard !hasActiveSubscription else { return }
        if weeklyTestsTaken < freeTestsPerWeek {
            weeklyTestsTaken += 1
            saveUserAccess()
        }
    }

    /// Unlock full access (called after successful purchase)
    func unlockFullAccess() {
        hasPurchased = true
        saveUserAccess()

        // Track purchase event
        EventTracker.shared.trackPurchaseCompleted()
    }

    /// Restore previous purchase
    func restorePurchase() async throws {
        // This will be called from Settings
        try await StoreKitManager.shared.restorePurchases()
    }

    /// Check and reset weekly limit if needed
    private func checkAndResetWeeklyLimit() {
        let calendar = Calendar.current
        let now = Date()

        // Check if we've crossed into a new week
        if let weeksSince = calendar.dateComponents([.weekOfYear], from: lastWeekResetDate, to: now).weekOfYear,
           weeksSince >= 1 {
            // Reset weekly counter
            weeklyTestsTaken = 0
            lastWeekResetDate = now
            saveUserAccess()
        }
    }

    /// Get days until weekly reset
    func daysUntilWeeklyReset() -> Int {
        let calendar = Calendar.current
        let now = Date()

        guard let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: lastWeekResetDate) else {
            return 7
        }

        let days = calendar.dateComponents([.day], from: now, to: nextWeek).day ?? 7
        return max(0, days)
    }

    /// Reset for testing (only use in debug)
    #if DEBUG
    func resetForTesting() {
        hasPurchased = false
        diagnosticTestTaken = false
        weeklyTestsTaken = 0
        lastWeekResetDate = Date()
        saveUserAccess()
    }
    #endif

    // MARK: - Private Methods

    private func loadUserAccess() {
        let defaults = UserDefaults.standard

        if defaults.object(forKey: hasPurchasedKey) != nil {
            hasPurchased = defaults.bool(forKey: hasPurchasedKey)
        } else if defaults.object(forKey: legacyHasActiveSubscriptionKey) != nil {
            hasPurchased = defaults.bool(forKey: legacyHasActiveSubscriptionKey)
        } else {
            hasPurchased = false
        }
        diagnosticTestTaken = defaults.bool(forKey: diagnosticTestTakenKey)
        if defaults.object(forKey: weeklyTestsTakenKey) != nil {
            weeklyTestsTaken = defaults.integer(forKey: weeklyTestsTakenKey)
        } else if let remaining = defaults.object(forKey: legacyTestsRemainingKey) as? Int {
            weeklyTestsTaken = max(0, freeTestsPerWeek - remaining)
        } else {
            weeklyTestsTaken = 0
        }

        if let savedDate = defaults.object(forKey: lastWeekResetDateKey) as? Date {
            lastWeekResetDate = savedDate
        } else {
            if let legacyDate = defaults.object(forKey: legacyLastResetKey) as? Date {
                lastWeekResetDate = legacyDate
            } else {
                lastWeekResetDate = Date()
            }
        }
    }

    private func saveUserAccess() {
        let defaults = UserDefaults.standard

        defaults.set(hasPurchased, forKey: hasPurchasedKey)
        defaults.set(diagnosticTestTaken, forKey: diagnosticTestTakenKey)
        defaults.set(weeklyTestsTaken, forKey: weeklyTestsTakenKey)
        defaults.set(lastWeekResetDate, forKey: lastWeekResetDateKey)
        defaults.set(hasActiveSubscription, forKey: legacyHasActiveSubscriptionKey)
        defaults.set(max(0, freeTestsPerWeek - weeklyTestsTaken), forKey: legacyTestsRemainingKey)
    }

    @objc private func handleDefaultsChanged(_ notification: Notification) {
        loadUserAccess()
    }
}
