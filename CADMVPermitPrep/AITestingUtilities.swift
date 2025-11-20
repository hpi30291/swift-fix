import Foundation

#if DEBUG
/// Testing utilities for AI API functionality (DEBUG builds only)
class AITestingUtilities {
    static let shared = AITestingUtilities()

    private init() {}

    // MARK: - Rate Limiter Testing

    /// Test rate limiter by simulating multiple requests
    func testRateLimiter() {
        let rateLimiter = RateLimiter(maxPerDay: 5, maxPerHour: 3)

        print("\n🧪 Testing Rate Limiter:")
        print("Configuration: 3/hour, 5/day\n")

        // Test hourly limit
        print("Testing Hourly Limit (3 requests):")
        for i in 1...5 {
            let (allowed, reason) = rateLimiter.canMakeRequest()
            if allowed {
                rateLimiter.recordRequest()
                let remaining = rateLimiter.getRemainingRequests()
                print("✅ Request \(i): Allowed (Remaining: \(remaining.hourly)/hour, \(remaining.daily)/day)")
            } else {
                print("❌ Request \(i): BLOCKED - \(reason ?? "Unknown")")
            }
        }

        print("\n")
    }

    /// Reset rate limiter counters (for testing)
    func resetRateLimiter() {
        UserDefaults.standard.removeObject(forKey: "aiTutorDailyCount")
        UserDefaults.standard.removeObject(forKey: "aiTutorHourlyCount")
        UserDefaults.standard.removeObject(forKey: "aiTutorLastResetDate")
        UserDefaults.standard.removeObject(forKey: "aiTutorLastHourlyReset")
        print("✅ Rate limiter counters reset")
    }

    /// Get current rate limiter status
    func printRateLimiterStatus() {
        let claudeAPI = ClaudeAPIService.shared
        let (allowed, reason) = claudeAPI.canMakeRequest()
        let remaining = claudeAPI.getRemainingRequests()

        print("\n📊 Rate Limiter Status:")
        print("Can make request: \(allowed ? "✅ Yes" : "❌ No")")
        if let reason = reason {
            print("Reason: \(reason)")
        }
        print("Remaining requests:")
        print("  - Hourly: \(remaining.hourly)")
        print("  - Daily: \(remaining.daily)")
        print("")
    }

    // MARK: - API Failure Testing

    /// Test API error handling
    func testAPIErrorHandling() async {
        print("\n🧪 Testing API Error Handling:\n")

        let claudeAPI = ClaudeAPIService.shared

        // Test 1: Empty message
        print("Test 1: Empty message")
        do {
            let _ = try await claudeAPI.sendMessage("", conversationHistory: [])
            print("❌ Should have failed with empty message")
        } catch {
            print("✅ Correctly handled: \(error.localizedDescription)")
        }

        // Test 2: Very long message (might exceed token limit)
        print("\nTest 2: Very long message")
        let longMessage = String(repeating: "This is a very long test message. ", count: 100)
        do {
            let response = try await claudeAPI.sendMessage(longMessage)
            print("✅ Long message handled: \(response.prefix(50))...")
        } catch {
            print("⚠️ Long message error: \(error.localizedDescription)")
        }

        print("\n")
    }

    // MARK: - Analytics Testing

    /// Test AI analytics tracking
    func testAIAnalytics() {
        print("\n🧪 Testing AI Analytics:\n")

        let eventTracker = EventTracker.shared

        // Simulate AI usage
        print("Simulating AI events...")

        eventTracker.trackAIQuestionAsked(
            questionLength: 150,
            category: "General"
        )
        print("✅ Tracked: AI tutor question asked")

        eventTracker.trackAIResponseReceived(
            responseLength: 200,
            timeToRespond: 1.5
        )
        print("✅ Tracked: AI response received")

        eventTracker.trackAIRateLimitReached(
            limitType: "hourly"
        )
        print("✅ Tracked: Rate limit reached")

        eventTracker.trackEvent(
            name: "ai_recommendation_generated",
            parameters: [
                "weak_categories": "Traffic Signs, Right of Way",
                "overall_accuracy": 0.75
            ]
        )
        print("✅ Tracked: AI recommendation generated")

        print("\nCheck Firebase Analytics console for these events")
        print("")
    }

    // MARK: - Network Simulation

    /// Test with simulated network conditions
    func testWithSlowNetwork() async {
        #if canImport(NetworkSimulator)
        print("\n🧪 Testing with Slow Network:\n")

        // Set slow 3G
        NetworkSimulator.shared.setCondition(.slow3G)

        let start = Date()
        do {
            let claudeAPI = ClaudeAPIService.shared
            let response = try await claudeAPI.sendMessage("What is a stop sign?")
            let duration = Date().timeIntervalSince(start)
            print("✅ Request succeeded after \(String(format: "%.1f", duration))s")
            print("Response: \(response.prefix(100))...")
        } catch {
            print("❌ Request failed: \(error.localizedDescription)")
        }

        // Reset to normal
        NetworkSimulator.shared.setCondition(.normal)
        print("🌐 Network reset to normal")
        print("")
        #else
        print("⚠️ NetworkSimulator not available")
        #endif
    }

    // MARK: - Complete Test Suite

    /// Run all AI tests
    func runAllTests() async {
        print("\n" + String(repeating: "=", count: 50))
        print("🧪 AI API Testing Suite")
        print(String(repeating: "=", count: 50))

        // 1. Rate limiter status
        printRateLimiterStatus()

        // 2. Rate limiter logic
        testRateLimiter()

        // 3. API error handling
        await testAPIErrorHandling()

        // 4. Analytics
        testAIAnalytics()

        // 5. Network simulation
        await testWithSlowNetwork()

        print(String(repeating: "=", count: 50))
        print("✅ All tests complete")
        print(String(repeating: "=", count: 50) + "\n")
    }
}
#endif
