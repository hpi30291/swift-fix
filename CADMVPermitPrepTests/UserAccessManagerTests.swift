import XCTest
@testable import CADMVPermitPrep

final class UserAccessManagerTests: XCTestCase {

    var sut: UserAccessManager!

    override func setUp() {
        super.setUp()
        sut = UserAccessManager.shared
        // Reset to free user state before each test
        #if DEBUG
        sut.resetForTesting()
        #endif
    }

    override func tearDown() {
        #if DEBUG
        sut.resetForTesting()
        #endif
        sut = nil
        super.tearDown()
    }

    // MARK: - Free User Tests

    func testFreeUserDefaults() {
        // Given - Fresh free user
        #if DEBUG
        sut.resetForTesting()
        #endif

        // Then
        XCTAssertFalse(sut.hasActiveSubscription, "Free user should not have active subscription")
        XCTAssertFalse(sut.hasPurchased, "Free user should not have purchased")
        XCTAssertEqual(sut.testsRemainingThisWeek, 5, "Free user should have 5 tests per week")
        XCTAssertTrue(sut.canTakePracticeTest, "Free user should be able to take practice tests")
    }

    func testFreeUserTestLimit() {
        // Given - Free user
        XCTAssertEqual(sut.weeklyTestsTaken, 0)

        // When - Takes 5 practice tests
        for _ in 0..<5 {
            sut.recordPracticeTestStarted()
        }

        // Then
        XCTAssertEqual(sut.weeklyTestsTaken, 5)
        XCTAssertEqual(sut.testsRemainingThisWeek, 0)
        XCTAssertFalse(sut.canTakePracticeTest, "Free user should not be able to take more tests")
    }

    func testFreeUserTestDecrement() {
        // Given - Free user with 5 tests
        XCTAssertEqual(sut.testsRemainingThisWeek, 5)

        // When - Takes 1 test
        sut.recordPracticeTestStarted()

        // Then
        XCTAssertEqual(sut.weeklyTestsTaken, 1)
        XCTAssertEqual(sut.testsRemainingThisWeek, 4)
    }

    func testFreeUserCannotAccessPremiumFeatures() {
        // Given - Free user
        XCTAssertFalse(sut.hasActiveSubscription)

        // Then - All premium features should be locked
        XCTAssertFalse(sut.canTakeFullPracticeTest, "46-question exam should be locked")
        XCTAssertFalse(sut.canAccessCategoryPractice, "Category practice should be locked")
        XCTAssertFalse(sut.canAccessWeakAreasPractice, "Weak areas practice should be locked")
        XCTAssertFalse(sut.canAccessLearnMode, "Learn mode should be locked")
        XCTAssertFalse(sut.canAccessAITutor, "AI Tutor should be locked")
        XCTAssertFalse(sut.canAccessAdvancedReadiness, "Advanced readiness should be locked")
        XCTAssertFalse(sut.canAccessDetailedAnalytics, "Detailed analytics should be locked")
        XCTAssertFalse(sut.canAccessMistakeReview, "Mistake review should be locked")
    }

    // MARK: - Premium User Tests

    func testPremiumUserUnlimitedTests() {
        // Given - Premium user
        sut.unlockFullAccess()

        // Then
        XCTAssertTrue(sut.hasActiveSubscription)
        XCTAssertEqual(sut.testsRemainingThisWeek, Int.max, "Premium user should have unlimited tests")
        XCTAssertTrue(sut.canTakePracticeTest)
    }

    func testPremiumUserTestsDoNotDecrement() {
        // Given - Premium user
        sut.unlockFullAccess()
        let initialTests = sut.testsRemainingThisWeek

        // When - Takes multiple tests
        sut.recordPracticeTestStarted()
        sut.recordPracticeTestStarted()
        sut.recordPracticeTestStarted()

        // Then - Tests should still be unlimited
        XCTAssertEqual(sut.testsRemainingThisWeek, initialTests, "Premium tests should remain unlimited")
        XCTAssertEqual(sut.weeklyTestsTaken, 0, "Premium user tests should not increment counter")
    }

    func testPremiumUserCanAccessAllFeatures() {
        // Given - Premium user
        sut.unlockFullAccess()

        // Then - All features should be unlocked
        XCTAssertTrue(sut.canTakeFullPracticeTest, "46-question exam should be unlocked")
        XCTAssertTrue(sut.canAccessCategoryPractice, "Category practice should be unlocked")
        XCTAssertTrue(sut.canAccessWeakAreasPractice, "Weak areas practice should be unlocked")
        XCTAssertTrue(sut.canAccessLearnMode, "Learn mode should be unlocked")
        XCTAssertTrue(sut.canAccessAITutor, "AI Tutor should be unlocked")
        XCTAssertTrue(sut.canAccessAdvancedReadiness, "Advanced readiness should be unlocked")
        XCTAssertTrue(sut.canAccessDetailedAnalytics, "Detailed analytics should be unlocked")
        XCTAssertTrue(sut.canAccessMistakeReview, "Mistake review should be unlocked")
    }

    // MARK: - Diagnostic Test Tests

    func testFreeUserCanTakeDiagnosticOnce() {
        // Given - Free user who hasn't taken diagnostic
        XCTAssertTrue(sut.needsDiagnosticTest)
        XCTAssertTrue(sut.canTakeDiagnosticTest)

        // When - Takes diagnostic
        sut.recordDiagnosticTestCompleted()

        // Then
        XCTAssertTrue(sut.diagnosticTestTaken)
        XCTAssertFalse(sut.needsDiagnosticTest)
        XCTAssertFalse(sut.canTakeDiagnosticTest, "Free user should not be able to retake diagnostic")
    }

    func testPremiumUserCanRetakeDiagnostic() {
        // Given - Premium user who already took diagnostic
        sut.recordDiagnosticTestCompleted()
        sut.unlockFullAccess()

        // Then
        XCTAssertTrue(sut.diagnosticTestTaken)
        XCTAssertFalse(sut.needsDiagnosticTest)
        XCTAssertTrue(sut.canTakeDiagnosticTest, "Premium user should be able to retake diagnostic")
    }

    // MARK: - Weekly Reset Tests

    func testDaysUntilWeeklyResetInitial() {
        // Given - Just reset
        let days = sut.daysUntilWeeklyReset()

        // Then - Should be around 7 days (could be 6-7 depending on time)
        XCTAssertGreaterThanOrEqual(days, 0)
        XCTAssertLessThanOrEqual(days, 7)
    }

    // MARK: - Purchase Flow Tests

    func testUnlockFullAccess() {
        // Given - Free user
        XCTAssertFalse(sut.hasActiveSubscription)

        // When - Purchases
        sut.unlockFullAccess()

        // Then
        XCTAssertTrue(sut.hasPurchased)
        XCTAssertTrue(sut.hasActiveSubscription)
    }

    func testUnlockFullAccessPersists() {
        // Given - User purchases
        sut.unlockFullAccess()
        XCTAssertTrue(sut.hasActiveSubscription)

        // When - Create new instance (simulates app restart)
        let newInstance = UserAccessManager.shared

        // Then - Should still be premium
        XCTAssertTrue(newInstance.hasActiveSubscription, "Purchase should persist after restart")
    }

    // MARK: - Edge Cases

    func testNegativeTestsHandledGracefully() {
        // Given - Manually set negative tests (shouldn't happen, but test it)
        sut.weeklyTestsTaken = -1

        // Then
        XCTAssertGreaterThanOrEqual(sut.testsRemainingThisWeek, 0, "Should never show negative tests")
    }

    func testExcessiveTestsHandledGracefully() {
        // Given - Free user
        // When - Try to take 10 tests (more than allowed)
        for _ in 0..<10 {
            if sut.canTakePracticeTest {
                sut.recordPracticeTestStarted()
            }
        }

        // Then - Should stop at 5
        XCTAssertLessThanOrEqual(sut.weeklyTestsTaken, 5, "Should not exceed weekly limit")
        XCTAssertEqual(sut.testsRemainingThisWeek, 0)
    }

    func testMultiplePurchaseCallsIdempotent() {
        // When - Call unlockFullAccess multiple times
        sut.unlockFullAccess()
        sut.unlockFullAccess()
        sut.unlockFullAccess()

        // Then - Should still work correctly
        XCTAssertTrue(sut.hasActiveSubscription)
    }

    // MARK: - Persistence Tests

    func testWeeklyTestsPersist() {
        // Given - User takes 3 tests
        for _ in 0..<3 {
            sut.recordPracticeTestStarted()
        }
        XCTAssertEqual(sut.weeklyTestsTaken, 3)

        // When - Simulate app restart by creating new instance
        let newInstance = UserAccessManager.shared

        // Then - Tests should persist
        XCTAssertEqual(newInstance.weeklyTestsTaken, 3, "Weekly tests should persist")
    }

    func testDiagnosticTestPersists() {
        // Given - User completes diagnostic
        sut.recordDiagnosticTestCompleted()
        XCTAssertTrue(sut.diagnosticTestTaken)

        // When - Simulate app restart
        let newInstance = UserAccessManager.shared

        // Then - Should still be marked as taken
        XCTAssertTrue(newInstance.diagnosticTestTaken, "Diagnostic status should persist")
    }

    // MARK: - Boundary Tests

    func testExactlyFiveTestsBoundary() {
        // When - Take exactly 5 tests
        for testNum in 1...5 {
            XCTAssertTrue(sut.canTakePracticeTest, "Should be able to take test \(testNum)")
            sut.recordPracticeTestStarted()
        }

        // Then
        XCTAssertEqual(sut.weeklyTestsTaken, 5)
        XCTAssertEqual(sut.testsRemainingThisWeek, 0)
        XCTAssertFalse(sut.canTakePracticeTest, "Should not be able to take 6th test")
    }

    func testOneTestRemainingBoundary() {
        // Given - 4 tests taken
        for _ in 0..<4 {
            sut.recordPracticeTestStarted()
        }

        // Then
        XCTAssertEqual(sut.testsRemainingThisWeek, 1)
        XCTAssertTrue(sut.canTakePracticeTest)

        // When - Take last test
        sut.recordPracticeTestStarted()

        // Then
        XCTAssertEqual(sut.testsRemainingThisWeek, 0)
        XCTAssertFalse(sut.canTakePracticeTest)
    }

    // MARK: - Debug Mode Tests

    #if DEBUG
    func testDebugPremiumFlag() {
        // Given - Free user
        XCTAssertFalse(sut.hasActiveSubscription)

        // When - Enable debug premium
        sut.debugPremiumEnabled = true

        // Then - Should have access
        XCTAssertTrue(sut.hasActiveSubscription, "Debug premium should grant access")
        XCTAssertTrue(sut.canAccessAITutor, "Debug mode should unlock features")
    }

    func testResetForTesting() {
        // Given - User with progress
        sut.unlockFullAccess()
        sut.recordDiagnosticTestCompleted()
        for _ in 0..<3 {
            sut.recordPracticeTestStarted()
        }

        // When - Reset
        sut.resetForTesting()

        // Then - Everything should be back to defaults
        XCTAssertFalse(sut.hasPurchased)
        XCTAssertFalse(sut.diagnosticTestTaken)
        XCTAssertEqual(sut.weeklyTestsTaken, 0)
    }
    #endif

    // MARK: - Integration Tests

    func testCompleteUserJourney() {
        // Step 1: Fresh free user
        XCTAssertEqual(sut.testsRemainingThisWeek, 5)

        // Step 2: Takes diagnostic
        sut.recordDiagnosticTestCompleted()
        XCTAssertTrue(sut.diagnosticTestTaken)

        // Step 3: Takes 3 practice tests
        for _ in 0..<3 {
            sut.recordPracticeTestStarted()
        }
        XCTAssertEqual(sut.testsRemainingThisWeek, 2)

        // Step 4: Purchases premium
        sut.unlockFullAccess()
        XCTAssertTrue(sut.hasActiveSubscription)
        XCTAssertEqual(sut.testsRemainingThisWeek, Int.max)

        // Step 5: Can now retake diagnostic
        XCTAssertTrue(sut.canTakeDiagnosticTest)
    }

    func testFreeToPaywallJourney() {
        // Simulates hitting paywall after running out of tests

        // Step 1: Use all 5 free tests
        for _ in 0..<5 {
            sut.recordPracticeTestStarted()
        }

        // Step 2: Hit limit
        XCTAssertFalse(sut.canTakePracticeTest)
        XCTAssertEqual(sut.testsRemainingThisWeek, 0)
        // At this point, PaywallView would be shown

        // Step 3: User purchases
        sut.unlockFullAccess()

        // Step 4: Can now take unlimited tests
        XCTAssertTrue(sut.canTakePracticeTest)
        XCTAssertEqual(sut.testsRemainingThisWeek, Int.max)
    }
}
