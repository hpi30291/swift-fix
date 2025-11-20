import Foundation

/// Manages caching of AI recommendations with 24-hour expiration
class AIRecommendationCache {
    static let shared = AIRecommendationCache()

    private let cacheKey = "ai_recommendation_cache"
    private let timestampKey = "ai_recommendation_timestamp"
    private let accuracySnapshotKey = "ai_recommendation_accuracy_snapshot"

    private let cacheExpirationHours: Double = 24

    private init() {}

    // MARK: - Cache Management

    func getCachedRecommendation() -> String? {
        // Check if cache exists and is still valid
        guard let timestamp = UserDefaults.standard.object(forKey: timestampKey) as? Date else {
            return nil
        }

        let hoursSinceCache = Date().timeIntervalSince(timestamp) / 3600

        if hoursSinceCache >= cacheExpirationHours {
            // Cache expired
            clearCache()
            return nil
        }

        // Check if accuracy changed significantly (>5% in any category)
        if hasAccuracyChangedSignificantly() {
            clearCache()
            return nil
        }

        return UserDefaults.standard.string(forKey: cacheKey)
    }

    func cacheRecommendation(_ recommendation: String) {
        UserDefaults.standard.set(recommendation, forKey: cacheKey)
        UserDefaults.standard.set(Date(), forKey: timestampKey)

        // Save current accuracy snapshot
        let accuracySnapshot = getCurrentAccuracySnapshot()
        if let encoded = try? JSONEncoder().encode(accuracySnapshot) {
            UserDefaults.standard.set(encoded, forKey: accuracySnapshotKey)
        }
    }

    func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.removeObject(forKey: timestampKey)
        UserDefaults.standard.removeObject(forKey: accuracySnapshotKey)
    }

    func getCacheTimestamp() -> Date? {
        return UserDefaults.standard.object(forKey: timestampKey) as? Date
    }

    func getTimeSinceLastUpdate() -> String {
        guard let timestamp = getCacheTimestamp() else {
            return "Never"
        }

        let hours = Int(Date().timeIntervalSince(timestamp) / 3600)

        if hours == 0 {
            let minutes = Int(Date().timeIntervalSince(timestamp) / 60)
            if minutes < 1 {
                return "Just now"
            }
            return "\(minutes)m ago"
        } else if hours < 24 {
            return "\(hours)h ago"
        } else {
            let days = hours / 24
            return "\(days)d ago"
        }
    }

    // MARK: - Accuracy Change Detection

    private func getCurrentAccuracySnapshot() -> [String: Double] {
        let categoryPerformance = PerformanceTracker.shared.getAllCategoryPerformance()
        var snapshot: [String: Double] = [:]

        for (category, performance) in categoryPerformance {
            snapshot[category] = performance.accuracy
        }

        return snapshot
    }

    private func hasAccuracyChangedSignificantly() -> Bool {
        // Get saved snapshot
        guard let data = UserDefaults.standard.data(forKey: accuracySnapshotKey),
              let savedSnapshot = try? JSONDecoder().decode([String: Double].self, from: data) else {
            return false
        }

        // Get current accuracy
        let currentSnapshot = getCurrentAccuracySnapshot()

        // Check if any category changed by >5%
        for (category, savedAccuracy) in savedSnapshot {
            if let currentAccuracy = currentSnapshot[category] {
                let change = abs(currentAccuracy - savedAccuracy)
                if change > 0.05 {
                    return true
                }
            }
        }

        // Check for new categories
        for category in currentSnapshot.keys {
            if savedSnapshot[category] == nil {
                return true
            }
        }

        return false
    }

    // MARK: - Manual Refresh Triggers

    func shouldRefreshAfterQuiz() -> Bool {
        // Refresh if user completed a quiz and accuracy changed significantly
        return hasAccuracyChangedSignificantly()
    }
}
