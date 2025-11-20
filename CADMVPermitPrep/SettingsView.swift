import SwiftUI

struct SettingsView: View {
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("hapticEnabled") private var hapticEnabled = true
    @StateObject private var userAccess = UserAccessManager.shared
    @State private var isRestoring = false
    @State private var showRestoreAlert = false
    @State private var restoreMessage = ""
    @State private var showPaywall = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.adaptiveBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Premium Status Banner (if unlocked)
                        if userAccess.hasActiveSubscription {
                            premiumStatusBanner
                        }

                        // Unlock Premium CTA (if not unlocked)
                        if !userAccess.hasActiveSubscription {
                            unlockPremiumCTA
                        }

                        // Debug (only in DEBUG builds)
                        #if DEBUG
                        VStack(alignment: .leading, spacing: 16) {
                            Text("DEBUG")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.adaptiveError)
                                .padding(.horizontal, 20)

                            VStack(spacing: 0) {
                                SettingsRow(
                                    icon: "crown.fill",
                                    title: "Premium Features",
                                    subtitle: "Test premium mode (DEBUG only)",
                                    iconColor: Color.adaptiveAccentYellow,
                                    toggle: $userAccess.debugPremiumEnabled
                                )

                                Divider()
                                    .padding(.leading, 72)

                                Button(action: {
                                    CrashlyticsManager.shared.testNonFatalError()
                                }) {
                                    SettingsButtonRow(
                                        icon: "exclamationmark.triangle.fill",
                                        title: "Test Non-Fatal Error",
                                        subtitle: "Test Crashlytics error logging",
                                        iconColor: .orange
                                    )
                                }

                                Divider()
                                    .padding(.leading, 72)

                                Button(action: {
                                    CrashlyticsManager.shared.testCrash()
                                }) {
                                    SettingsButtonRow(
                                        icon: "xmark.octagon.fill",
                                        title: "Test Crash (⚠️ Will Crash App)",
                                        subtitle: "Test crash reporting - app will restart",
                                        iconColor: Color.adaptiveError
                                    )
                                }

                                Divider()
                                    .padding(.leading, 72)

                                Button(action: {
                                    Task {
                                        await AITestingUtilities.shared.runAllTests()
                                    }
                                }) {
                                    SettingsButtonRow(
                                        icon: "cpu.fill",
                                        title: "Test AI System",
                                        subtitle: "Test rate limiting, analytics, fallbacks",
                                        iconColor: .blue
                                    )
                                }

                                Divider()
                                    .padding(.leading, 72)

                                Button(action: {
                                    AITestingUtilities.shared.resetRateLimiter()
                                }) {
                                    SettingsButtonRow(
                                        icon: "arrow.clockwise.circle.fill",
                                        title: "Reset AI Rate Limiter",
                                        subtitle: "Clear hourly/daily request counts",
                                        iconColor: .purple
                                    )
                                }

                                Divider()
                                    .padding(.leading, 72)

                                Button(action: {
                                    AITestingUtilities.shared.printRateLimiterStatus()
                                }) {
                                    SettingsButtonRow(
                                        icon: "chart.bar.fill",
                                        title: "AI Rate Limiter Status",
                                        subtitle: "Check remaining requests",
                                        iconColor: .green
                                    )
                                }

                                Divider()
                                    .padding(.leading, 72)

                                Button(action: {
                                    UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
                                    exit(0)
                                }) {
                                    HStack(spacing: 16) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color.adaptiveError.opacity(0.15))
                                                .frame(width: 40, height: 40)

                                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                                .font(.system(size: 18))
                                                .foregroundColor(Color.adaptiveError)
                                        }

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Reset Onboarding")
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .foregroundColor(Color.adaptiveTextPrimary)

                                            Text("App will restart to show onboarding")
                                                .font(.caption)
                                                .foregroundColor(Color.adaptiveTextSecondary)
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(Color.adaptiveTextSecondary)
                                    }
                                    .padding(16)
                                }
                            }
                            .background(Color.adaptiveCardBackground)
                            .cornerRadius(16)
                            .padding(.horizontal)
                        }
                        .padding(.top, 8)
                        #endif

                        // Preferences
                        VStack(alignment: .leading, spacing: 16) {
                            Text("PREFERENCES")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.adaptiveTextSecondary)
                                .padding(.horizontal, 20)

                            VStack(spacing: 0) {
                                SettingsRow(
                                    icon: "speaker.wave.2.fill",
                                    title: "Sound Effects",
                                    subtitle: "Audio feedback",
                                    iconColor: Color.adaptiveAccentPink,
                                    toggle: $soundEnabled
                                )

                                Divider()
                                    .padding(.leading, 72)

                                SettingsRow(
                                    icon: "hand.tap.fill",
                                    title: "Haptic Feedback",
                                    subtitle: "Vibration",
                                    iconColor: Color.adaptiveAccentTeal,
                                    toggle: $hapticEnabled
                                )

                                Divider()
                                    .padding(.leading, 72)

                                Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                                    HStack(spacing: 16) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color.adaptiveAccentYellow.opacity(0.15))
                                                .frame(width: 40, height: 40)

                                            Image(systemName: "bell.fill")
                                                .font(.system(size: 18))
                                                .foregroundColor(Color.adaptiveAccentYellow)
                                        }

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Notifications")
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .foregroundColor(Color.adaptiveTextPrimary)

                                            Text("Study reminders, streak alerts")
                                                .font(.caption)
                                                .foregroundColor(Color.adaptiveTextSecondary)
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(Color.adaptiveTextTertiary)
                                    }
                                    .padding()
                                }
                            }
                            .background(Color.adaptiveCardBackground)
                            .cornerRadius(16)
                            .padding(.horizontal)
                        }
                        .padding(.top, 8)

                        // Purchases
                        if !userAccess.hasPurchased {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("PURCHASES")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.adaptiveTextSecondary)
                                    .padding(.horizontal, 20)

                                VStack(spacing: 0) {
                                    Button(action: {
                                        restorePurchases()
                                    }) {
                                        HStack(spacing: 16) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(Color.adaptivePrimaryBlue.opacity(0.15))
                                                    .frame(width: 40, height: 40)

                                                if isRestoring {
                                                    ProgressView()
                                                        .tint(Color.adaptivePrimaryBlue)
                                                } else {
                                                    Image(systemName: "arrow.clockwise.circle.fill")
                                                        .font(.system(size: 18))
                                                        .foregroundColor(Color.adaptivePrimaryBlue)
                                                }
                                            }

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Restore Purchases")
                                                    .font(.body)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(Color.adaptiveTextPrimary)

                                                Text("Already purchased? Tap here")
                                                    .font(.caption)
                                                    .foregroundColor(Color.adaptiveTextSecondary)
                                            }

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundColor(Color.adaptiveTextSecondary)
                                        }
                                        .padding(16)
                                    }
                                    .disabled(isRestoring)
                                }
                                .background(Color.adaptiveCardBackground)
                                .cornerRadius(16)
                                .padding(.horizontal)
                            }
                        }

                        // Support
                        VStack(alignment: .leading, spacing: 16) {
                            Text("SUPPORT")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.adaptiveTextSecondary)
                                .padding(.horizontal, 20)

                            VStack(spacing: 0) {
                                Link(destination: URL(string: "https://www.trafficsafetyinstitute.com/app-privacy-policy/")!) {
                                    SettingsLinkRow(
                                        icon: "lock.shield.fill",
                                        title: "Privacy Policy",
                                        iconColor: Color.adaptiveSuccess
                                    )
                                }

                                Divider()
                                    .padding(.leading, 72)

                                Link(destination: URL(string: "https://www.trafficsafetyinstitute.com/app-support/")!) {
                                    SettingsLinkRow(
                                        icon: "lifepreserver.fill",
                                        title: "Support",
                                        iconColor: Color.adaptiveAccentTeal
                                    )
                                }
                            }
                            .background(Color.adaptiveCardBackground)
                            .cornerRadius(16)
                            .padding(.horizontal)
                        }

                        // About
                        VStack(alignment: .leading, spacing: 16) {
                            Text("ABOUT")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.adaptiveTextSecondary)
                                .padding(.horizontal, 20)

                            VStack(spacing: 0) {
                                SettingsInfoRow(
                                    icon: "info.circle.fill",
                                    title: "Version",
                                    value: "1.0",
                                    iconColor: Color.adaptivePrimaryBlue
                                )

                                Divider()
                                    .padding(.leading, 72)

                                SettingsInfoRow(
                                    icon: "person.fill",
                                    title: "Developer",
                                    value: "Traffic Safety Institute",
                                    iconColor: Color.adaptiveAccentYellow
                                )
                            }
                            .background(Color.adaptiveCardBackground)
                            .cornerRadius(16)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 24)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        HapticManager.shared.impact(style: .light)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Color.adaptivePrimaryBlue)
                }
            }
            .alert("Restore Purchases", isPresented: $showRestoreAlert) {
                Button("OK") { }
            } message: {
                Text(restoreMessage)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(
                    triggerPoint: .lockedFeature,
                    featureName: "Premium Features"
                )
            }
        }
    }

    // MARK: - Premium Banner Views
    private var premiumStatusBanner: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white.opacity(0.2))
                        .frame(width: 48, height: 48)

                    Image(systemName: "star.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Full Access Unlocked")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("All features • Lifetime access")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()
            }
            .padding(20)
        }
        .background(
            LinearGradient(
                colors: [Color.adaptivePrimaryBlue, Color.adaptiveAccentTeal],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var unlockPremiumCTA: some View {
        Button(action: {
            HapticManager.shared.impact(style: .medium)
            showPaywall = true
        }) {
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [Color.adaptivePrimaryBlue, Color.adaptiveAccentTeal],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)

                        Image(systemName: "star.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Unlock Everything")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.adaptiveTextPrimary)

                        Text("Get unlimited practice tests, Scout AI tutor, Learn Mode, and all 500+ questions")
                            .font(.subheadline)
                            .foregroundColor(Color.adaptiveTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 8) {
                            Text("Upgrade")
                                .fontWeight(.semibold)
                            Text("• $14.99 one-time")
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [Color.adaptivePrimaryBlue, Color.adaptiveAccentTeal],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                    }

                    Spacer()
                }
                .padding(20)
            }
            .background(Color.adaptiveCardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [Color.adaptivePrimaryBlue, Color.adaptiveAccentTeal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Restore Purchases Function
    private func restorePurchases() {
        isRestoring = true

        Task {
            do {
                try await userAccess.restorePurchase()
                await MainActor.run {
                    if userAccess.hasPurchased {
                        restoreMessage = "Purchase successfully restored! You now have access to all premium features."
                    } else {
                        restoreMessage = "No previous purchases found."
                    }
                    showRestoreAlert = true
                    isRestoring = false
                }
            } catch {
                await MainActor.run {
                    restoreMessage = "Unable to restore purchases. Please try again later."
                    showRestoreAlert = true
                    isRestoring = false
                }
            }
        }
    }
}

// MARK: - Settings Row Components
struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    @Binding var toggle: Bool

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(Color.adaptiveTextPrimary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(Color.adaptiveTextSecondary)
            }

            Spacer()

            Toggle("", isOn: $toggle)
                .labelsHidden()
                .tint(Color.adaptivePrimaryBlue)
                .onChange(of: toggle) {
                    HapticManager.shared.selection()
                }
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(subtitle)")
        .accessibilityValue(toggle ? "On" : "Off")
    }
}

struct SettingsInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
            }

            Text(title)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(Color.adaptiveTextPrimary)

            Spacer()

            Text(value)
                .font(.body)
                .foregroundColor(Color.adaptiveTextSecondary)
                .multilineTextAlignment(.trailing)
        }
        .padding()
    }
}

struct SettingsLinkRow: View {
    let icon: String
    let title: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
            }

            Text(title)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(Color.adaptiveTextPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Color.adaptiveTextTertiary)
        }
        .padding()
    }
}

struct SettingsButtonRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(Color.adaptiveTextPrimary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(Color.adaptiveTextSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Color.adaptiveTextTertiary)
        }
        .padding()
    }
}

