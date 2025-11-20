import Foundation
import SwiftUI
import Combine
import CoreData

class UserProgressManager: ObservableObject {
    static let shared = UserProgressManager()

    @Published var totalPoints: Int = 0
    @Published var currentLevel: Int = 1
    @Published var dailyGoal: Int = 20
    @Published var questionsAnsweredToday: Int = 0
    @Published var currentStreak: Int = 0
    @Published var studyDates: [Date] = []

    private let context: NSManagedObjectContext
    private let defaults = UserDefaults.standard
    private let eventTracker = EventTracker.shared
    
    // UserDefaults keys
    private let lastStudyDateKey = "lastStudyDate"
    private let currentStreakKey = "currentStreak"
    private let dailyGoalKey = "dailyGoal"
    private let questionsAnsweredTodayKey = "questionsAnsweredToday"
    private let lastResetDateKey = "lastResetDate"
    private let studyDatesKey = "studyDates"
    
    private init() {
        self.context = PersistenceController.shared.container.viewContext
        loadProgress()
        loadDailyProgress()
        checkAndResetDaily()
    }
    
    // Level thresholds
    let levelThresholds = [
        1: 0,
        2: 501,
        3: 1501,
        4: 3001,
        5: 5001
    ]
    
    let levelNames = [
        1: "Learner",
        2: "Student",
        3: "Driver",
        4: "Expert",
        5: "Master"
    ]
    
    let levelBadges = [
        1: "📚",
        2: "✏️",
        3: "🚗",
        4: "🏆",
        5: "👑"
    ]
    
    func loadProgress() {
        let request: NSFetchRequest<UserProgress> = UserProgress.fetchRequest()
        
        do {
            let results = try context.fetch(request)
            if let progress = results.first {
                self.totalPoints = Int(progress.totalPoints)
                self.currentLevel = Int(progress.currentLevel)
            } else {
                let newProgress = UserProgress(context: context)
                newProgress.totalPoints = 0
                newProgress.currentLevel = 1
                newProgress.lastStudyDate = Date()
                try context.save()
            }
        } catch {
            #if DEBUG
            print("Error loading progress: \(error)")
            #endif
        }
    }
    
    func loadDailyProgress() {
        let savedGoal = defaults.integer(forKey: dailyGoalKey)
        dailyGoal = savedGoal > 0 ? savedGoal : 20
        
        currentStreak = defaults.integer(forKey: currentStreakKey)
        questionsAnsweredToday = defaults.integer(forKey: questionsAnsweredTodayKey)
        
        if let savedDates = defaults.array(forKey: studyDatesKey) as? [Double] {
            studyDates = savedDates.map { Date(timeIntervalSince1970: $0) }
        }
    }
    
    func checkAndResetDaily() {
        let calendar = Calendar.current
        let now = Date()

        if let lastReset = defaults.object(forKey: lastResetDateKey) as? Date {
            if !calendar.isDate(lastReset, inSameDayAs: now) {
                questionsAnsweredToday = 0
                defaults.set(0, forKey: questionsAnsweredTodayKey)

                // Reset the date-based key too
                let todayKey = getTodayKey()
                defaults.set(0, forKey: "dailyQuestionsAnswered_\(todayKey)")

                defaults.set(now, forKey: lastResetDateKey)
            }
        } else {
            defaults.set(now, forKey: lastResetDateKey)
        }

        checkStreak()
    }
    
    func checkStreak() {
        let calendar = Calendar.current
        let now = Date()
        
        if let lastStudy = defaults.object(forKey: lastStudyDateKey) as? Date {
            let daysDifference = calendar.dateComponents([.day], from: lastStudy, to: now).day ?? 0
            
            if daysDifference > 1 {
                currentStreak = 0
                defaults.set(0, forKey: currentStreakKey)
            }
        }
    }
    
    func recordStudySession() {
        let calendar = Calendar.current
        let now = Date()
        
        if let lastStudy = defaults.object(forKey: lastStudyDateKey) as? Date {
            let daysDifference = calendar.dateComponents([.day], from: lastStudy, to: now).day ?? 0
            
            if daysDifference == 1 {
                currentStreak += 1
                defaults.set(currentStreak, forKey: currentStreakKey)

                // Track streak milestones
                if currentStreak == 7 || currentStreak == 10 || currentStreak == 30 {
                    eventTracker.trackStreakMilestone(streakDays: currentStreak)
                }
            } else if daysDifference == 0 {
                // Same day, don't increment streak
            } else {
                // Missed days, reset streak
                currentStreak = 1
                defaults.set(1, forKey: currentStreakKey)
            }
        } else {
            currentStreak = 1
            defaults.set(1, forKey: currentStreakKey)
        }
        
        defaults.set(now, forKey: lastStudyDateKey)
        
        let todayStart = calendar.startOfDay(for: now)
        if !studyDates.contains(where: { calendar.isDate($0, inSameDayAs: todayStart) }) {
            studyDates.append(todayStart)
            if studyDates.count > 90 {
                studyDates = Array(studyDates.suffix(90))
            }
            let timestamps = studyDates.map { $0.timeIntervalSince1970 }
            defaults.set(timestamps, forKey: studyDatesKey)
        }
    }
    
    func incrementDailyQuestions() {
        questionsAnsweredToday += 1
        defaults.set(questionsAnsweredToday, forKey: questionsAnsweredTodayKey)

        // Also update with today's date key for ContentView
        let todayKey = getTodayKey()
        let currentCount = defaults.integer(forKey: "dailyQuestionsAnswered_\(todayKey)")
        defaults.set(currentCount + 1, forKey: "dailyQuestionsAnswered_\(todayKey)")

        recordStudySession()
    }

    private func getTodayKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    func setDailyGoal(_ goal: Int) {
        dailyGoal = goal
        defaults.set(goal, forKey: dailyGoalKey)
    }
    
    func dailyProgress() -> Double {
        return min(Double(questionsAnsweredToday) / Double(dailyGoal), 1.0)
    }
    
    func isGoalComplete() -> Bool {
        return questionsAnsweredToday >= dailyGoal
    }
    
    func awardPoints(correct: Bool, streak: Int, isPerfectQuiz: Bool, totalCorrect: Int, totalQuestions: Int) -> Int {
        guard correct else { return 0 }
        
        var points = 25  // Changed from 10 to 25
        
        if streak == 5 {
            points += 100  // Changed from 50
        } else if streak == 10 {
            points += 200  // Changed from 100
        } else if streak == 15 {
            points += 400  // Changed from 200
        }
        
        if isPerfectQuiz {
            points += 1000  // Changed from 500
        }
        
        let oldLevel = currentLevel
        totalPoints += points
        
        incrementDailyQuestions()
        
        let request: NSFetchRequest<UserProgress> = UserProgress.fetchRequest()
        do {
            let results = try context.fetch(request)
            if let progress = results.first {
                progress.totalPoints = Int32(totalPoints)
                
                let newLevel = calculateLevel()
                if newLevel > oldLevel {
                    progress.currentLevel = Int32(newLevel)
                    currentLevel = newLevel

                    // Track level up event
                    eventTracker.trackLevelUp(newLevel: newLevel, totalPoints: totalPoints)
                }

                try context.save()
            }
        } catch {
            #if DEBUG
            print("Error updating points: \(error)")
            #endif
        }
        
        return points
    }
    
    func calculateLevel() -> Int {
        for level in (1...5).reversed() {
            if let threshold = levelThresholds[level], totalPoints >= threshold {
                return level
            }
        }
        return 1
    }
    
    var currentLevelInfo: (name: String, emoji: String) {
        return (levelNames[currentLevel] ?? "Learner", levelBadges[currentLevel] ?? "📚")
    }
    
    var nextLevelInfo: (name: String, emoji: String, threshold: Int)? {
        guard currentLevel < 5 else { return nil }
        let nextLevel = currentLevel + 1
        return (
            levelNames[nextLevel] ?? "",
            levelBadges[nextLevel] ?? "",
            levelThresholds[nextLevel] ?? 0
        )
    }
    
    var pointsToNextLevel: Int {
        guard let nextInfo = nextLevelInfo else { return 0 }
        return nextInfo.threshold - totalPoints
    }
    
    var progressToNextLevel: Double {
        guard let nextInfo = nextLevelInfo else { return 1.0 }
        let currentThreshold = levelThresholds[currentLevel] ?? 0
        let range = Double(nextInfo.threshold - currentThreshold)
        let progress = Double(totalPoints - currentThreshold)
        return min(max(progress / range, 0), 1.0)
    }
}
