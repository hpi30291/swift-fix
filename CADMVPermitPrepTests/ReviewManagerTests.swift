import XCTest
@testable import CADMVPermitPrep

@MainActor
final class ReviewManagerTests: XCTestCase {

    var sut: ReviewManager!

    override func setUp() {
        super.setUp()
        sut = ReviewManager.shared
        // Reset state before each test
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

    // MARK: - Significant Events Tests

    func testSignificantEventsCounterIncrementsCorrectly() {
        // Given
        let initialCount = sut.getSignificantEventsCount()

        // When
        sut.requestReviewIfAppropriate(after: .completedDiagnostic)

        // Then
        XCTAssertEqual(sut.getSignificantEventsCount(), initialCount + 1)
    }

    func testDoesNotRequestReviewBeforeEnoughSignificantEvents() {
        // Given - Need 5 events, only trigger 4
        for _ in 0..<4 {
            sut.requestReviewIfAppropriate(after: .dailyGoalCompleted)
        }

        // Then - Should not have requested review yet
        let lastRequestDate = UserDefaults.standard.object(forKey: "lastReviewRequestDate") as? Date
        XCTAssertNil(lastRequestDate, "Should not request review before 5 significant events")
    }

    func testRequestsReviewAfterEnoughSignificantEvents() {
        // Given - Need 5 events
        for _ in 0..<5 {
            sut.requestReviewIfAppropriate(after: .dailyGoalCompleted)
        }

        // Then - Should have requested review
        let lastRequestDate = UserDefaults.standard.object(forKey: "lastReviewRequestDate") as? Date
        XCTAssertNotNil(lastRequestDate, "Should request review after 5 significant events")
    }

    // MARK: - Timing Tests

    func testDoesNotRequestReviewTooSoon() {
        // Given - Just requested a review
        sut.requestReviewIfAppropriate(after: .completedDiagnostic)
        sut.requestReviewIfAppropriate(after: .dailyGoalCompleted)
        sut.requestReviewIfAppropriate(after: .weekStreakReached)
        sut.requestReviewIfAppropriate(after: .highAccuracyQuiz)
        sut.requestReviewIfAppropriate(after: .achievementUnlocked)

        let firstRequestDate = UserDefaults.standard.object(forKey: "lastReviewRequestDate") as? Date
        let firstRequestCount = UserDefaults.standard.integer(forKey: "reviewRequestCount")

        // When - Try to request again immediately with 5 more events
        for _ in 0..<5 {
            sut.requestReviewIfAppropriate(after: .dailyGoalCompleted)
        }

        let secondRequestDate = UserDefaults.standard.object(forKey: "lastReviewRequestDate") as? Date
        let secondRequestCount = UserDefaults.standard.integer(forKey: "reviewRequestCount")

        // Then - Should not have requested again (same dates/counts)
        XCTAssertEqual(firstRequestDate, secondRequestDate)
        XCTAssertEqual(firstRequestCount, secondRequestCount)
    }

    func testResetsSignificantEventsCounterAfterRequest() {
        // Given - 5 events to trigger review
        for _ in 0..<5 {
            sut.requestReviewIfAppropriate(after: .dailyGoalCompleted)
        }

        // Then - Counter should be reset to 0
        XCTAssertEqual(sut.getSignificantEventsCount(), 0)
    }

    // MARK: - Max Requests Tests

    func testDoesNotExceedMaxRequestsPerYear() {
        // Given - Max 3 requests per year
        // Simulate 3 requests (with enough events each time)

        for requestNum in 1...4 {
            // Accumulate 5 events
            for _ in 0..<5 {
                sut.requestReviewIfAppropriate(after: .dailyGoalCompleted)
            }

            // Manually reset the last request date to allow next request
            // (simulating 90+ days passing)
            if requestNum < 4 {
                let pastDate = Calendar.current.date(byAdding: .day, value: -91, to: Date())!
                UserDefaults.standard.set(pastDate, forKey: "lastReviewRequestDate")
            }
        }

        let requestCount = UserDefaults.standard.integer(forKey: "reviewRequestCount")

        // Then - Should not exceed 3 requests
        XCTAssertLessThanOrEqual(requestCount, 3)
    }

    // MARK: - Different Event Types Tests

    func testAcceptsDifferentSignificantEventTypes() {
        // Given
        let events: [ReviewManager.SignificantEvent] = [
            .completedDiagnostic,
            .firstQuizPassed,
            .dailyGoalCompleted,
            .weekStreakReached,
            .achievementUnlocked
        ]

        // When
        for event in events {
            sut.requestReviewIfAppropriate(after: event)
        }

        // Then - Should have tracked all events
        XCTAssertEqual(sut.getSignificantEventsCount(), 0) // Reset after request
        let lastRequestDate = UserDefaults.standard.object(forKey: "lastReviewRequestDate") as? Date
        XCTAssertNotNil(lastRequestDate)
    }

    // MARK: - Manual Request Tests

    func testManualReviewRequestWorks() {
        // When
        sut.manualReviewRequest()

        // Then - Should have requested review (updates date)
        let lastRequestDate = UserDefaults.standard.object(forKey: "lastReviewRequestDate") as? Date
        XCTAssertNotNil(lastRequestDate)
    }

    // MARK: - Helper Method Tests

    func testHasReviewedRecentlyReturnsTrueWhenRecent() {
        // Given - Just requested review
        for _ in 0..<5 {
            sut.requestReviewIfAppropriate(after: .dailyGoalCompleted)
        }

        // Then
        XCTAssertTrue(sut.hasReviewedRecently())
    }

    func testHasReviewedRecentlyReturnsFalseWhenOld() {
        // Given - Requested review 100 days ago
        let pastDate = Calendar.current.date(byAdding: .day, value: -100, to: Date())!
        UserDefaults.standard.set(pastDate, forKey: "lastReviewRequestDate")

        // Then
        XCTAssertFalse(sut.hasReviewedRecently())
    }

    // MARK: - Debug Info Tests

    #if DEBUG
    func testDebugInfoReturnsValidString() {
        // When
        let debugInfo = sut.debugInfo()

        // Then
        XCTAssertTrue(debugInfo.contains("ReviewManager Debug Info"))
        XCTAssertTrue(debugInfo.contains("Last request"))
        XCTAssertTrue(debugInfo.contains("Request count"))
        XCTAssertTrue(debugInfo.contains("Significant events"))
    }
    #endif
}

// MARK: - Helper Extension for Testing

private extension ReviewManager {
    func getSignificantEventsCount() -> Int {
        return UserDefaults.standard.integer(forKey: "significantEventsCount")
    }

    func hasReviewedRecently() -> Bool {
        guard let lastDate = UserDefaults.standard.object(forKey: "lastReviewRequestDate") as? Date else {
            return false
        }

        let daysSince = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        return daysSince < 90
    }
}
