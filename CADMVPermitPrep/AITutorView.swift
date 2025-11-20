import SwiftUI

// MARK: - Chat Message Model
struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
}

// MARK: - AI Tutor Chat View
struct AITutorView: View {
    @StateObject private var claudeAPI = ClaudeAPIService.shared
    @StateObject private var userAccess = UserAccessManager.shared
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var showPaywall = false
    @State private var scrollProxy: ScrollViewProxy?

    // Suggested questions
    private let suggestedQuestions = [
        "What does a yellow traffic light mean?",
        "When should I use my turn signals in California?",
        "What's the speed limit in residential areas?",
        "How far should I follow behind another car?",
        "What do I do at a stop sign?"
    ]

    var body: some View {
        ZStack {
            if userAccess.hasActiveSubscription {
                chatInterface
            } else {
                premiumOnlyView
            }
        }
        .navigationTitle("AI Tutor")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: HandbookSearchView()) {
                    HStack(spacing: 4) {
                        Image(systemName: "book.fill")
                        Image(systemName: "magnifyingglass")
                    }
                    .font(.subheadline)
                    .foregroundColor(Color.adaptivePrimaryBlue)
                }
            }
        }
        .onAppear {
            if messages.isEmpty && userAccess.hasActiveSubscription {
                addWelcomeMessage()
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(
                triggerPoint: .lockedFeature,
                featureName: "AI Tutor"
            )
        }
    }

    // MARK: - Chat Interface
    private var chatInterface: some View {
        VStack(spacing: 0) {
            // Offline banner
            if !NetworkMonitor.shared.isConnected {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                        .font(.caption)
                    Text("You're offline. Scout needs internet to chat.")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color.adaptiveAccentYellow)
            }

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
                .onAppear {
                    scrollProxy = proxy
                }
                .onChange(of: messages.count) {
                    if let lastMessage = messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            // Suggested questions (show when no messages)
            if messages.count <= 1 {
                suggestedQuestionsView
            }

            // Input area
            inputArea
        }
        .background(Color.adaptiveBackground)
    }

    // MARK: - Premium Only View
    private var premiumOnlyView: some View {
        VStack(spacing: 24) {
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

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
            }

            VStack(spacing: 12) {
                Text("Meet Scout")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color.adaptiveTextPrimary)

                Text("Your AI tutor for personalized help and explanations")
                    .font(.body)
                    .foregroundColor(Color.adaptiveTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(alignment: .leading, spacing: 12) {
                FeatureBullet(text: "Ask questions about California driving laws")
                FeatureBullet(text: "Get explanations for difficult concepts")
                FeatureBullet(text: "Personalized study recommendations")
                FeatureBullet(text: "Instant feedback on your weak areas")
            }
            .padding()
            .background(Color.adaptiveCardBackground)
            .cornerRadius(16)
            .padding(.horizontal)

            Button(action: {
                showPaywall = true
            }) {
                Text("Unlock Scout")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primaryGradient)
                    .cornerRadius(16)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top, 40)
        .background(Color.adaptiveBackground)
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

    // MARK: - Suggested Questions
    private var suggestedQuestionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Try asking:")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color.adaptiveTextSecondary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(suggestedQuestions, id: \.self) { question in
                        Button(action: {
                            sendMessage(question)
                        }) {
                            Text(question)
                                .font(.subheadline)
                                .foregroundColor(Color.adaptivePrimaryBlue)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.adaptivePrimaryBlue.opacity(0.1))
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.bottom, 8)
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
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: claudeAPI.isLoading
                        )
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
            TextField("Ask a question...", text: $inputText, axis: .vertical)
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
    private func addWelcomeMessage() {
        messages.append(ChatMessage(
            content: "Hi! I'm Scout, your AI tutor for the California DMV permit test. Ask me anything about California driving laws, traffic signs, or test preparation. How can I help you today?",
            isUser: false,
            timestamp: Date()
        ))
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

                let response = try await claudeAPI.askQuestion(text)

                await MainActor.run {
                    messages.append(ChatMessage(
                        content: response,
                        isUser: false,
                        timestamp: Date()
                    ))
                }
            } catch {
                await MainActor.run {
                    // Show user-friendly error message
                    let errorMessage: String
                    if error.localizedDescription.contains("offline") || error.localizedDescription.contains("internet connection") {
                        errorMessage = error.localizedDescription
                    } else {
                        errorMessage = "Sorry, I encountered an error. Please check your connection and try again."
                    }

                    messages.append(ChatMessage(
                        content: errorMessage,
                        isUser: false,
                        timestamp: Date()
                    ))
                }
            }
        }
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer() }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(message.isUser ? .white : Color.adaptiveTextPrimary)
                    .padding(12)
                    .background(
                        message.isUser ?
                            AnyView(Color.primaryGradient) :
                            AnyView(Color.adaptiveSecondaryBackground)
                    )
                    .cornerRadius(16)

                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(Color.adaptiveTextSecondary)
            }
            .frame(maxWidth: 280, alignment: message.isUser ? .trailing : .leading)

            if !message.isUser { Spacer() }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Feature Bullet
struct FeatureBullet: View {
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color.adaptiveSuccess)
            Text(text)
                .font(.subheadline)
                .foregroundColor(Color.adaptiveTextPrimary)
            Spacer()
        }
    }
}

#Preview {
    NavigationView {
        AITutorView()
    }
}
