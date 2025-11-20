import Foundation
import SwiftUI
import Combine

/// Provides smart learning recommendations based on practice test performance and Learn progress
class SmartRecommendationManager: ObservableObject {
    static let shared = SmartRecommendationManager()

    @Published var recommendations: [LearningRecommendation] = []
    @Published var aiRecommendedCategories: [String] = []  // Categories AI wants user to practice

    private let claudeAPI = ClaudeAPIService.shared
    private let userAccess = UserAccessManager.shared

    private init() {}

    // MARK: - Generate Recommendations

    /// Generate personalized recommendations based on practice test performance
    func generateRecommendations(includeAI: Bool = true) async -> [LearningRecommendation] {
        var recs: [LearningRecommendation] = []

        // 1. Check for weak categories from recent practice test performance
        let weakCategories = getWeakCategories()
        for weakCategory in weakCategories.prefix(3) { // Top 3 weak categories
            if let moduleId = categoryToModuleId(weakCategory.category) {
                let module = LearnManager.shared.modules.first(where: { $0.moduleId == moduleId })
                let progress = LearnManager.shared.progress(for: moduleId)
                let completedCount = LearnManager.shared.completedCount(for: moduleId)

                let priority: RecommendationPriority = {
                    if weakCategory.accuracy < 0.5 { return .critical }
                    else if weakCategory.accuracy < 0.7 { return .high }
                    else { return .medium }
                }()

                let reason: String = {
                    if completedCount == 0 {
                        return "You haven't studied this topic yet. Your practice test accuracy is \(Int(weakCategory.accuracy * 100))%"
                    } else if progress < 0.5 {
                        return "You're \(Int(progress * 100))% through this module but still struggling (\(Int(weakCategory.accuracy * 100))% accuracy)"
                    } else {
                        return "Complete the remaining lessons to improve your \(Int(weakCategory.accuracy * 100))% accuracy"
                    }
                }()

                recs.append(LearningRecommendation(
                    moduleId: moduleId,
                    moduleName: module?.moduleName ?? weakCategory.category,
                    priority: priority,
                    reason: reason,
                    currentProgress: progress,
                    quizAccuracy: weakCategory.accuracy,
                    suggestedAction: completedCount == 0 ? "Start Learning" : "Continue Learning"
                ))
            }
        }

        // 2. Check for incomplete modules that user has started
        let incompleteModules = getIncompleteStartedModules()
        for module in incompleteModules.prefix(2) { // Top 2 incomplete modules
            // Don't duplicate if already recommended above
            if !recs.contains(where: { $0.moduleId == module.moduleId }) {
                let progress = LearnManager.shared.progress(for: module.moduleId)
                let completedCount = LearnManager.shared.completedCount(for: module.moduleId)

                recs.append(LearningRecommendation(
                    moduleId: module.moduleId,
                    moduleName: module.moduleName,
                    priority: .medium,
                    reason: "You've completed \(completedCount)/\(module.totalLessons) lessons - finish the module!",
                    currentProgress: progress,
                    quizAccuracy: nil,
                    suggestedAction: "Complete Module"
                ))
            }
        }

        // 3. Suggest next module if user is doing well overall
        if weakCategories.isEmpty {
            if let nextModule = getNextUnstartedModule() {
                recs.append(LearningRecommendation(
                    moduleId: nextModule.moduleId,
                    moduleName: nextModule.moduleName,
                    priority: .low,
                    reason: "You're doing great! Ready to learn a new topic?",
                    currentProgress: 0,
                    quizAccuracy: nil,
                    suggestedAction: "Start Learning"
                ))
            }
        }

        // 4. Add AI-powered recommendation for premium users
        if includeAI && userAccess.hasActiveSubscription {
            if let aiRec = await generateAIRecommendation(weakCategories: weakCategories) {
                recs.append(aiRec)
            }
        }

        // Sort by priority
        recs.sort { $0.priority.rawValue > $1.priority.rawValue }

        recommendations = recs
        return recs
    }

    // MARK: - AI-Powered Recommendation
    private func generateAIRecommendation(weakCategories: [(category: String, accuracy: Double)]) async -> LearningRecommendation? {
        // Check cache first
        let cache = AIRecommendationCache.shared
        if let cachedRecommendation = cache.getCachedRecommendation() {
            // Return cached recommendation
            let topWeakCategory = weakCategories.first
            let moduleId = topWeakCategory.flatMap { categoryToModuleId($0.category) } ?? "module_1"

            return LearningRecommendation(
                moduleId: moduleId,
                moduleName: "Scout's Suggestion",
                priority: .high,
                reason: cachedRecommendation,
                currentProgress: 0,
                quizAccuracy: topWeakCategory?.accuracy,
                suggestedAction: "View Recommendation"
            )
        }

        // Check if user can make API request
        let (allowed, _) = claudeAPI.canMakeRequest()
        guard allowed else { return nil }

        // Get readiness data
        let readiness = ReadyToTestManager.shared.calculateReadiness()

        do {
            let weakCategoriesData = weakCategories.prefix(3).map { $0 }

            let aiResponse = try await claudeAPI.getPersonalizedRecommendation(
                weakCategories: Array(weakCategoriesData),
                overallAccuracy: readiness.overallAccuracy,
                questionsSeen: readiness.questionsSeen
            )

            // Cache the AI response
            cache.cacheRecommendation(aiResponse)

            // Extract categories mentioned in AI response and store them
            // This allows Practice Weak Areas to use AI-recommended categories
            let mentionedCategories = extractCategoriesFromResponse(aiResponse, weakCategories: weakCategories)
            aiRecommendedCategories = mentionedCategories

            // Get the top weak category's module ID
            let topWeakCategory = weakCategories.first
            let moduleId = topWeakCategory.flatMap { categoryToModuleId($0.category) } ?? "module_1"

            return LearningRecommendation(
                moduleId: moduleId,
                moduleName: "Scout's Suggestion",
                priority: .high,
                reason: aiResponse,
                currentProgress: 0,
                quizAccuracy: topWeakCategory?.accuracy,
                suggestedAction: "View Recommendation"
            )
        } catch {
            #if DEBUG
            print("Failed to get AI recommendation: \(error)")
            #endif
            return nil
        }
    }

    // MARK: - Helper Functions

    /// Get weak categories from PerformanceTracker (< 70% accuracy)
    private func getWeakCategories() -> [(category: String, accuracy: Double)] {
        return PerformanceTracker.shared.getWeakCategories()
    }

    /// Get modules that user has started but not completed
    private func getIncompleteStartedModules() -> [Module] {
        return LearnManager.shared.modules.filter { module in
            let progress = LearnManager.shared.progress(for: module.moduleId)
            return progress > 0 && progress < 1.0
        }.sorted { module1, module2 in
            // Sort by most progress first
            LearnManager.shared.progress(for: module1.moduleId) >
            LearnManager.shared.progress(for: module2.moduleId)
        }
    }

    /// Get next unstarted module
    private func getNextUnstartedModule() -> Module? {
        return LearnManager.shared.modules.first { module in
            LearnManager.shared.progress(for: module.moduleId) == 0
        }
    }

    /// Map quiz category to module ID using single source of truth
    private func categoryToModuleId(_ category: String) -> String? {
        return QuestionCategory.fromString(category)?.moduleId
    }

    /// Extract categories mentioned in AI response
    private func extractCategoriesFromResponse(_ response: String, weakCategories: [(category: String, accuracy: Double)]) -> [String] {
        var mentioned: [String] = []

        // Check if any weak category is mentioned in the response
        for weakCat in weakCategories {
            if response.lowercased().contains(weakCat.category.lowercased()) {
                mentioned.append(weakCat.category)
            }
        }

        // If no specific categories mentioned, use top 2 weakest
        if mentioned.isEmpty {
            mentioned = weakCategories.prefix(2).map { $0.category }
        }

        return mentioned
    }
}

// MARK: - Models

struct LearningRecommendation: Identifiable {
    let id = UUID()
    let moduleId: String
    let moduleName: String
    let priority: RecommendationPriority
    let reason: String
    let currentProgress: Double
    let quizAccuracy: Double?
    let suggestedAction: String

    var priorityColor: Color {
        switch priority {
        case .critical: return Color.adaptiveError
        case .high: return Color.adaptiveAccentYellow
        case .medium: return Color.adaptivePrimaryBlue
        case .low: return Color.adaptiveSuccess
        }
    }

    var priorityIcon: String {
        switch priority {
        case .critical: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.circle.fill"
        case .medium: return "info.circle.fill"
        case .low: return "star.fill"
        }
    }
}

enum RecommendationPriority: Int {
    case critical = 4 // < 50% accuracy, unstarted module
    case high = 3     // < 70% accuracy, low progress
    case medium = 2   // Incomplete started modules
    case low = 1      // Suggestions for strong students
}
