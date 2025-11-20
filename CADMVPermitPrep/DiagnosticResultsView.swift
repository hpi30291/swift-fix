import SwiftUI

struct DiagnosticResultsView: View {
    let result: DiagnosticTestResult
    @State private var showPaywall = false
    @State private var animatedProgress: Double = 0
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.adaptiveBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Text(result.passed ? "🎉" : "📊")
                            .font(.system(size: 80))

                        Text(result.passed ? "Great Work!" : "Diagnostic Complete")
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(Color.adaptiveTextPrimary)

                        Text(result.passed ? "You're ready for more practice" : "Let's see where you're at")
                            .font(.headline)
                            .foregroundColor(Color.adaptiveTextSecondary)
                    }
                    .padding(.top, 32)

                    // Score Card with Gap Visualization
                    scoreCard

                    // Category Breakdown
                    categoryBreakdown

                    // Time Taken
                    timeCard

                    // Action Buttons
                    actionButtons
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                animatedProgress = Double(result.percentage) / 100.0
            }

            // Track diagnostic completion
            EventTracker.shared.trackEvent(
                name: "diagnostic_completed",
                parameters: [
                    "score": result.score,
                    "percentage": result.percentage,
                    "passed": result.passed,
                    "time_taken": result.timeTaken
                ]
            )

            // Show paywall after brief delay if not passed
            if !result.passed {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showPaywall = true
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(
                triggerPoint: .diagnosticResults,
                diagnosticScore: result.score,
                diagnosticTotal: result.totalQuestions,
                gapPoints: result.gapPoints
            )
        }
    }

    // MARK: - Score Card with Gap Visualization
    private var scoreCard: some View {
        VStack(spacing: 24) {
            // Current Score vs Required
            VStack(spacing: 8) {
                HStack(alignment: .lastTextBaseline, spacing: 0) {
                    Text("Your Score: ")
                        .font(.headline)
                        .foregroundColor(Color.adaptiveTextSecondary)

                    Text("\(result.score)/\(result.totalQuestions)")
                        .font(.system(size: 48, weight: .black))
                        .foregroundColor(result.passed ? Color.adaptiveSuccess : Color.adaptiveError)

                    Text(" (\(result.percentage)%)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.adaptiveTextSecondary)
                }

                HStack(alignment: .lastTextBaseline, spacing: 0) {
                    Text("Required: ")
                        .font(.headline)
                        .foregroundColor(Color.adaptiveTextSecondary)

                    Text("\(result.passThreshold)/\(result.totalQuestions)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color.adaptiveSuccess)

                    Text(" (80%)")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(Color.adaptiveTextSecondary)
                }
            }

            // Visual Gap Indicator
            VStack(spacing: 16) {
                // Progress bars showing gap
                VStack(alignment: .leading, spacing: 12) {
                    // Current score bar
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your Level")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.adaptiveTextSecondary)

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.adaptiveSecondaryBackground)
                                    .frame(height: 16)

                                // Current score
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: result.passed ?
                                            [Color.adaptiveSuccess, Color.adaptiveSuccess.opacity(0.8)] :
                                            [Color.adaptiveError, Color.adaptiveError.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * animatedProgress, height: 16)
                            }
                        }
                        .frame(height: 16)
                    }

                    // Required score line
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Required to Pass DMV Test")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.adaptiveTextSecondary)

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.adaptiveSecondaryBackground)
                                    .frame(height: 16)

                                // Required threshold
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.adaptiveSuccess, Color.adaptiveSuccess.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * 0.8, height: 16)
                            }
                        }
                        .frame(height: 16)
                    }
                }

                // Gap Message
                if !result.passed {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title3)
                            .foregroundColor(Color.adaptiveAccentYellow)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Gap: \(result.gapPoints) points")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(Color.adaptiveTextPrimary)

                            Text("You need more practice to pass the real DMV test")
                                .font(.subheadline)
                                .foregroundColor(Color.adaptiveTextSecondary)
                        }

                        Spacer()
                    }
                    .padding(16)
                    .background(Color.adaptiveAccentYellow.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
        .padding(24)
        .background(Color.adaptiveCardBackground)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.1), radius: 20, y: 10)
    }

    // MARK: - Category Breakdown
    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Category Breakdown")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.adaptiveTextPrimary)

            VStack(spacing: 12) {
                ForEach(sortedCategories, id: \.key) { category, score in
                    categoryRow(category: category, score: score)
                }
            }
        }
        .padding(24)
        .background(Color.adaptiveCardBackground)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.1), radius: 20, y: 10)
    }

    private var sortedCategories: [(key: String, value: DiagnosticTestResult.CategoryScore)] {
        result.categoryBreakdown.sorted { $0.value.percentage < $1.value.percentage }
    }

    private func categoryRow(category: String, score: DiagnosticTestResult.CategoryScore) -> some View {
        VStack(spacing: 8) {
            HStack {
                // Icon
                Image(systemName: score.isWeak ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(score.isWeak ? Color.adaptiveError : Color.adaptiveSuccess)

                // Category name
                Text(category)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.adaptiveTextPrimary)

                Spacer()

                // Score
                Text("\(score.correct)/\(score.total)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.adaptiveTextPrimary)

                Text("(\(score.percentage)%)")
                    .font(.subheadline)
                    .foregroundColor(Color.adaptiveTextSecondary)

                // Weak indicator
                if score.isWeak {
                    Text("⚠ WEAK")
                        .font(.caption)
                        .fontWeight(.black)
                        .foregroundColor(Color.adaptiveError)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.adaptiveError.opacity(0.15))
                        .cornerRadius(6)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.adaptiveSecondaryBackground)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(score.isWeak ? Color.adaptiveError : Color.adaptiveSuccess)
                        .frame(width: geometry.size.width * Double(score.percentage) / 100.0, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(16)
        .background(Color.adaptiveInnerBackground)
        .cornerRadius(12)
    }

    // MARK: - Time Card
    private var timeCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.adaptiveAccentTeal.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: "clock.fill")
                    .font(.title2)
                    .foregroundColor(Color.adaptiveAccentTeal)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Time Taken")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.adaptiveTextSecondary)
                    .textCase(.uppercase)

                Text(formatTime(result.timeTaken))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.adaptiveTextPrimary)
            }

            Spacer()
        }
        .padding(20)
        .background(Color.adaptiveCardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5)
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if result.passed {
                // If passed, encourage practice tests
                Button(action: {
                    // Navigate to practice test
                    dismiss()
                }) {
                    Text("Start Practice Tests")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(18)
                        .background(Color.primaryGradient)
                        .cornerRadius(16)
                }
            } else {
                // If not passed, show upgrade or practice options
                Button(action: {
                    showPaywall = true
                }) {
                    Text("Unlock Full Access to Improve")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(18)
                        .background(Color.primaryGradient)
                        .cornerRadius(16)
                }
            }

            Button(action: {
                dismiss()
            }) {
                Text("Back to Home")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.adaptivePrimaryBlue)
                    .frame(maxWidth: .infinity)
                    .padding(18)
                    .background(Color.adaptiveInnerBackground)
                    .cornerRadius(16)
            }
        }
    }

    // MARK: - Helpers
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

#Preview {
    DiagnosticResultsView(
        result: DiagnosticTestResult(
            score: 8,
            totalQuestions: 15,
            categoryBreakdown: [
                "Traffic Signs": DiagnosticTestResult.CategoryScore(correct: 2, total: 3, isWeak: false),
                "Traffic Laws": DiagnosticTestResult.CategoryScore(correct: 1, total: 3, isWeak: true),
                "Safe Driving": DiagnosticTestResult.CategoryScore(correct: 2, total: 3, isWeak: false),
                "Right of Way": DiagnosticTestResult.CategoryScore(correct: 1, total: 2, isWeak: true),
                "Alcohol & Drugs": DiagnosticTestResult.CategoryScore(correct: 2, total: 2, isWeak: false)
            ],
            timeTaken: 456,
            passThreshold: 12
        )
    )
}
