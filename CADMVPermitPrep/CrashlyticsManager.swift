import Foundation
import UIKit
#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(FirebaseCrashlytics)
import FirebaseCrashlytics
#endif

/// Manages crash reporting and custom logging with Firebase Crashlytics
/// Provides centralized crash reporting, custom logs, and user context
class CrashlyticsManager {
    static let shared = CrashlyticsManager()

    private var isCrashlyticsEnabled = false

    private init() {
        #if canImport(FirebaseCrashlytics)
        isCrashlyticsEnabled = true
        configureCrashlytics()
        #else
        #if DEBUG
        print("⚠️ FirebaseCrashlytics not installed. Install via SPM to enable crash reporting.")
        print("📦 Add: https://github.com/firebase/firebase-ios-sdk")
        #endif
        #endif
    }

    // MARK: - Configuration

    private func configureCrashlytics() {
        #if canImport(FirebaseCrashlytics)
        let crashlytics = Crashlytics.crashlytics()

        // Enable/disable crash collection
        #if DEBUG
        // Enable in DEBUG for testing (you can disable later to avoid polluting reports)
        crashlytics.setCrashlyticsCollectionEnabled(true)
        print("🔧 Crashlytics: Enabled in DEBUG builds for testing")
        #else
        crashlytics.setCrashlyticsCollectionEnabled(true)
        print("✅ Crashlytics: Enabled for crash reporting")
        #endif

        // Log successful initialization
        logEvent("crashlytics_initialized")
        #endif
    }

    // MARK: - User Context

    /// Set user identifier for crash reports
    /// Helps identify which users are experiencing crashes
    func setUserID(_ userID: String) {
        #if canImport(FirebaseCrashlytics)
        Crashlytics.crashlytics().setUserID(userID)
        #endif
    }

    /// Set custom key-value pairs for crash context
    /// Example: subscription status, app version, feature flags
    func setCustomValue(_ value: Any, forKey key: String) {
        #if canImport(FirebaseCrashlytics)
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
        #endif
    }

    /// Set multiple custom values at once
    func setCustomValues(_ values: [String: Any]) {
        for (key, value) in values {
            setCustomValue(value, forKey: key)
        }
    }

    // MARK: - Logging

    /// Log a custom event/breadcrumb
    /// These appear in crash reports to show what happened before crash
    func logEvent(_ message: String) {
        #if canImport(FirebaseCrashlytics)
        Crashlytics.crashlytics().log(message)
        #endif

        #if DEBUG
        print("📝 Crashlytics Log: \(message)")
        #endif
    }

    /// Log with formatted parameters
    func logEvent(_ event: String, parameters: [String: Any]) {
        let message = "\(event): \(parameters.map { "\($0.key)=\($0.value)" }.joined(separator: ", "))"
        logEvent(message)
    }

    // MARK: - Error Reporting

    /// Record a non-fatal error
    /// Use this for caught exceptions that shouldn't crash the app
    func recordError(_ error: Error, userInfo: [String: Any]? = nil) {
        #if canImport(FirebaseCrashlytics)
        let nsError = error as NSError
        var fullUserInfo = nsError.userInfo

        // Add custom user info
        if let userInfo = userInfo {
            for (key, value) in userInfo {
                fullUserInfo[key] = value
            }
        }

        let enhancedError = NSError(
            domain: nsError.domain,
            code: nsError.code,
            userInfo: fullUserInfo
        )

        Crashlytics.crashlytics().record(error: enhancedError)
        #endif

        #if DEBUG
        print("❌ Crashlytics Error: \(error.localizedDescription)")
        if let userInfo = userInfo {
            print("   User Info: \(userInfo)")
        }
        #endif
    }

    /// Record error with custom message
    func recordError(domain: String, code: Int, message: String, userInfo: [String: Any]? = nil) {
        var info: [String: Any] = [NSLocalizedDescriptionKey: message]

        if let userInfo = userInfo {
            info.merge(userInfo) { _, new in new }
        }

        let error = NSError(domain: domain, code: code, userInfo: info)
        recordError(error)
    }

    // MARK: - Crash Testing (DEBUG only)

    #if DEBUG
    /// Test that crash reporting is working
    /// WARNING: This will actually crash the app!
    func testCrash() {
        logEvent("test_crash_triggered")
        print("💥 Triggering test crash in 1 second...")
        print("⚠️ App will crash - relaunch to see crash report in Firebase console")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            fatalError("🧪 Test crash from Crashlytics - this is intentional!")
        }
    }

    /// Test non-fatal error recording
    func testNonFatalError() {
        logEvent("test_non_fatal_error_triggered")

        let testError = NSError(
            domain: "com.cadmvpermitprep.test",
            code: 999,
            userInfo: [
                NSLocalizedDescriptionKey: "Test non-fatal error - this should appear in Crashlytics",
                "test_parameter": "test_value",
                "timestamp": Date().timeIntervalSince1970
            ]
        )

        recordError(testError)
        print("✅ Test non-fatal error recorded - check Firebase console")
    }
    #endif

    // MARK: - Common Error Scenarios

    /// Log API errors with context
    func recordAPIError(_ error: Error, endpoint: String, statusCode: Int? = nil) {
        var userInfo: [String: Any] = [
            "endpoint": endpoint,
            "error_type": "api_error"
        ]

        if let statusCode = statusCode {
            userInfo["status_code"] = statusCode
        }

        recordError(error, userInfo: userInfo)
        logEvent("api_error", parameters: userInfo)
    }

    /// Log data parsing errors
    func recordParsingError(_ error: Error, context: String) {
        recordError(error, userInfo: [
            "error_type": "parsing_error",
            "context": context
        ])
        logEvent("parsing_error: \(context)")
    }

    /// Log purchase errors
    func recordPurchaseError(_ error: Error, productID: String) {
        recordError(error, userInfo: [
            "error_type": "purchase_error",
            "product_id": productID
        ])
        logEvent("purchase_error: \(productID)")
    }

    /// Log database errors
    func recordDatabaseError(_ error: Error, operation: String) {
        recordError(error, userInfo: [
            "error_type": "database_error",
            "operation": operation
        ])
        logEvent("database_error: \(operation)")
    }

    // MARK: - Crash Context Helpers

    /// Set app context (call at app launch)
    func setAppContext() {
        setCustomValues([
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "build_number": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown",
            "ios_version": UIDevice.current.systemVersion,
            "device_model": UIDevice.current.model
        ])
    }

    /// Set user context (call when user state is known)
    func setUserContext(hasSubscription: Bool, questionsAnswered: Int, level: Int) {
        setCustomValues([
            "has_subscription": hasSubscription,
            "questions_answered": questionsAnswered,
            "user_level": level,
            "last_active": Date().timeIntervalSince1970
        ])
    }

    /// Set feature flags
    func setFeatureFlags(_ flags: [String: Bool]) {
        for (feature, enabled) in flags {
            setCustomValue(enabled, forKey: "feature_\(feature)")
        }
    }

    // MARK: - Status

    var isEnabled: Bool {
        #if canImport(FirebaseCrashlytics)
        return isCrashlyticsEnabled
        #else
        return false
        #endif
    }

    var statusMessage: String {
        if isEnabled {
            #if DEBUG
            return "Crashlytics: Installed but disabled in DEBUG builds"
            #else
            return "Crashlytics: Active and collecting crashes"
            #endif
        } else {
            return "Crashlytics: Not installed - add FirebaseCrashlytics via SPM"
        }
    }
}

// MARK: - Convenience Extensions

extension Error {
    /// Quick record to Crashlytics
    func recordToCrashlytics(userInfo: [String: Any]? = nil) {
        CrashlyticsManager.shared.recordError(self, userInfo: userInfo)
    }
}
