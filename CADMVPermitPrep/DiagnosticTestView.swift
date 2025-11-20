import SwiftUI
import Combine

struct DiagnosticTestView: View {
    @StateObject private var viewModel = DiagnosticTestViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.adaptiveBackground
                .ignoresSafeArea()

            if !viewModel.showResults {
                VStack(spacing: 0) {
                    // Header with timer and progress
                    diagnosticHeader

                    ScrollView {
                        VStack(spacing: 24) {
                            // Question card
                            questionCard

                            // Answer options
                            answerOptions
                        }
                        .padding()
                    }
                }
            } else if let result = viewModel.diagnosticResult {
                DiagnosticResultsView(result: result)
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Header
    private var diagnosticHeader: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .foregroundColor(Color.adaptiveTextPrimary)
                }

                Spacer()

                // Timer
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(Color.adaptiveAccentYellow)
                    Text(viewModel.timeRemaining)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.adaptiveTextPrimary)
                }

                Spacer()

                Text("\(viewModel.currentQuestionIndex + 1)/15")
                    .font(.headline)
                    .foregroundColor(Color.adaptiveTextSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.adaptiveSecondaryBackground)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.primaryGradientHorizontal)
                        .frame(width: geometry.size.width * viewModel.progress, height: 8)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.progress)
                }
            }
            .frame(height: 8)
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 16)
        .background(Color.adaptiveCardBackground)
        .shadow(color: Color.black.opacity(0.1), radius: 10, y: 4)
    }

    // MARK: - Question Card
    private var questionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Diagnostic Question")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color.adaptiveAccentTeal)
                .textCase(.uppercase)

            Text(viewModel.currentQuestion.questionText)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(Color.adaptiveTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(Color.adaptiveCardBackground)
        .cornerRadius(24)
        .shadow(color: Color.adaptivePrimaryBlue.opacity(0.1), radius: 15, y: 8)
    }

    // MARK: - Answer Options
    private var answerOptions: some View {
        VStack(spacing: 12) {
            DiagnosticAnswerButton(
                letter: "A",
                text: viewModel.currentQuestion.answerA ?? "",
                isSelected: viewModel.selectedAnswer == "A",
                action: { viewModel.selectAnswer("A") }
            )

            DiagnosticAnswerButton(
                letter: "B",
                text: viewModel.currentQuestion.answerB ?? "",
                isSelected: viewModel.selectedAnswer == "B",
                action: { viewModel.selectAnswer("B") }
            )

            if let answerC = viewModel.currentQuestion.answerC, !answerC.isEmpty {
                DiagnosticAnswerButton(
                    letter: "C",
                    text: answerC,
                    isSelected: viewModel.selectedAnswer == "C",
                    action: { viewModel.selectAnswer("C") }
                )
            }

            if let answerD = viewModel.currentQuestion.answerD, !answerD.isEmpty {
                DiagnosticAnswerButton(
                    letter: "D",
                    text: answerD,
                    isSelected: viewModel.selectedAnswer == "D",
                    action: { viewModel.selectAnswer("D") }
                )
            }
        }
    }
}

// MARK: - Answer Button
struct DiagnosticAnswerButton: View {
    let letter: String
    let text: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Circle indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.adaptivePrimaryBlue : Color.adaptiveSecondaryBackground, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Color.adaptivePrimaryBlue)
                            .frame(width: 12, height: 12)
                    }
                }

                Text(text)
                    .font(.body)
                    .foregroundColor(Color.adaptiveTextPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }
            .padding(20)
            .background(isSelected ? Color.adaptivePrimaryBlue.opacity(0.1) : Color.adaptiveInnerBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.adaptivePrimaryBlue : Color.adaptiveSecondaryBackground, lineWidth: 2)
            )
            .cornerRadius(16)
        }
    }
}

// MARK: - ViewModel
class DiagnosticTestViewModel: ObservableObject {
    @Published var questions: [Question] = []
    @Published var currentQuestionIndex = 0
    @Published var selectedAnswer: String?
    @Published var answersHistory: [AnswerRecord] = []
    @Published var showResults = false
    @Published var diagnosticResult: DiagnosticTestResult?
    @Published var timeRemaining: String = "10:00"

    private var startTime = Date()
    private var timeLimit: TimeInterval = 600 // 10 minutes
    private var timer: Timer?

    init() {
        questions = DiagnosticTestManager.shared.getDiagnosticQuestions()
        startTimer()

        // Track diagnostic test started
        EventTracker.shared.trackScreenView(screenName: "Diagnostic_Test")
    }

    var currentQuestion: Question {
        guard !questions.isEmpty, currentQuestionIndex < questions.count else {
            return Question(
                id: "error",
                questionText: "No questions available",
                answerA: "A",
                answerB: "B",
                answerC: "C",
                answerD: "D",
                correctAnswer: "A",
                category: "Error",
                explanation: nil
            )
        }
        return questions[currentQuestionIndex]
    }

    var progress: Double {
        return Double(currentQuestionIndex) / Double(questions.count)
    }

    func selectAnswer(_ answer: String) {
        selectedAnswer = answer
        let isCorrect = answer == currentQuestion.correctAnswer

        // Record answer
        answersHistory.append(AnswerRecord(
            question: currentQuestion,
            userAnswer: answer,
            wasCorrect: isCorrect
        ))

        // Move to next question after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.nextQuestion()
        }
    }

    private func nextQuestion() {
        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
            selectedAnswer = nil
        } else {
            finishTest()
        }
    }

    private func finishTest() {
        timer?.invalidate()

        let timeTaken = Date().timeIntervalSince(startTime)
        diagnosticResult = DiagnosticTestManager.shared.calculateResult(
            answers: answersHistory,
            timeTaken: timeTaken
        )

        // Update total stats for readiness calculation
        let correctCount = answersHistory.filter { $0.wasCorrect }.count
        let totalAnswered = UserDefaults.standard.integer(forKey: "totalQuestionsAnswered")
        let totalCorrect = UserDefaults.standard.integer(forKey: "totalCorrectAnswers")

        UserDefaults.standard.set(totalAnswered + answersHistory.count, forKey: "totalQuestionsAnswered")
        UserDefaults.standard.set(totalCorrect + correctCount, forKey: "totalCorrectAnswers")

        // Mark diagnostic test as completed
        UserAccessManager.shared.recordDiagnosticTestCompleted()

        showResults = true
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }

    private func updateTimer() {
        let elapsed = Date().timeIntervalSince(startTime)
        let remaining = max(0, timeLimit - elapsed)

        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        timeRemaining = String(format: "%d:%02d", minutes, seconds)

        // Auto-finish when time runs out
        if remaining <= 0 {
            finishTest()
        }
    }

    deinit {
        timer?.invalidate()
    }
}

#Preview {
    DiagnosticTestView()
}
