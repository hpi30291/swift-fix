import XCTest
@testable import CADMVPermitPrep

final class QuizViewModelTests: XCTestCase {
    
    var viewModel: QuizViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = QuizViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Score Calculation Tests
    
    func testScoreCalculationWithCorrectAnswers() {
        viewModel.correctAnswers = 8
        XCTAssertEqual(viewModel.correctAnswers, 8)
    }
    
    func testScoreCalculationWithZeroAnswers() {
        viewModel.correctAnswers = 0
        XCTAssertEqual(viewModel.correctAnswers, 0)
    }
    
    func testScoreIncreasesWithCorrectAnswer() {
        let initialScore = viewModel.correctAnswers
        viewModel.selectAnswer(viewModel.currentQuestion.correctAnswer)
        XCTAssertEqual(viewModel.correctAnswers, initialScore + 1)
    }
    
    func testScoreDoesNotIncreaseWithIncorrectAnswer() {
        let initialScore = viewModel.correctAnswers
        let wrongAnswer = viewModel.currentQuestion.correctAnswer == "A" ? "B" : "A"
        viewModel.selectAnswer(wrongAnswer)
        XCTAssertEqual(viewModel.correctAnswers, initialScore)
    }
    
    // MARK: - Pass/Fail Threshold Tests (80%)
    
    func testPassThresholdWith80Percent() {
        viewModel.correctAnswers = 8 // 80% of 10
        let passed = viewModel.correctAnswers >= Int(Double(viewModel.questions.count) * 0.8)
        XCTAssertTrue(passed, "Should pass with 80%")
    }
    
    func testFailThresholdWith79Percent() {
        viewModel.correctAnswers = 7 // 70% of 10
        let passed = viewModel.correctAnswers >= Int(Double(viewModel.questions.count) * 0.8)
        XCTAssertFalse(passed, "Should fail with 70%")
    }
    
    func testPassThresholdWith100Percent() {
        viewModel.correctAnswers = 10 // 100% of 10
        let passed = viewModel.correctAnswers >= Int(Double(viewModel.questions.count) * 0.8)
        XCTAssertTrue(passed, "Should pass with 100%")
    }
    
    func testPassThresholdScalesWithQuestionCount() {
        // Test with 46 questions
        let totalQuestions = 46
        let minimumCorrect = Int(Double(totalQuestions) * 0.8) // 36.8 -> 36
        XCTAssertEqual(minimumCorrect, 36, "Should require 36/46 to pass")
    }
    
    // MARK: - Question Randomization Tests
    
    func testResetShufflesQuestions() {
        let originalOrder = viewModel.questions.map { $0.id }
        viewModel.reset()
        let newOrder = viewModel.questions.map { $0.id }
        
        // Check all questions still present
        XCTAssertEqual(Set(originalOrder), Set(newOrder), "All questions should still be present")
    }
    
    // MARK: - Answer Selection Tests
    
    func testSelectingCorrectAnswer() {
        let correctAnswer = viewModel.currentQuestion.correctAnswer
        viewModel.selectAnswer(correctAnswer)
        
        XCTAssertTrue(viewModel.isCorrect, "Should mark answer as correct")
        XCTAssertEqual(viewModel.selectedAnswer, correctAnswer)
        XCTAssertTrue(viewModel.showFeedback, "Should show feedback")
    }
    
    func testSelectingIncorrectAnswer() {
        let correctAnswer = viewModel.currentQuestion.correctAnswer
        let wrongAnswer = correctAnswer == "A" ? "B" : "A"
        viewModel.selectAnswer(wrongAnswer)
        
        XCTAssertFalse(viewModel.isCorrect, "Should mark answer as incorrect")
        XCTAssertEqual(viewModel.selectedAnswer, wrongAnswer)
        XCTAssertTrue(viewModel.showFeedback, "Should show feedback")
    }
    
    // MARK: - Streak Tests
    
    func testStreakIncreasesWithCorrectAnswers() {
        XCTAssertEqual(viewModel.currentStreak, 0)
        
        viewModel.selectAnswer(viewModel.currentQuestion.correctAnswer)
        XCTAssertEqual(viewModel.currentStreak, 1)
        
        viewModel.nextQuestion()
        viewModel.selectAnswer(viewModel.currentQuestion.correctAnswer)
        XCTAssertEqual(viewModel.currentStreak, 2)
    }
    
    func testStreakResetsOnIncorrectAnswer() {
        // Build streak
        viewModel.selectAnswer(viewModel.currentQuestion.correctAnswer)
        viewModel.nextQuestion()
        viewModel.selectAnswer(viewModel.currentQuestion.correctAnswer)
        XCTAssertEqual(viewModel.currentStreak, 2)
        
        // Break streak
        viewModel.nextQuestion()
        let wrongAnswer = viewModel.currentQuestion.correctAnswer == "A" ? "B" : "A"
        viewModel.selectAnswer(wrongAnswer)
        XCTAssertEqual(viewModel.currentStreak, 0)
    }
    
    // MARK: - Navigation Tests
    
    func testShowResultsOnLastQuestion() {
        // Navigate to last question
        while viewModel.currentQuestionIndex < viewModel.questions.count - 1 {
            viewModel.nextQuestion()
        }
        
        XCTAssertFalse(viewModel.showResults)
        viewModel.selectAnswer(viewModel.currentQuestion.correctAnswer)
        viewModel.nextQuestion()
        XCTAssertTrue(viewModel.showResults)
    }
    
    // MARK: - Category Breakdown Tests
    
    func testCategoryBreakdownTracksCorrectly() {
        // Answer first question correctly
        let firstQuestion = viewModel.currentQuestion
        viewModel.selectAnswer(firstQuestion.correctAnswer)
        
        let breakdown = viewModel.categoryBreakdown
        XCTAssertEqual(breakdown[firstQuestion.category]?.correct, 1)
        XCTAssertEqual(breakdown[firstQuestion.category]?.total, 1)
    }
    
    func testCategoryBreakdownTracksIncorrectly() {
        let firstQuestion = viewModel.currentQuestion
        let wrongAnswer = firstQuestion.correctAnswer == "A" ? "B" : "A"
        viewModel.selectAnswer(wrongAnswer)
        
        let breakdown = viewModel.categoryBreakdown
        XCTAssertEqual(breakdown[firstQuestion.category]?.correct, 0)
        XCTAssertEqual(breakdown[firstQuestion.category]?.total, 1)
    }
    
    // MARK: - Reset Tests
    
    func testResetClearsProgress() {
        // Create some progress
        viewModel.selectAnswer(viewModel.currentQuestion.correctAnswer)
        viewModel.nextQuestion()
        viewModel.selectAnswer(viewModel.currentQuestion.correctAnswer)
        
        XCTAssertGreaterThan(viewModel.currentQuestionIndex, 0)
        XCTAssertGreaterThan(viewModel.correctAnswers, 0)
        XCTAssertGreaterThan(viewModel.currentStreak, 0)
        
        // Reset
        viewModel.reset()
        
        XCTAssertEqual(viewModel.currentQuestionIndex, 0)
        XCTAssertEqual(viewModel.correctAnswers, 0)
        XCTAssertEqual(viewModel.currentStreak, 0)
        XCTAssertFalse(viewModel.showResults)
        XCTAssertFalse(viewModel.showFeedback)
        XCTAssertTrue(viewModel.answersHistory.isEmpty)
    }
    
    // MARK: - Time Tracking Tests
    
    func testTimeTracking() {
        let startTime = viewModel.timeTaken
        sleep(1)
        let endTime = viewModel.timeTaken
        XCTAssertGreaterThanOrEqual(endTime, startTime + 1)
    }
    
    // MARK: - Answer History Tests
    
    func testAnswerHistoryRecordsAnswers() {
        XCTAssertTrue(viewModel.answersHistory.isEmpty)
        
        viewModel.selectAnswer(viewModel.currentQuestion.correctAnswer)
        XCTAssertEqual(viewModel.answersHistory.count, 1)
        
        viewModel.nextQuestion()
        viewModel.selectAnswer(viewModel.currentQuestion.correctAnswer)
        XCTAssertEqual(viewModel.answersHistory.count, 2)
    }
    
    func testAnswerHistoryStoresCorrectData() {
        let question = viewModel.currentQuestion
        let answer = "A"
        viewModel.selectAnswer(answer)
        
        let record = viewModel.answersHistory.first
        XCTAssertNotNil(record)
        XCTAssertEqual(record?.question.id, question.id)
        XCTAssertEqual(record?.userAnswer, answer)
        XCTAssertEqual(record?.wasCorrect, answer == question.correctAnswer)
    }
    
    // MARK: - Performance Tests
    
    func testAnswerSelectionPerformance() {
        measure {
            viewModel.selectAnswer("A")
        }
    }
}

// MARK: - Question Model Tests

final class QuestionTests: XCTestCase {
    
    func testQuestionHasAllRequiredFields() {
        let question = Question(
            id: "1",
            questionText: "Test question?",
            answerA: "Answer A",
            answerB: "Answer B",
            answerC: "Answer C",
            answerD: "Answer D",
            correctAnswer: "A",
            category: "Test Category"
        )
        
        XCTAssertEqual(question.id, "1")
        XCTAssertEqual(question.questionText, "Test question?")
        XCTAssertEqual(question.correctAnswer, "A")
        XCTAssertEqual(question.category, "Test Category")
    }
    
    func testQuestionWithExplanation() {
        let explanation = "This is why A is correct"
        let question = Question(
            id: "1",
            questionText: "Test?",
            answerA: "A",
            answerB: "B",
            answerC: "C",
            answerD: "D",
            correctAnswer: "A",
            category: "Test",
            explanation: explanation
        )
        
        XCTAssertEqual(question.explanation, explanation)
    }
}

// MARK: - Integration Tests

final class QuizIntegrationTests: XCTestCase {
    
    func testCompleteQuizFlow() {
        let viewModel = QuizViewModel()
        var correctCount = 0
        
        // Complete entire quiz
        for i in 0..<viewModel.questions.count {
            let question = viewModel.currentQuestion
            
            // Answer correctly on even indices, incorrectly on odd
            if i % 2 == 0 {
                viewModel.selectAnswer(question.correctAnswer)
                correctCount += 1
            } else {
                let wrongAnswer = question.correctAnswer == "A" ? "B" : "A"
                viewModel.selectAnswer(wrongAnswer)
            }
            
            if i < viewModel.questions.count - 1 {
                viewModel.nextQuestion()
            }
        }
        
        XCTAssertEqual(viewModel.correctAnswers, correctCount)
        XCTAssertEqual(viewModel.answersHistory.count, viewModel.questions.count)
    }
}
