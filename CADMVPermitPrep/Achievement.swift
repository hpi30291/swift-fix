import Foundation

struct Achievement: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let icon: String
    var isUnlocked: Bool
    var progress: Int
    let requirement: Int
    
    var progressPercentage: Double {
        min(Double(progress) / Double(requirement), 1.0)
    }
    
    static let allAchievements: [Achievement] = [
        Achievement(
            id: "first_steps",
            name: "First Steps",
            description: "Answer 15 questions",
            icon: "figure.walk",
            isUnlocked: false,
            progress: 0,
            requirement: 15
        ),
        Achievement(
            id: "getting_serious",
            name: "Getting Serious",
            description: "Answer 100 questions",
            icon: "brain.head.profile",
            isUnlocked: false,
            progress: 0,
            requirement: 100
        ),
        Achievement(
            id: "perfectionist",
            name: "Perfectionist",
            description: "Get perfect score on practice test",
            icon: "star.circle.fill",
            isUnlocked: false,
            progress: 0,
            requirement: 1
        ),
        Achievement(
            id: "week_warrior",
            name: "Week Warrior",
            description: "Maintain 7 day streak",
            icon: "flame.fill",
            isUnlocked: false,
            progress: 0,
            requirement: 7
        ),
        Achievement(
            id: "month_master",
            name: "Month Master",
            description: "Maintain 30 day streak",
            icon: "crown.fill",
            isUnlocked: false,
            progress: 0,
            requirement: 30
        ),
        Achievement(
            id: "speed_demon",
            name: "Speed Demon",
            description: "Complete test under 20 minutes",
            icon: "bolt.fill",
            isUnlocked: false,
            progress: 0,
            requirement: 1
        ),
        Achievement(
            id: "comeback_kid",
            name: "Comeback Kid",
            description: "Improve score by 20%",
            icon: "arrow.up.circle.fill",
            isUnlocked: false,
            progress: 0,
            requirement: 1
        ),
        Achievement(
            id: "category_master",
            name: "Category Master",
            description: "Get 100% in any category",
            icon: "checkmark.seal.fill",
            isUnlocked: false,
            progress: 0,
            requirement: 1
        ),
        Achievement(
            id: "road_sign_pro",
            name: "Road Sign Pro",
            description: "90%+ accuracy in Road Signs",
            icon: "shield.fill",
            isUnlocked: false,
            progress: 0,
            requirement: 90
        ),
        Achievement(
            id: "consistent_learner",
            name: "Consistent Learner",
            description: "Study 10 days in a row",
            icon: "calendar.badge.checkmark",
            isUnlocked: false,
            progress: 0,
            requirement: 10
        )
    ]
}
