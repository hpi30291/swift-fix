import Foundation

#if DEBUG
/// Simulates network conditions for testing (DEBUG builds only)
/// Useful for testing slow network, timeouts, and error handling
class NetworkSimulator {
    static let shared = NetworkSimulator()

    enum NetworkCondition {
        case normal              // No delay
        case slow3G             // 2-3 second delay
        case veryBadNetwork     // 5-8 second delay, 30% failure rate
        case offline            // Always fails
        case intermittent       // Random failures (50% success rate)

        var description: String {
            switch self {
            case .normal: return "Normal (no delay)"
            case .slow3G: return "3G (2-3s delay)"
            case .veryBadNetwork: return "Very Bad (5-8s delay, 30% failures)"
            case .offline: return "Offline (always fails)"
            case .intermittent: return "Intermittent (50% failures)"
            }
        }
    }

    private(set) var currentCondition: NetworkCondition = .normal

    private init() {}

    /// Set the simulated network condition
    func setCondition(_ condition: NetworkCondition) {
        currentCondition = condition
        print("🌐 Network Simulator: \(condition.description)")
    }

    /// Simulate network delay and potential failure
    /// - Throws: NSError if network simulation decides to fail
    /// - Returns: After simulated delay
    func simulateNetworkConditions() async throws {
        switch currentCondition {
        case .normal:
            // No delay, no failure
            return

        case .slow3G:
            // 2-3 second delay
            let delay = Double.random(in: 2.0...3.0)
            print("⏱️ Simulating 3G delay: \(String(format: "%.1f", delay))s")
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

        case .veryBadNetwork:
            // 5-8 second delay with 30% failure rate
            let delay = Double.random(in: 5.0...8.0)
            print("⏱️ Simulating very bad network: \(String(format: "%.1f", delay))s")
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

            // 30% chance of failure
            if Double.random(in: 0...1) < 0.3 {
                print("❌ Network simulation: Request failed (timeout)")
                throw NSError(
                    domain: "NetworkSimulator",
                    code: -1001,
                    userInfo: [NSLocalizedDescriptionKey: "The request timed out."]
                )
            }

        case .offline:
            // Always fail immediately
            print("❌ Network simulation: Offline mode")
            throw NSError(
                domain: "NetworkSimulator",
                code: -1009,
                userInfo: [NSLocalizedDescriptionKey: "The Internet connection appears to be offline."]
            )

        case .intermittent:
            // 50% chance of failure, 1-2s delay on success
            if Double.random(in: 0...1) < 0.5 {
                print("❌ Network simulation: Intermittent failure")
                throw NSError(
                    domain: "NetworkSimulator",
                    code: -1001,
                    userInfo: [NSLocalizedDescriptionKey: "The request timed out."]
                )
            } else {
                let delay = Double.random(in: 1.0...2.0)
                print("⏱️ Simulating intermittent network: \(String(format: "%.1f", delay))s")
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }

    /// Quick test to verify simulator is working
    func testSimulator() async {
        print("\n🧪 Testing Network Simulator:")

        for condition in [NetworkCondition.normal, .slow3G, .veryBadNetwork, .intermittent, .offline] {
            setCondition(condition)
            do {
                try await simulateNetworkConditions()
                print("✅ Request succeeded under: \(condition.description)")
            } catch {
                print("❌ Request failed: \(error.localizedDescription)")
            }
        }

        // Reset to normal
        setCondition(.normal)
        print("\n")
    }
}

// MARK: - Usage Example
/*
 To use the network simulator in your code:

 // In ClaudeAPIService or any network code:
 func sendMessage(...) async throws -> String {
     #if DEBUG
     try await NetworkSimulator.shared.simulateNetworkConditions()
     #endif

     // ... rest of your network code
 }

 // To change network conditions (in SettingsView for example):
 #if DEBUG
 Button("Simulate Slow Network") {
     NetworkSimulator.shared.setCondition(.slow3G)
 }
 #endif
 */
#endif
