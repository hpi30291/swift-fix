import SwiftUI

struct ContentView: View {

    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var paywallFeatureName: String?
    @State private var navigateToFullTest = false
    @State private var navigateToQuickPractice = false
    @State private var navigateToWeakAreas = false
    @State private var aiRecommendation: String?
    @State private var isLoadingAI = false
    @StateObject private var userAccess = UserAccessManager.shared
    private let eventTracker = EventTracker.shared

    // Daily goal tracking
    private var dailyGoal: Int {
        UserDefaults.standard.integer(forKey: "dailyQuestionsAnswered_\(getTodayKey())")
    }

    private var totalAnswered: Int {
        UserDefaults.standard.integer(forKey: "totalQuestionsAnswered")
    }

    private var totalCorrect: Int {
        UserDefaults.standard.integer(forKey: "totalCorrectAnswers")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.adaptiveBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                                Text("Welcome back!")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.adaptiveTextPrimary)

                                Text("Keep practicing to improve")
                                    .font(.subheadline)
                                    .foregroundColor(Color.adaptiveTextSecondary)
                            }

                            Spacer()

                            Button(action: {
                                HapticManager.shared.impact(style: .light)
                                showSettings = true
                            }) {
                                Image(systemName: "gear")
                                    .font(.title3)
                                    .foregroundColor(Color.adaptiveTextPrimary)
                                    .frame(width: 40, height: 40)
                                    .background(Color.adaptiveSecondaryBackground)
                                    .cornerRadius(20)
                            }
                            .accessibilityLabel("Settings")
                            .accessibilityHint("Opens settings and preferences")
                            .minimumTapTarget()
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.top, DesignSystem.Spacing.xs)

                        // Upgrade Banner - Free Users Only
                        if !userAccess.hasActiveSubscription {
                            Button(action: {
                                HapticManager.shared.impact(style: .medium)
                                withAnimation(DesignSystem.Animation.spring) {
                                    paywallFeatureName = "Unlock Everything"
                                    showPaywall = true
                                }
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "crown.fill")
                                        .font(.title3)
                                        .foregroundColor(.white)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Unlock Everything")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)

                                        Text("$14.99 one-time")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.9))
                                    }

                                    Spacer()

                                    Text("Upgrade")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color.adaptivePrimaryBlue)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(.white)
                                        .cornerRadius(8)
                                }
                                .padding(DesignSystem.Spacing.md)
                                .background(Color.primaryGradient)
                                .cornerRadius(DesignSystem.CornerRadius.md)
                                .shadow(
                                    color: DesignSystem.Shadow.lg.color,
                                    radius: DesignSystem.Shadow.lg.radius,
                                    y: DesignSystem.Shadow.lg.y
                                )
                            }
                            .pressAnimation()
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .transition(.scale.combined(with: .opacity))
                            .accessibilityLabel("Unlock everything for $14.99")
                            .accessibilityHint("One-time payment for lifetime access to all features")
                        }

                        // Daily Goal
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            HStack {
                                Image(systemName: "target")
                                    .font(.system(size: DesignSystem.IconSize.md))
                                    .foregroundColor(Color.adaptivePrimaryBlue)
                                    .accessibilityHidden(true)

                                Text("Daily Goal")
                                    .font(DesignSystem.Typography.h4)
                                    .foregroundColor(Color.adaptiveTextPrimary)

                                Spacer()

                                Text("\(dailyGoal)/20 questions")
                                    .font(DesignSystem.Typography.bodySmall)
                                    .foregroundColor(Color.adaptiveTextSecondary)
                            }

                            // Progress bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xs)
                                        .fill(Color.adaptiveSecondaryBackground)
                                        .frame(height: 12)

                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xs)
                                        .fill(Color.primaryGradientHorizontal)
                                        .frame(width: geometry.size.width * min(Double(dailyGoal) / 20.0, 1.0), height: 12)
                                        .animation(DesignSystem.Animation.smooth, value: dailyGoal)
                                }
                            }
                            .frame(height: 12)
                        }
                        .cardStyle()
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Daily goal: \(dailyGoal) out of 20 questions answered")
                        .accessibilityValue("\(Int((Double(dailyGoal) / 20.0) * 100))% complete")

                        // Test Readiness Card
                        ReadyToTestCard()

                        // Scout's Recommendation Card
                        ScoutRecommendationCard(
                            aiRecommendation: $aiRecommendation,
                            isLoading: $isLoadingAI,
                            navigateToWeakAreas: $navigateToWeakAreas,
                            showPaywall: $showPaywall
                        )

                        // More Practice
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("More Practice")
                                .font(DesignSystem.Typography.h4)
                                .foregroundColor(Color.adaptiveTextPrimary)
                                .padding(.horizontal, DesignSystem.Spacing.md)

                            // Quick Practice
                            Button(action: {
                                HapticManager.shared.impact(style: .medium)
                                if userAccess.canTakePracticeTest {
                                    navigateToQuickPractice = true
                                } else {
                                    paywallFeatureName = "Quick Practice"
                                    showPaywall = true
                                }
                            }) {
                                HStack(spacing: DesignSystem.Spacing.md) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                                            .fill(Color.adaptivePrimaryBlue.opacity(0.2))
                                            .frame(width: 48, height: 48)

                                        Image(systemName: "bolt.fill")
                                            .font(.system(size: DesignSystem.IconSize.md))
                                            .foregroundColor(Color.adaptivePrimaryBlue)
                                    }

                                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                                        Text("Quick Practice")
                                            .font(DesignSystem.Typography.body)
                                            .fontWeight(.bold)
                                            .foregroundColor(Color.adaptiveTextPrimary)

                                        Text("10 random questions")
                                            .font(DesignSystem.Typography.caption)
                                            .foregroundColor(Color.adaptiveTextSecondary)

                                        if !userAccess.hasActiveSubscription {
                                            Text("\(userAccess.testsRemainingThisWeek)/5 tests this week")
                                                .font(DesignSystem.Typography.caption)
                                                .foregroundColor(Color.adaptivePrimaryBlue)
                                        }
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: DesignSystem.IconSize.sm))
                                        .foregroundColor(Color.adaptiveTextTertiary)
                                }
                                .padding(DesignSystem.Spacing.md)
                                .background(Color.adaptiveCardBackground)
                                .cornerRadius(DesignSystem.CornerRadius.md)
                            }
                            .pressAnimation()
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .accessibilityLabel("Quick Practice: 10 random questions")
                            .accessibilityHint(userAccess.hasActiveSubscription ? "Start a quick practice session" : "\(userAccess.testsRemainingThisWeek) of 5 free tests remaining this week")

                            // Full Practice Test
                            Button(action: {
                                HapticManager.shared.impact(style: .medium)
                                if userAccess.canTakeFullPracticeTest {
                                    navigateToFullTest = true
                                } else {
                                    paywallFeatureName = "Full Practice Test"
                                    showPaywall = true
                                }
                            }) {
                                HStack(spacing: DesignSystem.Spacing.md) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                                            .fill(userAccess.hasActiveSubscription ? Color.adaptiveAccentTeal.opacity(0.2) : Color.adaptiveSecondaryBackground)
                                            .frame(width: 48, height: 48)

                                        Image(systemName: userAccess.hasActiveSubscription ? "target" : "lock.fill")
                                            .font(.system(size: DesignSystem.IconSize.md))
                                            .foregroundColor(userAccess.hasActiveSubscription ? Color.adaptiveAccentTeal : Color.adaptiveTextTertiary)
                                    }

                                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                                        Text("Full Practice Test")
                                            .font(DesignSystem.Typography.body)
                                            .fontWeight(.bold)
                                            .foregroundColor(Color.adaptiveTextPrimary)

                                        Text("46 questions • Real DMV format")
                                            .font(DesignSystem.Typography.caption)
                                            .foregroundColor(Color.adaptiveTextSecondary)
                                    }

                                    Spacer()

                                    Image(systemName: userAccess.hasActiveSubscription ? "chevron.right" : "lock.fill")
                                        .font(.system(size: DesignSystem.IconSize.sm))
                                        .foregroundColor(Color.adaptiveTextTertiary)
                                }
                                .padding(DesignSystem.Spacing.md)
                                .background(Color.adaptiveCardBackground)
                                .cornerRadius(DesignSystem.CornerRadius.md)
                            }
                            .pressAnimation()
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .accessibilityLabel("Full Practice Test: 46 questions in real DMV format")
                            .accessibilityHint(userAccess.hasActiveSubscription ? "Start a full length practice exam" : "Premium feature - unlock to access")
                        }

                        // Quick Links
                        if totalAnswered > 0 {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                HStack(spacing: DesignSystem.Spacing.sm) {
                                    // Achievements Card
                                    NavigationLink(destination: AchievementsView()) {
                                        HStack(spacing: DesignSystem.Spacing.sm) {
                                            Image(systemName: "trophy.fill")
                                                .font(.system(size: DesignSystem.IconSize.md))
                                                .foregroundColor(Color.adaptiveAccentYellow)

                                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                                                Text("Achievements")
                                                    .font(DesignSystem.Typography.body)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(Color.adaptiveTextPrimary)

                                                Text("\(AchievementManager.shared.unlockedCount)/\(AchievementManager.shared.achievements.count) unlocked")
                                                    .font(DesignSystem.Typography.caption)
                                                    .foregroundColor(Color.adaptiveTextSecondary)
                                            }
                                        }
                                        .padding(DesignSystem.Spacing.md)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.adaptiveCardBackground)
                                        .cornerRadius(DesignSystem.CornerRadius.md)
                                        .shadow(
                                            color: DesignSystem.Shadow.sm.color,
                                            radius: DesignSystem.Shadow.sm.radius,
                                            y: DesignSystem.Shadow.sm.y
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .pressAnimation()

                                    // Learn Mode Card
                                    NavigationLink(destination: ModuleListView()) {
                                        HStack(spacing: DesignSystem.Spacing.sm) {
                                            Image(systemName: "book.fill")
                                                .font(.system(size: DesignSystem.IconSize.md))
                                                .foregroundColor(Color.adaptivePrimaryBlue)

                                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                                                Text("Learn Mode")
                                                    .font(DesignSystem.Typography.body)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(Color.adaptiveTextPrimary)

                                                Text(userAccess.hasActiveSubscription ? "45 lessons" : "1 free module")
                                                    .font(DesignSystem.Typography.caption)
                                                    .foregroundColor(Color.adaptiveTextSecondary)
                                            }
                                        }
                                        .padding(DesignSystem.Spacing.md)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.adaptiveCardBackground)
                                        .cornerRadius(DesignSystem.CornerRadius.md)
                                        .shadow(
                                            color: DesignSystem.Shadow.sm.color,
                                            radius: DesignSystem.Shadow.sm.radius,
                                            y: DesignSystem.Shadow.sm.y
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .pressAnimation()
                                }
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .onAppear {
                        eventTracker.trackScreenView(screenName: "Settings")
                    }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(
                    triggerPoint: .lockedFeature,
                    featureName: paywallFeatureName
                )
            }
            .navigationDestination(isPresented: $navigateToWeakAreas) {
                QuizView(questionCount: 10, isWeakAreas: true)
            }
            .navigationDestination(isPresented: $navigateToQuickPractice) {
                QuizView(questionCount: 10)
            }
            .navigationDestination(isPresented: $navigateToFullTest) {
                QuizView(questionCount: 46, isExamMode: true)
            }
            .onAppear {
                // Mark app launch complete when home screen appears
                PerformanceMonitor.shared.markAppLaunchComplete()

                // Set Crashlytics user context
                let progressManager = UserProgressManager.shared
                CrashlyticsManager.shared.setUserContext(
                    hasSubscription: userAccess.hasActiveSubscription,
                    questionsAnswered: totalAnswered,
                    level: progressManager.currentLevel
                )

                eventTracker.trackScreenView(screenName: "Home")
                loadAIRecommendation()
            }
        }
    }

    private func getTodayKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func loadAIRecommendation() {
        // Check if user has enough data (at least 20 questions answered)
        let hasEnoughData = totalAnswered >= 20

        // For free users without enough data, don't show preview
        if !userAccess.hasActiveSubscription && !hasEnoughData {
            aiRecommendation = nil
            return
        }

        // For free users with data, show preview
        if !userAccess.hasActiveSubscription {
            aiRecommendation = "Focus on your weakest areas. Practice 10 questions to improve your score..."
            return
        }

        // Premium users: Check cache first
        let cache = AIRecommendationCache.shared
        if let cached = cache.getCachedRecommendation() {
            aiRecommendation = cached
            return
        }

        // Generate new recommendation (premium only)
        isLoadingAI = true

        Task {
            let recommendations = await SmartRecommendationManager.shared.generateRecommendations(includeAI: true)

            await MainActor.run {
                // Find Scout's Suggestion
                if let scoutRec = recommendations.first(where: { $0.moduleName == "Scout's Suggestion" }) {
                    aiRecommendation = scoutRec.reason
                } else {
                    aiRecommendation = "Great job! Keep practicing to maintain your progress."
                }
                isLoadingAI = false
            }
        }
    }
}

// MARK: - Scout Recommendation Card
struct ScoutRecommendationCard: View {
    @Binding var aiRecommendation: String?
    @Binding var isLoading: Bool
    @Binding var navigateToWeakAreas: Bool
    @Binding var showPaywall: Bool

    @StateObject private var userAccess = UserAccessManager.shared

    // Check if we should show the card at all
    private var shouldShow: Bool {
        // Show for premium users always
        if userAccess.hasActiveSubscription {
            return true
        }
        // Show for free users only if we have recommendation data
        return aiRecommendation != nil
    }

    private var shouldShowInsufficientDataMessage: Bool {
        !userAccess.hasActiveSubscription && aiRecommendation == nil
    }

    var body: some View {
        if shouldShowInsufficientDataMessage {
            // Show "Complete another quiz" message for free users without data
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: DesignSystem.IconSize.md))
                        .foregroundColor(Color.adaptivePrimaryBlue)

                    Text("Build Your Profile")
                        .font(DesignSystem.Typography.h4)
                        .foregroundColor(Color.adaptiveTextPrimary)

                    Spacer()
                }

                Text("Complete a few more practice tests so Scout can analyze your weak areas and create a personalized study plan.")
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(Color.adaptiveTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .cardStyle()
            .padding(.horizontal, DesignSystem.Spacing.md)
        } else if shouldShow {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: DesignSystem.IconSize.md))
                    .foregroundColor(Color.adaptivePrimaryBlue)

                Text("Scout's Recommendation")
                    .font(DesignSystem.Typography.h4)
                    .foregroundColor(Color.adaptiveTextPrimary)

                Spacer()

                // AI Badge
                HStack(spacing: DesignSystem.Spacing.xxs) {
                    Text("AI")
                        .font(DesignSystem.Typography.captionSmall)
                        .fontWeight(.bold)
                        .foregroundColor(Color.adaptivePrimaryBlue)
                }
                .padding(.horizontal, DesignSystem.Spacing.xs)
                .padding(.vertical, DesignSystem.Spacing.xxs)
                .background(Color.adaptivePrimaryBlue.opacity(0.15))
                .cornerRadius(DesignSystem.CornerRadius.xs)
            }

            if isLoading {
                // Loading state
                LoadingView(message: "Scout is analyzing your progress...")
                    .padding(DesignSystem.Spacing.md)
            } else if userAccess.hasActiveSubscription {
                // Premium: Full AI recommendation
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text(aiRecommendation ?? "Great job! Keep practicing to maintain your progress.")
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(Color.adaptiveTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    // Timestamp
                    HStack(spacing: DesignSystem.Spacing.xxs) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: DesignSystem.IconSize.xs))
                        Text("Updated \(AIRecommendationCache.shared.getTimeSinceLastUpdate())")
                            .font(DesignSystem.Typography.captionSmall)
                    }
                    .foregroundColor(Color.adaptiveTextTertiary)
                }
            } else {
                // Free: Preview with lock overlay
                VStack(alignment: .leading, spacing: 12) {
                    // Truncated preview
                    ZStack(alignment: .bottomLeading) {
                        Text(aiRecommendation ?? "Focus on specific areas...")
                            .font(.subheadline)
                            .foregroundColor(Color.adaptiveTextSecondary)
                            .lineLimit(2)

                        // Gradient overlay
                        LinearGradient(
                            colors: [Color.adaptiveCardBackground.opacity(0), Color.adaptiveCardBackground],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 40)
                    }

                    // Lock CTA
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .font(.title3)
                                .foregroundColor(Color.adaptivePrimaryBlue)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Unlock AI-Powered Coaching")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.adaptivePrimaryBlue)

                                Text("Get personalized study advice from Scout")
                                    .font(.caption)
                                    .foregroundColor(Color.adaptiveTextSecondary)
                            }

                            Spacer()
                        }

                        Button(action: { showPaywall = true }) {
                            Text("Upgrade for $14.99")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.adaptivePrimaryBlue)
                                .cornerRadius(10)
                        }
                    }
                    .padding(16)
                    .background(Color.adaptiveBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.adaptivePrimaryBlue.opacity(0.3), lineWidth: 2)
                    )
                    .cornerRadius(12)
                }
            }

            // Practice Weak Areas Button
            Button(action: {
                if userAccess.canTakePracticeTest {
                    navigateToWeakAreas = true
                } else {
                    showPaywall = true
                }
            }) {
                Text("Practice Weak Areas")
                    .font(DesignSystem.Typography.labelLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(Color.primaryGradient)
                    .cornerRadius(DesignSystem.CornerRadius.sm)
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .cardStyle()
        .padding(.horizontal, DesignSystem.Spacing.md)
            }
        }
    }

