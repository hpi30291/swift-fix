import SwiftUI
import Combine

// MARK: - Answer Record
struct AnswerRecord: Identifiable {
    let id = UUID()
    let question: Question
    let userAnswer: String
    let wasCorrect: Bool
}

// MARK: - All Answers Review View (for diagnostic)
struct AllAnswersReviewView: View {
    let answers: [AnswerRecord]
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Review Answers")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.adaptivePrimaryBlue, Color.adaptivePrimaryBlueDark],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(Array(answers.enumerated()), id: \.element.id) { index, record in
                        VStack(alignment: .leading, spacing: 12) {
                            // Question number and text
                            HStack(alignment: .top) {
                                Text("Q\(index + 1)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        record.wasCorrect ? Color.adaptiveSuccess : Color.adaptiveError
                                    )
                                    .cornerRadius(8)

                                Text(record.question.questionText)
                                    .font(.headline)
                                    .foregroundColor(Color.adaptiveTextPrimary)
                            }

                            // Show image if available
                            if let imageName = record.question.imageName {
                                Image(imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 150)
                                    .cornerRadius(8)
                            }

                            // User's answer
                            HStack {
                                Text("Your answer:")
                                    .font(.subheadline)
                                    .foregroundColor(Color.adaptiveTextSecondary)
                                Text(record.userAnswer)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(record.wasCorrect ? Color.adaptiveSuccess : Color.adaptiveError)
                            }

                            // Correct answer (if wrong)
                            if !record.wasCorrect {
                                HStack {
                                    Text("Correct answer:")
                                        .font(.subheadline)
                                        .foregroundColor(Color.adaptiveTextSecondary)
                                    Text(record.question.correctAnswer)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color.adaptiveSuccess)
                                }
                            }

                            // Explanation
                            if let explanation = record.question.explanation {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Explanation:")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color.adaptiveTextPrimary)
                                    Text(explanation)
                                        .font(.subheadline)
                                        .foregroundColor(Color.adaptiveTextSecondary)
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding()
                        .background(Color.adaptiveCardBackground)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
                    }
                }
                .padding()
            }
            .background(Color.adaptiveBackground)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cornerRadius(32)
        .shadow(color: .black.opacity(0.2), radius: 30)
        .padding(24)
    }
}

// MARK: - Quiz View
struct QuizView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: QuizViewModel
    @StateObject private var userAccess = UserAccessManager.shared

    let isDiagnostic: Bool
    let isExamMode: Bool  // Hide answers for exam simulator
    let onDiagnosticComplete: ((Int, Int, [AnswerRecord]) -> Void)?

    init(questionCount: Int = 10, category: String? = nil, isDiagnostic: Bool = false, isExamMode: Bool = false, isWeakAreas: Bool = false, onDiagnosticComplete: ((Int, Int, [AnswerRecord]) -> Void)? = nil) {
        let shouldHideAnswers = isDiagnostic || isExamMode
        _viewModel = StateObject(wrappedValue: QuizViewModel(questionCount: questionCount, category: category, isDiagnostic: isDiagnostic, isWeakAreas: isWeakAreas, shouldAutoAdvance: shouldHideAnswers))
        self.isDiagnostic = isDiagnostic
        self.isExamMode = isExamMode
        self.onDiagnosticComplete = onDiagnosticComplete
    }

    // Determine if we should hide answers (diagnostic OR exam mode)
    private var shouldHideAnswers: Bool {
        return isDiagnostic || isExamMode
    }

    
    var body: some View {
        ZStack {
            // Background
            Color.adaptiveBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                        
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.adaptivePrimaryBlue, Color.adaptiveAccentTeal],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * (Double(viewModel.currentQuestionIndex + 1) / Double(viewModel.questions.count)))
                    }
                }
                .frame(height: 8)
                .cornerRadius(4)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Question counter
                HStack {
                    Text("Question \(viewModel.currentQuestionIndex + 1)/\(viewModel.questions.count)")
                        .font(.headline)
                        .foregroundColor(Color.adaptiveTextPrimary)
                    Spacer()
                    if viewModel.currentStreak >= 3 {
                        HStack(spacing: 4) {
                            Text("🔥")
                            Text("\(viewModel.currentStreak) in a row!")
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                colors: [Color.adaptiveAccentYellow, Color.adaptiveAccentRed],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(20)
                        .shadow(color: Color.adaptiveAccentYellow.opacity(0.3), radius: 8, y: 4)
                    }
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Question card
                        VStack(alignment: .leading, spacing: 12) {
                            // Display sign image if available
                            if let imageName = viewModel.currentQuestion.imageName {
                                Image(imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                                    .frame(maxWidth: .infinity)
                                    .padding(.bottom, 8)
                            }

                            Text(viewModel.currentQuestion.questionText)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .fixedSize(horizontal: false, vertical: true)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(
                            LinearGradient(
                                colors: [Color.adaptivePrimaryBlue, Color.adaptivePrimaryBlueDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: Color.adaptivePrimaryBlue.opacity(0.3), radius: 15, y: 8)

                        // Answer buttons
                        VStack(spacing: 12) {
                            if let answerA = viewModel.currentQuestion.answerA, !answerA.isEmpty {
                                AnswerButton(
                                    letter: "A",
                                    text: answerA,
                                    isSelected: viewModel.selectedAnswer == "A",
                                    isCorrect: viewModel.showFeedback && viewModel.currentQuestion.correctAnswer == "A",
                                    isDisabled: viewModel.selectedAnswer != nil,
                                    isExamMode: shouldHideAnswers,
                                    action: { viewModel.selectAnswer("A") }
                                )
                            }

                            if let answerB = viewModel.currentQuestion.answerB, !answerB.isEmpty {
                                AnswerButton(
                                    letter: "B",
                                    text: answerB,
                                    isSelected: viewModel.selectedAnswer == "B",
                                    isCorrect: viewModel.showFeedback && viewModel.currentQuestion.correctAnswer == "B",
                                    isDisabled: viewModel.selectedAnswer != nil,
                                    isExamMode: shouldHideAnswers,
                                    action: { viewModel.selectAnswer("B") }
                                )
                            }

                            if let answerC = viewModel.currentQuestion.answerC, !answerC.isEmpty {
                                AnswerButton(
                                    letter: "C",
                                    text: answerC,
                                    isSelected: viewModel.selectedAnswer == "C",
                                    isCorrect: viewModel.showFeedback && viewModel.currentQuestion.correctAnswer == "C",
                                    isDisabled: viewModel.selectedAnswer != nil,
                                    isExamMode: shouldHideAnswers,
                                    action: { viewModel.selectAnswer("C") }
                                )
                            }

                            if let answerD = viewModel.currentQuestion.answerD, !answerD.isEmpty {
                                AnswerButton(
                                    letter: "D",
                                    text: answerD,
                                    isSelected: viewModel.selectedAnswer == "D",
                                    isCorrect: viewModel.showFeedback && viewModel.currentQuestion.correctAnswer == "D",
                                    isDisabled: viewModel.selectedAnswer != nil,
                                    isExamMode: shouldHideAnswers,
                                    action: { viewModel.selectAnswer("D") }
                                )
                            }
                        }
                            
                            // Feedback message - Compact
                            if viewModel.showFeedback {
                                VStack(spacing: 10) {
                                    // Only show feedback message if not hiding answers
                                    if !shouldHideAnswers {
                                        Text(viewModel.feedbackMessage)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)

                                        if !viewModel.isCorrect {
                                            VStack(spacing: 6) {
                                                Text("Correct answer: \(viewModel.currentQuestion.correctAnswer)")
                                                    .font(.caption)
                                                    .foregroundColor(.white.opacity(0.9))

                                                if let explanation = viewModel.currentQuestion.explanation {
                                                    Text(explanation)
                                                        .font(.caption)
                                                        .foregroundColor(.white.opacity(0.9))
                                                }
                                            }
                                        }
                                    }

                                    Button(action: { viewModel.nextQuestion() }) {
                                        Text(shouldHideAnswers ? "Next Question" : "Next Question")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(Color.white.opacity(0.2))
                                            .cornerRadius(10)
                                    }
                                }
                                .padding(16)
                                .background(
                                    shouldHideAnswers ?
                                    // Neutral background for exam mode
                                    LinearGradient(
                                        colors: [Color.adaptivePrimaryBlue, Color.adaptivePrimaryBlueDark],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) :
                                    // Success/error background for practice mode
                                    LinearGradient(
                                        colors: viewModel.isCorrect ?
                                        [Color.adaptiveSuccess, Color.adaptiveSuccess.opacity(0.8)] :
                                            [Color.adaptiveError, Color.adaptiveError.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: shouldHideAnswers ? Color.adaptivePrimaryBlue.opacity(0.3) : (viewModel.isCorrect ? Color.adaptiveSuccess : Color.adaptiveError).opacity(0.3), radius: 12, y: 6)
                            }
                        }
                        .padding()
                    }
                }
                
                // Show results (only for non-diagnostic tests)
                if viewModel.showResults && !isDiagnostic {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {}

                    ResultsView(
                        score: viewModel.correctAnswers,
                        total: viewModel.questions.count,
                        timeTaken: viewModel.timeTaken,
                        categoryBreakdown: viewModel.categoryBreakdown,
                        answers: viewModel.answersHistory,
                        onReview: {
                            viewModel.showReview = true
                            viewModel.showResults = false
                        },
                        onRetry: {
                            viewModel.reset()
                        },
                        onDismiss: {
                            // Check achievements after dismissing results
                            viewModel.checkAchievements()
                            dismiss()
                        }
                    )
                }
                
                // Show review
                if viewModel.showReview {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {}
                    
                    ReviewView(
                        answers: viewModel.answersHistory,
                        onDismiss: {
                            viewModel.showReview = false
                            viewModel.showResults = true
                        }
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $viewModel.showPaywall) {
                PaywallView(
                    triggerPoint: .questionsLimit
                )
            }
            .onAppear {
                #if DEBUG
                print("✅ QuizView appeared with \(viewModel.questions.count) questions")
                #endif
                viewModel.recordFirstQuestion()
            }
            .onChange(of: viewModel.showResults) { _, newValue in
                // For diagnostic tests, call the completion callback instead of showing results
                if newValue && isDiagnostic {
                    onDiagnosticComplete?(viewModel.correctAnswers, viewModel.questions.count, viewModel.answersHistory)
                }
            }
        }
    }
    
    // MARK: - Answer Button
    struct AnswerButton: View {
        let letter: String
        let text: String
        let isSelected: Bool
        let isCorrect: Bool
        let isDisabled: Bool
        let isExamMode: Bool  // For neutral purple color
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                HStack(spacing: DesignSystem.Spacing.md) {
                    // Circle indicator
                    ZStack {
                        Circle()
                            .stroke(buttonBorderColor, lineWidth: 2)
                            .frame(width: 24, height: 24)

                        // Show filled circle in exam mode when selected
                        if isExamMode && isSelected {
                            Circle()
                                .fill(Color.adaptivePrimaryBlue)
                                .frame(width: 12, height: 12)
                        }
                        // Only show checkmark/X in practice mode (not exam mode)
                        else if !isExamMode {
                            if isCorrect {
                                Image(systemName: "checkmark")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            } else if isSelected {
                                Image(systemName: "xmark")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                    }

                    Text(text)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(buttonTextColor)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()

                    // Only show right-side icons in practice mode
                    if !isExamMode {
                        if isCorrect {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: DesignSystem.IconSize.md))
                                .foregroundColor(.white)
                        } else if isSelected {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: DesignSystem.IconSize.md))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(DesignSystem.Spacing.lg)
                .background(buttonBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .stroke(buttonBorderColor, lineWidth: 2)
                )
                .cornerRadius(DesignSystem.CornerRadius.md)
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(isDisabled)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint(accessibilityHint)
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        }

        private var accessibilityLabel: String {
            var label = "Answer \(letter): \(text)"
            if isCorrect && !isExamMode {
                label += " - Correct"
            } else if isSelected && !isCorrect && !isExamMode {
                label += " - Incorrect"
            } else if isSelected && isExamMode {
                label += " - Selected"
            }
            return label
        }

        private var accessibilityHint: String {
            if isDisabled {
                return ""
            }
            return "Double tap to select this answer"
        }
        
        private var buttonTextColor: Color {
            if isExamMode && isSelected {
                return .white
            } else if isCorrect || isSelected {
                return .white
            }
            return Color.adaptiveTextPrimary
        }

        private var buttonBorderColor: Color {
            if isExamMode && isSelected {
                return Color.adaptivePrimaryBlue
            } else if isCorrect {
                return Color.adaptiveSuccess
            } else if isSelected {
                return Color.adaptiveError
            } else {
                return Color.adaptiveSecondaryBackground
            }
        }

        private var buttonBackground: Color {
            if isExamMode && isSelected {
                return Color.adaptivePrimaryBlue.opacity(0.15)
            } else if isCorrect {
                return Color.adaptiveSuccess.opacity(0.1)
            } else if isSelected {
                return Color.adaptiveError.opacity(0.1)
            } else {
                return Color.adaptiveInnerBackground
            }
        }
    }
    
    // MARK: - Results View
    struct ResultsView: View {
        let score: Int
        let total: Int
        let timeTaken: Int
        let categoryBreakdown: [String: (correct: Int, total: Int)]
        let answers: [AnswerRecord]
        let onReview: () -> Void
        let onRetry: () -> Void
        let onDismiss: () -> Void

        @State private var showConfetti = false
        @State private var navigateToLearn = false
        @State private var selectedModuleId: String?
        @State private var recommendations: [LearningRecommendation] = []
        @State private var showPaywall = false
        @StateObject private var learnManager = LearnManager.shared
        @StateObject private var userAccess = UserAccessManager.shared
        @StateObject private var smartRecs = SmartRecommendationManager.shared
        
        var percentage: Int {
            Int((Double(score) / Double(total)) * 100)
        }

        var passed: Bool {
            score >= Int(Double(total) * 0.8)
        }

        // Find categories where user got < 70% correct
        var weakCategories: [(category: String, accuracy: Double)] {
            categoryBreakdown.compactMap { category, stats in
                guard stats.total > 0 else { return nil }
                let accuracy = Double(stats.correct) / Double(stats.total)
                if accuracy < 0.7 {
                    return (category: category, accuracy: accuracy)
                }
                return nil
            }.sorted { $0.accuracy < $1.accuracy }
        }

        // Map category names to module IDs using single source of truth
        func getModuleId(for category: String) -> String? {
            return QuestionCategory.fromString(category)?.moduleId
        }
        
        var body: some View {
            ZStack {
                ScrollView {
                    VStack(spacing: 16) {
                        // Header - Very Compact
                        HStack(spacing: 12) {
                            Text(percentage == 100 ? "🎊" : (passed ? "🎉" : (percentage < 50 ? "📖" : "💪")))
                                .font(.system(size: 40))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(percentage == 100 ? "Perfect Score!" : (passed ? "Great job!" : (percentage < 50 ? "Keep Learning" : "Getting There!")))
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)

                                if !passed {
                                    Text(percentage < 50 ? "Study the material below to improve" : "You're improving with each practice")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.85))
                                }
                            }
                            Spacer()
                        }
                        .padding(16)
                        .background(
                            LinearGradient(
                                colors: passed ?
                                [Color.adaptiveSuccess, Color.adaptiveSuccess.opacity(0.8)] :
                                    [Color.adaptivePrimaryBlue, Color.adaptivePrimaryBlueDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: (passed ? Color.adaptiveSuccess : Color.adaptivePrimaryBlue).opacity(0.25), radius: 8, y: 4)
                        .padding(.horizontal)
                        .padding(.top, 12)
                        
                        // Score card - Very Compact
                        HStack(spacing: 16) {
                            // Score
                            VStack(spacing: 2) {
                                Text("\(score)/\(total)")
                                    .font(.system(size: 36, weight: .bold))
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                                    .foregroundColor(Color.adaptivePrimaryBlue)
                                Text("\(percentage)%")
                                    .font(.subheadline)
                                    .foregroundColor(Color.adaptiveTextSecondary)
                            }

                            Divider()
                                .frame(height: 50)

                            // Time
                            VStack(spacing: 2) {
                                Image(systemName: "clock.fill")
                                    .font(.body)
                                    .foregroundColor(Color.adaptivePrimaryBlue)
                                Text("\(timeTaken / 60):\(String(format: "%02d", timeTaken % 60))")
                                    .font(.subheadline)
                                    .foregroundColor(Color.adaptiveTextSecondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.adaptiveCardBackground)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
                        .padding(.horizontal)
                        
                        // Message - Compact (only show for perfect/passed)
                        if percentage == 100 {
                            Text("Flawless! You absolutely crushed it!")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.adaptiveSuccess)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        } else if passed {
                            Text("You're ready for the real test!")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.adaptiveSuccess)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }

                        // Category breakdown - Compact
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Category Breakdown")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.adaptiveTextPrimary)

                            ForEach(categoryBreakdown.sorted(by: { $0.key < $1.key }), id: \.key) { category, stats in
                                HStack {
                                    Text(category)
                                        .font(.caption)
                                        .foregroundColor(Color.adaptiveTextPrimary)
                                    Spacer()
                                    Text("\(stats.correct)/\(stats.total)")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color.adaptivePrimaryBlue)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .padding(16)
                        .background(Color.adaptiveCardBackground)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
                        .padding(.horizontal)

                        // Smart Learning Recommendations (show 1-2 max)
                        if !recommendations.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 6) {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.subheadline)
                                        .foregroundColor(Color.adaptivePrimaryBlue)
                                    Text(passed ? "Keep It Up!" : "Next Step")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color.adaptiveTextPrimary)
                                }

                                Text(passed ? "Ready to solidify your knowledge:" : "Focus here to improve your score:")
                                    .font(.caption)
                                    .foregroundColor(Color.adaptiveTextSecondary)

                                ForEach(recommendations.prefix(passed ? 1 : 2)) { rec in
                                    if let module = learnManager.modules.first(where: { $0.moduleId == rec.moduleId }) {
                                        Button(action: {
                                            if userAccess.canAccessLearnMode {
                                                selectedModuleId = rec.moduleId
                                                navigateToLearn = true
                                            } else {
                                                // Show paywall for Learn Mode
                                                showPaywall = true
                                            }
                                        }) {
                                            VStack(spacing: 12) {
                                                HStack(spacing: 12) {
                                                    // Priority badge
                                                    VStack(spacing: 4) {
                                                        Image(systemName: rec.priorityIcon)
                                                            .font(.caption)
                                                            .foregroundColor(rec.priorityColor)
                                                    }
                                                    .frame(width: 32, height: 32)
                                                    .background(rec.priorityColor.opacity(0.1))
                                                    .cornerRadius(8)

                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text(rec.moduleName)
                                                            .font(.subheadline)
                                                            .fontWeight(.semibold)
                                                            .foregroundColor(Color.adaptiveTextPrimary)

                                                        Text(rec.reason)
                                                            .font(.caption)
                                                            .foregroundColor(Color.adaptiveTextSecondary)
                                                            .fixedSize(horizontal: false, vertical: true)
                                                    }

                                                    Spacer()

                                                    if !userAccess.canAccessLearnMode {
                                                        Image(systemName: "lock.fill")
                                                            .font(.caption)
                                                            .foregroundColor(Color.adaptiveTextSecondary)
                                                    } else {
                                                        Image(systemName: "arrow.right")
                                                            .font(.caption)
                                                            .foregroundColor(Color.adaptivePrimaryBlue)
                                                    }
                                                }

                                                // Progress bar if applicable
                                                if rec.currentProgress > 0 {
                                                    HStack(spacing: 8) {
                                                        ProgressView(value: rec.currentProgress)
                                                            .tint(module.swiftUIColor)
                                                        Text("\(Int(rec.currentProgress * 100))%")
                                                            .font(.caption2)
                                                            .foregroundColor(Color.adaptiveTextSecondary)
                                                            .frame(width: 35)
                                                    }
                                                }
                                            }
                                            .padding(12)
                                            .background(Color.adaptiveInnerBackground)
                                            .cornerRadius(12)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                            .padding(16)
                            .background(Color.adaptivePrimaryBlue.opacity(0.05))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
                            .padding(.horizontal)
                        }

                        // Buttons
                        VStack(spacing: 10) {
                            Button(action: onRetry) {
                                Text("Try Again")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.adaptivePrimaryBlue, Color.adaptivePrimaryBlueDark],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                                    .shadow(color: Color.adaptivePrimaryBlue.opacity(0.3), radius: 8, y: 4)
                            }

                            Button(action: onDismiss) {
                                Text("Back to Home")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color.adaptiveTextPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.adaptiveCardBackground.opacity(0.6))
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 32)
                        .padding(.bottom, 24)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.adaptiveBackground)
                .cornerRadius(32)
                .shadow(color: .black.opacity(0.2), radius: 30)
                .padding(24)
                
                // Confetti (only for perfect scores)
                if showConfetti && percentage == 100 {
                    ConfettiView()
                }
            }
            .onAppear {
                // Only show confetti for perfect 100% scores
                if percentage == 100 {
                    // Delay slightly so it appears after the score card animates in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showConfetti = true
                    }
                    // Keep confetti longer for perfect scores
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        showConfetti = false
                    }
                }
                // Generate smart recommendations based on performance
                Task {
                    recommendations = await smartRecs.generateRecommendations(includeAI: true)
                }
            }
            .navigationDestination(isPresented: $navigateToLearn) {
                if let moduleId = selectedModuleId,
                   let module = learnManager.modules.first(where: { $0.moduleId == moduleId }),
                   let firstLesson = learnManager.nextLesson(for: moduleId) {
                    LessonView(module: module, lesson: firstLesson)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(
                    triggerPoint: .lockedFeature,
                    featureName: "Learn Mode"
                )
            }
        }
    }
    
    // MARK: - Review View
    struct ReviewView: View {
        let answers: [AnswerRecord]
        let onDismiss: () -> Void
        
        var incorrectAnswers: [AnswerRecord] {
            answers.filter { !$0.wasCorrect }
        }
        
        var body: some View {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Review Mistakes")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.adaptivePrimaryBlue, Color.adaptivePrimaryBlueDark],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                
                ScrollView {
                    VStack(spacing: 16) {
                        if incorrectAnswers.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 70))
                                    .foregroundColor(Color.adaptiveSuccess)
                                Text("Perfect! No mistakes to review.")
                                    .font(.headline)
                                    .foregroundColor(Color.adaptiveTextPrimary)
                            }
                            .padding(.top, 60)
                        } else {
                            ForEach(incorrectAnswers) { record in
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(record.question.questionText)
                                        .font(.headline)
                                        .foregroundColor(Color.adaptiveTextPrimary)
                                    
                                    HStack {
                                        Text("Your answer:")
                                            .font(.subheadline)
                                            .foregroundColor(Color.adaptiveTextSecondary)
                                        Text(record.userAnswer)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(Color.adaptiveError)
                                    }
                                    
                                    HStack {
                                        Text("Correct answer:")
                                            .font(.subheadline)
                                            .foregroundColor(Color.adaptiveTextSecondary)
                                        Text(record.question.correctAnswer)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(Color.adaptiveSuccess)
                                    }
                                    
                                    if let explanation = record.question.explanation {
                                        Text(explanation)
                                            .font(.subheadline)
                                            .foregroundColor(Color.adaptiveTextSecondary)
                                            .padding(.top, 4)
                                    }
                                }
                                .padding()
                                .background(Color.adaptiveCardBackground)
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
                            }
                        }
                    }
                    .padding()
                }
                .background(Color.adaptiveBackground)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .cornerRadius(32)
            .shadow(color: .black.opacity(0.2), radius: 30)
            .padding(24)
        }
    }

    // MARK: - View Model
    class QuizViewModel: ObservableObject {
        private let progressManager = UserProgressManager.shared
        private let eventTracker = EventTracker.shared
        private let userAccess = UserAccessManager.shared
        private let testHistoryManager = TestHistoryManager.shared
        @Published var pointsEarned = 0
        @Published var questions: [Question] = []
        @Published var currentQuestionIndex = 0
        @Published var selectedAnswer: String?
        @Published var showFeedback = false
        @Published var isCorrect = false
        @Published var correctAnswers = 0
        @Published var currentStreak = 0
        @Published var showResults = false
        @Published var showReview = false
        @Published var feedbackMessage = ""
        @Published var answersHistory: [AnswerRecord] = []
        @Published var showPaywall = false

        private var startTime = Date()
        private var questionStartTime = Date()
        private let performanceTracker = PerformanceTracker.shared
        private let quizCategory: String?
        private let shouldAutoAdvance: Bool
        private let isDiagnostic: Bool

        private let encouragingMessages = [
            "Great job!", "You're on fire!", "Excellent!",
            "Perfect!", "Keep it up!", "Nice work!", "Awesome!"
        ]

        init(questionCount: Int = 10, category: String? = nil, isDiagnostic: Bool = false, isWeakAreas: Bool = false, shouldAutoAdvance: Bool = false) {
            self.quizCategory = category
            self.shouldAutoAdvance = shouldAutoAdvance
            self.isDiagnostic = isDiagnostic

            // Use diagnostic questions if this is a diagnostic test
            if isDiagnostic {
                let diagnosticQuestions = DiagnosticTestManager.shared.getDiagnosticQuestions()
                // Shuffle answer order to prevent patterns (e.g., too many B answers)
                questions = diagnosticQuestions.map { $0.withShuffledAnswers() }
                #if DEBUG
                print("📝 QuizViewModel initialized with \(questions.count) diagnostic questions (answers shuffled)")
                #endif
            } else if isWeakAreas {
                // Use weak areas quiz generation
                questions = QuestionManager.shared.getWeakAreasQuestions(count: questionCount)
                #if DEBUG
                print("📝 QuizViewModel initialized with \(questions.count) weak areas questions")
                #endif
            } else {
                questions = QuestionManager.shared.getAdaptiveQuestions(count: questionCount, category: category)
                #if DEBUG
                print("📝 QuizViewModel initialized with \(questions.count) questions for category: \(category ?? "All")")
                #endif
            }

            questionStartTime = Date()

            // Track quiz started (skip for diagnostic)
            if !isDiagnostic {
                eventTracker.trackQuizStarted(
                    category: isWeakAreas ? "Weak Areas" : (category ?? "All Categories"),
                    questionCount: questions.count
                )

                // Record that a practice test was started (for weekly limit tracking)
                DispatchQueue.main.async { [weak self] in
                    self?.userAccess.recordPracticeTestStarted()
                }
            }
        }

        func recordFirstQuestion() {
            // No longer tracking individual questions - we track practice tests taken instead
            // This is now a no-op but kept for compatibility
        }
        
        var currentQuestion: Question {
            guard !questions.isEmpty, currentQuestionIndex < questions.count else {
                // Return a dummy question if array is empty or index is out of bounds
                return Question(
                    id: "error",
                    questionText: "No questions available",
                    answerA: "Option A",
                    answerB: "Option B",
                    answerC: "Option C",
                    answerD: "Option D",
                    correctAnswer: "A",
                    category: "Error",
                    explanation: nil
                )
            }
            return questions[currentQuestionIndex]
        }
        
        var timeTaken: Int {
            Int(Date().timeIntervalSince(startTime))
        }
        
        var categoryBreakdown: [String: (correct: Int, total: Int)] {
            var breakdown: [String: (correct: Int, total: Int)] = [:]
            for answer in answersHistory {
                let category = answer.question.category
                let current = breakdown[category] ?? (correct: 0, total: 0)
                breakdown[category] = (
                    correct: current.correct + (answer.wasCorrect ? 1 : 0),
                    total: current.total + 1
                )
            }
            return breakdown
        }
        
        func selectAnswer(_ answer: String) {

            selectedAnswer = answer
            isCorrect = answer == currentQuestion.correctAnswer
            showFeedback = !shouldAutoAdvance  // Don't show feedback in exam/diagnostic mode


            let questionTime = Int(Date().timeIntervalSince(questionStartTime))

            // Always track performance, even for diagnostic
            // This ensures readiness score and Scout have data to work with
            performanceTracker.recordAttempt(
                questionId: currentQuestion.id,
                category: currentQuestion.category,
                wasCorrect: isCorrect,
                timeTaken: questionTime
            )

            // Track question answered event (skip for diagnostic to avoid inflated event counts)
            if !isDiagnostic {
                eventTracker.trackQuestionAnswered(
                    questionId: currentQuestion.id,
                    category: currentQuestion.category,
                    wasCorrect: isCorrect,
                    timeTaken: TimeInterval(questionTime)
                )
            }

            answersHistory.append(AnswerRecord(
                question: currentQuestion,
                userAnswer: answer,
                wasCorrect: isCorrect
            ))

            // Only provide haptic feedback in practice mode
            if !shouldAutoAdvance {
                HapticManager.shared.notification(type: isCorrect ? .success : .error)

                // Announce result for VoiceOver users
                AccessibilityAnnouncement.announce(
                    isCorrect ? "Correct!" : "Incorrect. The correct answer is \(currentQuestion.correctAnswer)"
                )
            }

            // Track total questions answered (for stats, not limits)
            let totalAnswered = UserDefaults.standard.integer(forKey: "totalQuestionsAnswered")
            UserDefaults.standard.set(totalAnswered + 1, forKey: "totalQuestionsAnswered")

            // INCREMENT DAILY QUESTIONS FOR ALL ANSWERS:
            UserProgressManager.shared.incrementDailyQuestions()

            if isCorrect {
                correctAnswers += 1
                currentStreak += 1

                let isPerfect = (correctAnswers == questions.count && currentQuestionIndex == questions.count - 1)
                pointsEarned = progressManager.awardPoints(
                    correct: true,
                    streak: currentStreak,
                    isPerfectQuiz: isPerfect,
                    totalCorrect: correctAnswers,
                    totalQuestions: questions.count
                )

                feedbackMessage = encouragingMessages.randomElement() ?? "Correct!"

                let totalCorrect = UserDefaults.standard.integer(forKey: "totalCorrectAnswers")
                UserDefaults.standard.set(totalCorrect + 1, forKey: "totalCorrectAnswers")
            } else {
                currentStreak = 0
                feedbackMessage = "Not quite"
            }

            // Auto-advance to next question in exam/diagnostic mode
            if shouldAutoAdvance {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    self.nextQuestion()
                }
            }
        }
        
        func nextQuestion() {
            // Prevent skipping questions without answering
            guard selectedAnswer != nil else { return }

            if currentQuestionIndex < questions.count - 1 {
                withAnimation {
                    currentQuestionIndex += 1
                    selectedAnswer = nil
                    showFeedback = false
                    questionStartTime = Date()
                }
            } else {
                showResults = true

                // Track quiz completed (skip for diagnostic)
                if !isDiagnostic {
                    eventTracker.trackQuizCompleted(
                        category: quizCategory ?? "All Categories",
                        totalQuestions: questions.count,
                        correctAnswers: correctAnswers,
                        timeSpent: Date().timeIntervalSince(startTime)
                    )

                    // Save test history
                    let testType: String
                    if questions.count >= 40 {
                        testType = "Full Practice Test"
                    } else if quizCategory != nil {
                        testType = "Category Practice"
                    } else {
                        testType = "Quick Practice"
                    }

                    testHistoryManager.saveTest(
                        score: correctAnswers,
                        totalQuestions: questions.count,
                        timeTaken: timeTaken,
                        testType: testType,
                        category: quizCategory,
                        categoryBreakdown: categoryBreakdown
                    )
                }
                // Note: achievements are checked when user dismisses results, not when results first show
            }
        }
        func getAnswerText(for letter: String) -> String {
            switch letter {
            case "A": return currentQuestion.answerA ?? ""
            case "B": return currentQuestion.answerB ?? ""
            case "C": return currentQuestion.answerC ?? ""
            case "D": return currentQuestion.answerD ?? ""
            default: return ""
            }
        }

        func checkAchievements() {
            let totalAnswered = UserDefaults.standard.integer(forKey: "totalQuestionsAnswered")
            let perfectScore = false // Not end of quiz yet
            var categoryAccuracy: [String: Double] = [:]
            for (category, stats) in categoryBreakdown {
                categoryAccuracy[category] = Double(stats.correct) / Double(stats.total)
            }
            
            AchievementManager.shared.checkAchievements(
                totalAnswered: totalAnswered,
                currentStreak: UserProgressManager.shared.currentStreak,
                perfectScore: perfectScore,
                testTimeSeconds: timeTaken,
                categoryAccuracy: categoryAccuracy
            )
        }
        
        func reset() {
            currentQuestionIndex = 0
            selectedAnswer = nil
            showFeedback = false
            isCorrect = false
            correctAnswers = 0
            currentStreak = 0
            showResults = false
            showReview = false
            answersHistory = []
            startTime = Date()
            questionStartTime = Date()
            questions.shuffle()
        }
    }

