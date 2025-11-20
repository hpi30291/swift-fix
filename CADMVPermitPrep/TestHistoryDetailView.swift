import SwiftUI
import Combine

struct TestHistoryDetailView: View {
    @Environment(\.dismiss) var dismiss
    let test: TestHistoryRecord

    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            HStack {
                Text("Test Details")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.adaptiveTextPrimary)

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color.adaptiveTextSecondary)
                }
            }
            .padding()
            .background(Color.adaptiveCardBackground)

            ScrollView {
                VStack(spacing: 24) {
                    // Header Card
                    headerCard

                    // Stats Card
                    statsCard

                    // Category Breakdown
                    if !test.categoryBreakdown.isEmpty {
                        categoryBreakdownSection
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top, 20)
            }
            .background(Color.adaptiveBackground)
        }
        .onAppear {
            print("DEBUG: Test detail appeared - Score: \(test.score)/\(test.totalQuestions)")
        }
    }

    private var headerCard: some View {
        VStack(spacing: 16) {
            // Score Circle
            ZStack {
                Circle()
                    .stroke(Color.adaptiveSecondaryBackground, lineWidth: 12)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: CGFloat(test.percentage) / 100.0)
                    .stroke(
                        scoreColor,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text("\(test.percentage)%")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(scoreColor)

                    Text(test.passed ? "Passed" : "Failed")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(scoreColor)
                }
            }

            // Test Info
            VStack(spacing: 8) {
                Text(test.testType)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.adaptiveTextPrimary)

                if let category = test.category {
                    Text(category)
                        .font(.subheadline)
                        .foregroundColor(Color.adaptiveTextSecondary)
                }

                Text(test.formattedDate)
                    .font(.caption)
                    .foregroundColor(Color.adaptiveTextSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.adaptiveCardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        .padding(.horizontal)
    }

    private var statsCard: some View {
        VStack(spacing: 16) {
            Text("Statistics")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Color.adaptiveTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                StatRow(
                    icon: "checkmark.circle.fill",
                    label: "Correct Answers",
                    value: "\(test.score)",
                    color: Color.adaptiveSuccess
                )

                StatRow(
                    icon: "xmark.circle.fill",
                    label: "Incorrect Answers",
                    value: "\(test.totalQuestions - test.score)",
                    color: Color.adaptiveError
                )

                StatRow(
                    icon: "questionmark.circle.fill",
                    label: "Total Questions",
                    value: "\(test.totalQuestions)",
                    color: Color.adaptivePrimaryBlue
                )

                StatRow(
                    icon: "clock.fill",
                    label: "Time Taken",
                    value: test.formattedTime,
                    color: Color.adaptiveAccentTeal
                )

                StatRow(
                    icon: "timer",
                    label: "Avg Time per Question",
                    value: String(format: "%.1fs", Double(test.timeTaken) / Double(test.totalQuestions)),
                    color: Color.adaptiveAccentYellow
                )
            }
        }
        .padding(20)
        .background(Color.adaptiveCardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        .padding(.horizontal)
    }

    private var categoryBreakdownSection: some View {
        VStack(spacing: 16) {
            Text("Category Breakdown")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Color.adaptiveTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                ForEach(test.categoryBreakdown.sorted(by: { $0.key < $1.key }), id: \.key) { category, stats in
                    CategoryBreakdownRow(
                        category: category,
                        correct: stats.correct,
                        total: stats.total
                    )
                }
            }
        }
        .padding(20)
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

// MARK: - Stat Row
struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)

            Text(label)
                .font(.subheadline)
                .foregroundColor(Color.adaptiveTextSecondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color.adaptiveTextPrimary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Category Breakdown Row
struct CategoryBreakdownRow: View {
    let category: String
    let correct: Int
    let total: Int

    var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total)
    }

    var accuracyColor: Color {
        if percentage >= 0.8 {
            return Color.adaptiveSuccess
        } else if percentage >= 0.7 {
            return Color.adaptiveAccentYellow
        } else {
            return Color.adaptiveError
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(category)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.adaptiveTextPrimary)

                Spacer()

                Text("\(correct)/\(total)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(accuracyColor)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.adaptiveSecondaryBackground)
                        .cornerRadius(4)

                    Rectangle()
                        .fill(accuracyColor)
                        .frame(width: geometry.size.width * percentage)
                        .cornerRadius(4)
                }
            }
            .frame(height: 6)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TestHistoryDetailView(
        test: TestHistoryRecord(
            id: UUID(),
            date: Date(),
            score: 38,
            totalQuestions: 46,
            timeTaken: 1200,
            testType: "Full Practice Test",
            category: nil,
            percentage: 83,
            categoryBreakdown: [
                "Traffic Signs": (correct: 10, total: 12),
                "Road Rules": (correct: 15, total: 18),
                "Safe Driving": (correct: 13, total: 16)
            ]
        )
    )
}
