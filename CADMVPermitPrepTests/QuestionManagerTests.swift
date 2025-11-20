import XCTest
@testable import CADMVPermitPrep

final class QuestionManagerTests: XCTestCase {

    var questionManager: QuestionManager!

    override func setUp() {
        super.setUp()
        questionManager = QuestionManager.shared
    }

    override func tearDown() {
        // Don't set singletons to nil - they're shared instances
        super.tearDown()
    }

    // MARK: - JSON Loading Tests

    func testLoadQuestionsFromJSON() {
        XCTAssertFalse(questionManager.allQuestions.isEmpty, "Should load questions from JSON")
        XCTAssertGreaterThan(questionManager.allQuestions.count, 0, "Should have questions loaded")
    }

    func testLoadedQuestionsHaveRequiredFields() {
        guard let firstQuestion = questionManager.allQuestions.first else {
            XCTFail("No questions loaded")
            return
        }

        XCTAssertFalse(firstQuestion.id.isEmpty, "Question should have ID")
        XCTAssertFalse(firstQuestion.questionText.isEmpty, "Question should have text")
        XCTAssertFalse(firstQuestion.correctAnswer.isEmpty, "Question should have correct answer")
        XCTAssertFalse(firstQuestion.category.isEmpty, "Question should have category")
    }

    func testAllQuestionsHaveUniqueIds() {
        let allIds = questionManager.allQuestions.map { $0.id }
        let uniqueIds = Set(allIds)

        XCTAssertEqual(allIds.count, uniqueIds.count, "All question IDs should be unique")
    }

    func testLoadedQuestionsHaveValidCorrectAnswers() {
        let validAnswers = ["A", "B", "C", "D"]

        for question in questionManager.allQuestions {
            XCTAssertTrue(
                validAnswers.contains(question.correctAnswer),
                "Question \(question.id) has invalid correct answer: \(question.correctAnswer)"
            )
        }
    }

    // MARK: - Get All Questions Tests

    func testGetAllQuestions() {
        let questions = questionManager.getAllQuestions()
        XCTAssertEqual(questions.count, questionManager.allQuestions.count)
        XCTAssertFalse(questions.isEmpty)
    }

    // MARK: - Random Questions Tests

    func testGetRandomQuestions() {
        let count = 10
        let randomQuestions = questionManager.getRandomQuestions(count: count)

        XCTAssertEqual(randomQuestions.count, count, "Should return requested number of questions")
    }

    func testGetRandomQuestionsWithCountGreaterThanTotal() {
        let totalQuestions = questionManager.allQuestions.count
        let randomQuestions = questionManager.getRandomQuestions(count: totalQuestions + 100)

        XCTAssertEqual(randomQuestions.count, totalQuestions, "Should return all available questions")
    }

    func testGetRandomQuestionsNoDuplicates() {
        let randomQuestions = questionManager.getRandomQuestions(count: 20)
        let uniqueIds = Set(randomQuestions.map { $0.id })

        XCTAssertEqual(randomQuestions.count, uniqueIds.count, "Random questions should have no duplicates")
    }

    func testGetRandomQuestionsReturnsDifferentOrder() {
        let first = questionManager.getRandomQuestions(count: 10).map { $0.id }
        let second = questionManager.getRandomQuestions(count: 10).map { $0.id }

        // While there's a small chance they could be the same, it's highly unlikely
        XCTAssertNotEqual(first, second, "Random questions should return different order")
    }

    // MARK: - Category Tests

    func testGetCategories() {
        let categories = questionManager.getCategories()

        XCTAssertFalse(categories.isEmpty, "Should have at least one category")
        XCTAssertEqual(categories, categories.sorted(), "Categories should be sorted")

        let uniqueCategories = Set(categories)
        XCTAssertEqual(categories.count, uniqueCategories.count, "Categories should be unique")
    }

    func testGetQuestionsByCategory() {
        let categories = questionManager.getCategories()
        guard let firstCategory = categories.first else {
            XCTFail("No categories found")
            return
        }

        let categoryQuestions = questionManager.getQuestionsByCategory(firstCategory)

        XCTAssertFalse(categoryQuestions.isEmpty, "Should have questions for category")

        for question in categoryQuestions {
            XCTAssertEqual(question.category, firstCategory, "All questions should match category")
        }
    }

    func testGetQuestionsByInvalidCategory() {
        let invalidCategory = "NonExistentCategory12345"
        let questions = questionManager.getQuestionsByCategory(invalidCategory)

        XCTAssertTrue(questions.isEmpty, "Should return empty array for invalid category")
    }

    func testAllCategoriesHaveQuestions() {
        let categories = questionManager.getCategories()

        for category in categories {
            let questions = questionManager.getQuestionsByCategory(category)
            XCTAssertGreaterThan(questions.count, 0, "Category \(category) should have at least one question")
        }
    }

    // MARK: - Adaptive Question Selection Tests

    func testGetAdaptiveQuestionsReturnsRequestedCount() {
        let count = 10
        let adaptiveQuestions = questionManager.getAdaptiveQuestions(count: count)

        XCTAssertEqual(adaptiveQuestions.count, count, "Should return requested number of questions")
    }

    func testGetAdaptiveQuestionsWithZeroCount() {
        let adaptiveQuestions = questionManager.getAdaptiveQuestions(count: 0)

        XCTAssertTrue(adaptiveQuestions.isEmpty, "Should return empty array for zero count")
    }

    func testGetAdaptiveQuestionsWithCountGreaterThanAvailable() {
        let totalQuestions = questionManager.allQuestions.count
        let adaptiveQuestions = questionManager.getAdaptiveQuestions(count: totalQuestions + 100)

        XCTAssertLessThanOrEqual(adaptiveQuestions.count, totalQuestions, "Cannot return more than available")
    }

    func testGetAdaptiveQuestionsNoDuplicates() {
        let adaptiveQuestions = questionManager.getAdaptiveQuestions(count: 20)
        let uniqueIds = Set(adaptiveQuestions.map { $0.id })

        XCTAssertEqual(adaptiveQuestions.count, uniqueIds.count, "Adaptive questions should have no duplicates")
    }

    func testGetAdaptiveQuestionsByCategory() {
        let categories = questionManager.getCategories()
        guard let testCategory = categories.first else {
            XCTFail("No categories found")
            return
        }

        let categoryQuestions = questionManager.getQuestionsByCategory(testCategory)
        let requestCount = min(5, categoryQuestions.count)
        let adaptiveQuestions = questionManager.getAdaptiveQuestions(count: requestCount, category: testCategory)

        XCTAssertEqual(adaptiveQuestions.count, requestCount)

        for question in adaptiveQuestions {
            XCTAssertEqual(question.category, testCategory, "All adaptive questions should match category")
        }
    }

    func testGetAdaptiveQuestionsWithInvalidCategory() {
        let invalidCategory = "NonExistentCategory12345"
        let adaptiveQuestions = questionManager.getAdaptiveQuestions(count: 10, category: invalidCategory)

        XCTAssertTrue(adaptiveQuestions.isEmpty, "Should return empty array for invalid category")
    }

    func testGetAdaptiveQuestionsReturnsShuffledResults() {
        let first = questionManager.getAdaptiveQuestions(count: 10).map { $0.id }
        let second = questionManager.getAdaptiveQuestions(count: 10).map { $0.id }

        // Note: There's a small chance they could be the same, but highly unlikely
        // This tests that the final shuffle is working
        XCTAssertNotEqual(first, second, "Adaptive questions should be shuffled")
    }

    func testGetAdaptiveQuestionsWithEmptyPool() {
        // Test with category that has no questions
        let emptyCategory = "CategoryWithNoQuestions999"
        let questions = questionManager.getAdaptiveQuestions(count: 10, category: emptyCategory)

        XCTAssertTrue(questions.isEmpty, "Should return empty array when pool is empty")
    }

    // MARK: - Adaptive Algorithm Weight Tests

    func testAdaptiveQuestionsIncludesNeverSeenQuestions() {
        // This test verifies that unseen questions can be selected
        // Since we can't control performance data in this test without mocking,
        // we verify the algorithm doesn't crash and returns valid questions
        let adaptiveQuestions = questionManager.getAdaptiveQuestions(count: 20)

        XCTAssertFalse(adaptiveQuestions.isEmpty, "Should return questions")
        XCTAssertGreaterThan(adaptiveQuestions.count, 0, "Should have at least some questions")
    }

    func testAdaptiveQuestionSelectionConsistency() {
        // Test that requesting the same count multiple times doesn't cause errors
        for _ in 1...5 {
            let questions = questionManager.getAdaptiveQuestions(count: 10)
            XCTAssertEqual(questions.count, 10, "Should consistently return requested count")
        }
    }

    // MARK: - Integration Tests

    func testCompleteWorkflow() {
        // Get categories
        let categories = questionManager.getCategories()
        XCTAssertFalse(categories.isEmpty)

        // Get questions by category
        guard let firstCategory = categories.first else {
            XCTFail("No categories found")
            return
        }

        let categoryQuestions = questionManager.getQuestionsByCategory(firstCategory)
        XCTAssertFalse(categoryQuestions.isEmpty)

        // Get adaptive questions for that category
        let count = min(5, categoryQuestions.count)
        let adaptiveQuestions = questionManager.getAdaptiveQuestions(count: count, category: firstCategory)
        XCTAssertEqual(adaptiveQuestions.count, count)

        // Verify all are from the correct category
        for question in adaptiveQuestions {
            XCTAssertEqual(question.category, firstCategory)
        }
    }

    // MARK: - Performance Tests

    func testLoadQuestionsPerformance() {
        measure {
            questionManager.loadQuestions()
        }
    }

    func testGetAdaptiveQuestionsPerformance() {
        measure {
            _ = questionManager.getAdaptiveQuestions(count: 20)
        }
    }

    func testGetRandomQuestionsPerformance() {
        measure {
            _ = questionManager.getRandomQuestions(count: 20)
        }
    }

    func testGetCategoriesPerformance() {
        measure {
            _ = questionManager.getCategories()
        }
    }
}
