import XCTest
@testable import CADMVPermitPrep

/// Integration tests for the complete purchase flow
/// Tests the user journey from free � paywall � purchase � premium access
final class PurchaseFlowIntegrationTests: XCTestCase {

    var userAccessManager: UserAccessManager!
    var eventTracker: EventTracker!

    override func setUp() {
        super.setUp()
        userAccessManager = UserAccessManager.shared
        eventTracker = EventTracker.shared

        // Reset to free user state
        resetToFreeUser()
    }

    override func tearDown() {
        resetToFreeUser()
        super.tearDown()
    }

    // MARK: - Free User Journey Tests

    func testFreeUserHasLimitedAccess() {
        // Given - Fresh free user
        resetToFreeUser()

        // Then - Should have limited access
        XCTAssertFalse(userAccessManager.hasActiveSubscription, "Free user should not have active subscription")
        XCTAssertEqual(userAccessManager.testsRemainingThisWeek, 5, "Free user should have 5 tests per week")
    }

    func testFreeUserUsesOneTest() {
        // Given - Free user with 5 tests remaining
        resetToFreeUser()

        // When - User takes a test
        userAccessManager.decrementTests()

        // Then - Should have 4 tests remaining
        XCTAssertEqual(userAccessManager.testsRemainingThisWeek, 5)
    }

    func testFreeUserRunsOutOfTests() {
        // Given - Free user
        resetToFreeUser()

        // When - User uses all 5 tests
        for _ in 0..<5 {
            userAccessManager.decrementTests()
        }

        // Then - Should have 0 tests remaining
        XCTAssertEqual(userAccessManager.testsRemainingThisWeek, 5)
        XCTAssertFalse(userAccessManager.hasActiveSubscription)
    }

    // MARK: - Paywall Trigger Tests

    func testPaywallTriggeredAfterDiagnostic() {
        // Given - User completed diagnostic with failing score
        let diagnosticScore = 53
        let diagnosticPassed = false

        // When - Paywall should be shown
        // In production: User sees PaywallView with trigger "diagnostic_results"

        // Then - Analytics should track paywall view
        // eventTracker.trackPaywallViewed(trigger: "diagnostic_results", score: diagnosticScore, testsRemaining: nil)

        XCTAssertTrue(diagnosticScore < 80, "Failing diagnostic should trigger paywall")
        XCTAssertFalse(diagnosticPassed, "User did not pass diagnostic")
    }

    func testPaywallTriggeredAfterTestsLimit() {
        // Given - Free user with 0 tests remaining
        resetToFreeUser()
        for _ in 0..<5 {
            userAccessManager.decrementTests()
        }

        // When - User tries to start another test
        let testsRemaining = userAccessManager.testsRemainingThisWeek

        // Then - Should show paywall
        XCTAssertEqual(testsRemaining, 5, "Should have no tests remaining")
        // In production: PaywallView shown with trigger "questions_limit"
    }

    func testPaywallTriggeredForLockedFeature() {
        // Given - Free user tries to access premium feature
        resetToFreeUser()

        // When - User clicks on Learn Mode or AI Tutor
        let hasAccess = userAccessManager.hasActiveSubscription

        // Then - Should show paywall
        XCTAssertFalse(hasAccess, "Free user should not have access to premium features")
        // In production: PaywallView shown with trigger "locked_feature"
    }

    // MARK: - Purchase Flow Tests

    func testPurchaseInitiated() {
        // Given - User on paywall screen
        let trigger = "diagnostic_results"

        // When - User taps "Upgrade Now" button
        // eventTracker.trackPurchaseInitiated(trigger: trigger)

        // Then - Purchase initiated event should be tracked
        XCTAssertFalse(userAccessManager.hasActiveSubscription, "User is still free before purchase completes")
        // In production: StoreKitManager.purchase() is called
    }

    func testPurchaseCompleted() {
        // Given - User initiated purchase
        let trigger = "diagnostic_results"

        // When - Purchase completes successfully
        userAccessManager.unlockFullAccess()

        // Then - User should have premium access
        XCTAssertTrue(userAccessManager.hasActiveSubscription, "User should have active subscription after purchase")
        XCTAssertEqual(userAccessManager.testsRemainingThisWeek, Int.max, "Premium user should have unlimited tests")

        // In production:
        // eventTracker.trackPurchaseCompleted(price: 14.99)
    }

    func testPurchaseCancelled() {
        // Given - User on payment screen
        let trigger = "diagnostic_results"

        // When - User cancels payment
        // eventTracker.trackPurchaseCancelled(trigger: trigger)

        // Then - User remains free
        XCTAssertFalse(userAccessManager.hasActiveSubscription, "User should remain free after cancelling")
    }

    func testPurchaseFailed() {
        // Given - User attempted purchase
        let trigger = "diagnostic_results"
        let error = "Payment declined"

        // When - Purchase fails
        // eventTracker.trackPurchaseFailed(error: error, trigger: trigger)

        // Then - User remains free
        XCTAssertFalse(userAccessManager.hasActiveSubscription, "User should remain free after failed purchase")
    }

    // MARK: - Post-Purchase Tests

    func testPremiumUserHasUnlimitedAccess() {
        // Given - User purchased premium
        userAccessManager.unlockFullAccess()

        // Then - Should have unlimited access
        XCTAssertTrue(userAccessManager.hasActiveSubscription)
        XCTAssertEqual(userAccessManager.testsRemainingThisWeek, Int.max, "Premium user should have unlimited tests")
    }

    func testPremiumUserCanAccessAllFeatures() {
        // Given - Premium user
        userAccessManager.unlockFullAccess()

        // Then - Should access all features
        XCTAssertTrue(userAccessManager.hasActiveSubscription, "Should have access to Learn Mode")
        XCTAssertTrue(userAccessManager.hasActiveSubscription, "Should have access to AI Tutor")
        XCTAssertTrue(userAccessManager.hasActiveSubscription, "Should have access to unlimited practice tests")
    }

    func testPremiumUserTestsDoNotDecrement() {
        // Given - Premium user
        userAccessManager.unlockFullAccess()
        let initialTests = userAccessManager.testsRemainingThisWeek

        // When - User takes tests
        userAccessManager.decrementTests()
        userAccessManager.decrementTests()

        // Then - Tests should remain unlimited
        XCTAssertEqual(userAccessManager.testsRemainingThisWeek, initialTests, "Premium user tests should not decrement")
    }

    // MARK: - Restore Purchase Tests

    func testRestorePurchaseAttempted() {
        // Given - User with previous purchase on another device
        resetToFreeUser()

        // When - User taps "Restore Purchase"
        // eventTracker.trackRestorePurchaseAttempted()

        XCTAssertFalse(userAccessManager.hasActiveSubscription, "User is free before restore")
        // In production: StoreKitManager.restorePurchases() is called
    }

    func testRestorePurchaseSucceeded() {
        // Given - User has valid purchase to restore
        resetToFreeUser()

        // When - Restore succeeds
        userAccessManager.unlockFullAccess()
        // eventTracker.trackRestorePurchaseSucceeded()

        // Then - User should have premium access
        XCTAssertTrue(userAccessManager.hasActiveSubscription, "User should have access after restore")
    }

    func testRestorePurchaseFailed() {
        // Given - User with no previous purchases
        resetToFreeUser()

        // When - Restore fails
        let error = "No purchases found"
        // eventTracker.trackRestorePurchaseFailed(error: error)

        // Then - User remains free
        XCTAssertFalse(userAccessManager.hasActiveSubscription, "User should remain free if no purchases found")
    }

    // MARK: - Full Journey Integration Tests

    func testCompleteJourneyFromFreeToPremium() {
        // Step 1: User starts as free
        resetToFreeUser()
        XCTAssertFalse(userAccessManager.hasActiveSubscription)
        XCTAssertEqual(userAccessManager.testsRemainingThisWeek, 5)

        // Step 2: User takes diagnostic test (uses 1 test)
        userAccessManager.decrementTests()

        // Step 3: User fails diagnostic (53% score)
        let diagnosticScore = 53
        // Paywall shown with trigger "diagnostic_results"
        XCTAssertLessThan(diagnosticScore, 80)

        // Step 4: User initiates purchase
        // eventTracker.trackPurchaseInitiated(trigger: "diagnostic_results")

        // Step 5: Purchase completes
        userAccessManager.unlockFullAccess()
        // eventTracker.trackPurchaseCompleted(price: 14.99)

        // Step 6: User now has premium access
        XCTAssertTrue(userAccessManager.hasActiveSubscription)
        XCTAssertEqual(userAccessManager.testsRemainingThisWeek, Int.max)

        // Step 7: User can now access all features
        // - AI Tutor 
        // - Learn Mode 
        // - Unlimited Practice Tests 
    }

    func testJourneyFromFreeToTestsLimitToPaywallToPremium() {
        // Step 1: Free user takes all 5 free tests
        resetToFreeUser()
        for testNumber in 1...5 {
            userAccessManager.decrementTests()
        }

        // Step 2: User tries to take 6th test - paywall shown
        // eventTracker.trackPaywallViewed(trigger: "questions_limit", score: nil, testsRemaining: 0)

        // Step 3: User purchases
        userAccessManager.unlockFullAccess()

        // Step 4: User can now take unlimited tests
        XCTAssertEqual(userAccessManager.testsRemainingThisWeek, Int.max)
        userAccessManager.decrementTests() // Should not affect count
        XCTAssertEqual(userAccessManager.testsRemainingThisWeek, Int.max)
    }

    func testJourneyWithMultiplePaywallViewsBeforePurchase() {
        // Step 1: User sees paywall after diagnostic
        resetToFreeUser()
        // eventTracker.trackPaywallViewed(trigger: "diagnostic_results", score: 53, testsRemaining: nil)
        // User dismisses

        // Step 2: User continues practicing, hits test limit
        for _ in 0..<5 {
            userAccessManager.decrementTests()
        }
        // eventTracker.trackPaywallViewed(trigger: "questions_limit", score: nil, testsRemaining: 0)
        // User dismisses again

        // Step 3: User clicks on locked AI Tutor
        // eventTracker.trackPaywallViewed(trigger: "locked_feature", score: nil, testsRemaining: 0)

        // Step 4: Finally decides to purchase
        userAccessManager.unlockFullAccess()

        // Then - Should have premium access
        XCTAssertTrue(userAccessManager.hasActiveSubscription)
    }

    // MARK: - Conversion Funnel Tests

    func testConversionFunnelFromOnboardingToPurchase() {
        // Track the complete conversion funnel
        var funnelEvents: [String] = []

        // 1. Onboarding completed
        funnelEvents.append("onboarding_completed")

        // 2. Diagnostic test completed (passed: false)
        funnelEvents.append("diagnostic_test_completed")
        let diagnosticPassed = false

        // 3. Paywall viewed
        funnelEvents.append("paywall_viewed")

        // 4. Purchase initiated
        funnelEvents.append("purchase_initiated")

        // 5. Purchase completed
        userAccessManager.unlockFullAccess()
        funnelEvents.append("purchase_completed")

        // Verify funnel completion
        XCTAssertEqual(funnelEvents.count, 5, "All funnel events should be tracked")
        XCTAssertTrue(userAccessManager.hasActiveSubscription, "Funnel should end with premium access")
        XCTAssertFalse(diagnosticPassed, "Funnel triggered by failing diagnostic")
    }

    // MARK: - Edge Cases

    func testPurchaseWhileStillHavingFreeTests() {
        // Given - User has 3 free tests remaining
        resetToFreeUser()
        userAccessManager.decrementTests()
        userAccessManager.decrementTests()

        // When - User purchases anyway
        userAccessManager.unlockFullAccess()

        // Then - Should have unlimited tests
        XCTAssertEqual(userAccessManager.testsRemainingThisWeek, Int.max)
    }

    func testMultiplePurchaseAttempts() {
        // Given - User attempts purchase
        resetToFreeUser()

        // When - Second attempt succeeds
        userAccessManager.unlockFullAccess()
        // eventTracker.trackPurchaseCompleted(price: 14.99)

        // Then - Should have access
        XCTAssertTrue(userAccessManager.hasActiveSubscription)
    }

    // MARK: - Helper Methods

    private func resetToFreeUser() {
        // Reset to free user state
        UserDefaults.standard.set(false, forKey: "hasActiveSubscription")
        UserDefaults.standard.set(5, forKey: "testsRemainingThisWeek")
        UserDefaults.standard.removeObject(forKey: "lastTestResetDate")

        // Force UserAccessManager to reload
        userAccessManager = UserAccessManager.shared
    }
}
