import SwiftUI

/// User profile showing progress, stats, daily goals, and achievements
struct ProfileView: View {
    @StateObject private var learnManager = LearnManager.shared
    @StateObject private var userAccess = UserAccessManager.shared
    private let performanceTracker = PerformanceTracker.shared

    @AppStorage("dailyGoalQuestions") private var dailyGoalQuestions: Int = 20
    @AppStorage("questionsAnsweredToday") private var questionsAnsweredToday: Int = 0
    @AppStorage("lastActivityDate") private var lastActivityDateString: String = ""
    @AppStorage("currentStreak") private var currentStreak: Int = 0
    @AppStorage("longestStreak") private var longestStreak: Int = 0

    @State private var showGoalPicker = false
    @State private var showPaywall = false
    @State private var categoryStats: [String: CategoryPerformance] = [:]

    var todayProgress: Double {
        guard dailyGoalQuestions > 0 else { return 0 }
        return min(Double(questionsAnsweredToday) / Double(dailyGoalQuestions), 1.0)
    }

    // Only show category performance if at least one category has 5+ questions answered
    var hasSufficientCategoryData: Bool {
        categoryStats.values.contains { $0.questionsAnswered >= 5 }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header - Plan Status
                    VStack(spacing: 16) {
                        Text("Learner Driver")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.adaptiveTextPrimary)

                        // Subscription badge
                        if userAccess.hasActiveSubscription {
                            HStack(spacing: 6) {
                                Image(systemName: "crown.fill")
                                    .font(.caption)
                                Text("Premium")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(
                                LinearGradient(
                                    colors: [Color.adaptivePrimaryBlue, Color.adaptiveAccentTeal],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(10)
                        } else {
                            HStack(spacing: 6) {
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                Text("Free Plan")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(Color.adaptiveTextSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.adaptiveSecondaryBackground)
                            .cornerRadius(10)
                        }
                    }
                    .padding(.top, 20)

                    // Upgrade CTA (for free users)
                    if !userAccess.hasActiveSubscription {
                        upgradeCTA
                    }

                    // Daily Goal Card
                    VStack(spacing: 16) {
                        HStack {
                            HStack(spacing: 12) {
                                Image(systemName: "target")
                                    .font(.title3)
                                    .foregroundColor(Color.adaptivePrimaryBlue)

                                Text("Daily Goal")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.adaptiveTextPrimary)
                            }

                            Spacer()

                            Button(action: {
                                showGoalPicker = true
                            }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color.adaptiveTextSecondary)
                                    .padding(8)
                                    .background(Color.adaptiveSecondaryBackground)
                                    .cornerRadius(8)
                            }
                        }

                        Text("\(questionsAnsweredToday) / \(dailyGoalQuestions) questions")
                            .font(.subheadline)
                            .foregroundColor(Color.adaptiveTextSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.adaptiveSecondaryBackground)
                                    .frame(height: 12)

                                if todayProgress >= 1.0 {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.adaptiveSuccess)
                                        .frame(width: geometry.size.width * todayProgress, height: 12)
                                        .animation(.spring(), value: todayProgress)
                                } else {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.adaptivePrimaryBlue, Color.adaptiveAccentTeal],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * todayProgress, height: 12)
                                        .animation(.spring(), value: todayProgress)
                                }
                            }
                        }
                        .frame(height: 12)

                        if todayProgress >= 1.0 {
                            HStack(spacing: 6) {
                                Text("⭐")
                                Text("Goal completed! Great job!")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color.adaptiveSuccess)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(20)
                    .background(Color.adaptiveCardBackground)
                    .cornerRadius(20)
                    .padding(.horizontal)

                    // Stats Grid - 3 columns
                    HStack(spacing: 12) {
                        // Current Streak
                        VStack(spacing: 12) {
                            Text("🔥")
                                .font(.largeTitle)
                            Text("\(currentStreak)")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(Color.adaptiveAccentYellow)
                            Text("Day Streak")
                                .font(.caption)
                                .foregroundColor(Color.adaptiveTextSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.adaptiveCardBackground)
                        .cornerRadius(16)

                        // Best Streak
                        VStack(spacing: 12) {
                            Text("🏆")
                                .font(.largeTitle)
                            Text("\(longestStreak)")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(Color.adaptiveSuccess)
                            Text("Best Streak")
                                .font(.caption)
                                .foregroundColor(Color.adaptiveTextSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.adaptiveCardBackground)
                        .cornerRadius(16)

                        // Lessons Completed
                        VStack(spacing: 12) {
                            Text("📚")
                                .font(.largeTitle)
                            Text("\(learnManager.totalCompletedLessons)")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(Color.adaptivePrimaryBlue)
                            Text("Lessons")
                                .font(.caption)
                                .foregroundColor(Color.adaptiveTextSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.adaptiveCardBackground)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal)

                    // Category Performance (only show if enough data)
                    if !categoryStats.isEmpty && hasSufficientCategoryData {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 12) {
                                Image(systemName: "chart.bar.fill")
                                    .font(.title3)
                                    .foregroundColor(Color.adaptiveAccentTeal)
                                Text("Category Performance")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.adaptiveTextPrimary)
                            }

                            ForEach(Array(categoryStats.filter { $0.value.questionsAnswered >= 5 }.sorted(by: { $0.key < $1.key })), id: \.key) { category, stats in
                                VStack(spacing: 8) {
                                    HStack {
                                        Text(category)
                                            .font(.subheadline)
                                            .foregroundColor(Color.adaptiveTextPrimary)

                                        Spacer()

                                        Text("\(Int(stats.accuracy * 100))%")
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundColor(categoryColor(for: stats.accuracy))
                                    }

                                    GeometryReader { geometry in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color.adaptiveSecondaryBackground)
                                                .frame(height: 8)

                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(categoryColor(for: stats.accuracy))
                                                .frame(width: geometry.size.width * stats.accuracy, height: 8)
                                        }
                                    }
                                    .frame(height: 8)
                                }
                            }
                        }
                        .padding(20)
                        .background(Color.adaptiveCardBackground)
                        .cornerRadius(20)
                        .padding(.horizontal)
                    }

                    // Test History Button
                    NavigationLink(destination: TestHistoryListView()) {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.adaptivePrimaryBlue.opacity(0.2))
                                    .frame(width: 40, height: 40)

                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color.adaptivePrimaryBlue)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Test History")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color.adaptiveTextPrimary)

                                Text("View past test results")
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
                    .background(Color.adaptiveCardBackground)
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // Analytics Button
                    NavigationLink(destination: AnalyticsView()) {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.adaptiveAccentTeal.opacity(0.2))
                                    .frame(width: 40, height: 40)

                                Image(systemName: "chart.xyaxis.line")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color.adaptiveAccentTeal)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Analytics")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color.adaptiveTextPrimary)

                                Text("Detailed stats & history")
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
                    .background(Color.adaptiveCardBackground)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .background(Color.adaptiveBackground)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                updateTodayProgress()
                loadCategoryStats()
            }
            .sheet(isPresented: $showGoalPicker) {
                DailyGoalPickerView(selectedGoal: $dailyGoalQuestions)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(
                    triggerPoint: .lockedFeature,
                    featureName: "Premium Features"
                )
            }
        }
    }

    // MARK: - Upgrade CTA
    private var upgradeCTA: some View {
        Button(action: { showPaywall = true }) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.title3)
                        .foregroundColor(Color.adaptivePrimaryBlue)

                    Text("Unlock Full Access")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.adaptiveTextPrimary)
                }

                Text("Get unlimited tests, Scout AI tutor, and all features")
                    .font(.subheadline)
                    .foregroundColor(Color.adaptiveTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Upgrade • $14.99")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.adaptivePrimaryBlue, Color.adaptiveAccentTeal],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            .padding(20)
        }
        .buttonStyle(PlainButtonStyle())
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
        .padding(.horizontal)
    }

    private func categoryColor(for accuracy: Double) -> Color {
        if accuracy >= 0.8 { return Color.adaptiveSuccess }
        else if accuracy >= 0.7 { return Color.adaptiveAccentYellow }
        else { return Color.adaptiveError }
    }

    private func updateTodayProgress() {
        let today = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)

        // Reset if it's a new day
        if lastActivityDateString != today {
            if !lastActivityDateString.isEmpty {
                // Check if yesterday (continue streak) or break in streak
                if isYesterday(lastActivityDateString) {
                    currentStreak += 1
                } else {
                    currentStreak = 0
                }
            }
            questionsAnsweredToday = 0
            lastActivityDateString = today
        }

        // Update longest streak
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
    }

    private func isYesterday(_ dateString: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none

        guard let lastDate = formatter.date(from: dateString) else { return false }
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()

        return Calendar.current.isDate(lastDate, inSameDayAs: yesterday)
    }

    private func loadCategoryStats() {
        categoryStats = PerformanceTracker.shared.getAllCategoryPerformance()
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color.adaptiveTextPrimary)

            Text(label)
                .font(.caption)
                .foregroundColor(Color.adaptiveTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.adaptiveCardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
    }
}

struct AchievementBadge: View {
    let icon: String
    let title: String
    var subtitle: String = ""
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? Color.adaptiveAccentYellow.opacity(0.2) : Color.adaptiveSecondaryBackground)
                    .frame(width: 60, height: 60)

                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isUnlocked ? Color.adaptiveAccentYellow : Color.adaptiveTextSecondary)
            }

            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color.adaptiveTextPrimary)

            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(Color.adaptiveTextSecondary)
            }
        }
        .frame(width: 90)
        .opacity(isUnlocked ? 1.0 : 0.5)
    }
}

struct DailyGoalPickerView: View {
    @Binding var selectedGoal: Int
    @Environment(\.presentationMode) var presentationMode

    let goalOptions = [10, 20, 30, 50, 100]

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("How many questions do you want to answer each day?")
                    .font(.headline)
                    .foregroundColor(Color.adaptiveTextPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)
                    .padding(.horizontal)

                ForEach(goalOptions, id: \.self) { goal in
                    Button(action: {
                        selectedGoal = goal
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(goal) questions/day")
                                    .font(.headline)
                                    .foregroundColor(Color.adaptiveTextPrimary)

                                Text(goalDescription(for: goal))
                                    .font(.caption)
                                    .foregroundColor(Color.adaptiveTextSecondary)
                            }

                            Spacer()

                            if selectedGoal == goal {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color.adaptivePrimaryBlue)
                                    .font(.title3)
                            }
                        }
                        .padding()
                        .background(
                            selectedGoal == goal ?
                            Color.adaptivePrimaryBlue.opacity(0.1) :
                            Color.adaptiveCardBackground
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    selectedGoal == goal ? Color.adaptivePrimaryBlue : Color.clear,
                                    lineWidth: 2
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal)

                Spacer()

                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Save Goal")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.adaptivePrimaryBlue)
                        .cornerRadius(14)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .background(Color.adaptiveBackground)
            .navigationTitle("Daily Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    private func goalDescription(for goal: Int) -> String {
        switch goal {
        case 10: return "Light practice - perfect for busy days"
        case 20: return "Balanced - recommended for most learners"
        case 30: return "Focused - serious about passing"
        case 50: return "Intensive - preparing for test soon"
        case 100: return "Power user - maximum preparation"
        default: return ""
        }
    }
}

#Preview {
    ProfileView()
}
