import Foundation

/// Provides fallback responses when AI API is unavailable
/// Helps maintain good UX even when Scout AI can't respond
class AIFallbackManager {
    static let shared = AIFallbackManager()

    private init() {}

    // MARK: - Fallback Messages

    /// Get fallback message for when AI is offline/unavailable
    func getFallbackMessage(for error: Error) -> String {
        let nsError = error as NSError

        switch nsError.code {
        case -1009: // Offline
            return offlineFallback()

        case 429: // Rate limit
            return rateLimitFallback(message: nsError.localizedDescription)

        case 401: // API key issue
            return apiKeyFallback()

        case 500...599: // Server error
            return serverErrorFallback()

        default:
            return genericFallback()
        }
    }

    // MARK: - Specific Fallbacks

    private func offlineFallback() -> String {
        return """
        I can't reach Scout right now because you're offline.

        While you wait for internet:
        • Review the Learn Mode lessons
        • Practice with offline quizzes
        • Check your weak areas in Analytics

        I'll be ready to help when you're back online!
        """
    }

    private func rateLimitFallback(message: String) -> String {
        let isHourly = message.contains("hourly") || message.contains("hour")

        if isHourly {
            return """
            You've reached your hourly limit for Scout.

            Try again in an hour, or:
            • Practice quizzes to identify weak areas
            • Review Learn Mode lessons
            • Check your progress in Analytics

            Scout will be ready to help again soon!
            """
        } else {
            return """
            You've used all your Scout questions for today!

            Come back tomorrow, or:
            • Practice with quiz mode
            • Review Learn Mode content
            • Check your weak categories

            Scout resets at midnight!
            """
        }
    }

    private func apiKeyFallback() -> String {
        return """
        Scout is temporarily unavailable.

        In the meantime:
        • Use Learn Mode for structured lessons
        • Practice with quiz mode
        • Review explanations for questions you miss

        We're working on getting Scout back online!
        """
    }

    private func serverErrorFallback() -> String {
        return """
        Scout is taking a break (server error).

        While Scout rests:
        • Try the Practice Quiz mode
        • Review your weak categories
        • Check out Learn Mode lessons

        Try asking Scout again in a few minutes!
        """
    }

    private func genericFallback() -> String {
        return """
        Scout can't help right now, but don't worry!

        Here's what you can do:
        • Practice quizzes to test your knowledge
        • Learn Mode has detailed explanations
        • Check Analytics for your weak areas

        Try Scout again in a moment!
        """
    }

    // MARK: - Topic-Based Fallbacks

    /// Get helpful suggestions based on the question topic
    func getSuggestions(for question: String) -> [String] {
        let lowercased = question.lowercased()

        // Traffic signs
        if lowercased.contains("sign") {
            return [
                "Check Learn Mode → Traffic Signs",
                "Practice: Traffic Signs category quiz",
                "Most signs in CA DMV handbook Chapter 7"
            ]
        }

        // Right of way
        if lowercased.contains("right of way") || lowercased.contains("yield") || lowercased.contains("who goes first") {
            return [
                "Check Learn Mode → Right of Way",
                "Practice: Right of Way category quiz",
                "CA DMV handbook Chapter 5 covers this"
            ]
        }

        // Speed limits
        if lowercased.contains("speed") || lowercased.contains("mph") {
            return [
                "Default speed: 25mph residential, 65mph highway",
                "Check Learn Mode → Traffic Laws",
                "CA DMV handbook has complete speed limits"
            ]
        }

        // Alcohol/drugs
        if lowercased.contains("alcohol") || lowercased.contains("drunk") || lowercased.contains("dui") {
            return [
                "Check Learn Mode → Alcohol & Drugs",
                "Zero tolerance for drivers under 21",
                "CA DMV handbook Chapter 9 is essential"
            ]
        }

        // Parking
        if lowercased.contains("park") {
            return [
                "Check Learn Mode → Parking & Stopping",
                "Practice: Parking category quiz",
                "CA DMV handbook Chapter 8 covers parking rules"
            ]
        }

        // Generic suggestions
        return [
            "Try Learn Mode for structured lessons",
            "Practice quizzes to test your knowledge",
            "Check Analytics to find your weak areas"
        ]
    }

    // MARK: - Full Fallback Response

    /// Get complete fallback response with message and suggestions
    func getFullFallback(for error: Error, question: String) -> (message: String, suggestions: [String]) {
        let message = getFallbackMessage(for: error)
        let suggestions = getSuggestions(for: question)

        // Track fallback usage
        EventTracker.shared.trackEvent(
            name: "ai_fallback_shown",
            parameters: [
                "error_code": (error as NSError).code,
                "has_suggestions": !suggestions.isEmpty
            ]
        )

        return (message, suggestions)
    }

    // MARK: - Retry Logic

    /// Check if error is retryable
    func shouldRetry(error: Error) -> Bool {
        let nsError = error as NSError

        switch nsError.code {
        case -1009: // Offline - not retryable until online
            return false

        case 429: // Rate limit - not retryable until time passes
            return false

        case 401: // API key - not retryable (config issue)
            return false

        case 500...503: // Server error - can retry
            return true

        case 408, -1001: // Timeout - can retry
            return true

        default:
            return false
        }
    }

    /// Get retry delay in seconds
    func getRetryDelay(for error: Error, attempt: Int) -> TimeInterval {
        let nsError = error as NSError

        switch nsError.code {
        case 500...503: // Server error - exponential backoff
            return min(pow(2.0, Double(attempt)), 30.0) // Max 30 seconds

        case 408, -1001: // Timeout - shorter retry
            return Double(attempt * 3) // 3, 6, 9 seconds

        default:
            return 5.0
        }
    }
}
