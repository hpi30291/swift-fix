import Foundation
import CoreData

// MARK: - Question Performance Stats
struct QuestionPerformance {
    let questionId: String
    let category: String
    var timesSeen: Int = 0
    var timesCorrect: Int = 0
    var timesIncorrect: Int = 0
    var lastAttemptDate: Date?
    var averageTimeTaken: Double = 0
    
    var accuracy: Double {
        guard timesSeen > 0 else { return 0 }
        return Double(timesCorrect) / Double(timesSeen)
    }
    
    var weight: Int {
        if timesSeen == 0 {
            return 10 // Never seen
        } else if timesIncorrect == 1 {
            return 8 // Incorrect once
        } else if timesIncorrect >= 2 {
            return 10 // Struggling - priority
        } else if timesCorrect == 1 {
            return 5 // Correct once
        } else if timesCorrect == 2 {
            return 3 // Correct twice
        } else {
            return 1 // Mastered (3+ correct)
        }
    }
    
    init(questionId: String, category: String, attempts: [QuestionAttempt]) {
        self.questionId = questionId
        self.category = category
        self.timesSeen = attempts.count
        self.timesCorrect = attempts.filter { $0.wasCorrect }.count
        self.timesIncorrect = attempts.filter { !$0.wasCorrect }.count
        self.lastAttemptDate = attempts.last?.timestamp
        
        if !attempts.isEmpty {
            let totalTime = attempts.reduce(0) { $0 + Int($1.timeTaken) }
            self.averageTimeTaken = Double(totalTime) / Double(attempts.count)
        }
    }
}

// MARK: - Category Performance
struct CategoryPerformance {
    let category: String
    let questionsAnswered: Int
    let totalAttempts: Int
    let correctAttempts: Int
    
    var accuracy: Double {
        guard totalAttempts > 0 else { return 0 }
        return Double(correctAttempts) / Double(totalAttempts)
    }
    
    var isWeak: Bool {
        return questionsAnswered >= 5 && accuracy < 0.7
    }
}

// MARK: - Performance Tracker
class PerformanceTracker {
    static let shared = PerformanceTracker()
    
    private let context: NSManagedObjectContext
    
    private init() {
        self.context = PersistenceController.shared.container.viewContext
    }
    
    // MARK: - Record Attempt
    func recordAttempt(questionId: String, category: String, wasCorrect: Bool, timeTaken: Int = 0) {
        let attempt = QuestionAttempt(context: context)
        attempt.questionID = questionId
        attempt.category = category
        attempt.wasCorrect = wasCorrect
        attempt.timestamp = Date()
        attempt.timeTaken = Int32(timeTaken)
        
        saveContext()
    }
    
    // MARK: - Fetch Attempts
    private func fetchAttempts(for questionId: String) -> [QuestionAttempt] {
        let request: NSFetchRequest<QuestionAttempt> = QuestionAttempt.fetchRequest()
        request.predicate = NSPredicate(format: "questionID == %@", questionId)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        
        return (try? context.fetch(request)) ?? []
    }
    
    private func fetchAttempts(forCategory category: String) -> [QuestionAttempt] {
        let request: NSFetchRequest<QuestionAttempt> = QuestionAttempt.fetchRequest()
        request.predicate = NSPredicate(format: "category == %@", category)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        return (try? context.fetch(request)) ?? []
    }
    
    // MARK: - Get Performance
    func getPerformance(for questionId: String, category: String) -> QuestionPerformance {
        let attempts = fetchAttempts(for: questionId)
        return QuestionPerformance(questionId: questionId, category: category, attempts: attempts)
    }
    
    func getAllPerformance(questions: [Question]) -> [String: QuestionPerformance] {
        var performanceMap: [String: QuestionPerformance] = [:]
        
        for question in questions {
            let attempts = fetchAttempts(for: question.id)
            let performance = QuestionPerformance(
                questionId: question.id,
                category: question.category,
                attempts: attempts
            )
            performanceMap[question.id] = performance
        }
        
        return performanceMap
    }
    
    func getCategoryPerformance(for category: String) -> CategoryPerformance {
        let attempts = fetchAttempts(forCategory: category)
        let uniqueQuestions = Set(attempts.compactMap { $0.questionID })
        let correctAttempts = attempts.filter { $0.wasCorrect }.count
        
        return CategoryPerformance(
            category: category,
            questionsAnswered: uniqueQuestions.count,
            totalAttempts: attempts.count,
            correctAttempts: correctAttempts
        )
    }
    
    func getAllCategoryPerformance() -> [String: CategoryPerformance] {
        let request: NSFetchRequest<QuestionAttempt> = QuestionAttempt.fetchRequest()
        let allAttempts = (try? context.fetch(request)) ?? []
        
        var categoryGroups: [String: [QuestionAttempt]] = [:]
        for attempt in allAttempts {
            if let category = attempt.category {
                categoryGroups[category, default: []].append(attempt)
            }
        }
        
        var performance: [String: CategoryPerformance] = [:]
        for (category, attempts) in categoryGroups {
            let uniqueQuestions = Set(attempts.compactMap { $0.questionID })
            let correctAttempts = attempts.filter { $0.wasCorrect }.count
            
            performance[category] = CategoryPerformance(
                category: category,
                questionsAnswered: uniqueQuestions.count,
                totalAttempts: attempts.count,
                correctAttempts: correctAttempts
            )
        }
        
        return performance
    }
    
    private func saveContext() {
        if context.hasChanges {
            try? context.save()
        }
    }
    
    func getWeakCategories() -> [(category: String, accuracy: Double)] {
        let categoryPerformance = getAllCategoryPerformance()
        
        return categoryPerformance.values
            .filter { $0.questionsAnswered >= 5 && $0.accuracy < 0.7 }
            .map { (category: $0.category, accuracy: $0.accuracy) }
            .sorted { $0.accuracy < $1.accuracy }
    }
}
