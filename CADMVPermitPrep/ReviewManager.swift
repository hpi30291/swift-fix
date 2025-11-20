import Foundation
import StoreKit

/// Manages App Store review requests with intelligent timing
/// Asks users to leave reviews at optimal moments when they're likely to be happy
class ReviewManager {
    static let shared = ReviewManager()

    private let defaults = UserDefaults.standard
    private let eventTracker = EventTracker.shared

    // MARK: - UserDefaults Keys
    private let lastReviewRequestDateKey = "lastReviewRequestDate"
    private let reviewRequestCountKey = "reviewRequestCount"
    private let hasLeftReviewKey = "hasLeftReview"
    private let significantEventsCountKey = "significantEventsCount"

    // MARK: - Configuration
    private let minimumDaysBetweenRequests = 90  // 3 months between requests
    private let maxRequestsPerYear = 3           // Max 3 times per year
    private let significantEventsRequired = 5     // Need 5 positive events before asking

    private init() {}

    // MARK: - Public Methods

    /// Check if we should request a review after a significant positive event
    @MainActor func requestReviewIfAppropriate(after event: SignificantEvent) {
        // Don't ask if user already left a review recently
        guard !hasReviewedRecently() else { return }

        // Don't exceed max requests per year
        guard !hasExceededMaxRequests() else { return }

        // Increment significant events counter
        incrementSignificantEvents()

        // Only ask after enough positive events
        guard hasEnoughSignificantEvents() else { return }

        // Check if enough time has passed since last request
        guard hasEnoughTimePassed() else { return }

        // All conditions met - request review!
        requestReview(trigger: event.rawValue)
    }

    /// Manually request review (for settings/about screen)
    @MainActor func manualReviewRequest() {
        requestReview(trigger: "manual_settings")
    }

    // MARK: - Significant Events

    /// Events that indicate user is having a positive experience
    enum SignificantEvent: String {
        // Free user events
        case completedDiagnostic = "completed_diagnostic_test"
        case firstQuizPassed = "first_quiz_passed"
        case dailyGoalCompleted = "daily_goal_completed"
        case weekStreakReached = "week_streak_reached"
        case achievementUnlocked = "achievement_unlocked"
        case highAccuracyQuiz = "high_accuracy_quiz"  // 90%+ on quiz

        // Paid user events
        case purchaseCompleted = "purchase_completed"
        case firstLessonCompleted = "first_lesson_completed"
        case moduleCompleted = "module_completed"
        case readyToTest = "ready_to_test"  // Reached 85%+ readiness
        case monthStreak = "month_streak_reached"
        case aiTutorUsedSuccessfully = "ai_tutor_used_successfully"
    }

    // MARK: - Review Request Logic

    @MainActor private func requestReview(trigger: String) {
        let isPremium = UserAccessManager.shared.hasActiveSubscription

        // Track analytics - Review requested
        eventTracker.trackReviewRequested(
            trigger: trigger,
            significantEventsCount: getSignificantEventsCount(),
            isPremium: isPremium
        )

        // Update last request date
        defaults.set(Date(), forKey: lastReviewRequestDateKey)

        // Increment request count
        let currentCount = defaults.integer(forKey: reviewRequestCountKey)
        defaults.set(currentCount + 1, forKey: reviewRequestCountKey)

        // Store trigger for later tracking
        defaults.set(trigger, forKey: "lastReviewTrigger")

        // Reset significant events counter
        defaults.set(0, forKey: significantEventsCountKey)

        // Request review from App Store
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            if #available(iOS 18.0, *) {
                AppStore.requestReview(in: scene)
            } else {
                SKStoreReviewController.requestReview(in: scene)
            }

            // Track that prompt was shown (happens immediately)
            eventTracker.trackReviewPromptShown(trigger: trigger)

            // Monitor for dismissal (user continues using app within 5 seconds)
            monitorForReviewDismissal(trigger: trigger)
        }
    }

    // MARK: - Review Outcome Tracking

    /// Monitor if user dismissed the review prompt (they continue using app quickly)
    private func monitorForReviewDismissal(trigger: String) {
        let requestTime = Date()

        // Check after 5 seconds if user is still in app
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self = self else { return }

            // If app is still active and they didn't leave to App Store, they likely dismissed
            let secondsSince = Int(Date().timeIntervalSince(requestTime))
            self.eventTracker.trackReviewDismissed(
                trigger: trigger,
                secondsBeforeDismiss: secondsSince
            )
        }

        // Check after 30 seconds - if they left and came back, they might have reviewed
        DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) { [weak self] in
            guard let self = self else { return }

            // Check if app went to background and came back (sign of App Store visit)
            if self.didAppGoToBackgroundRecently(within: 30) {
                self.eventTracker.trackReviewLikelyCompleted(trigger: trigger)

                // Mark that user has reviewed (so we don't ask again soon)
                self.defaults.set(true, forKey: self.hasLeftReviewKey)
            }
        }
    }

    /// Check if app went to background recently (user might have gone to App Store)
    private func didAppGoToBackgroundRecently(within seconds: Int) -> Bool {
        // This is a heuristic - we can't know for sure if they reviewed
        // But if the app backgrounded shortly after review request, it's likely
        if let lastBackgroundDate = defaults.object(forKey: "lastBackgroundDate") as? Date {
            let secondsSince = Int(Date().timeIntervalSince(lastBackgroundDate))
            return secondsSince <= seconds
        }
        return false
    }

    // MARK: - Helper Methods

    private func hasReviewedRecently() -> Bool {
        guard let lastDate = defaults.object(forKey: lastReviewRequestDateKey) as? Date else {
            return false
        }

        let daysSince = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        return daysSince < minimumDaysBetweenRequests
    }

    private func hasExceededMaxRequests() -> Bool {
        let requestCount = defaults.integer(forKey: reviewRequestCountKey)

        // Reset counter if it's been over a year since first request
        if let lastDate = defaults.object(forKey: lastReviewRequestDateKey) as? Date {
            let daysSince = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
            if daysSince > 365 {
                defaults.set(0, forKey: reviewRequestCountKey)
                return false
            }
        }

        return requestCount >= maxRequestsPerYear
    }

    private func incrementSignificantEvents() {
        let current = getSignificantEventsCount()
        defaults.set(current + 1, forKey: significantEventsCountKey)
    }

    private func getSignificantEventsCount() -> Int {
        return defaults.integer(forKey: significantEventsCountKey)
    }

    private func hasEnoughSignificantEvents() -> Bool {
        return getSignificantEventsCount() >= significantEventsRequired
    }

    private func hasEnoughTimePassed() -> Bool {
        guard let lastDate = defaults.object(forKey: lastReviewRequestDateKey) as? Date else {
            return true  // Never asked before
        }

        let daysSince = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        return daysSince >= minimumDaysBetweenRequests
    }

    // MARK: - Debug Helpers

    #if DEBUG
    /// Reset review request state (for testing)
    func resetForTesting() {
        defaults.removeObject(forKey: lastReviewRequestDateKey)
        defaults.removeObject(forKey: reviewRequestCountKey)
        defaults.removeObject(forKey: hasLeftReviewKey)
        defaults.removeObject(forKey: significantEventsCountKey)
        print("🧪 ReviewManager reset for testing")
    }

    /// Get debug info about review state
    func debugInfo() -> String {
        let lastDate = defaults.object(forKey: lastReviewRequestDateKey) as? Date
        let requestCount = defaults.integer(forKey: reviewRequestCountKey)
        let eventsCount = getSignificantEventsCount()

        var info = "📊 ReviewManager Debug Info:\n"
        info += "   Last request: \(lastDate?.description ?? "Never")\n"
        info += "   Request count: \(requestCount)/\(maxRequestsPerYear)\n"
        info += "   Significant events: \(eventsCount)/\(significantEventsRequired)\n"
        info += "   Can request: \(!hasReviewedRecently() && !hasExceededMaxRequests() && hasEnoughSignificantEvents())\n"

        return info
    }
    #endif
}

// MARK: - Recommended Trigger Points

/*

 WHEN TO ASK FOR REVIEWS

 ═══════════════════════════════════════════════════════════════════════════════

 ## FREE USERS - Focus on Early Wins

 Ask after they've experienced value but BEFORE they hit the paywall:

 1. **After completing diagnostic test with passing score**
    - They just learned their baseline
    - Positive first impression
    - Timing: Right after seeing results (if passed)

 2. **After first quiz with 80%+ accuracy**
    - They feel smart and capable
    - Positive reinforcement moment
    - Timing: Results screen

 3. **After reaching 7-day streak**
    - They're engaged and committed
    - Building a habit
    - Timing: When streak milestone is shown

 4. **After daily goal completed 3x**
    - They're consistent users
    - Getting value regularly
    - Timing: After 3rd daily goal completion

 5. **After first achievement unlocked**
    - Gamification working
    - Feeling accomplished
    - Timing: When achievement popup is dismissed

 ═══════════════════════════════════════════════════════════════════════════════

 ## PAID USERS - Focus on Advanced Wins

 Ask after they've gotten value from premium features:

 1. **3 days after purchase**
    - Honeymoon period
    - Excited about premium features
    - Timing: After 3rd login post-purchase

 2. **After completing first Learn Mode module**
    - Successfully using premium feature
    - Learning and improving
    - Timing: Module completion screen

 3. **After reaching 85%+ readiness**
    - Close to being test-ready
    - Seeing real progress
    - Timing: When readiness card updates

 4. **After 30-day streak**
    - Long-term engaged user
    - Getting consistent value
    - Timing: When milestone is shown

 5. **After AI Tutor helps them understand a concept**
    - Premium feature delivering value
    - "Aha!" moment
    - Timing: After successful AI interaction

 ═══════════════════════════════════════════════════════════════════════════════

 ## BEST PRACTICES

 ✅ **DO:**
 - Ask after positive experiences (high score, achievement, streak)
 - Space requests at least 90 days apart
 - Limit to 3 requests per year maximum
 - Require 5 positive events before asking
 - Use native SKStoreReviewController (in-app popup)
 - Track when you've asked to avoid over-asking

 ❌ **DON'T:**
 - Ask after negative experiences (failed quiz, low score)
 - Ask immediately after launch
 - Ask when user hits paywall/limit
 - Ask repeatedly if they dismiss
 - Use custom UI (Apple requires native)
 - Interrupt critical flows (during quiz)

 ═══════════════════════════════════════════════════════════════════════════════

 ## IMPLEMENTATION EXAMPLES

 ### Free User - After Diagnostic Test
 ```swift
 if diagnosticResult.passed {
     ReviewManager.shared.requestReviewIfAppropriate(after: .completedDiagnostic)
 }
 ```

 ### Free User - After High-Score Quiz
 ```swift
 let accuracy = Double(correctAnswers) / Double(totalQuestions)
 if accuracy >= 0.90 {
     ReviewManager.shared.requestReviewIfAppropriate(after: .highAccuracyQuiz)
 }
 ```

 ### Free User - After Streak Milestone
 ```swift
 if currentStreak == 7 {
     ReviewManager.shared.requestReviewIfAppropriate(after: .weekStreakReached)
 } else if currentStreak == 30 {
     ReviewManager.shared.requestReviewIfAppropriate(after: .monthStreak)
 }
 ```

 ### Paid User - After Purchase
 ```swift
 // Wait 3 days after purchase
 if daysSincePurchase == 3 {
     ReviewManager.shared.requestReviewIfAppropriate(after: .purchaseCompleted)
 }
 ```

 ### Paid User - After Module Completion
 ```swift
 ReviewManager.shared.requestReviewIfAppropriate(after: .moduleCompleted)
 ```

 ### Paid User - After Reaching Readiness
 ```swift
 if readiness.percentage >= 85 {
     ReviewManager.shared.requestReviewIfAppropriate(after: .readyToTest)
 }
 ```

 ═══════════════════════════════════════════════════════════════════════════════

 ## ANALYTICS TO MONITOR

 Track these events to optimize timing:

 - review_requested (trigger, significant_events_count)
 - review_shown (did the popup actually appear?)
 - review_completed (did user leave a review? - estimated)
 - review_dismissed (user dismissed popup)

 Monitor conversion by trigger:
 - Which events lead to most reviews?
 - Are free or paid users more likely to review?
 - What's the optimal number of positive events?

 ═══════════════════════════════════════════════════════════════════════════════

 */
