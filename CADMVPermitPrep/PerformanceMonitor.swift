import Foundation
import UIKit

/// Monitors app performance metrics including memory usage, launch time, and network performance
class PerformanceMonitor {
    static let shared = PerformanceMonitor()

    private let eventTracker = EventTracker.shared
    private var appLaunchTime: Date?
    private var memoryWarningCount = 0

    // MARK: - Configuration
    private let maxAcceptableLaunchTime: TimeInterval = 2.0 // 2 seconds
    private let memoryWarningThreshold = 3 // Alert after 3 warnings

    private init() {
        setupMemoryWarningObserver()
    }

    // MARK: - App Launch Monitoring

    /// Call this in AppDelegate/App init to start launch time tracking
    func markAppLaunchStart() {
        appLaunchTime = Date()
    }

    /// Call this when app UI is fully loaded (e.g., in ContentView.onAppear)
    func markAppLaunchComplete() {
        guard let launchTime = appLaunchTime else { return }

        let launchDuration = Date().timeIntervalSince(launchTime)

        #if DEBUG
        print("📊 App Launch Time: \(String(format: "%.2f", launchDuration))s")
        if launchDuration > maxAcceptableLaunchTime {
            print("⚠️ Launch time exceeds target of \(maxAcceptableLaunchTime)s")
        } else {
            print("✅ Launch time within acceptable range")
        }
        #endif

        // Track launch time in analytics
        eventTracker.trackEvent(
            name: "app_launch_time",
            parameters: [
                "duration_seconds": launchDuration,
                "is_slow": launchDuration > maxAcceptableLaunchTime
            ]
        )

        // Reset for next launch
        appLaunchTime = nil
    }

    // MARK: - Memory Monitoring

    /// Get current memory usage in MB
    func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }

        guard kerr == KERN_SUCCESS else {
            return 0
        }

        let usedMemoryMB = Double(info.resident_size) / 1024.0 / 1024.0
        return usedMemoryMB
    }

    /// Log current memory usage
    func logMemoryUsage(context: String = "") {
        let memoryMB = getCurrentMemoryUsage()

        #if DEBUG
        let contextString = context.isEmpty ? "" : " [\(context)]"
        print("💾 Memory Usage\(contextString): \(String(format: "%.2f", memoryMB)) MB")
        #endif

        // Track high memory usage
        if memoryMB > 200 { // Alert if over 200 MB
            eventTracker.trackEvent(
                name: "high_memory_usage",
                parameters: [
                    "memory_mb": memoryMB,
                    "context": context
                ]
            )
        }
    }

    private func setupMemoryWarningObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    @objc private func handleMemoryWarning() {
        memoryWarningCount += 1
        let memoryMB = getCurrentMemoryUsage()

        #if DEBUG
        print("⚠️ Memory Warning #\(memoryWarningCount) - Current: \(String(format: "%.2f", memoryMB)) MB")
        #endif

        eventTracker.trackEvent(
            name: "memory_warning",
            parameters: [
                "warning_count": memoryWarningCount,
                "memory_mb": memoryMB
            ]
        )

        if memoryWarningCount >= memoryWarningThreshold {
            #if DEBUG
            print("🚨 Multiple memory warnings detected! Consider optimizing memory usage.")
            #endif
        }
    }

    // MARK: - Network Performance Monitoring

    /// Measure network request duration
    func measureNetworkRequest<T>(
        name: String,
        request: () async throws -> T
    ) async throws -> T {
        let startTime = Date()

        do {
            let result = try await request()
            let duration = Date().timeIntervalSince(startTime)

            #if DEBUG
            print("🌐 Network Request [\(name)]: \(String(format: "%.2f", duration))s")
            #endif

            eventTracker.trackEvent(
                name: "network_request",
                parameters: [
                    "request_name": name,
                    "duration_seconds": duration,
                    "success": true
                ]
            )

            return result
        } catch {
            let duration = Date().timeIntervalSince(startTime)

            #if DEBUG
            print("❌ Network Request Failed [\(name)]: \(error)")
            #endif

            eventTracker.trackEvent(
                name: "network_request",
                parameters: [
                    "request_name": name,
                    "duration_seconds": duration,
                    "success": false,
                    "error": error.localizedDescription
                ]
            )

            throw error
        }
    }

    // MARK: - Battery Impact Monitoring

    /// Check if battery usage is in low power mode
    func isBatteryOptimizationNeeded() -> Bool {
        return ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    /// Log battery state
    func logBatteryState() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryLevel = UIDevice.current.batteryLevel
        let batteryState = UIDevice.current.batteryState
        let isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled

        #if DEBUG
        if batteryLevel >= 0 {
            print("🔋 Battery: \(Int(batteryLevel * 100))%, State: \(batteryStateDescription(batteryState)), Low Power: \(isLowPowerMode)")
        }
        #endif

        if isLowPowerMode {
            eventTracker.trackEvent(
                name: "low_power_mode_active",
                parameters: [
                    "battery_level": Int(batteryLevel * 100)
                ]
            )
        }
    }

    // MARK: - Leak Detection Helpers

    /// Track object lifecycle for leak detection (DEBUG only)
    #if DEBUG
    private var trackedObjects: [String: Int] = [:]

    func trackObjectAllocation(_ objectType: String) {
        trackedObjects[objectType, default: 0] += 1
        print("➕ \(objectType) allocated (total: \(trackedObjects[objectType] ?? 0))")
    }

    func trackObjectDeallocation(_ objectType: String) {
        trackedObjects[objectType, default: 0] -= 1
        print("➖ \(objectType) deallocated (remaining: \(trackedObjects[objectType] ?? 0))")

        if let count = trackedObjects[objectType], count < 0 {
            print("⚠️ POTENTIAL ISSUE: \(objectType) deallocation count is negative!")
        }
    }

    func printObjectStats() {
        print("\n📊 Object Allocation Stats:")
        for (objectType, count) in trackedObjects.sorted(by: { $0.key < $1.key }) {
            let status = count == 0 ? "✅" : (count > 0 ? "⚠️" : "❌")
            print("\(status) \(objectType): \(count)")
        }
        print("")
    }
    #endif
}

// MARK: - Battery State Helper
extension PerformanceMonitor {
    func batteryStateDescription(_ state: UIDevice.BatteryState) -> String {
        switch state {
        case .unknown: return "Unknown"
        case .unplugged: return "Unplugged"
        case .charging: return "Charging"
        case .full: return "Full"
        @unknown default: return "Unknown"
        }
    }
}
