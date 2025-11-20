import Foundation
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

/// Centralized event tracking for Firebase Analytics
/// This class makes it easy to track user actions throughout the app
/// Gracefully handles offline scenarios by queuing events locally
class EventTracker {

    static let shared = EventTracker()

    private let networkMonitor = NetworkMonitor.shared
    private var queuedEvents: [(name: String, parameters: [String: Any])] = []
    private let maxQueueSize = 100

    private init() {
        // Attempt to flush queued events when network becomes available
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(networkStatusChanged),
            name: NSNotification.Name("NetworkStatusChanged"),
            object: nil
        )
    }

    @objc private func networkStatusChanged() {
        if networkMonitor.isConnected {
            flushQueuedEvents()
        }
    }

    private func flushQueuedEvents() {
        guard networkMonitor.isConnected else { return }

        #if canImport(FirebaseAnalytics)
        for event in queuedEvents { Analytics.logEvent(event.name, parameters: event.parameters) }
        #endif
        queuedEvents.removeAll()
    }

    private func safeLogEvent(_ name: String, parameters: [String: Any]) {
        #if DEBUG
        debugLog(name, parameters: parameters)
        #endif

        #if canImport(FirebaseAnalytics)
        if networkMonitor.isConnected { Analytics.logEvent(name, parameters: parameters) } else {
            // Queue event for later if offline
            if queuedEvents.count < maxQueueSize {
                queuedEvents.append((name, parameters))
            }
        }
        #endif
    }

    // MARK: - Quiz Events

    /// Track when a quiz starts
    func trackQuizStarted(category: String, questionCount: Int) {
        safeLogEvent("quiz_started", parameters: [
            "category": category,
            "question_count": questionCount
        ])
    }

    /// Track when a quiz is completed
    func trackQuizCompleted(
        category: String,
        totalQuestions: Int,
        correctAnswers: Int,
        timeSpent: TimeInterval
    ) {
        let accuracy = Double(correctAnswers) / Double(totalQuestions) * 100

        safeLogEvent("quiz_completed", parameters: [
            "category": category,
            "total_questions": totalQuestions,
            "correct_answers": correctAnswers,
            "accuracy_percentage": accuracy,
            "time_spent_seconds": Int(timeSpent)
        ])
    }

    // MARK: - Question Events

    /// Track individual question answers
    func trackQuestionAnswered(
        questionId: String,
        category: String,
        wasCorrect: Bool,
        timeTaken: TimeInterval
    ) {
        safeLogEvent("question_answered", parameters: [
            "question_id": questionId,
            "category": category,
            "was_correct": wasCorrect,
            "time_taken_seconds": Int(timeTaken)
        ])
    }

    // MARK: - Achievement Events

    /// Track when an achievement is unlocked
    func trackAchievementUnlocked(achievementId: String, achievementName: String) {
        safeLogEvent("achievement_unlocked", parameters: [
            "achievement_id": achievementId,
            "achievement_name": achievementName
        ])
    }

    // MARK: - Progress Events

    /// Track when user levels up
    func trackLevelUp(newLevel: Int, totalPoints: Int) {
        safeLogEvent("level_up", parameters: [
            "new_level": newLevel,
            "total_points": totalPoints
        ])
    }

    /// Track streak milestones
    func trackStreakMilestone(streakDays: Int) {
        safeLogEvent("streak_milestone", parameters: [
            "streak_days": streakDays
        ])
    }

    /// Track daily goal completion
    func trackDailyGoalCompleted(questionsAnswered: Int) {
        safeLogEvent("daily_goal_completed", parameters: [
            "questions_answered": questionsAnswered
        ])
    }

    // MARK: - Readiness Events

    /// Track when user checks their readiness
    func trackReadinessChecked(percentage: Double, status: String) {
        safeLogEvent("readiness_checked", parameters: [
            "readiness_percentage": percentage,
            "readiness_status": status
        ])
    }

    /// Convenience overload to match test labels
    func trackReadinessChecked(readinessPercentage percentage: Double, readinessStatus status: String) {
        trackReadinessChecked(percentage: percentage, status: status)
    }

    // MARK: - Navigation Events

    /// Track screen views
    func trackScreenView(screenName: String) {
        #if canImport(FirebaseAnalytics)
        safeLogEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName,
            AnalyticsParameterScreenClass: screenName
        ])
        #else
        safeLogEvent("screen_view", parameters: ["screen_name": screenName])
        #endif
    }

    // MARK: - Study Session Events

    /// Track when user starts a study session
    func trackStudySessionStarted(mode: String) {
        safeLogEvent("study_session_started", parameters: [
            "mode": mode // "adaptive", "category", "random"
        ])
    }

    /// Track when user ends a study session
    func trackStudySessionEnded(duration: TimeInterval, questionsAnswered: Int) {
        safeLogEvent("study_session_ended", parameters: [
            "duration_seconds": Int(duration),
            "questions_answered": questionsAnswered
        ])
    }

    // MARK: - Category Performance Events

    /// Track when a category is mastered (high accuracy)
    func trackCategoryMastered(category: String, accuracy: Double) {
        safeLogEvent("category_mastered", parameters: [
            "category": category,
            "accuracy_percentage": accuracy
        ])
    }

    /// Track when weak category is identified
    func trackWeakCategoryIdentified(category: String, accuracy: Double) {
        safeLogEvent("weak_category_identified", parameters: [
            "category": category,
            "accuracy_percentage": accuracy
        ])
    }

    // MARK: - Settings Events

    /// Track when user changes settings
    func trackSettingChanged(settingName: String, newValue: String) {
        safeLogEvent("setting_changed", parameters: [
            "setting_name": settingName,
            "new_value": newValue
        ])
    }

    // MARK: - Monetization Events

    /// Track when paywall is viewed
    func trackPaywallViewed(trigger: String, score: Int? = nil, testsRemaining: Int? = nil) {
        var params: [String: Any] = ["trigger": trigger]
        if let score = score {
            params["diagnostic_score"] = score
        }
        if let testsRemaining = testsRemaining {
            params["tests_remaining"] = testsRemaining
        }
        safeLogEvent("paywall_viewed", parameters: params)
    }

    /// Track when purchase is initiated
    func trackPurchaseInitiated(trigger: String) {
        safeLogEvent("purchase_initiated", parameters: [
            "trigger": trigger,
            "product_id": "lifetime_access"
        ])
    }

    /// Track when purchase is completed
    func trackPurchaseCompleted(price: Double = 14.99) {
        #if canImport(FirebaseAnalytics)
        safeLogEvent(AnalyticsEventPurchase, parameters: [
            AnalyticsParameterItemID: "lifetime_access",
            AnalyticsParameterPrice: price,
            AnalyticsParameterCurrency: "USD",
            AnalyticsParameterValue: price
        ])
        #else
        safeLogEvent("purchase", parameters: [
            "item_id": "lifetime_access",
            "price": price,
            "currency": "USD",
            "value": price
        ])
        #endif

        // Also log custom event for easier filtering
        safeLogEvent("purchase_completed", parameters: [
            "product_id": "lifetime_access",
            "price": price,
            "currency": "USD"
        ])
    }

    /// Track when purchase fails
    func trackPurchaseFailed(error: String, trigger: String) {
        safeLogEvent("purchase_failed", parameters: [
            "error": error,
            "trigger": trigger
        ])
    }

    /// Track when user cancels purchase
    func trackPurchaseCancelled(trigger: String) {
        safeLogEvent("purchase_cancelled", parameters: [
            "trigger": trigger
        ])
    }

    /// Track when restore purchase is attempted
    func trackRestorePurchaseAttempted() {
        safeLogEvent("restore_purchase_attempted", parameters: [:])
    }

    /// Track when restore purchase succeeds
    func trackRestorePurchaseSucceeded() {
        safeLogEvent("restore_purchase_succeeded", parameters: [:])
    }

    /// Track when restore purchase fails
    func trackRestorePurchaseFailed(error: String) {
        safeLogEvent("restore_purchase_failed", parameters: [
            "error": error
        ])
    }

    // MARK: - Learn Mode Events

    /// Track when user starts a lesson
    func trackLessonStarted(moduleId: String, lessonId: String, lessonTitle: String) {
        safeLogEvent("lesson_started", parameters: [
            "module_id": moduleId,
            "lesson_id": lessonId,
            "lesson_title": lessonTitle
        ])
    }

    /// Track when user completes a lesson
    func trackLessonCompleted(moduleId: String, lessonId: String, timeSpent: TimeInterval) {
        safeLogEvent("lesson_completed", parameters: [
            "module_id": moduleId,
            "lesson_id": lessonId,
            "time_spent_seconds": Int(timeSpent)
        ])
    }

    /// Track when user completes a module
    func trackModuleCompleted(moduleId: String, moduleName: String, totalLessons: Int) {
        safeLogEvent("module_completed", parameters: [
            "module_id": moduleId,
            "module_name": moduleName,
            "total_lessons": totalLessons
        ])
    }

    // MARK: - AI Tutor Events

    /// Track when AI tutor is accessed
    func trackAITutorOpened() {
        safeLogEvent("ai_tutor_opened", parameters: [:])
    }

    /// Track when user asks AI a question
    func trackAIQuestionAsked(questionLength: Int, category: String? = nil) {
        var params: [String: Any] = ["question_length": questionLength]
        if let category = category {
            params["category"] = category
        }
        safeLogEvent("ai_question_asked", parameters: params)
    }

    /// Track when AI responds
    func trackAIResponseReceived(responseLength: Int, timeToRespond: TimeInterval) {
        safeLogEvent("ai_response_received", parameters: [
            "response_length": responseLength,
            "time_to_respond_seconds": Int(timeToRespond)
        ])
    }

    /// Track when AI request fails
    func trackAIRequestFailed(error: String) {
        safeLogEvent("ai_request_failed", parameters: [
            "error": error
        ])
    }

    /// Track when user hits rate limit
    func trackAIRateLimitReached(limitType: String) {
        safeLogEvent("ai_rate_limit_reached", parameters: [
            "limit_type": limitType // "hourly" or "daily"
        ])
    }

    // MARK: - Diagnostic Test Events

    /// Track when diagnostic test is started
    func trackDiagnosticStarted() {
        safeLogEvent("diagnostic_test_started", parameters: [:])
    }

    /// Backward-compatible name used in tests
    func trackDiagnosticTestStarted() {
        trackDiagnosticStarted()
    }

    /// Track when diagnostic test is completed
    func trackDiagnosticCompleted(score: Int, totalQuestions: Int, passed: Bool, timeSpent: TimeInterval) {
        let percentage = Int(Double(score) / Double(totalQuestions) * 100)

        safeLogEvent("diagnostic_test_completed", parameters: [
            "score": score,
            "total_questions": totalQuestions,
            "percentage": percentage,
            "passed": passed,
            "time_spent_seconds": Int(timeSpent)
        ])
    }

    /// Backward-compatible name used in tests
    func trackDiagnosticTestCompleted(score: Int, totalQuestions: Int, passed: Bool, timeSpent: TimeInterval) {
        trackDiagnosticCompleted(score: score, totalQuestions: totalQuestions, passed: passed, timeSpent: timeSpent)
    }

    // MARK: - Onboarding Events

    /// Track onboarding step completion
    func trackOnboardingStepCompleted(step: Int, totalSteps: Int) {
        safeLogEvent("onboarding_step_completed", parameters: [
            "step": step,
            "total_steps": totalSteps
        ])
    }

    /// Track onboarding completion
    func trackOnboardingCompleted() {
        safeLogEvent("onboarding_completed", parameters: [:])
    }

    // MARK: - Feature Discovery Events

    /// Track when user discovers a feature
    func trackFeatureDiscovered(featureName: String, discoveryMethod: String) {
        safeLogEvent("feature_discovered", parameters: [
            "feature_name": featureName,
            "discovery_method": discoveryMethod // "tap", "recommendation", "tutorial"
        ])
    }

    /// Track when locked feature is clicked
    func trackLockedFeatureClicked(featureName: String) {
        safeLogEvent("locked_feature_clicked", parameters: [
            "feature_name": featureName
        ])
    }

    // MARK: - Engagement Events

    /// Track app session start
    func trackSessionStart() {
        safeLogEvent(AnalyticsEventAppOpen, parameters: [:])
    }

    /// Track app session end
    func trackSessionEnd(duration: TimeInterval) {
        safeLogEvent("session_ended", parameters: [
            "duration_seconds": Int(duration)
        ])
    }

    /// Track when user returns after X days
    func trackUserReturn(daysSinceLastVisit: Int) {
        safeLogEvent("user_returned", parameters: [
            "days_since_last_visit": daysSinceLastVisit
        ])
    }

    // MARK: - Error Events

    /// Track when an error occurs
    func trackError(errorType: String, errorMessage: String, screen: String? = nil) {
        var params: [String: Any] = [
            "error_type": errorType,
            "error_message": errorMessage
        ]
        if let screen = screen {
            params["screen"] = screen
        }
        safeLogEvent("error_occurred", parameters: params)
    }

    // MARK: - Review Request Events

    /// Track when review is requested
    func trackReviewRequested(trigger: String, significantEventsCount: Int, isPremium: Bool) {
        safeLogEvent("review_requested", parameters: [
            "trigger": trigger,
            "significant_events_count": significantEventsCount,
            "is_premium": isPremium
        ])
    }

    /// Track when review prompt is shown (estimated)
    func trackReviewPromptShown(trigger: String) {
        safeLogEvent("review_prompt_shown", parameters: [
            "trigger": trigger
        ])
    }

    /// Track when review is likely dismissed (user continues using app shortly after)
    func trackReviewDismissed(trigger: String, secondsBeforeDismiss: Int) {
        safeLogEvent("review_dismissed", parameters: [
            "trigger": trigger,
            "seconds_before_dismiss": secondsBeforeDismiss
        ])
    }

    /// Track when we think user left a review (went to App Store)
    func trackReviewLikelyCompleted(trigger: String) {
        safeLogEvent("review_likely_completed", parameters: [
            "trigger": trigger
        ])
    }

    /// Track generic events with parameters
    func trackEvent(name: String, parameters: [String: Any]) {
        safeLogEvent(name, parameters: parameters)
    }

    // MARK: - User Properties

    /// Set user properties for segmentation
    func setUserProperty(name: String, value: String) {
        #if canImport(FirebaseAnalytics)
        Analytics.setUserProperty(value, forName: name)
        #endif
    }

    /// Update user level property
    func updateUserLevel(_ level: Int) {
        #if canImport(FirebaseAnalytics)
        Analytics.setUserProperty("\(level)", forName: "user_level")
        #endif
    }

    /// Update total questions answered property
    func updateTotalQuestionsAnswered(_ count: Int) {
        #if canImport(FirebaseAnalytics)
        Analytics.setUserProperty("\(count)", forName: "total_questions_answered")
        #endif
    }

    // MARK: - Debug Mode

    #if DEBUG
    /// Enable verbose logging in debug mode
    func enableDebugMode() {
        print("📊 Firebase Analytics Debug Mode Enabled")
        print("📊 Events will be printed to console")
        print("📊 Use Firebase DebugView to see real-time events")
        print("📊 Run with -FIRDebugEnabled argument for more details")
    }

    /// Log event to console in debug mode
    private func debugLog(_ name: String, parameters: [String: Any]) {
        print("📊 Analytics Event: \(name)")
        if !parameters.isEmpty {
            print("   Parameters:")
            for (key, value) in parameters {
                print("   - \(key): \(value)")
            }
        }
    }

    /// Reset tracking state for testing
    func resetForTesting() {
        queuedEvents.removeAll()
        print("🧪 EventTracker reset for testing")
    }
    #endif
}

// MARK: - Analytics Debug Helper

#if DEBUG
extension EventTracker {
    /// Test all analytics events (for debugging)
    func testAllEvents() {
        print("\n🧪 Testing All Analytics Events...")

        // Screen views
        trackScreenView(screenName: "test_screen")

        // Quiz events
        trackQuizStarted(category: "Test Category", questionCount: 10)
        trackQuizCompleted(category: "Test Category", totalQuestions: 10, correctAnswers: 8, timeSpent: 120)
        trackQuestionAnswered(questionId: "test_q1", category: "Test Category", wasCorrect: true, timeTaken: 5.0)

        // Diagnostic events
        trackDiagnosticStarted()
        trackDiagnosticCompleted(score: 12, totalQuestions: 15, passed: true, timeSpent: 180)

        // Achievement events
        trackAchievementUnlocked(achievementId: "test_achievement", achievementName: "Test Achievement")
        trackLevelUp(newLevel: 5, totalPoints: 500)
        trackStreakMilestone(streakDays: 7)
        trackDailyGoalCompleted(questionsAnswered: 20)

        // Learn mode events
        trackLessonStarted(moduleId: "module_1", lessonId: "lesson_1", lessonTitle: "Test Lesson")
        trackLessonCompleted(moduleId: "module_1", lessonId: "lesson_1", timeSpent: 60)
        trackModuleCompleted(moduleId: "module_1", moduleName: "Test Module", totalLessons: 5)

        // AI events
        trackAITutorOpened()
        trackAIQuestionAsked(questionLength: 50, category: "Test Category")
        trackAIResponseReceived(responseLength: 200, timeToRespond: 2.5)

        // Monetization events
        trackPaywallViewed(trigger: "test_trigger", score: 12, testsRemaining: 3)
        trackPurchaseInitiated(trigger: "test_trigger")

        // Engagement events
        trackSessionStart()
        trackFeatureDiscovered(featureName: "Test Feature", discoveryMethod: "tap")
        trackLockedFeatureClicked(featureName: "Premium Feature")

        print("✅ All analytics events tested! Check Firebase DebugView\n")
    }
}
#endif
