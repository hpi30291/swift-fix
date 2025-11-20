import SwiftUI
import Combine

/// Manages the complete onboarding flow for new users
struct OnboardingFlow: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.adaptiveBackground
                .ignoresSafeArea()

            switch viewModel.currentStep {
            case .welcome:
                WelcomeScreen(onContinue: {
                    viewModel.moveToNext()
                })
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

            case .goalSetting:
                GoalSettingScreen(selectedGoal: $viewModel.testGoal, onContinue: {
                    viewModel.moveToNext()
                })
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

            case .readinessExplainer:
                ReadinessExplainerScreen(onStartAssessment: {
                    viewModel.moveToNext()
                })
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

            case .diagnosticTest:
                DiagnosticTestScreen(onComplete: { score, total, answers in
                    viewModel.diagnosticScore = score
                    viewModel.diagnosticTotal = total
                    viewModel.diagnosticAnswers = answers
                    viewModel.moveToNext()
                })
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

            case .diagnosticResults:
                DiagnosticResultsScreen(
                    score: viewModel.diagnosticScore,
                    total: viewModel.diagnosticTotal,
                    answers: viewModel.diagnosticAnswers,
                    onContinue: {
                        viewModel.moveToNext()
                    }
                )
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

            case .notificationPermission:
                NotificationPermissionScreen(onComplete: { enabled in
                    viewModel.completeOnboarding()
                    // The main app will detect the UserDefaults change and hide onboarding
                })
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
    }
}

// MARK: - OnboardingViewModel

class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var testGoal: TestGoal = .notScheduled
    @Published var diagnosticScore: Int = 0
    @Published var diagnosticTotal: Int = 15
    @Published var diagnosticAnswers: [AnswerRecord] = []

    func moveToNext() {
        switch currentStep {
        case .welcome:
            currentStep = .goalSetting
        case .goalSetting:
            currentStep = .readinessExplainer
        case .readinessExplainer:
            currentStep = .diagnosticTest
        case .diagnosticTest:
            currentStep = .diagnosticResults
        case .diagnosticResults:
            currentStep = .notificationPermission
        case .notificationPermission:
            break // Final step
        }
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.set(testGoal.rawValue, forKey: "userTestGoal")

        // Mark diagnostic test as completed
        UserAccessManager.shared.recordDiagnosticTestCompleted()

        // Track onboarding completion
        EventTracker.shared.trackEvent(
            name: "onboarding_completed",
            parameters: [
                "test_goal": testGoal.rawValue,
                "diagnostic_score": diagnosticScore,
                "diagnostic_total": diagnosticTotal
            ]
        )
    }
}

// MARK: - OnboardingStep

enum OnboardingStep {
    case welcome
    case goalSetting
    case readinessExplainer
    case diagnosticTest
    case diagnosticResults
    case notificationPermission
}

// MARK: - TestGoal

enum TestGoal: String, CaseIterable {
    case oneToTwoWeeks = "1-2 weeks"
    case threeToFourWeeks = "3-4 weeks"
    case oneToTwoMonths = "1-2 months"
    case notScheduled = "Not scheduled"

    var displayName: String {
        return self.rawValue
    }

    var icon: String {
        switch self {
        case .oneToTwoWeeks: return "clock.fill"
        case .threeToFourWeeks: return "calendar"
        case .oneToTwoMonths: return "calendar.badge.clock"
        case .notScheduled: return "questionmark.circle"
        }
    }
}

#Preview {
    OnboardingFlow()
}
