import SwiftUI

struct CategorySelectionView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedCategory: String?
    @State private var navigateToQuiz = false

    let categories: [String]
    let categoryStats: [String: CategoryPerformance]

    init() {
        self.categories = QuestionManager.shared.getCategories()
        self.categoryStats = PerformanceTracker.shared.getAllCategoryPerformance()
    }

    var body: some View {
        ZStack {
            Color.adaptiveBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header - Simple text version
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Practice by Category")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color.adaptiveTextPrimary)

                        Text("Focus on specific topics to strengthen weak areas")
                            .font(.subheadline)
                            .foregroundColor(Color.adaptiveTextSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 20)

                    // Categories
                    ForEach(categories, id: \.self) { category in
                        NavigationLink(destination: QuizView(questionCount: 20, category: category)) {
                            CategoryCardContent(
                                category: category,
                                stats: categoryStats[category]
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CategoryCardContent: View {
    let category: String
    let stats: CategoryPerformance?

    var accuracyColor: Color {
        guard let accuracy = stats?.accuracy else { return .gray }
        if accuracy >= 0.8 { return .green }
        if accuracy >= 0.7 { return .orange }
        return .red
    }

    var body: some View {
            HStack(spacing: 16) {
                // Icon with gradient background
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [categoryColor.opacity(0.2), categoryColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)

                    Image(systemName: categoryIcon(category))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(categoryColor)
                }

                // Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(category)
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundColor(Color.adaptiveTextPrimary)

                    if let stats = stats, stats.questionsAnswered > 0 {
                        HStack(spacing: 8) {
                            // Accuracy badge
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(accuracyColor)
                                    .frame(width: 8, height: 8)

                                Text("\(Int(stats.accuracy * 100))%")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.adaptiveTextSecondary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(accuracyColor.opacity(0.1))
                            .cornerRadius(12)

                            Text("\(stats.questionsAnswered) answered")
                                .font(.caption)
                                .foregroundColor(Color.adaptiveTextSecondary)
                        }
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.caption2)
                                .foregroundColor(Color.adaptiveAccentYellow)

                            Text("Start practicing")
                                .font(.caption)
                                .foregroundColor(Color.adaptiveTextSecondary)
                        }
                    }
                }

                Spacer()

                // Arrow button
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(categoryColor)
            }
            .padding(20)
            .background(Color.adaptiveCardBackground)
            .cornerRadius(20)
            .shadow(color: categoryColor.opacity(0.15), radius: 12, y: 6)
            .padding(.horizontal)
    }

    var categoryColor: Color {
        // Use enum for consistent colors
        guard let categoryEnum = QuestionCategory.fromString(category) else {
            return Color.adaptivePrimaryBlue
        }

        switch categoryEnum {
        case .trafficSigns: return Color.adaptiveError
        case .trafficLaws: return Color.adaptivePrimaryBlue
        case .defensiveDriving: return Color.adaptiveSuccess
        case .sharingTheRoad: return Color.adaptiveAccentTeal
        case .rightOfWay: return Color.adaptiveAccentYellow
        case .parking: return Color.adaptiveAccentPink
        case .alcoholAndDrugs: return Color.orange
        case .specialSituations: return Color.purple
        }
    }

    func categoryIcon(_ category: String) -> String {
        // Use enum for consistent icons
        return QuestionCategory.fromString(category)?.icon ?? "folder.fill"
    }
}
