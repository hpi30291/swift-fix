import Foundation

/// Result from diagnostic test
struct DiagnosticTestResult {
    let score: Int
    let totalQuestions: Int
    let categoryBreakdown: [String: CategoryScore]
    let timeTaken: TimeInterval
    let passThreshold: Int

    var percentage: Int {
        return Int((Double(score) / Double(totalQuestions)) * 100)
    }

    var passed: Bool {
        return score >= passThreshold
    }

    var gapPoints: Int {
        return passThreshold - score
    }

    struct CategoryScore {
        let correct: Int
        let total: Int
        let isWeak: Bool

        var percentage: Int {
            guard total > 0 else { return 0 }
            return Int((Double(correct) / Double(total)) * 100)
        }
    }
}

/// Manages diagnostic test
class DiagnosticTestManager {
    static let shared = DiagnosticTestManager()

    private var diagnosticQuestions: [Question] = []

    private init() {
        loadDiagnosticQuestions()
    }

    /// Load diagnostic questions from diagnostic_questions.json
    private func loadDiagnosticQuestions() {
        guard let url = Bundle.main.url(forResource: "diagnostic_questions", withExtension: "json") else {
            #if DEBUG
            print("❌ Could not find diagnostic_questions.json")
            #endif
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            diagnosticQuestions = try decoder.decode([Question].self, from: data)
            #if DEBUG
            print("✅ Loaded \(diagnosticQuestions.count) diagnostic questions")
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to load diagnostic questions: \(error)")
            #endif
        }
    }

    /// Get 15 diagnostic questions (covering all categories)
    /// Uses the dedicated questions from diagnostic_questions.json
    func getDiagnosticQuestions() -> [Question] {
        // If we have diagnostic questions loaded, use all 15
        if diagnosticQuestions.count >= 15 {
            return Array(diagnosticQuestions.shuffled().prefix(15))
        }

        // Fallback to regular questions if diagnostic_questions.json isn't loaded
        #if DEBUG
        print("⚠️ Using fallback questions - diagnostic_questions.json not loaded properly")
        #endif
        let allQuestions = QuestionManager.shared.getAllQuestions()

        // Category requirements
        let categoryDistribution: [String: Int] = [
            "Traffic Signs": 3,
            "Traffic Laws": 3,
            "Safe Driving": 3,
            "Right of Way": 2,
            "Alcohol & Drugs": 2,
            "Parking": 2
        ]

        var selectedQuestions: [Question] = []

        for (category, count) in categoryDistribution {
            let categoryQuestions = allQuestions.filter { $0.category == category }
            let selected = Array(categoryQuestions.shuffled().prefix(count))
            selectedQuestions.append(contentsOf: selected)
        }

        // If we don't have enough questions in some categories, fill with random
        while selectedQuestions.count < 15 {
            if let randomQuestion = allQuestions.randomElement(),
               !selectedQuestions.contains(where: { $0.id == randomQuestion.id }) {
                selectedQuestions.append(randomQuestion)
            }
        }

        return Array(selectedQuestions.prefix(15)).shuffled()
    }

    /// Calculate diagnostic test result
    func calculateResult(answers: [AnswerRecord], timeTaken: TimeInterval) -> DiagnosticTestResult {
        let correctAnswers = answers.filter { $0.wasCorrect }.count
        let passThreshold = 12 // 80% of 15 questions

        // Calculate category breakdown
        var categoryBreakdown: [String: DiagnosticTestResult.CategoryScore] = [:]
        var categoryCounts: [String: (correct: Int, total: Int)] = [:]

        for answer in answers {
            let category = answer.question.category
            let current = categoryCounts[category] ?? (correct: 0, total: 0)
            categoryCounts[category] = (
                correct: current.correct + (answer.wasCorrect ? 1 : 0),
                total: current.total + 1
            )
        }

        for (category, counts) in categoryCounts {
            let percentage = Double(counts.correct) / Double(counts.total) * 100
            let isWeak = percentage < 70 // Categories below 70% are marked as weak

            categoryBreakdown[category] = DiagnosticTestResult.CategoryScore(
                correct: counts.correct,
                total: counts.total,
                isWeak: isWeak
            )
        }

        return DiagnosticTestResult(
            score: correctAnswers,
            totalQuestions: answers.count,
            categoryBreakdown: categoryBreakdown,
            timeTaken: timeTaken,
            passThreshold: passThreshold
        )
    }
}
