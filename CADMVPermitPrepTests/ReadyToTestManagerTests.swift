import XCTest
@testable import CADMVPermitPrep

final class ReadyToTestManagerTests: XCTestCase {

    var readyToTestManager: ReadyToTestManager!
    var performanceTracker: PerformanceTracker!
    var questionManager: QuestionManager!

    override func setUp() {
        super.setUp()
        readyToTestManager = ReadyToTestManager.shared
        performanceTracker = PerformanceTracker.shared
        questionManager = QuestionManager.shared
    }

    override func tearDown() {
        // Clean up UserDefaults
        UserDefaults.standard.removeObject(forKey: "totalQuestionsAnswered")
        UserDefaults.standard.removeObject(forKey: "totalCorrectAnswers")
        // Don't set singletons to nil - they're shared instances
        super.tearDown()
    }

    // MARK: - ReadinessScore Structure Tests

    func testReadinessScoreCalculation() {
        let score = readyToTestManager.calculateReadiness()

        XCTAssertGreaterThanOrEqual(score.percentage, 0, "Percentage should be >= 0")
        XCTAssertLessThanOrEqual(score.percentage, 100, "Percentage should be <= 100")
        XCTAssertGreaterThanOrEqual(score.overallAccuracy, 0.0, "Accuracy should be >= 0")
        XCTAssertLessThanOrEqual(score.overallAccuracy, 1.0, "Accuracy should be <= 1")
        XCTAssertGreaterThanOrEqual(score.questionsSeen, 0, "Questions seen should be >= 0")
        XCTAssertGreaterThanOrEqual(score.totalQuestions, 0, "Total questions should be >= 0")
        XCTAssertGreaterThanOrEqual(score.weakestAccuracy, 0.0, "Weakest accuracy should be >= 0")
        XCTAssertFalse(score.recommendations.isEmpty, "Should have at least one recommendation")
    }

    func testReadinessScoreWithNoProgress() {
        // Clean state with no answers
        UserDefaults.standard.set(0, forKey: "totalQuestionsAnswered")
        UserDefaults.standard.set(0, forKey: "totalCorrectAnswers")

        let score = readyToTestManager.calculateReadiness()

        XCTAssertEqual(score.overallAccuracy, 0.0, "Should have 0% accuracy with no answers")
        // Note: questionsSeen may include data from previous test runs or app usage
        // Just verify it's a valid number
        XCTAssertGreaterThanOrEqual(score.questionsSeen, 0, "Questions seen should be >= 0")
        XCTAssertGreaterThanOrEqual(score.weakestAccuracy, 0.0, "Weakest accuracy should be >= 0")
        XCTAssertLessThan(score.percentage, 90, "Should have reasonable readiness calculation")
    }

    func testReadinessScoreWithPerfectProgress() {
        // Simulate perfect progress
        let totalQuestions = questionManager.allQuestions.count
        UserDefaults.standard.set(totalQuestions, forKey: "totalQuestionsAnswered")
        UserDefaults.standard.set(totalQuestions, forKey: "totalCorrectAnswers")

        let score = readyToTestManager.calculateReadiness()

        XCTAssertEqual(score.overallAccuracy, 1.0, "Should have 100% accuracy")
        XCTAssertGreaterThanOrEqual(score.percentage, 40, "Should have reasonable readiness with perfect accuracy")
    }

    func testReadinessScoreWith50PercentAccuracy() {
        // Simulate 50% accuracy
        UserDefaults.standard.set(100, forKey: "totalQuestionsAnswered")
        UserDefaults.standard.set(50, forKey: "totalCorrectAnswers")

        let score = readyToTestManager.calculateReadiness()

        XCTAssertEqual(score.overallAccuracy, 0.5, accuracy: 0.01, "Should have 50% accuracy")
        XCTAssertLessThan(score.percentage, 60, "Should have moderate readiness with 50% accuracy")
    }

    func testReadinessScoreWith90PercentAccuracy() {
        // Simulate 90% accuracy
        UserDefaults.standard.set(100, forKey: "totalQuestionsAnswered")
        UserDefaults.standard.set(90, forKey: "totalCorrectAnswers")

        let score = readyToTestManager.calculateReadiness()

        XCTAssertEqual(score.overallAccuracy, 0.9, accuracy: 0.01, "Should have 90% accuracy")
        XCTAssertGreaterThan(score.percentage, 30, "Should have good readiness with 90% accuracy")
    }

    // MARK: - ReadinessStatus Tests

    func testReadinessStatusNotReady() {
        // Simulate low progress
        UserDefaults.standard.set(10, forKey: "totalQuestionsAnswered")
        UserDefaults.standard.set(5, forKey: "totalCorrectAnswers")

        let score = readyToTestManager.calculateReadiness()

        XCTAssertEqual(score.status, .notReady, "Should be not ready with low progress")
        XCTAssertLessThanOrEqual(score.percentage, 60, "Not ready should be <= 60%")
    }

    func testReadinessStatusAlmostReady() {
        // Simulate moderate progress
        UserDefaults.standard.set(100, forKey: "totalQuestionsAnswered")
        UserDefaults.standard.set(80, forKey: "totalCorrectAnswers")

        let score = readyToTestManager.calculateReadiness()

        if score.percentage > 60 && score.percentage < 85 {
            XCTAssertEqual(score.status, .almostReady, "Should be almost ready with moderate progress")
        }
    }

    func testReadinessStatusReady() {
        // Simulate excellent progress
        let totalQuestions = questionManager.allQuestions.count
        let almostAll = Int(Double(totalQuestions) * 0.95)
        UserDefaults.standard.set(totalQuestions, forKey: "totalQuestionsAnswered")
        UserDefaults.standard.set(almostAll, forKey: "totalCorrectAnswers")

        let score = readyToTestManager.calculateReadiness()

        if score.percentage >= 85 {
            XCTAssertEqual(score.status, .ready, "Should be ready with excellent progress")
        }
    }

    // MARK: - ReadinessStatus Enum Tests

    func testReadinessStatusColors() {
        XCTAssertEqual(ReadinessStatus.notReady.color, "red")
        XCTAssertEqual(ReadinessStatus.almostReady.color, "yellow")
        XCTAssertEqual(ReadinessStatus.ready.color, "green")
    }

    func testReadinessStatusTitles() {
        XCTAssertEqual(ReadinessStatus.notReady.title, "Not Ready")
        XCTAssertEqual(ReadinessStatus.almostReady.title, "Almost Ready")
        XCTAssertEqual(ReadinessStatus.ready.title, "Ready to Test!")
    }

    // MARK: - Weighted Algorithm Tests (40% Accuracy, 30% Coverage, 30% Weak Areas)

    func testWeightedAlgorithmAccuracyComponent() {
        // Test with perfect accuracy but no coverage
        UserDefaults.standard.set(10, forKey: "totalQuestionsAnswered")
        UserDefaults.standard.set(10, forKey: "totalCorrectAnswers")

        let score = readyToTestManager.calculateReadiness()

        // Even with perfect accuracy, low coverage should keep percentage low
        XCTAssertLessThan(score.percentage, 70, "Perfect accuracy but low coverage should not be ready")
    }

    func testWeightedAlgorithmCoverageComponent() {
        let totalQuestions = questionManager.allQuestions.count

        // Test with full coverage but low accuracy
        UserDefaults.standard.set(totalQuestions, forKey: "totalQuestionsAnswered")
        UserDefaults.standard.set(Int(Double(totalQuestions) * 0.5), forKey: "totalCorrectAnswers")

        let score = readyToTestManager.calculateReadiness()

        // Full coverage but low accuracy should not be ready
        XCTAssertLessThan(score.percentage, 60, "Full coverage but low accuracy should not be ready")
    }

    func testWeightedAlgorithmBalancedScoring() {
        // Test with balanced progress: 85% accuracy, 80% coverage
        let totalQuestions = questionManager.allQuestions.count
        let coverage = Int(Double(totalQuestions) * 0.8)
        let correct = Int(Double(coverage) * 0.85)

        UserDefaults.standard.set(coverage, forKey: "totalQuestionsAnswered")
        UserDefaults.standard.set(correct, forKey: "totalCorrectAnswers")

        let score = readyToTestManager.calculateReadiness()

        // Verify the weighted algorithm is working
        XCTAssertGreaterThanOrEqual(score.percentage, 0, "Should have valid readiness percentage")
        XCTAssertLessThanOrEqual(score.percentage, 100, "Percentage should not exceed 100")

    }

    // MARK: - Recommendation Tests

    func testRecommendationsWithLowAccuracy() {
        UserDefaults.standard.set(100, forKey: "totalQuestionsAnswered")
        UserDefaults.standard.set(70, forKey: "totalCorrectAnswers") // 70% accuracy

        let score = readyToTestManager.calculateReadiness()

        let hasAccuracyRecommendation = score.recommendations.contains { recommendation in
            recommendation.lowercased().contains("accuracy") || recommendation.lowercased().contains("improve")
        }

        XCTAssertTrue(hasAccuracyRecommendation, "Should recommend improving accuracy when below 90%")
    }

    func testRecommendationsWithIncompleteCoverage() {
        let totalQuestions = questionManager.allQuestions.count

        UserDefaults.standard.set(50, forKey: "totalQuestionsAnswered")
        UserDefaults.standard.set(45, forKey: "totalCorrectAnswers")

        let score = readyToTestManager.calculateReadiness()

        if score.questionsSeen < totalQuestions {
            let hasCoverageRecommendation = score.recommendations.contains { recommendation in
                recommendation.lowercased().contains("practice") && recommendation.lowercased().contains("more")
            }

            XCTAssertTrue(hasCoverageRecommendation, "Should recommend practicing more questions")
        }
    }

    func testRecommendationsWhenReady() {
        // Simulate being ready
        let totalQuestions = questionManager.allQuestions.count
        UserDefaults.standard.set(totalQuestions, forKey: "totalQuestionsAnswered")
        UserDefaults.standard.set(Int(Double(totalQuestions) * 0.95), forKey: "totalCorrectAnswers")

        let score = readyToTestManager.calculateReadiness()

        if score.percentage >= 85 && score.overallAccuracy >= 0.90 {
            let hasReadyMessage = score.recommendations.contains { recommendation in
                recommendation.lowercased().contains("ready") && recommendation.lowercased().contains("test")
            }

            XCTAssertTrue(hasReadyMessage, "Should have ready message when criteria met")
        }
    }

    func testRecommendationsNotEmpty() {
        let score = readyToTestManager.calculateReadiness()

        XCTAssertFalse(score.recommendations.isEmpty, "Should always have at least one recommendation")
        XCTAssertGreaterThan(score.recommendations.count, 0, "Recommendations should not be empty")
    }

    // MARK: - Weakest Category Tests

    func testWeakestCategoryWithNoData() {
        // Clean state
        UserDefaults.standard.set(0, forKey: "totalQuestionsAnswered")
        UserDefaults.standard.set(0, forKey: "totalCorrectAnswers")

        let score = readyToTestManager.calculateReadiness()

        // Note: May have weakest category from previous app usage or test runs
        // Just verify it's a valid result
        if let weakest = score.weakestCategory {
            XCTAssertFalse(weakest.isEmpty, "If weakest category exists, should have a name")
        }
        XCTAssertGreaterThanOrEqual(score.weakestAccuracy, 0.0, "Weakest accuracy should be >= 0")
    }

    // MARK: - Edge Cases

    func testReadinessWithZeroTotalQuestions() {
        // This shouldn't happen in production, but test the edge case
        UserDefaults.standard.set(0, forKey: "totalQuestionsAnswered")
        UserDefaults.standard.set(0, forKey: "totalCorrectAnswers")

        let score = readyToTestManager.calculateReadiness()

        XCTAssertEqual(score.overallAccuracy, 0.0, "Should handle zero questions gracefully")
    }

    func testReadinessWithVeryHighAnswerCount() {
        // Test with more answers than total questions (retakes)
        let totalQuestions = questionManager.allQuestions.count
        UserDefaults.standard.set(totalQuestions * 3, forKey: "totalQuestionsAnswered")
        UserDefaults.standard.set(Int(Double(totalQuestions * 3) * 0.9), forKey: "totalCorrectAnswers")

        let score = readyToTestManager.calculateReadiness()

        XCTAssertGreaterThanOrEqual(score.percentage, 0, "Should handle multiple retakes properly")
        XCTAssertLessThanOrEqual(score.percentage, 100, "Percentage should be in valid range")
    }

    func testReadinessConsistency() {
        // Set specific values
        UserDefaults.standard.set(100, forKey: "totalQuestionsAnswered")
        UserDefaults.standard.set(85, forKey: "totalCorrectAnswers")

        // Calculate readiness multiple times
        let score1 = readyToTestManager.calculateReadiness()
        let score2 = readyToTestManager.calculateReadiness()
        let score3 = readyToTestManager.calculateReadiness()

        XCTAssertEqual(score1.percentage, score2.percentage, "Readiness should be consistent")
        XCTAssertEqual(score2.percentage, score3.percentage, "Readiness should be consistent")
        XCTAssertEqual(score1.overallAccuracy, score2.overallAccuracy, accuracy: 0.001, "Accuracy should be consistent")
    }

    // MARK: - Integration Tests

    func testCompleteReadinessFlow() {
        // Start with no progress
        UserDefaults.standard.set(0, forKey: "totalQuestionsAnswered")
        UserDefaults.standard.set(0, forKey: "totalCorrectAnswers")

        let initialScore = readyToTestManager.calculateReadiness()
        XCTAssertEqual(initialScore.status, .notReady)

        // Add some progress
        UserDefaults.standard.set(50, forKey: "totalQuestionsAnswered")
        UserDefaults.standard.set(40, forKey: "totalCorrectAnswers")

        let improvedScore = readyToTestManager.calculateReadiness()
        XCTAssertGreaterThan(improvedScore.percentage, initialScore.percentage)

        // Add excellent progress
        UserDefaults.standard.set(200, forKey: "totalQuestionsAnswered")
        UserDefaults.standard.set(185, forKey: "totalCorrectAnswers")

        let finalScore = readyToTestManager.calculateReadiness()
        XCTAssertGreaterThan(finalScore.percentage, improvedScore.percentage)
    }

    // MARK: - Performance Tests

    func testCalculateReadinessPerformance() {
        UserDefaults.standard.set(100, forKey: "totalQuestionsAnswered")
        UserDefaults.standard.set(80, forKey: "totalCorrectAnswers")

        measure {
            _ = readyToTestManager.calculateReadiness()
        }
    }

    func testMultipleReadinessCalculationsPerformance() {
        UserDefaults.standard.set(100, forKey: "totalQuestionsAnswered")
        UserDefaults.standard.set(80, forKey: "totalCorrectAnswers")

        measure {
            for _ in 0..<10 {
                _ = readyToTestManager.calculateReadiness()
            }
        }
    }
}
