import SwiftUI

struct ReadyToTestCard: View {
    @State private var readiness: ReadinessScore?
    @State private var animatedProgress: Double = 0
    @State private var showQuiz = false
    @State private var navigateToQuiz = false
    @State private var showPaywall = false
    @StateObject private var userAccess = UserAccessManager.shared

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Header
            Text("Test Readiness")
                .font(DesignSystem.Typography.h4)
                .foregroundColor(Color.adaptiveTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let readiness = readiness {
                // Circular gauge - Compact style
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.adaptiveSecondaryBackground, lineWidth: 16)
                        .frame(width: 160, height: 160)

                    // Progress circle
                    Circle()
                        .trim(from: 0, to: animatedProgress)
                        .stroke(
                            statusColor(for: readiness.status),
                            style: StrokeStyle(lineWidth: 16, lineCap: .round)
                        )
                        .frame(width: 160, height: 160)
                        .rotationEffect(.degrees(-90))
                        .animation(DesignSystem.Animation.smooth, value: animatedProgress)

                    // Center content
                    VStack(spacing: DesignSystem.Spacing.xxs) {
                        Text("\(readiness.percentage)%")
                            .font(.system(size: 48, weight: .black))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .foregroundColor(statusColor(for: readiness.status))

                        Text(readiness.status.title)
                            .font(DesignSystem.Typography.captionSmall)
                            .fontWeight(.medium)
                            .foregroundColor(Color.adaptiveTextSecondary)
                    }
                }
                .padding(.vertical, DesignSystem.Spacing.md)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Test readiness: \(readiness.percentage) percent, \(readiness.status.title)")

                // Message
                Text("You need 83% to pass the DMV test")
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(Color.adaptiveTextSecondary)
                    .multilineTextAlignment(.center)
            } else {
                LoadingView(message: "Calculating readiness...")
                    .padding(DesignSystem.Spacing.md)
            }
        }
        .cardStyle()
        .padding(.horizontal, DesignSystem.Spacing.md)
        .onAppear {
            calculateReadiness()
        }
    }

    private var destinationView: some View {
        Group {
            if let readiness = readiness {
                if readiness.status == .ready {
                    // Ready - take full practice test
                    QuizView(questionCount: 46)
                } else if let weakestCategory = readiness.weakestCategory, !weakestCategory.isEmpty {
                    // Not ready - practice weakest category
                    // Verify category has questions before using it
                    let categoryQuestions = QuestionManager.shared.getQuestionsByCategory(weakestCategory)
                    if !categoryQuestions.isEmpty {
                        QuizView(questionCount: 20, category: weakestCategory)
                    } else {
                        // Category has no questions, do random practice
                        QuizView(questionCount: 20)
                    }
                } else {
                    // No weak category identified - random practice
                    QuizView(questionCount: 20)
                }
            } else {
                // No readiness data - random practice
                QuizView(questionCount: 20)
            }
        }
    }
    
    private func calculateReadiness() {
        readiness = ReadyToTestManager.shared.calculateReadiness()
        
        withAnimation(.easeInOut(duration: 1.5)) {
            animatedProgress = Double(readiness?.percentage ?? 0) / 100.0
        }
    }
    
    private func gaugeGradient(for status: ReadinessStatus) -> LinearGradient {
        switch status {
        case .notReady:
            return LinearGradient(
                colors: [Color.adaptiveError, Color.adaptiveError.opacity(0.7)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .almostReady:
            return LinearGradient(
                colors: [Color.adaptiveAccentYellow, Color.adaptiveAccentYellow.opacity(0.7)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .ready:
            return LinearGradient(
                colors: [Color.adaptiveSuccess, Color.adaptiveSuccess.opacity(0.7)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    private func statusColor(for status: ReadinessStatus) -> Color {
        switch status {
        case .notReady: return Color.adaptiveError
        case .almostReady: return Color.adaptiveAccentYellow
        case .ready: return Color.adaptiveSuccess
        }
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: DesignSystem.IconSize.md))
                .foregroundColor(Color.adaptivePrimaryBlue)
                .accessibilityHidden(true)

            Text(value)
                .font(DesignSystem.Typography.h4)
                .foregroundColor(Color.adaptiveTextPrimary)

            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(Color.adaptiveTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

#Preview {
    ReadyToTestCard()
        .padding()
}
