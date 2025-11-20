import Foundation
import SwiftUI
import Combine

class AchievementManager: ObservableObject {
    static let shared = AchievementManager()

    @Published var achievements: [Achievement] = []
    @Published var newlyUnlockedAchievement: Achievement?

    private let defaults = UserDefaults.standard
    private let achievementsKey = "savedAchievements"
    private let eventTracker = EventTracker.shared

    private init() {
        loadAchievements()
    }
    
    func loadAchievements() {
        if let data = defaults.data(forKey: achievementsKey),
           let saved = try? JSONDecoder().decode([Achievement].self, from: data) {
            achievements = saved
        } else {
            achievements = Achievement.allAchievements
            saveAchievements()
        }
    }
    
    func saveAchievements() {
        if let data = try? JSONEncoder().encode(achievements) {
            defaults.set(data, forKey: achievementsKey)
        }
    }
    
    func checkAchievements(
        totalAnswered: Int,
        currentStreak: Int,
        perfectScore: Bool,
        testTimeSeconds: Int? = nil,
        scoreImprovement: Int? = nil,
        categoryAccuracy: [String: Double] = [:]
    ) {
        var unlocked: [Achievement] = []
        
        // First Steps
        if let index = achievements.firstIndex(where: { $0.id == "first_steps" }) {
            achievements[index].progress = totalAnswered
            if !achievements[index].isUnlocked && totalAnswered >= 15 {
                achievements[index].isUnlocked = true
                unlocked.append(achievements[index])
            }
        }
        
        // Getting Serious
        if let index = achievements.firstIndex(where: { $0.id == "getting_serious" }) {
            achievements[index].progress = totalAnswered
            if !achievements[index].isUnlocked && totalAnswered >= 100 {
                achievements[index].isUnlocked = true
                unlocked.append(achievements[index])
            }
        }
        
        // Perfectionist
        if perfectScore {
            if let index = achievements.firstIndex(where: { $0.id == "perfectionist" }) {
                if !achievements[index].isUnlocked {
                    achievements[index].isUnlocked = true
                    achievements[index].progress = 1
                    unlocked.append(achievements[index])
                }
            }
        }
        
        // Week Warrior
        if let index = achievements.firstIndex(where: { $0.id == "week_warrior" }) {
            achievements[index].progress = currentStreak
            if !achievements[index].isUnlocked && currentStreak >= 7 {
                achievements[index].isUnlocked = true
                unlocked.append(achievements[index])
            }
        }
        
        // Month Master
        if let index = achievements.firstIndex(where: { $0.id == "month_master" }) {
            achievements[index].progress = currentStreak
            if !achievements[index].isUnlocked && currentStreak >= 30 {
                achievements[index].isUnlocked = true
                unlocked.append(achievements[index])
            }
        }
        
        // Consistent Learner
        if let index = achievements.firstIndex(where: { $0.id == "consistent_learner" }) {
            achievements[index].progress = currentStreak
            if !achievements[index].isUnlocked && currentStreak >= 10 {
                achievements[index].isUnlocked = true
                unlocked.append(achievements[index])
            }
        }
        
        // Speed Demon
        if let timeSeconds = testTimeSeconds, timeSeconds < 1200 {
            if let index = achievements.firstIndex(where: { $0.id == "speed_demon" }) {
                if !achievements[index].isUnlocked {
                    achievements[index].isUnlocked = true
                    achievements[index].progress = 1
                    unlocked.append(achievements[index])
                }
            }
        }
        
        // Comeback Kid
        if let improvement = scoreImprovement, improvement >= 20 {
            if let index = achievements.firstIndex(where: { $0.id == "comeback_kid" }) {
                if !achievements[index].isUnlocked {
                    achievements[index].isUnlocked = true
                    achievements[index].progress = 1
                    unlocked.append(achievements[index])
                }
            }
        }
        
        // Category Master - Requires at least 20 questions answered in category with 100% accuracy
        let categoryPerformance = PerformanceTracker.shared.getAllCategoryPerformance()
        for (_, performance) in categoryPerformance {
            if performance.questionsAnswered >= 20 && performance.accuracy >= 1.0 {
                if let index = achievements.firstIndex(where: { $0.id == "category_master" }) {
                    if !achievements[index].isUnlocked {
                        achievements[index].isUnlocked = true
                        achievements[index].progress = 1
                        unlocked.append(achievements[index])
                        break
                    }
                }
            }
        }
        
        // Road Sign Pro
        if let roadSignAccuracy = categoryAccuracy["Traffic Signs"], roadSignAccuracy >= 0.9 {
            if let index = achievements.firstIndex(where: { $0.id == "road_sign_pro" }) {
                achievements[index].progress = Int(roadSignAccuracy * 100)
                if !achievements[index].isUnlocked {
                    achievements[index].isUnlocked = true
                    unlocked.append(achievements[index])
                }
            }
        }
        
        saveAchievements()

        // Track unlocked achievements
        for achievement in unlocked {
            eventTracker.trackAchievementUnlocked(
                achievementId: achievement.id,
                achievementName: achievement.name
            )
        }

        // Show first unlocked achievement
        if let first = unlocked.first {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.newlyUnlockedAchievement = first
            }
        }
    }
    
    func dismissAchievement() {
        newlyUnlockedAchievement = nil
    }
    
    var unlockedCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }
}
