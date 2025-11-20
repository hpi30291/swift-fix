import SwiftUI

/// Shows personalized learning recommendations based on practice test performance
struct SmartStudyPlanView: View {
    @StateObject private var smartRecs = SmartRecommendationManager.shared
    @StateObject private var learnManager = LearnManager.shared
    @StateObject private var userAccess = UserAccessManager.shared
    @Environment(\.presentationMode) var presentationMode

    @State private var recommendations: [LearningRecommendation] = []
    @State private var navigateToLesson = false
    @State private var selectedModuleId: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 60))
                        .foregroundColor(Color.adaptivePrimaryBlue)

                    Text("Your Smart Study Plan")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color.adaptiveTextPrimary)

                    Text("Personalized recommendations based on your practice test performance and learning progress")
                        .font(.subheadline)
                        .foregroundColor(Color.adaptiveTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 20)

                // Overall Progress
                VStack(spacing: 12) {
                    HStack {
                        Text("Overall Progress")
                            .font(.headline)
                            .foregroundColor(Color.adaptiveTextPrimary)
                        Spacer()
                        Text("\(learnManager.totalCompletedLessons)/\(learnManager.totalLessons) lessons")
                            .font(.subheadline)
                            .foregroundColor(Color.adaptiveTextSecondary)
                    }

                    ProgressView(value: learnManager.overallProgress)
                        .tint(Color.adaptivePrimaryBlue)

                    Text("\(Int(learnManager.overallProgress * 100))% complete")
                        .font(.caption)
                        .foregroundColor(Color.adaptiveTextSecondary)
                }
                .padding()
                .background(Color.adaptiveCardBackground)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
                .padding(.horizontal)

                // Priority Recommendations
                if !recommendations.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recommended for You")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.adaptiveTextPrimary)
                            .padding(.horizontal)

                        ForEach(recommendations) { rec in
                            if let module = learnManager.modules.first(where: { $0.moduleId == rec.moduleId }) {
                                RecommendationCard(
                                    recommendation: rec,
                                    module: module,
                                    onTap: {
                                        if userAccess.canAccessLearnMode {
                                            selectedModuleId = rec.moduleId
                                            navigateToLesson = true
                                        } else {
                                            // TODO: Show paywall when user clicks locked lesson (integrate PaywallView with trigger "locked_feature")
                                        }
                                    }
                                )
                                .padding(.horizontal)
                            }
                        }
                    }
                } else {
                    // No recommendations - user is doing great!
                    VStack(spacing: 16) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Color.adaptiveSuccess)

                        Text("You're All Caught Up!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.adaptiveTextPrimary)

                        Text("Great job! Keep taking practice tests to maintain your skills.")
                            .font(.subheadline)
                            .foregroundColor(Color.adaptiveTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(Color.adaptiveCardBackground)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
                    .padding(.horizontal)
                }

                // Refresh button
                Button(action: {
                    Task {
                        recommendations = await smartRecs.generateRecommendations(includeAI: true)
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh Recommendations")
                    }
                    .font(.subheadline)
                    .foregroundColor(Color.adaptivePrimaryBlue)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(Color.adaptivePrimaryBlue.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.bottom, 32)
            }
        }
        .background(Color.adaptiveBackground)
        .navigationTitle("Study Plan")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            recommendations = await smartRecs.generateRecommendations(includeAI: true)
        }
        .navigationDestination(isPresented: $navigateToLesson) {
            if let moduleId = selectedModuleId,
               let module = learnManager.modules.first(where: { $0.moduleId == moduleId }),
               let firstLesson = learnManager.nextLesson(for: moduleId) {
                LessonView(module: module, lesson: firstLesson)
            }
        }
    }
}

struct RecommendationCard: View {
    let recommendation: LearningRecommendation
    let module: Module
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    // Priority badge
                    VStack(spacing: 4) {
                        Image(systemName: recommendation.priorityIcon)
                            .font(.title3)
                            .foregroundColor(recommendation.priorityColor)
                    }
                    .frame(width: 50, height: 50)
                    .background(recommendation.priorityColor.opacity(0.1))
                    .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 6) {
                        // Module name with icon
                        HStack(spacing: 6) {
                            Image(systemName: module.icon)
                                .foregroundColor(module.swiftUIColor)
                            Text(recommendation.moduleName)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(Color.adaptiveTextPrimary)
                        }

                        // Reason
                        Text(recommendation.reason)
                            .font(.subheadline)
                            .foregroundColor(Color.adaptiveTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        // Practice test accuracy if available
                        if let accuracy = recommendation.quizAccuracy {
                            HStack(spacing: 4) {
                                Image(systemName: accuracy < 0.5 ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(accuracy < 0.5 ? Color.adaptiveError : Color.adaptiveAccentYellow)
                                Text("Practice test accuracy: \(Int(accuracy * 100))%")
                                    .font(.caption)
                                    .foregroundColor(Color.adaptiveTextSecondary)
                            }
                        }
                    }

                    Spacer()

                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color.adaptivePrimaryBlue)
                }

                // Progress bar
                VStack(spacing: 6) {
                    HStack {
                        Text("Progress")
                            .font(.caption)
                            .foregroundColor(Color.adaptiveTextSecondary)
                        Spacer()
                        Text("\(LearnManager.shared.completedCount(for: module.moduleId))/\(module.totalLessons) lessons")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.adaptivePrimaryBlue)
                    }

                    ProgressView(value: recommendation.currentProgress)
                        .tint(module.swiftUIColor)
                }

                // Action button
                HStack {
                    Spacer()
                    Text(recommendation.suggestedAction)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(module.swiftUIColor)
                    Spacer()
                }
                .padding(.vertical, 10)
                .background(module.swiftUIColor.opacity(0.1))
                .cornerRadius(10)
            }
            .padding(16)
            .background(Color.adaptiveCardBackground)
            .cornerRadius(16)
            .shadow(color: recommendation.priorityColor.opacity(0.1), radius: 15, y: 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationView {
        SmartStudyPlanView()
    }
}
