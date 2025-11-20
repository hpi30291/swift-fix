import Foundation

class QuestionManager {
    static let shared = QuestionManager()

    var allQuestions: [Question] = []
    private let performanceTracker = PerformanceTracker.shared
    private var isLoaded = false

    private init() {
        // Don't load questions at init - lazy load when first accessed
        // This speeds up app launch
    }
    
    func loadQuestions() {
        // Only load once
        guard !isLoaded else { return }
        isLoaded = true

        var loadedQuestions: [Question] = []

        // Load main questions
        if let mainQuestions = loadQuestionsFromFile("questions") {
            loadedQuestions.append(contentsOf: mainQuestions)
            #if DEBUG
            print("📚 Loaded \(mainQuestions.count) questions from questions.json")
            #endif
        }

        // Load traffic signs questions
        if let trafficSignQuestions = loadQuestionsFromFile("traffic-signs-questions") {
            loadedQuestions.append(contentsOf: trafficSignQuestions)
            #if DEBUG
            print("🚦 Loaded \(trafficSignQuestions.count) traffic sign questions")
            #endif
        }

        if !loadedQuestions.isEmpty {
            allQuestions = loadedQuestions
            #if DEBUG
            print("✅ Total questions loaded: \(allQuestions.count)")
            #endif
        } else {
            allQuestions = getDummyQuestions()
            #if DEBUG
            print("⚠️ No JSON files found, using dummy questions")
            #endif
        }
    }

    private func loadQuestionsFromFile(_ filename: String) -> [Question]? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let questions = try? JSONDecoder().decode([Question].self, from: data) else {
            #if DEBUG
            print("❌ Could not load \(filename).json")
            #endif
            return nil
        }
        return questions
    }

    private func loadFromJSON() -> [Question]? {
        return loadQuestionsFromFile("questions")
    }
    
    func getAllQuestions() -> [Question] {
        loadQuestions() // Ensure questions are loaded
        return allQuestions
    }
    
    // MARK: - Adaptive Question Selection
    func getAdaptiveQuestions(count: Int, category: String? = nil) -> [Question] {
        loadQuestions() // Ensure questions are loaded
        var pool = allQuestions
        
        if let category = category {
            pool = pool.filter { $0.category == category }
        }
        
        guard !pool.isEmpty else { return [] }
        
        let performanceMap = performanceTracker.getAllPerformance(questions: pool)
        
        var weightedPool: [Question] = []
        
        for question in pool {
            let performance = performanceMap[question.id] ?? QuestionPerformance(
                questionId: question.id,
                category: question.category,
                attempts: []
            )
            
            let weight = performance.weight
            
            for _ in 0..<weight {
                weightedPool.append(question)
            }
        }
        
        var selected: [Question] = []
        var usedIds = Set<String>()
        
        let targetCount = min(count, pool.count)
        
        while selected.count < targetCount && !weightedPool.isEmpty {
            if let randomQuestion = weightedPool.randomElement(),
               !usedIds.contains(randomQuestion.id) {
                selected.append(randomQuestion)
                usedIds.insert(randomQuestion.id)
            }
        }
        
        return selected.shuffled()
    }
    
    func getRandomQuestions(count: Int) -> [Question] {
        loadQuestions() // Ensure questions are loaded
        return Array(allQuestions.shuffled().prefix(count))
    }

    // MARK: - Weak Areas Quiz Generation
    /// Generate quiz with questions from weak categories (<70% accuracy)
    /// Prioritizes AI-recommended categories if available
    /// Questions are weighted toward lowest accuracy categories
    /// - Parameter count: Total number of questions to generate (default 10)
    /// - Returns: Array of questions weighted toward weak areas
    func getWeakAreasQuestions(count: Int = 10) -> [Question] {
        // Check if AI has recommended specific categories
        let aiCategories = SmartRecommendationManager.shared.aiRecommendedCategories

        var categoriesToUse: [(category: String, accuracy: Double)] = []

        if !aiCategories.isEmpty {
            // Use AI-recommended categories
            let allCategoryPerformance = performanceTracker.getAllCategoryPerformance()
            for category in aiCategories {
                if let performance = allCategoryPerformance[category] {
                    categoriesToUse.append((category: category, accuracy: performance.accuracy))
                }
            }
        }

        // If no AI categories or they're empty, fall back to weak categories
        if categoriesToUse.isEmpty {
            categoriesToUse = performanceTracker.getWeakCategories()
        }

        guard !categoriesToUse.isEmpty else {
            // No weak areas - return adaptive questions
            return getAdaptiveQuestions(count: count)
        }

        // Calculate total weight for proportional distribution
        // Lower accuracy = higher weight (invert accuracy for weight)
        let totalWeight = categoriesToUse.reduce(0.0) { $0 + (1.0 - $1.accuracy) }

        var selectedQuestions: [Question] = []
        var usedIds = Set<String>()

        // Distribute questions proportionally to weakness
        for weakCategory in categoriesToUse {
            let weight = (1.0 - weakCategory.accuracy) / totalWeight
            let questionsForCategory = Int(Double(count) * weight) + 1 // +1 to ensure at least 1

            // Get questions from this category
            let categoryQuestions = getAdaptiveQuestions(
                count: questionsForCategory,
                category: weakCategory.category
            )

            // Add unique questions
            for question in categoryQuestions {
                if !usedIds.contains(question.id) && selectedQuestions.count < count {
                    selectedQuestions.append(question)
                    usedIds.insert(question.id)
                }
            }

            // Stop if we have enough questions
            if selectedQuestions.count >= count {
                break
            }
        }

        // If we don't have enough questions yet, fill with adaptive questions
        while selectedQuestions.count < count {
            let additional = getAdaptiveQuestions(count: count - selectedQuestions.count)
            for question in additional {
                if !usedIds.contains(question.id) {
                    selectedQuestions.append(question)
                    usedIds.insert(question.id)
                    if selectedQuestions.count >= count {
                        break
                    }
                }
            }
            // Prevent infinite loop
            if additional.isEmpty {
                break
            }
        }

        return selectedQuestions.shuffled()
    }
    
    func getQuestionsByCategory(_ category: String) -> [Question] {
        loadQuestions() // Ensure questions are loaded
        return allQuestions.filter { $0.category == category }
    }

    func getCategories() -> [String] {
        loadQuestions() // Ensure questions are loaded
        // Return categories from enum for consistency
        // But also include any categories from questions that might not be in enum yet
        let questionCategories = Set(allQuestions.map { $0.category })
        let enumCategories = Set(QuestionCategory.allDisplayNames)
        return Array(questionCategories.union(enumCategories)).sorted()
    }

    /// Get all valid categories from the QuestionCategory enum
    func getValidCategories() -> [QuestionCategory] {
        return QuestionCategory.allCases
    }
    
    
    // MARK: - Dummy Questions
    private func getDummyQuestions() -> [Question] {
        return [
            Question(
                id: "1",
                questionText: "What does a red octagonal sign mean?",
                answerA: "Slow down",
                answerB: "Stop",
                answerC: "Yield",
                answerD: "No parking",
                correctAnswer: "B",
                category: "Traffic Signs",
                explanation: "A red octagon is always a stop sign. You must come to a complete stop."
            ),
            Question(
                id: "2",
                questionText: "At a four-way stop, who has the right of way?",
                answerA: "The largest vehicle",
                answerB: "The vehicle on the right",
                answerC: "The first vehicle to arrive",
                answerD: "The fastest vehicle",
                correctAnswer: "C",
                category: "Right of Way",
                explanation: "The first vehicle to reach the intersection goes first."
            ),
            Question(
                id: "3",
                questionText: "What is the speed limit in a residential area unless posted otherwise?",
                answerA: "15 mph",
                answerB: "25 mph",
                answerC: "35 mph",
                answerD: "45 mph",
                correctAnswer: "B",
                category: "Traffic Laws",
                explanation: "California's default speed limit in residential areas is 25 mph."
            )
        ]
    }
}
