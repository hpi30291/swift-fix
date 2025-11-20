import SwiftUI

struct TestHistoryListView: View {
    @StateObject private var historyManager = TestHistoryManager.shared
    @State private var selectedTest: TestHistoryRecord? = nil

    var allTests: [TestHistoryRecord] {
        historyManager.fetchAllTests()
    }

    var body: some View {
        ZStack {
            Color.adaptiveBackground
                .ignoresSafeArea()

            if allTests.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Stats Summary
                        statsSection

                        // Test History List
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Tests")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(Color.adaptiveTextPrimary)
                                .padding(.horizontal)

                            ForEach(allTests) { test in
                                TestHistoryCard(test: test)
                                    .onTapGesture {
                                        print("DEBUG: Tapped test - \(test.testType) - \(test.score)/\(test.totalQuestions)")
                                        selectedTest = test
                                        print("DEBUG: selectedTest set to: \(selectedTest?.testType ?? "nil")")
                                    }
                            }
                        }
                        .padding(.bottom, 24)
                    }
                    .padding(.top, 20)
                }
            }
        }
        .navigationTitle("Test History")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedTest) { test in
            TestHistoryDetailView(test: test)
                .presentationDetents([.large])
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 70))
                .foregroundColor(Color.adaptiveTextSecondary.opacity(0.5))

            Text("No Test History Yet")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.adaptiveTextPrimary)

            Text("Complete practice tests to see your history here")
                .font(.subheadline)
                .foregroundColor(Color.adaptiveTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private var statsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Total Tests
                HistoryStatCard(
                    title: "Tests Taken",
                    value: "\(allTests.count)",
                    icon: "checkmark.circle.fill",
                    color: Color.adaptivePrimaryBlue
                )

                // Average Score
                HistoryStatCard(
                    title: "Avg Score",
                    value: "\(Int(historyManager.getAverageScore()))%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: Color.adaptiveAccentTeal
                )
            }

            HStack(spacing: 16) {
                // Tests Passed
                HistoryStatCard(
                    title: "Passed",
                    value: "\(allTests.filter { $0.passed }.count)",
                    icon: "star.fill",
                    color: Color.adaptiveSuccess
                )

                // Best Score
                HistoryStatCard(
                    title: "Best Score",
                    value: "\(allTests.map { $0.percentage }.max() ?? 0)%",
                    icon: "trophy.fill",
                    color: Color.adaptiveAccentYellow
                )
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Test History Card
struct TestHistoryCard: View {
    let test: TestHistoryRecord

    var body: some View {
        HStack(spacing: 16) {
            // Score indicator
            ZStack {
                Circle()
                    .fill(scoreColor.opacity(0.15))
                    .frame(width: 60, height: 60)

                VStack(spacing: 2) {
                    Text("\(test.percentage)%")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(scoreColor)

                    Image(systemName: test.passed ? "checkmark" : "xmark")
                        .font(.caption2)
                        .foregroundColor(scoreColor)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                // Test type
                Text(test.testType)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.adaptiveTextPrimary)

                // Category if applicable
                if let category = test.category {
                    Text(category)
                        .font(.subheadline)
                        .foregroundColor(Color.adaptiveTextSecondary)
                }

                // Date and time
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text(test.formattedDate)
                            .font(.caption)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text(test.formattedTime)
                            .font(.caption)
                    }
                }
                .foregroundColor(Color.adaptiveTextSecondary)

                // Score
                Text("\(test.score)/\(test.totalQuestions) correct")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color.adaptivePrimaryBlue)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Color.adaptiveTextSecondary)
        }
        .padding(16)
        .background(Color.adaptiveCardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        .padding(.horizontal)
    }

    private var scoreColor: Color {
        if test.percentage >= 90 {
            return Color.adaptiveSuccess
        } else if test.percentage >= 80 {
            return Color.adaptivePrimaryBlue
        } else if test.percentage >= 70 {
            return Color.adaptiveAccentYellow
        } else {
            return Color.adaptiveError
        }
    }
}

// MARK: - History Stat Card
struct HistoryStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)

                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.adaptiveTextPrimary)
            }

            Text(title)
                .font(.caption)
                .foregroundColor(Color.adaptiveTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.adaptiveCardBackground)
        .cornerRadius(12)
        .shadow(color: color.opacity(0.15), radius: 8, y: 4)
    }
}

#Preview {
    NavigationStack {
        TestHistoryListView()
    }
}
