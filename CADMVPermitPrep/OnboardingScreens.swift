import SwiftUI
import UserNotifications

// MARK: - Welcome Screen

struct WelcomeScreen: View {
    let onContinue: () -> Void
    @State private var opacity: Double = 0

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // App Logo/Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.adaptivePrimaryBlue, Color.adaptivePrimaryBlueDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: Color.adaptivePrimaryBlue.opacity(0.4), radius: 20, y: 10)

                Image(systemName: "car.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
            }
            .opacity(opacity)

            VStack(spacing: 16) {
                Text("CA DMV Permit Prep")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(Color.adaptiveTextPrimary)
                    .multilineTextAlignment(.center)

                Text("Pass your test on the first try")
                    .font(.title3)
                    .foregroundColor(Color.adaptiveTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(opacity)

            Spacer()

            Button(action: onContinue) {
                HStack {
                    Text("Get Started")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.primaryGradient)
                .cornerRadius(16)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                opacity = 1.0
            }
        }
    }
}

// MARK: - Goal Setting Screen

struct GoalSettingScreen: View {
    @Binding var selectedGoal: TestGoal
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                Text("📅")
                    .font(.system(size: 60))

                Text("When's your test?")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color.adaptiveTextPrimary)
                    .multilineTextAlignment(.center)

                Text("We'll personalize your study plan")
                    .font(.body)
                    .foregroundColor(Color.adaptiveTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 60)

            // Goal options
            VStack(spacing: 16) {
                ForEach(TestGoal.allCases, id: \.self) { goal in
                    GoalOptionButton(
                        goal: goal,
                        isSelected: selectedGoal == goal,
                        action: { selectedGoal = goal }
                    )
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            // Continue button
            Button(action: onContinue) {
                HStack {
                    Text("Continue")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.primaryGradient)
                .cornerRadius(16)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
    }
}

struct GoalOptionButton: View {
    let goal: TestGoal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: goal.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? Color.adaptivePrimaryBlue : Color.adaptiveTextSecondary)
                    .frame(width: 30)

                Text(goal.displayName)
                    .font(.headline)
                    .foregroundColor(Color.adaptiveTextPrimary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(Color.adaptivePrimaryBlue)
                }
            }
            .padding(20)
            .background(
                isSelected ?
                Color.adaptivePrimaryBlue.opacity(0.1) :
                Color.adaptiveCardBackground
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.adaptivePrimaryBlue : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Readiness Explainer Screen

struct ReadinessExplainerScreen: View {
    let onStartAssessment: () -> Void
    @State private var animateGauge: Bool = false

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 16) {
                Text("📊")
                    .font(.system(size: 60))

                Text("Your Readiness Score")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color.adaptiveTextPrimary)
                    .multilineTextAlignment(.center)

                Text("We'll show you exactly how ready you are\nto pass the DMV test")
                    .font(.body)
                    .foregroundColor(Color.adaptiveTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Visual gauge preview
            ZStack {
                Circle()
                    .stroke(Color.adaptiveSecondaryBackground, lineWidth: 20)
                    .frame(width: 180, height: 180)

                Circle()
                    .trim(from: 0, to: animateGauge ? 0.85 : 0)
                    .stroke(
                        LinearGradient(
                            colors: [Color.adaptiveSuccess, Color.adaptiveSuccess.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 1.5), value: animateGauge)

                VStack(spacing: 4) {
                    Text("85%")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(Color.adaptiveSuccess)

                    Text("Test Ready")
                        .font(.caption)
                        .foregroundColor(Color.adaptiveTextSecondary)
                }
            }
            .padding(.vertical, 20)

            VStack(spacing: 8) {
                Text("Most students score 40-60% at first.")
                    .font(.subheadline)
                    .foregroundColor(Color.adaptiveTextSecondary)
                    .multilineTextAlignment(.center)

                Text("That's normal! We'll help you improve.")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.adaptivePrimaryBlue)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer()

            // CTA button
            Button(action: onStartAssessment) {
                HStack {
                    Text("Take Assessment Now")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.primaryGradient)
                .cornerRadius(16)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                animateGauge = true
            }
        }
    }
}

// MARK: - Diagnostic Test Screen

struct DiagnosticTestScreen: View {
    let onComplete: (Int, Int, [AnswerRecord]) -> Void

    var body: some View {
        // Redirect to QuizView with 15 questions
        QuizView(questionCount: 15, category: nil, isDiagnostic: true, onDiagnosticComplete: onComplete)
    }
}

// MARK: - Diagnostic Results Screen (for onboarding)

struct DiagnosticResultsScreen: View {
    let score: Int
    let total: Int
    let answers: [AnswerRecord]
    let onContinue: () -> Void

    @State private var animateGauge: Bool = false
    @State private var showReview: Bool = false

    var percentage: Int {
        guard total > 0 else { return 0 }
        return Int((Double(score) / Double(total)) * 100)
    }

    var readinessLevel: String {
        switch percentage {
        case 85...100: return "Test Ready!"
        case 70..<85: return "Almost Ready"
        case 50..<70: return "Keep Practicing"
        default: return "Needs Work"
        }
    }

    var readinessColor: Color {
        switch percentage {
        case 85...100: return Color.adaptiveSuccess
        case 70..<85: return Color.adaptivePrimaryBlue
        case 50..<70: return Color.adaptiveAccentYellow
        default: return Color.adaptiveError
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Text("📊")
                    .font(.system(size: 60))

                Text("Your Readiness Score")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color.adaptiveTextPrimary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 60)

            // Readiness Gauge
            ZStack {
                Circle()
                    .stroke(Color.adaptiveSecondaryBackground, lineWidth: 20)
                    .frame(width: 180, height: 180)

                Circle()
                    .trim(from: 0, to: animateGauge ? Double(percentage) / 100.0 : 0)
                    .stroke(
                        LinearGradient(
                            colors: [readinessColor, readinessColor.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 1.5), value: animateGauge)

                VStack(spacing: 4) {
                    Text("\(percentage)%")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(readinessColor)

                    Text(readinessLevel)
                        .font(.caption)
                        .foregroundColor(Color.adaptiveTextSecondary)
                }
            }
            .padding(.vertical, 20)

            // Score breakdown
            VStack(spacing: 12) {
                Text("You got \(score) out of \(total) questions correct")
                    .font(.headline)
                    .foregroundColor(Color.adaptiveTextPrimary)

                Text("DMV passing score is 38/46 (83%)")
                    .font(.subheadline)
                    .foregroundColor(Color.adaptiveTextSecondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                // Review Answers button
                Button(action: {
                    showReview = true
                }) {
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass")
                        Text("Review Answers")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(Color.adaptivePrimaryBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.adaptivePrimaryBlue.opacity(0.1))
                    .cornerRadius(16)
                }

                // Continue button
                Button(action: onContinue) {
                    HStack {
                        Text("Continue")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.primaryGradient)
                    .cornerRadius(16)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateGauge = true
            }
        }
        .fullScreenCover(isPresented: $showReview) {
            ZStack {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        // Prevent taps behind the review
                    }

                AllAnswersReviewView(
                    answers: answers,
                    onDismiss: {
                        showReview = false
                    }
                )
            }
        }
    }
}

// MARK: - Notification Permission Screen

struct NotificationPermissionScreen: View {
    let onComplete: (Bool) -> Void
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 16) {
                Text("🔔")
                    .font(.system(size: 60))

                Text("Stay consistent")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color.adaptiveTextPrimary)
                    .multilineTextAlignment(.center)

                Text("Daily reminders help students\nimprove 2x faster")
                    .font(.body)
                    .foregroundColor(Color.adaptiveTextSecondary)
                    .multilineTextAlignment(.center)
            }

            // Benefits list
            VStack(alignment: .leading, spacing: 16) {
                BenefitRow(icon: "calendar", text: "Daily study reminders")
                BenefitRow(icon: "chart.line.uptrend.xyaxis", text: "Track your progress")
                BenefitRow(icon: "bell.badge", text: "Motivational tips")
            }
            .padding(.horizontal, 48)

            Spacer()

            // Buttons
            VStack(spacing: 16) {
                Button(action: {
                    requestNotificationPermission()
                }) {
                    HStack {
                        if isRequesting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Enable Notifications")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.primaryGradient)
                    .cornerRadius(16)
                }
                .disabled(isRequesting)

                Button(action: {
                    onComplete(false)
                }) {
                    Text("Not Now")
                        .font(.subheadline)
                        .foregroundColor(Color.adaptiveTextSecondary)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
    }

    private func requestNotificationPermission() {
        isRequesting = true

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                isRequesting = false
                onComplete(granted)

                // Track result
                EventTracker.shared.trackEvent(
                    name: "notification_permission",
                    parameters: ["granted": granted]
                )
            }
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color.adaptivePrimaryBlue)
                .frame(width: 30)

            Text(text)
                .font(.body)
                .foregroundColor(Color.adaptiveTextPrimary)

            Spacer()
        }
    }
}

#Preview("Welcome") {
    WelcomeScreen(onContinue: {})
}

#Preview("Goal Setting") {
    GoalSettingScreen(selectedGoal: .constant(.notScheduled), onContinue: {})
}

#Preview("Readiness Explainer") {
    ReadinessExplainerScreen(onStartAssessment: {})
}

#Preview("Diagnostic Results") {
    DiagnosticResultsScreen(score: 8, total: 15, answers: [], onContinue: {})
}

#Preview("Notification Permission") {
    NotificationPermissionScreen(onComplete: { _ in })
}
