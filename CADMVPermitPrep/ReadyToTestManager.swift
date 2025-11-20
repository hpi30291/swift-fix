import Foundation

struct ReadinessScore {
    let percentage: Int
    let overallAccuracy: Double
    let questionsSeen: Int
    let totalQuestions: Int
    let weakestCategory: String?
    let weakestAccuracy: Double
    let recommendations: [String]
    let status: ReadinessStatus
}

enum ReadinessStatus {
    case notReady
    case almostReady
    case ready
    
    var color: String {
        switch self {
        case .notReady: return "red"
        case .almostReady: return "yellow"
        case .ready: return "green"
        }
    }
    
    var title: String {
        switch self {
        case .notReady: return "Not Ready"
        case .almostReady: return "Almost Ready"
        case .ready: return "Ready to Test!"
        }
    }
}

class ReadyToTestManager {
    static let shared = ReadyToTestManager()
    
    private let performanceTracker = PerformanceTracker.shared
    private let questionManager = QuestionManager.shared
    
    private init() {}
    
    func calculateReadiness() -> ReadinessScore {
        let totalQuestions = questionManager.allQuestions.count
        let categoryPerformance = performanceTracker.getAllCategoryPerformance()

        // Readiness is based on overall accuracy - matches diagnostic results
        let overallAccuracy = calculateOverallAccuracy()
        let questionsSeen = getUniqueQuestionsSeen()
        let weakestAccuracy = getWeakestCategoryAccuracy(from: categoryPerformance)

        // Show the actual accuracy percentage
        // This exactly matches what users see in their diagnostic test
        let percentage = Int(overallAccuracy * 100)

        // Generate recommendations
        let recommendations = generateRecommendations(
            overallAccuracy: overallAccuracy,
            questionsSeen: questionsSeen,
            totalQuestions: totalQuestions,
            categoryPerformance: categoryPerformance
        )

        return ReadinessScore(
            percentage: percentage,
            overallAccuracy: overallAccuracy,
            questionsSeen: questionsSeen,
            totalQuestions: totalQuestions,
            weakestCategory: getWeakestCategory(from: categoryPerformance),
            weakestAccuracy: weakestAccuracy,
            recommendations: recommendations,
            status: getStatus(for: percentage)
        )
    }
    
    private func calculateOverallAccuracy() -> Double {
        let totalAnswered = UserDefaults.standard.integer(forKey: "totalQuestionsAnswered")
        let totalCorrect = UserDefaults.standard.integer(forKey: "totalCorrectAnswers")
        
        guard totalAnswered > 0 else { return 0.0 }
        return Double(totalCorrect) / Double(totalAnswered)
    }
    
    private func getUniqueQuestionsSeen() -> Int {
        let allPerformance = performanceTracker.getAllPerformance(questions: questionManager.allQuestions)
        return allPerformance.filter { $0.value.timesSeen > 0 }.count
    }
    
    private func getWeakestCategoryAccuracy(from performance: [String: CategoryPerformance]) -> Double {
        let accuracies = performance.values
            .filter { $0.questionsAnswered > 0 }
            .map { $0.accuracy }
        
        return accuracies.min() ?? 0.0
    }
    
    private func getWeakestCategory(from performance: [String: CategoryPerformance]) -> String? {
        return performance
            .filter { $0.value.questionsAnswered > 0 }
            .min(by: { $0.value.accuracy < $1.value.accuracy })?
            .key
    }
    
    private func generateRecommendations(
        overallAccuracy: Double,
        questionsSeen: Int,
        totalQuestions: Int,
        categoryPerformance: [String: CategoryPerformance]
    ) -> [String] {
        var recommendations: [String] = []
        
        // Check overall accuracy
        if overallAccuracy < 0.90 {
            recommendations.append("Improve overall accuracy to 90% (currently \(Int(overallAccuracy * 100))%)")
        }

        // Check weak categories
        for (category, stats) in categoryPerformance {
            if stats.questionsAnswered > 5 && stats.accuracy < 0.80 {
                let questionsNeeded = Int(ceil(Double(stats.questionsAnswered) * 0.2))
                recommendations.append("Practice \(questionsNeeded) more \(category) questions (currently \(Int(stats.accuracy * 100))%)")
            }
        }
        
        // If ready
        if recommendations.isEmpty {
            recommendations.append("You're ready! Schedule your DMV test!")
        }
        
        return recommendations
    }
    
    private func getStatus(for percentage: Int) -> ReadinessStatus {
        switch percentage {
        case 0...60:
            return .notReady
        case 61...84:
            return .almostReady
        default:
            return .ready
        }
    }
}
