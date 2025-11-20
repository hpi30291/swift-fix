import Foundation

/*

 ANALYTICS TRACKING PLAN
 CA DMV Permit Prep App

 This document outlines all Firebase Analytics events tracked in the app.
 Use this as a reference when analyzing user behavior and conversion funnels.

 ═══════════════════════════════════════════════════════════════════════════════

 ## EVENT NAMING CONVENTION

 - Use snake_case for event names
 - Keep names descriptive but concise
 - Use past tense for completed actions (e.g., "quiz_completed" not "complete_quiz")
 - Group related events with prefixes (e.g., "ai_", "purchase_", "lesson_")

 ═══════════════════════════════════════════════════════════════════════════════

 ## SCREEN VIEW EVENTS

 These events track which screens users visit.

 1. screen_view (Firebase standard event)
    - screen_name: String (e.g., "Home", "Quiz", "Settings")
    - screen_class: String (same as screen_name)

    Tracked in:
    - ContentView (Home)
    - QuizView
    - SettingsView
    - AchievementsView
    - AITutorView
    - LessonView
    - etc.

 ═══════════════════════════════════════════════════════════════════════════════

 ## QUIZ & PRACTICE EVENTS

 2. quiz_started
    - category: String (e.g., "Traffic Signs", "All Categories")
    - question_count: Int (10 or 46)

 3. quiz_completed
    - category: String
    - total_questions: Int
    - correct_answers: Int
    - accuracy_percentage: Double
    - time_spent_seconds: Int

 4. question_answered
    - question_id: String
    - category: String
    - was_correct: Bool
    - time_taken_seconds: Int

 ═══════════════════════════════════════════════════════════════════════════════

 ## DIAGNOSTIC TEST EVENTS

 5. diagnostic_test_started
    - No parameters

 6. diagnostic_test_completed
    - score: Int (e.g., 12)
    - total_questions: Int (15)
    - percentage: Int (80)
    - passed: Bool
    - time_spent_seconds: Int

 ═══════════════════════════════════════════════════════════════════════════════

 ## ACHIEVEMENT & PROGRESS EVENTS

 7. achievement_unlocked
    - achievement_id: String (e.g., "first_steps")
    - achievement_name: String (e.g., "First Steps")

 8. level_up
    - new_level: Int
    - total_points: Int

 9. streak_milestone
    - streak_days: Int (e.g., 7, 30)

 10. daily_goal_completed
     - questions_answered: Int

 ═══════════════════════════════════════════════════════════════════════════════

 ## LEARN MODE EVENTS

 11. lesson_started
     - module_id: String (e.g., "module_1")
     - lesson_id: String (e.g., "lesson_1_1")
     - lesson_title: String

 12. lesson_completed
     - module_id: String
     - lesson_id: String
     - time_spent_seconds: Int

 13. module_completed
     - module_id: String
     - module_name: String
     - total_lessons: Int

 ═══════════════════════════════════════════════════════════════════════════════

 ## AI TUTOR EVENTS

 14. ai_tutor_opened
     - No parameters

 15. ai_question_asked
     - question_length: Int (character count)
     - category: String? (optional, if question is about specific category)

 16. ai_response_received
     - response_length: Int
     - time_to_respond_seconds: Int

 17. ai_request_failed
     - error: String

 18. ai_rate_limit_reached
     - limit_type: String ("hourly" or "daily")

 ═══════════════════════════════════════════════════════════════════════════════

 ## MONETIZATION EVENTS (CRITICAL FOR CONVERSION ANALYSIS)

 19. paywall_viewed
     - trigger: String (e.g., "diagnostic_results", "questions_limit", "locked_feature")
     - diagnostic_score: Int? (optional, only for diagnostic_results trigger)
     - tests_remaining: Int? (optional, only for questions_limit trigger)

 20. purchase_initiated
     - trigger: String (same as paywall trigger)
     - product_id: String ("lifetime_access")

 21. purchase (Firebase standard event)
     - item_id: String ("lifetime_access")
     - price: Double (14.99)
     - currency: String ("USD")
     - value: Double (14.99)

 22. purchase_completed (custom event for easier filtering)
     - product_id: String
     - price: Double
     - currency: String

 23. purchase_failed
     - error: String
     - trigger: String

 24. purchase_cancelled
     - trigger: String

 25. restore_purchase_attempted
     - No parameters

 26. restore_purchase_succeeded
     - No parameters

 27. restore_purchase_failed
     - error: String

 ═══════════════════════════════════════════════════════════════════════════════

 ## ENGAGEMENT EVENTS

 28. app_open (Firebase standard event)
     - No custom parameters

 29. session_ended
     - duration_seconds: Int

 30. user_returned
     - days_since_last_visit: Int

 31. readiness_checked
     - readiness_percentage: Double
     - readiness_status: String ("Not Ready", "Almost Ready", "Ready to Test!")

 ═══════════════════════════════════════════════════════════════════════════════

 ## ONBOARDING EVENTS

 32. onboarding_step_completed
     - step: Int (1, 2, 3, etc.)
     - total_steps: Int

 33. onboarding_completed
     - No parameters

 ═══════════════════════════════════════════════════════════════════════════════

 ## FEATURE DISCOVERY EVENTS

 34. feature_discovered
     - feature_name: String (e.g., "AI Tutor", "Learn Mode")
     - discovery_method: String ("tap", "recommendation", "tutorial")

 35. locked_feature_clicked
     - feature_name: String (e.g., "Full Practice Test", "Category Practice")

 ═══════════════════════════════════════════════════════════════════════════════

 ## CATEGORY PERFORMANCE EVENTS

 36. category_mastered
     - category: String
     - accuracy_percentage: Double

 37. weak_category_identified
     - category: String
     - accuracy_percentage: Double

 ═══════════════════════════════════════════════════════════════════════════════

 ## SETTINGS EVENTS

 38. setting_changed
     - setting_name: String (e.g., "sound_enabled", "haptic_enabled")
     - new_value: String ("true" or "false")

 ═══════════════════════════════════════════════════════════════════════════════

 ## ERROR EVENTS

 39. error_occurred
     - error_type: String (e.g., "network_error", "api_error")
     - error_message: String
     - screen: String? (optional)

 ═══════════════════════════════════════════════════════════════════════════════

 ## REVIEW REQUEST EVENTS (NEW)

 40. review_requested
     - trigger: String (e.g., "completed_diagnostic_test", "high_accuracy_quiz")
     - significant_events_count: Int (how many positive events before asking)
     - is_premium: Bool

 41. review_prompt_shown
     - trigger: String (same as review_requested)

 42. review_dismissed
     - trigger: String
     - seconds_before_dismiss: Int (how long before user dismissed)

 43. review_likely_completed
     - trigger: String (user went to App Store after prompt)

 ═══════════════════════════════════════════════════════════════════════════════

 ## USER PROPERTIES

 These are set once per user and used for segmentation.

 - user_level: String (current level, e.g., "5")
 - total_questions_answered: String (lifetime count, e.g., "250")
 - is_premium: Bool (automatically set by Firebase for purchasers)

 ═══════════════════════════════════════════════════════════════════════════════

 ## KEY FUNNELS TO MONITOR

 ### Conversion Funnel (Free → Paid)
 1. onboarding_completed
 2. diagnostic_test_completed (passed: false)
 3. paywall_viewed (trigger: "diagnostic_results")
 4. purchase_initiated
 5. purchase_completed

 ### Engagement Funnel
 1. app_open
 2. quiz_started
 3. quiz_completed (accuracy > 80%)
 4. daily_goal_completed
 5. streak_milestone (7 days)

 ### Learn Mode Funnel
 1. lesson_started
 2. lesson_completed
 3. module_completed
 4. category_mastered

 ### AI Tutor Funnel
 1. ai_tutor_opened
 2. ai_question_asked
 3. ai_response_received
 4. ai_rate_limit_reached → paywall_viewed

 ═══════════════════════════════════════════════════════════════════════════════

 ## CRITICAL METRICS TO TRACK

 ### Revenue Metrics
 - Conversion rate: (purchase_completed / paywall_viewed) * 100
 - Revenue per user: Total revenue / Total users
 - Average time to purchase: Time from app_open to purchase_completed

 ### Engagement Metrics
 - DAU (Daily Active Users): Count of unique users with app_open per day
 - Session length: Average duration_seconds from session_ended
 - Questions per session: Average question_answered per session
 - Retention rate: Percentage of users returning after 7 days

 ### Learning Metrics
 - Average accuracy: Mean accuracy_percentage from quiz_completed
 - Completion rate: (quiz_completed / quiz_started) * 100
 - Time to readiness: Days from first app_open to readiness_status = "Ready"

 ### Feature Adoption
 - AI Tutor usage: (ai_question_asked / app_open) * 100
 - Learn Mode adoption: (lesson_started / app_open) * 100
 - Achievement engagement: unique achievement_unlocked per user

 ### Review Request Metrics (NEW)
 - Request rate: review_requested / unique_users * 100
 - Show rate: review_prompt_shown / review_requested * 100
 - Dismiss rate: review_dismissed / review_prompt_shown * 100
 - Completion rate (estimated): review_likely_completed / review_prompt_shown * 100
 - Best trigger: Which trigger has highest completion rate?
 - Free vs Paid: Do premium users review more often?
 - Optimal timing: What significant_events_count works best?

 ═══════════════════════════════════════════════════════════════════════════════

 ## TESTING ANALYTICS IN DEBUG MODE

 1. Enable Firebase Debug Mode:
    - Edit Scheme → Run → Arguments
    - Add: -FIRDebugEnabled

 2. Use Firebase DebugView:
    - Open Firebase Console
    - Analytics → DebugView
    - Run app on simulator/device
    - Events appear in real-time

 3. Test all events programmatically:
    ```swift
    #if DEBUG
    EventTracker.shared.testAllEvents()
    #endif
    ```

 4. Verify events in console output:
    - Look for "📊 Analytics Event: ..." logs
    - Check all parameters are correct

 ═══════════════════════════════════════════════════════════════════════════════

 ## IMPORTANT NOTES

 - All events are automatically queued if offline and sent when connection restored
 - Events are throttled to max 100 queued events to avoid memory issues
 - Firebase Analytics has a 500 event limit per app instance
 - Custom event parameters are limited to 100 per event
 - Parameter names must be ≤ 40 characters
 - Parameter values (strings) must be ≤ 100 characters

 ═══════════════════════════════════════════════════════════════════════════════

 Last Updated: 2025-01-16

 */

// This file is documentation only - no executable code
