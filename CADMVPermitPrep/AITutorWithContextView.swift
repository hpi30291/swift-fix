import SwiftUI

/// AI Tutor view that starts with a specific question context
struct AITutorWithContextView: View {
    let questionText: String
    let userAnswer: String
    let correctAnswer: String
    let category: String
    let explanation: String?

    @StateObject private var claudeAPI = ClaudeAPIService.shared
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var hasAskedInitialQuestion = false

    var body: some View {
        VStack(spacing: 0) {
            // Usage indicator
            usageIndicator

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }

                        if claudeAPI.isLoading {
                            typingIndicator
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) {
                    if let lastMessage = messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            // Input area
            inputArea
        }
        .background(Color.adaptiveBackground)
        .navigationTitle("AI Tutor")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !hasAskedInitialQuestion {
                askInitialQuestion()
            }
        }
    }

    // MARK: - Usage Indicator
    private var usageIndicator: some View {
        let (daily, hourly) = claudeAPI.getRemainingRequests()

        return HStack(spacing: 8) {
            Image(systemName: "clock.fill")
                .font(.caption)
                .foregroundColor(hourly > 5 ? Color.adaptiveSuccess : Color.adaptiveAccentYellow)

            Text("\(hourly) questions left this hour • \(daily) left today")
                .font(.caption)
                .foregroundColor(Color.adaptiveTextSecondary)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color.adaptiveSecondaryBackground)
    }

    // MARK: - Typing Indicator
    private var typingIndicator: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.adaptiveTextSecondary)
                        .frame(width: 8, height: 8)
                        .opacity(0.5)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.adaptiveSecondaryBackground)
            .cornerRadius(20)

            Spacer()
        }
    }

    // MARK: - Input Area
    private var inputArea: some View {
        HStack(spacing: 12) {
            TextField("Ask a follow-up question...", text: $inputText, axis: .vertical)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(12)
                .background(Color.adaptiveSecondaryBackground)
                .cornerRadius(20)
                .lineLimit(1...4)

            Button(action: {
                sendMessage(inputText)
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(inputText.isEmpty ? Color.adaptiveTextSecondary : Color.adaptivePrimaryBlue)
            }
            .disabled(inputText.isEmpty || claudeAPI.isLoading)
        }
        .padding()
        .background(Color.adaptiveCardBackground)
    }

    // MARK: - Actions
    private func askInitialQuestion() {
        hasAskedInitialQuestion = true

        // Add user's original question
        let questionContext = """
        Question: \(questionText)

        I answered: \(userAnswer)
        Correct answer: \(correctAnswer)
        Category: \(category)
        \(explanation != nil ? "\nExplanation: \(explanation!)" : "")

        Can you help me understand why the correct answer is right and why my answer was wrong?
        """

        messages.append(ChatMessage(
            content: questionContext,
            isUser: true,
            timestamp: Date()
        ))

        // Get AI response
        Task {
            do {
                let response = try await claudeAPI.explainAnswer(
                    questionText: questionText,
                    userAnswer: userAnswer,
                    correctAnswer: correctAnswer,
                    category: category,
                    explanation: explanation
                )

                await MainActor.run {
                    messages.append(ChatMessage(
                        content: response,
                        isUser: false,
                        timestamp: Date()
                    ))
                }
            } catch {
                await MainActor.run {
                    messages.append(ChatMessage(
                        content: "Sorry, I encountered an error: \(error.localizedDescription). Please try asking again.",
                        isUser: false,
                        timestamp: Date()
                    ))
                }
            }
        }
    }

    private func sendMessage(_ text: String) {
        guard !text.isEmpty else { return }

        // Add user message
        messages.append(ChatMessage(
            content: text,
            isUser: true,
            timestamp: Date()
        ))

        // Clear input
        inputText = ""

        // Get AI response
        Task {
            do {
                // Check rate limit
                let (allowed, reason) = claudeAPI.canMakeRequest()
                guard allowed else {
                    await MainActor.run {
                        messages.append(ChatMessage(
                            content: reason ?? "Rate limit reached. Please try again later.",
                            isUser: false,
                            timestamp: Date()
                        ))
                    }
                    return
                }

                // Build conversation history for context
                let conversationHistory = messages.dropLast().map { msg in
                    ClaudeMessage(role: msg.isUser ? "user" : "assistant", content: msg.content)
                }

                let response = try await claudeAPI.sendMessage(text, conversationHistory: Array(conversationHistory))

                await MainActor.run {
                    messages.append(ChatMessage(
                        content: response,
                        isUser: false,
                        timestamp: Date()
                    ))
                }
            } catch {
                await MainActor.run {
                    messages.append(ChatMessage(
                        content: "Sorry, I encountered an error: \(error.localizedDescription). Please try again.",
                        isUser: false,
                        timestamp: Date()
                    ))
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        AITutorWithContextView(
            questionText: "What should you do at a yellow light?",
            userAnswer: "Speed up to get through",
            correctAnswer: "Slow down and prepare to stop",
            category: "Traffic Laws",
            explanation: "A yellow light means the signal is about to turn red. You should slow down and prepare to stop if it's safe to do so."
        )
    }
}
