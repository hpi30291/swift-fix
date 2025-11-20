import Foundation
import Combine

// MARK: - API Models
struct ClaudeMessage: Codable {
    let role: String // "user" or "assistant"
    let content: String
}

struct ClaudeRequest: Codable {
    let model: String
    let maxTokens: Int
    let messages: [ClaudeMessage]
    let system: String?

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case messages
        case system
    }
}

struct ClaudeResponse: Codable {
    let id: String
    let type: String
    let role: String
    let content: [ContentBlock]
    let model: String
    let stopReason: String?
    let usage: Usage

    struct ContentBlock: Codable {
        let type: String
        let text: String
    }

    struct Usage: Codable {
        let inputTokens: Int
        let outputTokens: Int

        enum CodingKeys: String, CodingKey {
            case inputTokens = "input_tokens"
            case outputTokens = "output_tokens"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, type, role, content, model
        case stopReason = "stop_reason"
        case usage
    }
}

struct ClaudeAPIError: Codable {
    let type: String
    let error: ErrorDetail

    struct ErrorDetail: Codable {
        let type: String
        let message: String
    }
}

// MARK: - Rate Limiter
class RateLimiter {
    private let maxRequestsPerDay: Int
    private let maxRequestsPerHour: Int
    private var requestCountToday: Int = 0
    private var requestCountThisHour: Int = 0
    private var lastResetDate: Date = Date()
    private var lastHourlyReset: Date = Date()

    init(maxPerDay: Int = 50, maxPerHour: Int = 10) {
        self.maxRequestsPerDay = maxPerDay
        self.maxRequestsPerHour = maxPerHour
        loadCounts()
    }

    func canMakeRequest() -> (allowed: Bool, reason: String?) {
        resetIfNeeded()

        if requestCountThisHour >= maxRequestsPerHour {
            return (false, "You've reached the hourly limit. Please try again in an hour.")
        }

        if requestCountToday >= maxRequestsPerDay {
            return (false, "You've reached the daily AI tutor limit. Resets tomorrow.")
        }

        return (true, nil)
    }

    func recordRequest() {
        resetIfNeeded()
        requestCountToday += 1
        requestCountThisHour += 1
        saveCounts()
    }

    func getRemainingRequests() -> (daily: Int, hourly: Int) {
        resetIfNeeded()
        return (
            daily: max(0, maxRequestsPerDay - requestCountToday),
            hourly: max(0, maxRequestsPerHour - requestCountThisHour)
        )
    }

    private func resetIfNeeded() {
        let now = Date()
        let calendar = Calendar.current

        // Reset hourly count
        if calendar.dateComponents([.hour], from: lastHourlyReset, to: now).hour ?? 0 >= 1 {
            requestCountThisHour = 0
            lastHourlyReset = now
        }

        // Reset daily count
        if !calendar.isDate(lastResetDate, inSameDayAs: now) {
            requestCountToday = 0
            requestCountThisHour = 0
            lastResetDate = now
            lastHourlyReset = now
        }
    }

    private func saveCounts() {
        UserDefaults.standard.set(requestCountToday, forKey: "aiTutorDailyCount")
        UserDefaults.standard.set(requestCountThisHour, forKey: "aiTutorHourlyCount")
        UserDefaults.standard.set(lastResetDate, forKey: "aiTutorLastResetDate")
        UserDefaults.standard.set(lastHourlyReset, forKey: "aiTutorLastHourlyReset")
    }

    private func loadCounts() {
        requestCountToday = UserDefaults.standard.integer(forKey: "aiTutorDailyCount")
        requestCountThisHour = UserDefaults.standard.integer(forKey: "aiTutorHourlyCount")
        if let date = UserDefaults.standard.object(forKey: "aiTutorLastResetDate") as? Date {
            lastResetDate = date
        }
        if let date = UserDefaults.standard.object(forKey: "aiTutorLastHourlyReset") as? Date {
            lastHourlyReset = date
        }
        resetIfNeeded()
    }
}

// MARK: - Claude API Service
class ClaudeAPIService: ObservableObject {
    static let shared = ClaudeAPIService()

    private let apiKey: String
    private let apiURL = "https://api.anthropic.com/v1/messages"
    private let model = "claude-haiku-4-5" // Claude 4.5 Haiku - Latest Haiku, fast, and cost-effective
    private let rateLimiter = RateLimiter()
    private let networkMonitor = NetworkMonitor.shared

    @Published var isLoading = false
    @Published var error: String?

    private init() {
        // Load API key from Config.plist (secure and not committed to git)
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
           let config = NSDictionary(contentsOfFile: path),
           let key = config["ANTHROPIC_API_KEY"] as? String {
            self.apiKey = key
        } else {
            // Fallback - API key not found
            #if DEBUG
            print("⚠️ WARNING: ANTHROPIC_API_KEY not found in Config.plist")
            #endif
            self.apiKey = ""
        }
    }

    // MARK: - System Prompt with Guardrails
    private let systemPrompt = """
    You are Scout, an AI tutor assistant for the California DMV Permit Test preparation app. Your role is strictly limited to helping students prepare for the California DMV written knowledge test.

    REFERENCE MATERIALS (in order of priority):
    1. Official California DMV Driver Handbook (2024) - PRIMARY SOURCE
    2. CA Drivers Ed Full Course PDF - SUPPLEMENTARY MATERIAL
    3. Road Sign Cheat Sheet - VISUAL REFERENCE

    STRICT RULES - YOU MUST FOLLOW THESE:
    1. ONLY answer questions related to California driving laws, traffic signs, road safety, and DMV test preparation
    2. ALL answers MUST be based on the CA DMV Handbook and our course materials
    3. If our course material conflicts with the DMV Handbook, the DMV Handbook ALWAYS wins
    4. You CAN answer educational questions about driving safety and accident prevention as they relate to California driving
    5. REFUSE to answer questions completely unrelated to driving (math, history, general knowledge, etc.)
    6. Explain concepts and reasoning - help students understand, not just memorize
    7. If asked about other states' laws, politely redirect to California only
    8. If asked non-driving questions, politely decline: "I can only help with California DMV test preparation"
    9. NEVER make up information - if you're unsure, say "I recommend checking the official DMV Handbook"
    10. Do NOT discuss topics outside driving and road safety

    YOUR TEACHING APPROACH:
    - Be encouraging and supportive - learning to drive is a big step
    - Explain WHY rules exist (safety, traffic flow, etc.)
    - Use real-world California driving scenarios as examples
    - Break complex rules into simple, memorable steps
    - Connect concepts to what students already know
    - Acknowledge when topics are commonly confusing

    RESPONSE FORMAT:
    - Keep responses concise (2-3 short paragraphs max for cost control)
    - Write in PLAIN TEXT - do NOT use markdown formatting
    - Do NOT use # for headers, ** for bold, or other markdown syntax
    - Use simple paragraphs and line breaks for structure
    - Use bullet points with simple dashes (-) if listing items
    - End with a practical tip or next study step when appropriate
    - NO lengthy explanations - students want quick, clear answers

    RESPONSE EXAMPLES:
    Good: "A yellow light means the signal is about to turn red. You should slow down and stop if you can do so safely. If you're too close to stop safely, proceed through with caution. Remember: yellow means 'prepare to stop,' not 'speed up!'"

    Bad: "**Answer:** A yellow light means..." [NO MARKDOWN]
    Bad: "Yellow lights are a complex topic with many considerations. Historically, traffic signals were developed in the early 1900s..." [TOO LONG]

    Remember: Your goal is to help students UNDERSTAND California driving laws efficiently, not just pass the test. Every response costs money, so be helpful but concise.
    """

    // MARK: - Public API Methods

    /// Check if user can make a request (for UI)
    func canMakeRequest() -> (allowed: Bool, reason: String?) {
        return rateLimiter.canMakeRequest()
    }

    /// Get remaining requests
    func getRemainingRequests() -> (daily: Int, hourly: Int) {
        return rateLimiter.getRemainingRequests()
    }

    /// Send a message to Claude API
    func sendMessage(
        _ message: String,
        conversationHistory: [ClaudeMessage] = []
    ) async throws -> String {
        // Track API request attempt
        let startTime = Date()

        // Check network connectivity
        guard networkMonitor.isConnected else {
            EventTracker.shared.trackAIRequestFailed(error: "offline")
            throw NSError(domain: "Network", code: -1009, userInfo: [
                NSLocalizedDescriptionKey: "You're offline. Scout needs an internet connection to help."
            ])
        }

        // Check rate limit
        let (allowed, reason) = rateLimiter.canMakeRequest()
        guard allowed else {
            let limitType = reason?.contains("hourly") == true ? "hourly" : "daily"
            EventTracker.shared.trackAIRateLimitReached(limitType: limitType)
            throw NSError(domain: "RateLimit", code: 429, userInfo: [
                NSLocalizedDescriptionKey: reason ?? "Rate limit exceeded"
            ])
        }

        // Check API key
        guard !apiKey.isEmpty else {
            throw NSError(domain: "APIKey", code: 401, userInfo: [
                NSLocalizedDescriptionKey: "API key not configured"
            ])
        }

        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }

        defer {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }

        // Build messages array
        var messages = conversationHistory
        messages.append(ClaudeMessage(role: "user", content: message))

        // Create request
        let request = ClaudeRequest(
            model: model,
            maxTokens: 300, // Keep responses very concise to save costs (Haiku is cheap but we want tight control)
            messages: messages,
            system: systemPrompt
        )

        // Make API call with performance monitoring
        var urlRequest = URLRequest(url: URL(string: apiURL)!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await PerformanceMonitor.shared.measureNetworkRequest(
            name: "claude_api_sendMessage"
        ) {
            try await URLSession.shared.data(for: urlRequest)
        }

        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "Network", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Invalid response"
            ])
        }

        if httpResponse.statusCode == 200 {
            // Success - record request and parse response
            rateLimiter.recordRequest()

            let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)

            // Extract text from content blocks
            let responseText = claudeResponse.content
                .filter { $0.type == "text" }
                .map { $0.text }
                .joined(separator: "\n")

            // Track successful API response
            let duration = Date().timeIntervalSince(startTime)
            EventTracker.shared.trackAIResponseReceived(
                responseLength: responseText.count,
                timeToRespond: duration
            )

            // Log to Crashlytics for monitoring
            CrashlyticsManager.shared.logEvent("ai_response_success", parameters: [
                "duration": duration,
                "response_length": responseText.count
            ])

            return responseText
        } else {
            // Error - try to parse error message
            let error: NSError
            if let errorResponse = try? JSONDecoder().decode(ClaudeAPIError.self, from: data) {
                error = NSError(domain: "API", code: httpResponse.statusCode, userInfo: [
                    NSLocalizedDescriptionKey: errorResponse.error.message
                ])
            } else {
                error = NSError(domain: "API", code: httpResponse.statusCode, userInfo: [
                    NSLocalizedDescriptionKey: "API request failed with status \(httpResponse.statusCode)"
                ])
            }

            // Track failed API request
            EventTracker.shared.trackAIRequestFailed(error: "api_error_\(httpResponse.statusCode)")

            // Report API error to Crashlytics
            CrashlyticsManager.shared.recordAPIError(
                error,
                endpoint: "claude_api",
                statusCode: httpResponse.statusCode
            )

            throw error
        }
    }

    /// Get personalized study recommendation based on weak areas
    func getPersonalizedRecommendation(
        weakCategories: [(category: String, accuracy: Double)],
        overallAccuracy: Double,
        questionsSeen: Int
    ) async throws -> String {
        let weakAreasText: String
        if weakCategories.isEmpty {
            weakAreasText = "I just completed the diagnostic test but haven't identified specific weak areas yet."
        } else {
            weakAreasText = "My weak areas:\n" + weakCategories.map { "- \($0.category): \(Int($0.accuracy * 100))% accuracy" }.joined(separator: "\n")
        }

        let prompt = """
        I'm preparing for the California DMV permit test. Here's my current performance:

        Overall Accuracy: \(Int(overallAccuracy * 100))%
        Questions Practiced: \(questionsSeen)

        \(weakAreasText)

        Give me 1-2 sentence recommendation focusing on what to study next. If I have weak areas, prioritize the weakest. If I just took the diagnostic, suggest starting with common DMV test topics. Be specific about what to study (like "right-of-way at 4-way stops" not just "right of way"). Keep it under 40 words total.
        """

        return try await sendMessage(prompt)
    }

    /// Explain why an answer is correct/incorrect
    func explainAnswer(
        questionText: String,
        userAnswer: String,
        correctAnswer: String,
        category: String,
        explanation: String?
    ) async throws -> String {
        let prompt = """
        Question: \(questionText)

        I answered: \(userAnswer)
        Correct answer: \(correctAnswer)
        Category: \(category)
        \(explanation != nil ? "Explanation: \(explanation!)" : "")

        Can you help me understand why the correct answer is right and why my answer was wrong? What concept should I review?
        """

        return try await sendMessage(prompt)
    }

    /// Ask a general DMV-related question
    func askQuestion(_ question: String) async throws -> String {
        return try await sendMessage(question)
    }
}
