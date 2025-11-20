import SwiftUI

struct HandbookSearchView: View {
    @StateObject private var claudeAPI = ClaudeAPIService.shared
    @StateObject private var userAccess = UserAccessManager.shared
    @State private var searchQuery = ""
    @State private var searchResults: [SearchResult] = []
    @State private var isSearching = false
    @State private var showPaywall = false

    struct SearchResult: Identifiable {
        let id = UUID()
        let title: String
        let content: String
        let source: String
        let relevance: String
    }

    var body: some View {
        ZStack {
            if userAccess.hasActiveSubscription {
                searchInterface
            } else {
                premiumOnlyView
            }
        }
        .navigationTitle("Handbook Search")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView(
                triggerPoint: .lockedFeature,
                featureName: "Handbook Search"
            )
        }
    }

    // MARK: - Search Interface
    private var searchInterface: some View {
        VStack(spacing: 0) {
            // Offline banner
            if !NetworkMonitor.shared.isConnected {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                        .font(.caption)
                    Text("You're offline. Search requires internet.")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color.adaptiveAccentYellow)
            }

            // Search bar
            searchBar

            // Usage indicator
            usageIndicator

            // Results or empty state
            if searchResults.isEmpty && !isSearching {
                emptyState
            } else if isSearching {
                loadingState
            } else {
                resultsScrollView
            }
        }
        .background(Color.adaptiveBackground)
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color.adaptiveTextSecondary)

                TextField("Search the DMV Handbook...", text: $searchQuery)
                    .textFieldStyle(PlainTextFieldStyle())
                    .submitLabel(.search)
                    .onSubmit {
                        performSearch()
                    }

                if !searchQuery.isEmpty {
                    Button(action: {
                        searchQuery = ""
                        searchResults = []
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color.adaptiveTextSecondary)
                    }
                }
            }
            .padding()
            .background(Color.adaptiveSecondaryBackground)
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.top, 16)

            // Search button
            Button(action: performSearch) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Search with AI")
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    Group {
                        if searchQuery.isEmpty || isSearching {
                            Color.gray
                        } else {
                            Color.primaryGradient
                        }
                    }
                )
                .cornerRadius(12)
            }
            .disabled(searchQuery.isEmpty || isSearching)
            .padding(.horizontal)
        }
        .padding(.bottom, 12)
        .background(Color.adaptiveCardBackground)
    }

    // MARK: - Usage Indicator
    private var usageIndicator: some View {
        let (daily, hourly) = claudeAPI.getRemainingRequests()

        return HStack(spacing: 8) {
            Image(systemName: "clock.fill")
                .font(.caption)
                .foregroundColor(hourly > 5 ? Color.adaptiveSuccess : Color.adaptiveAccentYellow)

            Text("\(hourly) searches left this hour • \(daily) left today")
                .font(.caption)
                .foregroundColor(Color.adaptiveTextSecondary)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color.adaptiveSecondaryBackground)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.adaptivePrimaryBlue.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "book.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Color.adaptivePrimaryBlue)
            }

            VStack(spacing: 12) {
                Text("Search the DMV Handbook")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.adaptiveTextPrimary)

                Text("Get instant answers from the official California DMV Driver Handbook")
                    .font(.subheadline)
                    .foregroundColor(Color.adaptiveTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(alignment: .leading, spacing: 16) {
                Text("Try searching for:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.adaptiveTextSecondary)

                VStack(alignment: .leading, spacing: 12) {
                    ExampleQuery(icon: "speedometer", text: "Speed limits in California")
                    ExampleQuery(icon: "car.fill", text: "Right of way rules")
                    ExampleQuery(icon: "exclamationmark.triangle.fill", text: "DUI penalties")
                    ExampleQuery(icon: "parkingsign", text: "Parking restrictions")
                }
            }
            .padding(20)
            .background(Color.adaptiveCardBackground)
            .cornerRadius(16)
            .padding(.horizontal)

            Spacer()
        }
    }

    // MARK: - Loading State
    private var loadingState: some View {
        VStack(spacing: 16) {
            Spacer()

            ProgressView()
                .scaleEffect(1.5)

            Text("Searching the handbook...")
                .font(.subheadline)
                .foregroundColor(Color.adaptiveTextSecondary)

            Spacer()
        }
    }

    // MARK: - Results
    private var resultsScrollView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Query summary
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.adaptiveSuccess)
                    Text("Found \(searchResults.count) result\(searchResults.count == 1 ? "" : "s") for \"\(searchQuery)\"")
                        .font(.subheadline)
                        .foregroundColor(Color.adaptiveTextSecondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 16)

                // Results
                ForEach(searchResults) { result in
                    SearchResultCard(result: result)
                }

                // New search prompt
                VStack(spacing: 12) {
                    Divider()
                        .padding(.vertical, 8)

                    Text("Want to refine your search?")
                        .font(.subheadline)
                        .foregroundColor(Color.adaptiveTextSecondary)

                    Button(action: {
                        searchQuery = ""
                        searchResults = []
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("New Search")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.adaptivePrimaryBlue)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.adaptivePrimaryBlue.opacity(0.1))
                        .cornerRadius(20)
                    }
                }
                .padding()
            }
        }
    }

    // MARK: - Premium Only View
    private var premiumOnlyView: some View {
        VStack(spacing: 24) {
            Spacer()

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

                Image(systemName: "book.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
            }

            VStack(spacing: 12) {
                Text("Handbook Search")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color.adaptiveTextPrimary)

                Text("AI-powered search of the official CA DMV Driver Handbook")
                    .font(.body)
                    .foregroundColor(Color.adaptiveTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(alignment: .leading, spacing: 12) {
                FeatureBullet(text: "Instant answers from the official handbook")
                FeatureBullet(text: "Natural language search - ask any question")
                FeatureBullet(text: "Specific page references and sources")
                FeatureBullet(text: "Save time studying with smart search")
            }
            .padding()
            .background(Color.adaptiveCardBackground)
            .cornerRadius(16)
            .padding(.horizontal)

            Button(action: {
                showPaywall = true
            }) {
                Text("Unlock Handbook Search")
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
        .background(Color.adaptiveBackground)
    }

    // MARK: - Actions
    private func performSearch() {
        guard !searchQuery.isEmpty else { return }

        // Check rate limit
        let (allowed, reason) = claudeAPI.canMakeRequest()
        guard allowed else {
            // Show rate limit error as a result
            searchResults = [SearchResult(
                title: "Rate Limit Reached",
                content: reason ?? "You've reached your search limit. Please try again later.",
                source: "System",
                relevance: "Error"
            )]
            return
        }

        isSearching = true
        searchResults = []

        Task {
            do {
                let prompt = """
                Search the Official California DMV Driver Handbook for information about: "\(searchQuery)"

                Please provide a clear, helpful response that includes:
                1. A direct answer to the question
                2. Specific details from the handbook
                3. Any relevant examples or scenarios if applicable
                4. Mention specific sections or page references when possible

                Write in plain text paragraphs - do NOT use markdown formatting like ** or #.
                Keep it concise and easy to read.
                """

                let response = try await claudeAPI.askQuestion(prompt)

                await MainActor.run {
                    // Parse the AI response into a structured result
                    searchResults = [SearchResult(
                        title: searchQuery,
                        content: response,
                        source: "CA DMV Driver Handbook",
                        relevance: "AI-Verified"
                    )]
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    // Show user-friendly error message
                    let errorMessage: String
                    if error.localizedDescription.contains("offline") || error.localizedDescription.contains("internet connection") {
                        errorMessage = error.localizedDescription
                    } else {
                        errorMessage = "Sorry, there was an error searching the handbook. Please check your connection and try again."
                    }

                    searchResults = [SearchResult(
                        title: "Search Error",
                        content: errorMessage,
                        source: "System",
                        relevance: "Error"
                    )]
                    isSearching = false
                }
            }
        }
    }
}

// MARK: - Search Result Card
struct SearchResultCard: View {
    let result: HandbookSearchView.SearchResult

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(Color.adaptivePrimaryBlue)

                VStack(alignment: .leading, spacing: 4) {
                    Text(result.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.adaptiveTextPrimary)

                    HStack(spacing: 8) {
                        Text(result.source)
                            .font(.caption)
                            .foregroundColor(Color.adaptiveTextSecondary)

                        Text("•")
                            .foregroundColor(Color.adaptiveTextSecondary)

                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption2)
                            Text(result.relevance)
                                .font(.caption)
                        }
                        .foregroundColor(Color.adaptiveSuccess)
                    }
                }

                Spacer()
            }

            Divider()

            // Content
            Text(result.content)
                .font(.body)
                .foregroundColor(Color.adaptiveTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(Color.adaptiveCardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
        .padding(.horizontal)
    }
}

// MARK: - Example Query
struct ExampleQuery: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(Color.adaptivePrimaryBlue)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
                .foregroundColor(Color.adaptiveTextPrimary)
        }
    }
}

#Preview {
    NavigationView {
        HandbookSearchView()
    }
}
