import SwiftUI

struct ScoutView: View {
    @StateObject private var userAccess = UserAccessManager.shared
    @State private var showPaywall = false
    @State private var messages: [ScoutMessage] = []
    @State private var currentMessage: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingRateLimit = false

    private let claudeAPI = ClaudeAPIService.shared

    var body: some View {
        NavigationView {
            ZStack {
                Color.adaptiveBackground
                    .ignoresSafeArea()

                if userAccess.hasActiveSubscription {
                    // Premium users see full Scout interface
                    VStack(spacing: 0) {
                        // Offline banner
                        if !NetworkMonitor.shared.isConnected {
                            HStack(spacing: 8) {
                                Image(systemName: "wifi.slash")
                                    .font(.subheadline)
                                Text("You're offline. Scout needs internet to help.")
                                    .font(.subheadline)
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color.adaptiveAccentYellow)
                        }

                        // Chat interface
                        chatInterface
                    }
                } else {
                    // Free users see locked state
                    lockedStateView
                }
            }
            .navigationTitle("Scout AI")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPaywall) {
                PaywallView(
                    triggerPoint: .lockedFeature,
                    featureName: "Scout AI Tutor"
                )
            }
            .alert("Rate Limit Reached", isPresented: $showingRateLimit) {
                Button("OK") { }
            } message: {
                Text("You've reached your daily or hourly limit for Scout. Premium users get 50 questions per day (10 per hour).")
            }
            .onAppear {
                if messages.isEmpty && userAccess.hasActiveSubscription {
                    addWelcomeMessage()
                }
            }
        }
    }

    // MARK: - Chat Interface
    private var chatInterface: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(messages) { message in
                            ScoutMessageBubble(message: message)
                                .id(message.id)
                        }

                        // Suggested prompts - show only before first user message
                        if messages.count == 1 && !isLoading {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 8) {
                                    Image(systemName: "sparkles")
                                        .font(.subheadline)
                                        .foregroundColor(Color.adaptiveTextSecondary)
                                    Text("Try asking:")
                                        .font(.subheadline)
                                        .foregroundColor(Color.adaptiveTextSecondary)
                                }
                                .padding(.horizontal, 4)

                                // 2x2 grid of suggested prompts
                                VStack(spacing: 12) {
                                    HStack(spacing: 12) {
                                        SuggestedPromptButton(text: "Explain right of way rules") {
                                            currentMessage = "Explain right of way rules"
                                            sendMessage()
                                        }
                                        SuggestedPromptButton(text: "What do yellow signs mean?") {
                                            currentMessage = "What do yellow signs mean?"
                                            sendMessage()
                                        }
                                    }
                                    HStack(spacing: 12) {
                                        SuggestedPromptButton(text: "When must I use headlights?") {
                                            currentMessage = "When must I use headlights?"
                                            sendMessage()
                                        }
                                        SuggestedPromptButton(text: "Tell me about speed limits") {
                                            currentMessage = "Tell me about speed limits"
                                            sendMessage()
                                        }
                                    }
                                }
                            }
                            .padding(.top, 8)
                        }

                        if isLoading {
                            HStack {
                                ProgressView()
                                    .tint(Color.adaptivePrimaryBlue)
                                Text("Scout is thinking...")
                                    .font(.caption)
                                    .foregroundColor(Color.adaptiveTextSecondary)
                            }
                            .padding()
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

            // Input bar
            chatInputBar
        }
    }

    // MARK: - Input Bar
    private var chatInputBar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 12) {
                TextField("Ask Scout anything about the CA DMV test...", text: $currentMessage, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(12)
                    .background(Color.adaptiveCardBackground)
                    .cornerRadius(20)
                    .lineLimit(1...4)

                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(currentMessage.isEmpty ? Color.adaptiveTextTertiary : Color.adaptivePrimaryBlue)
                }
                .disabled(currentMessage.isEmpty || isLoading)
            }
            .padding()
            .background(Color.adaptiveBackground)
        }
    }

    // MARK: - Placeholders
    private var welcomePlaceholder: some View {
        VStack(spacing: 0) {
            Spacer()
            Spacer()
        }
    }

    // MARK: - Locked State
    private var lockedStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lock.fill")
                .font(.system(size: 60))
                .foregroundColor(Color.adaptivePrimaryBlue)

            VStack(spacing: 12) {
                Text("Scout AI is Premium")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.adaptiveTextPrimary)

                Text("Upgrade to get unlimited access to Scout, your personal AI tutor for the CA DMV permit test")
                    .font(.body)
                    .foregroundColor(Color.adaptiveTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(alignment: .leading, spacing: 16) {
                ScoutFeatureRow(icon: "brain.head.profile", text: "Ask Scout any DMV test question")
                ScoutFeatureRow(icon: "lightbulb.fill", text: "Get explanations for wrong answers")
                ScoutFeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Personalized study recommendations")
            }
            .padding(.horizontal, 32)

            Button(action: { showPaywall = true }) {
                Text("Upgrade to Premium • $14.99")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.adaptivePrimaryBlue, Color.adaptiveAccentTeal],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    // MARK: - Actions
    private func addWelcomeMessage() {
        messages.append(ScoutMessage(
            content: "Hi! I'm Scout, your AI tutor for the California DMV permit test. I can help you understand traffic laws, signs, safe driving practices, and everything else you need to pass your test. What would you like to learn about?",
            isUser: false,
            timestamp: Date()
        ))
    }

    private func sendMessage() {
        let userMessage = currentMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userMessage.isEmpty else { return }

        messages.append(ScoutMessage(
            content: userMessage,
            isUser: true,
            timestamp: Date()
        ))

        currentMessage = ""
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let conversationHistory = messages.map { message in
                    ClaudeMessage(role: message.isUser ? "user" : "assistant", content: message.content)
                }

                let response = try await claudeAPI.sendMessage(userMessage, conversationHistory: conversationHistory)

                await MainActor.run {
                    messages.append(ScoutMessage(
                        content: response,
                        isUser: false,
                        timestamp: Date()
                    ))
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    let errorMsg = error.localizedDescription
                    if errorMsg.contains("rate limit") || errorMsg.contains("Rate limit") {
                        showingRateLimit = true
                    } else {
                        errorMessage = errorMsg
                        messages.append(ScoutMessage(
                            content: "Sorry, I encountered an error: \(errorMsg). Please try again.",
                            isUser: false,
                            timestamp: Date()
                        ))
                    }
                    isLoading = false
                }
            }
        }
    }

}

// MARK: - Supporting Views
struct ScoutMessageBubble: View {
    let message: ScoutMessage

    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(message.isUser ? .white : Color.adaptiveTextPrimary)
                    .padding(12)
                    .background(
                        message.isUser ?
                        AnyView(Color.primaryGradient) :
                        AnyView(Color.adaptiveCardBackground)
                    )
                    .cornerRadius(16)

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(Color.adaptiveTextTertiary)
            }

            if !message.isUser {
                Spacer(minLength: 60)
            }
        }
    }
}

struct SuggestedPromptButton: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.subheadline)
                .foregroundColor(Color.adaptiveTextPrimary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.adaptiveCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.adaptiveSecondaryBackground, lineWidth: 2)
                )
                .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ScoutFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(Color.adaptivePrimaryBlue)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
                .foregroundColor(Color.adaptiveTextPrimary)
        }
    }
}

// MARK: - Scout Message Model
struct ScoutMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
}
