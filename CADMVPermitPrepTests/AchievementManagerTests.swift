import XCTest
@testable import CADMVPermitPrep

@MainActor
final class AchievementManagerTests: XCTestCase {

    var achievementManager: AchievementManager!

    override func setUp() {
        super.setUp()
        achievementManager = AchievementManager.shared

        // Clear saved achievements
        UserDefaults.standard.removeObject(forKey: "savedAchievements")

        // Reset to default state
        achievementManager.loadAchievements()
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "savedAchievements")
        achievementManager.newlyUnlockedAchievement = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testLoadAchievementsInitialState() {
        XCTAssertEqual(achievementManager.achievements.count, 10, "Should load all 10 achievements")

        for achievement in achievementManager.achievements {
            XCTAssertFalse(achievement.isUnlocked, "All achievements should start locked")
            XCTAssertEqual(achievement.progress, 0, "All achievements should start with 0 progress")
        }
    }

    func testAllAchievementIdsAreUnique() {
        let ids = achievementManager.achievements.map { $0.id }
        let uniqueIds = Set(ids)

        XCTAssertEqual(ids.count, uniqueIds.count, "All achievement IDs should be unique")
    }

    func testAllAchievementsHaveRequiredFields() {
        for achievement in achievementManager.achievements {
            XCTAssertFalse(achievement.id.isEmpty, "Achievement should have ID")
            XCTAssertFalse(achievement.name.isEmpty, "Achievement should have name")
            XCTAssertFalse(achievement.description.isEmpty, "Achievement should have description")
            XCTAssertFalse(achievement.icon.isEmpty, "Achievement should have icon")
            XCTAssertGreaterThan(achievement.requirement, 0, "Achievement should have positive requirement")
        }
    }

    // MARK: - Save/Load Tests

    func testSaveAndLoadAchievements() {
        // Unlock an achievement
        achievementManager.checkAchievements(
            totalAnswered: 15,
            currentStreak: 0,
            perfectScore: false
        )

        // Save
        achievementManager.saveAchievements()

        // Clear and reload
        UserDefaults.standard.removeObject(forKey: "savedAchievements")
        achievementManager.achievements = []
        achievementManager.loadAchievements()

        // Should be back to initial state since we cleared UserDefaults
        let firstSteps = achievementManager.achievements.first { $0.id == "first_steps" }
        XCTAssertNotNil(firstSteps)
    }

    func testPersistenceAfterUnlock() {
        // Unlock First Steps
        achievementManager.checkAchievements(
            totalAnswered: 15,
            currentStreak: 0,
            perfectScore: false
        )

        let firstSteps = achievementManager.achievements.first { $0.id == "first_steps" }
        XCTAssertTrue(firstSteps?.isUnlocked ?? false, "Should be unlocked")

        // Reload
        achievementManager.loadAchievements()

        let reloadedFirstSteps = achievementManager.achievements.first { $0.id == "first_steps" }
        XCTAssertTrue(reloadedFirstSteps?.isUnlocked ?? false, "Should persist unlocked state")
    }

    // MARK: - First Steps Achievement Tests

    func testFirstStepsUnlockAt10Questions() {
        achievementManager.checkAchievements(
            totalAnswered: 15,
            currentStreak: 0,
            perfectScore: false
        )

        let firstSteps = achievementManager.achievements.first { $0.id == "first_steps" }
        XCTAssertNotNil(firstSteps)
        XCTAssertTrue(firstSteps?.isUnlocked ?? false, "Should unlock at 15 questions")
        XCTAssertEqual(firstSteps?.progress, 15)
    }

    func testFirstStepsProgressBeforeUnlock() {
        achievementManager.checkAchievements(
            totalAnswered: 10,
            currentStreak: 0,
            perfectScore: false
        )

        let firstSteps = achievementManager.achievements.first { $0.id == "first_steps" }
        XCTAssertFalse(firstSteps?.isUnlocked ?? true, "Should not unlock at 10 questions")
        XCTAssertEqual(firstSteps?.progress, 10, "Should track progress")
    }

    func testFirstStepsDoesNotUnlockTwice() {
        // First unlock
        achievementManager.checkAchievements(
            totalAnswered: 15,
            currentStreak: 0,
            perfectScore: false
        )

        // Second check
        achievementManager.checkAchievements(
            totalAnswered: 20,
            currentStreak: 0,
            perfectScore: false
        )

        let firstSteps = achievementManager.achievements.first { $0.id == "first_steps" }
        XCTAssertTrue(firstSteps?.isUnlocked ?? false, "Should remain unlocked")
        XCTAssertEqual(firstSteps?.progress, 20, "Should update progress")
    }

    // MARK: - Getting Serious Achievement Tests

    func testGettingSeriousUnlockAt100Questions() {
        achievementManager.checkAchievements(
            totalAnswered: 100,
            currentStreak: 0,
            perfectScore: false
        )

        let gettingSerious = achievementManager.achievements.first { $0.id == "getting_serious" }
        XCTAssertTrue(gettingSerious?.isUnlocked ?? false, "Should unlock at 100 questions")
        XCTAssertEqual(gettingSerious?.progress, 100)
    }

    func testGettingSeriousProgressTracking() {
        achievementManager.checkAchievements(
            totalAnswered: 50,
            currentStreak: 0,
            perfectScore: false
        )

        let gettingSerious = achievementManager.achievements.first { $0.id == "getting_serious" }
        XCTAssertFalse(gettingSerious?.isUnlocked ?? true, "Should not unlock at 50 questions")
        XCTAssertEqual(gettingSerious?.progress, 50)
    }

    // MARK: - Perfectionist Achievement Tests

    func testPerfectionistUnlockWithPerfectScore() {
        achievementManager.checkAchievements(
            totalAnswered: 10,
            currentStreak: 0,
            perfectScore: true
        )

        let perfectionist = achievementManager.achievements.first { $0.id == "perfectionist" }
        XCTAssertTrue(perfectionist?.isUnlocked ?? false, "Should unlock with perfect score")
        XCTAssertEqual(perfectionist?.progress, 1)
    }

    func testPerfectionistDoesNotUnlockWithoutPerfectScore() {
        achievementManager.checkAchievements(
            totalAnswered: 10,
            currentStreak: 0,
            perfectScore: false
        )

        let perfectionist = achievementManager.achievements.first { $0.id == "perfectionist" }
        XCTAssertFalse(perfectionist?.isUnlocked ?? true, "Should not unlock without perfect score")
        XCTAssertEqual(perfectionist?.progress, 0)
    }

    // MARK: - Streak Achievement Tests (Week Warrior, Month Master, Consistent Learner)

    func testWeekWarriorUnlockAt7DayStreak() {
        achievementManager.checkAchievements(
            totalAnswered: 50,
            currentStreak: 7,
            perfectScore: false
        )

        let weekWarrior = achievementManager.achievements.first { $0.id == "week_warrior" }
        XCTAssertTrue(weekWarrior?.isUnlocked ?? false, "Should unlock at 7 day streak")
        XCTAssertEqual(weekWarrior?.progress, 7)
    }

    func testWeekWarriorProgressTracking() {
        achievementManager.checkAchievements(
            totalAnswered: 20,
            currentStreak: 4,
            perfectScore: false
        )

        let weekWarrior = achievementManager.achievements.first { $0.id == "week_warrior" }
        XCTAssertFalse(weekWarrior?.isUnlocked ?? true, "Should not unlock at 4 day streak")
        XCTAssertEqual(weekWarrior?.progress, 4, "Should track streak progress")
    }

    func testMonthMasterUnlockAt30DayStreak() {
        achievementManager.checkAchievements(
            totalAnswered: 200,
            currentStreak: 30,
            perfectScore: false
        )

        let monthMaster = achievementManager.achievements.first { $0.id == "month_master" }
        XCTAssertTrue(monthMaster?.isUnlocked ?? false, "Should unlock at 30 day streak")
        XCTAssertEqual(monthMaster?.progress, 30)
    }

    func testConsistentLearnerUnlockAt10DayStreak() {
        achievementManager.checkAchievements(
            totalAnswered: 50,
            currentStreak: 10,
            perfectScore: false
        )

        let consistentLearner = achievementManager.achievements.first { $0.id == "consistent_learner" }
        XCTAssertTrue(consistentLearner?.isUnlocked ?? false, "Should unlock at 10 day streak")
        XCTAssertEqual(consistentLearner?.progress, 10)
    }

    func testMultipleStreakAchievementsUnlockSimultaneously() {
        achievementManager.checkAchievements(
            totalAnswered: 100,
            currentStreak: 30,
            perfectScore: false
        )

        let weekWarrior = achievementManager.achievements.first { $0.id == "week_warrior" }
        let consistentLearner = achievementManager.achievements.first { $0.id == "consistent_learner" }
        let monthMaster = achievementManager.achievements.first { $0.id == "month_master" }

        XCTAssertTrue(weekWarrior?.isUnlocked ?? false, "Week Warrior should unlock")
        XCTAssertTrue(consistentLearner?.isUnlocked ?? false, "Consistent Learner should unlock")
        XCTAssertTrue(monthMaster?.isUnlocked ?? false, "Month Master should unlock")
    }

    // MARK: - Speed Demon Achievement Tests

    func testSpeedDemonUnlockUnder20Minutes() {
        achievementManager.checkAchievements(
            totalAnswered: 46,
            currentStreak: 0,
            perfectScore: false,
            testTimeSeconds: 1199 // 19:59
        )

        let speedDemon = achievementManager.achievements.first { $0.id == "speed_demon" }
        XCTAssertTrue(speedDemon?.isUnlocked ?? false, "Should unlock under 20 minutes (1200 seconds)")
        XCTAssertEqual(speedDemon?.progress, 1)
    }

    func testSpeedDemonDoesNotUnlockAt20MinutesExact() {
        achievementManager.checkAchievements(
            totalAnswered: 46,
            currentStreak: 0,
            perfectScore: false,
            testTimeSeconds: 1200 // Exactly 20:00
        )

        let speedDemon = achievementManager.achievements.first { $0.id == "speed_demon" }
        XCTAssertFalse(speedDemon?.isUnlocked ?? true, "Should not unlock at exactly 20 minutes")
    }

    func testSpeedDemonDoesNotUnlockOver20Minutes() {
        achievementManager.checkAchievements(
            totalAnswered: 46,
            currentStreak: 0,
            perfectScore: false,
            testTimeSeconds: 1201 // 20:01
        )

        let speedDemon = achievementManager.achievements.first { $0.id == "speed_demon" }
        XCTAssertFalse(speedDemon?.isUnlocked ?? true, "Should not unlock over 20 minutes")
    }

    // MARK: - Comeback Kid Achievement Tests

    func testComebackKidUnlockWith20PercentImprovement() {
        achievementManager.checkAchievements(
            totalAnswered: 20,
            currentStreak: 0,
            perfectScore: false,
            scoreImprovement: 20
        )

        let comebackKid = achievementManager.achievements.first { $0.id == "comeback_kid" }
        XCTAssertTrue(comebackKid?.isUnlocked ?? false, "Should unlock with 20% improvement")
        XCTAssertEqual(comebackKid?.progress, 1)
    }

    func testComebackKidDoesNotUnlockBelow20Percent() {
        achievementManager.checkAchievements(
            totalAnswered: 20,
            currentStreak: 0,
            perfectScore: false,
            scoreImprovement: 19
        )

        let comebackKid = achievementManager.achievements.first { $0.id == "comeback_kid" }
        XCTAssertFalse(comebackKid?.isUnlocked ?? true, "Should not unlock with 19% improvement")
    }

    // MARK: - Category Master Achievement Tests

    func testCategoryMasterUnlockWith100PercentAccuracy() {
        achievementManager.checkAchievements(
            totalAnswered: 50,
            currentStreak: 0,
            perfectScore: false,
            categoryAccuracy: ["Traffic Signs": 1.0]
        )

        let categoryMaster = achievementManager.achievements.first { $0.id == "category_master" }
        XCTAssertTrue(categoryMaster?.isUnlocked ?? false, "Should unlock with 100% in any category")
        XCTAssertEqual(categoryMaster?.progress, 1)
    }

    func testCategoryMasterDoesNotUnlockWithLessThan100Percent() {
        achievementManager.checkAchievements(
            totalAnswered: 50,
            currentStreak: 0,
            perfectScore: false,
            categoryAccuracy: ["Traffic Signs": 0.99]
        )

        let categoryMaster = achievementManager.achievements.first { $0.id == "category_master" }
        XCTAssertFalse(categoryMaster?.isUnlocked ?? true, "Should not unlock with 99% accuracy")
    }

    // MARK: - Road Sign Pro Achievement Tests

    func testRoadSignProUnlockWith90PercentInTrafficSigns() {
        achievementManager.checkAchievements(
            totalAnswered: 50,
            currentStreak: 0,
            perfectScore: false,
            categoryAccuracy: ["Traffic Signs": 0.9]
        )

        let roadSignPro = achievementManager.achievements.first { $0.id == "road_sign_pro" }
        XCTAssertTrue(roadSignPro?.isUnlocked ?? false, "Should unlock with 90%+ in Traffic Signs")
        XCTAssertEqual(roadSignPro?.progress, 90)
    }

    func testRoadSignProProgressTracking() {
        achievementManager.checkAchievements(
            totalAnswered: 50,
            currentStreak: 0,
            perfectScore: false,
            categoryAccuracy: ["Traffic Signs": 0.85]
        )

        let roadSignPro = achievementManager.achievements.first { $0.id == "road_sign_pro" }
        XCTAssertFalse(roadSignPro?.isUnlocked ?? true, "Should not unlock with 85%")
    }

    func testRoadSignProRequiresTrafficSignsCategory() {
        achievementManager.checkAchievements(
            totalAnswered: 50,
            currentStreak: 0,
            perfectScore: false,
            categoryAccuracy: ["Other Category": 0.95]
        )

        let roadSignPro = achievementManager.achievements.first { $0.id == "road_sign_pro" }
        XCTAssertFalse(roadSignPro?.isUnlocked ?? true, "Should only unlock for Traffic Signs category")
    }

    // MARK: - Progress Percentage Tests

    func testProgressPercentageCalculation() {
        let achievement = Achievement(
            id: "test",
            name: "Test",
            description: "Test",
            icon: "test",
            isUnlocked: false,
            progress: 5,
            requirement: 10
        )

        XCTAssertEqual(achievement.progressPercentage, 0.5, accuracy: 0.01, "Should be 50%")
    }

    func testProgressPercentageCappedAt100Percent() {
        let achievement = Achievement(
            id: "test",
            name: "Test",
            description: "Test",
            icon: "test",
            isUnlocked: false,
            progress: 15,
            requirement: 10
        )

        XCTAssertEqual(achievement.progressPercentage, 1.0, accuracy: 0.01, "Should cap at 100%")
    }

    // MARK: - Unlocked Count Tests

    func testUnlockedCountInitiallyZero() {
        XCTAssertEqual(achievementManager.unlockedCount, 0, "Should start with 0 unlocked")
    }

    func testUnlockedCountAfterUnlocking() {
        achievementManager.checkAchievements(
            totalAnswered: 15,
            currentStreak: 0,
            perfectScore: true
        )

        XCTAssertGreaterThan(achievementManager.unlockedCount, 0, "Should have unlocked achievements")
    }

    // MARK: - Newly Unlocked Achievement Tests

    @MainActor
    func testNewlyUnlockedAchievementIsSet() async throws {
        achievementManager.checkAchievements(
            totalAnswered: 15,
            currentStreak: 0,
            perfectScore: false
        )

        // Wait for async task (0.5s delay in AchievementManager + small buffer)
        try await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds

        XCTAssertNotNil(achievementManager.newlyUnlockedAchievement, "Should set newly unlocked achievement")
    }

    func testDismissAchievement() {
        achievementManager.newlyUnlockedAchievement = Achievement.allAchievements[0]
        XCTAssertNotNil(achievementManager.newlyUnlockedAchievement)

        achievementManager.dismissAchievement()
        XCTAssertNil(achievementManager.newlyUnlockedAchievement, "Should clear newly unlocked achievement")
    }

    // MARK: - Edge Cases

    func testCheckAchievementsWithZeroValues() {
        achievementManager.checkAchievements(
            totalAnswered: 0,
            currentStreak: 0,
            perfectScore: false
        )

        XCTAssertEqual(achievementManager.unlockedCount, 0, "Should not unlock anything with zero values")
    }

    func testCheckAchievementsWithNegativeValues() {
        // Should handle gracefully even though this shouldn't happen
        achievementManager.checkAchievements(
            totalAnswered: -1,
            currentStreak: -1,
            perfectScore: false
        )

        XCTAssertEqual(achievementManager.unlockedCount, 0, "Should handle negative values gracefully")
    }

    func testMultipleChecksDoNotDuplicateUnlocks() {
        achievementManager.checkAchievements(
            totalAnswered: 15,
            currentStreak: 0,
            perfectScore: false
        )

        let countAfterFirst = achievementManager.unlockedCount

        achievementManager.checkAchievements(
            totalAnswered: 15,
            currentStreak: 0,
            perfectScore: false
        )

        let countAfterSecond = achievementManager.unlockedCount

        XCTAssertEqual(countAfterFirst, countAfterSecond, "Should not unlock same achievement twice")
    }

    // MARK: - Integration Tests

    func testCompleteAchievementFlow() {
        // Start with no achievements
        XCTAssertEqual(achievementManager.unlockedCount, 0)

        // Answer 15 questions
        achievementManager.checkAchievements(
            totalAnswered: 15,
            currentStreak: 0,
            perfectScore: false
        )
        XCTAssertGreaterThan(achievementManager.unlockedCount, 0)

        // Continue to 100 questions
        achievementManager.checkAchievements(
            totalAnswered: 100,
            currentStreak: 7,
            perfectScore: false
        )
        XCTAssertGreaterThan(achievementManager.unlockedCount, 1)

        // Verify persistence
        achievementManager.saveAchievements()
        let savedCount = achievementManager.unlockedCount

        achievementManager.loadAchievements()
        XCTAssertEqual(achievementManager.unlockedCount, savedCount, "Should persist unlocked achievements")
    }

    // MARK: - Performance Tests

    func testSaveAchievementsPerformance() {
        achievementManager.checkAchievements(
            totalAnswered: 100,
            currentStreak: 15,
            perfectScore: true
        )

        measure {
            achievementManager.saveAchievements()
        }
    }
}
