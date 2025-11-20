import Foundation
import SwiftUI

// MARK: - Lesson Model
struct Lesson: Identifiable, Codable {
    let lessonNumber: Int
    let title: String
    let icon: String
    let overview: String
    let keyPoints: [String]
    let detailedContent: String
    let example: String
    let memoryTip: String
    let images: [String]
    let estimatedReadTime: Int

    var id: String {
        "\(lessonNumber)"
    }

    // Progress tracking (not stored in JSON, loaded from UserDefaults)
    var isCompleted: Bool {
        get {
            // Will be implemented in LearnManager
            return false
        }
    }
}

// MARK: - Module Model
struct Module: Identifiable, Codable {
    let moduleId: String
    let moduleName: String
    let icon: String
    let color: String
    let lessons: [Lesson]

    var id: String { moduleId }

    // Computed properties
    var totalLessons: Int {
        lessons.count
    }

    var completedCount: Int {
        // Will be calculated from UserDefaults
        0
    }

    var progress: Double {
        guard totalLessons > 0 else { return 0 }
        return Double(completedCount) / Double(totalLessons)
    }

    var estimatedTime: Int {
        lessons.reduce(0) { $0 + $1.estimatedReadTime }
    }

    var swiftUIColor: Color {
        return Color(hex: color)
    }
}
