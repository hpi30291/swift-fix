import SwiftUI

struct LessonListView: View {
    let module: Module

    @StateObject private var learnManager = LearnManager.shared
    @State private var selectedLesson: Lesson?
    @State private var navigateToLesson = false
    private let eventTracker = EventTracker.shared

    var body: some View {
        ZStack {
            Color.adaptiveBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Module Header
                    VStack(alignment: .leading, spacing: 12) {
                        // Module icon and name
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(module.swiftUIColor.opacity(0.2))
                                    .frame(width: 72, height: 72)

                                Image(systemName: module.icon)
                                    .font(.system(size: 32))
                                    .foregroundColor(module.swiftUIColor)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(module.moduleName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.adaptiveTextPrimary)

                                Text("\(module.totalLessons) lessons • \(module.estimatedTime) min")
                                    .font(.subheadline)
                                    .foregroundColor(Color.adaptiveTextSecondary)
                            }

                            Spacer()
                        }

                        // Progress bar
                        let progress = learnManager.progress(for: module.moduleId)
                        let completedCount = learnManager.completedCount(for: module.moduleId)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Your Progress")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color.adaptiveTextSecondary)

                                Spacer()

                                Text("\(completedCount)/\(module.totalLessons) complete")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(module.swiftUIColor)
                            }

                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.adaptiveSecondaryBackground)
                                        .frame(height: 8)

                                    if progress > 0 {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(module.swiftUIColor)
                                            .frame(width: geometry.size.width * progress, height: 8)
                                    }
                                }
                            }
                            .frame(height: 8)
                        }
                    }
                    .padding(20)
                    .background(Color.adaptiveCardBackground)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .padding(.top, 20)

                    // Lessons List
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Lessons")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.adaptiveTextPrimary)
                            .padding(.horizontal)

                        ForEach(module.lessons) { lesson in
                            LessonRow(
                                lesson: lesson,
                                module: module,
                                isCompleted: learnManager.isLessonCompleted(moduleId: module.moduleId, lessonNumber: lesson.lessonNumber),
                                onTap: {
                                    selectedLesson = lesson
                                    navigateToLesson = true
                                }
                            )
                        }
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            eventTracker.trackScreenView(screenName: "Lesson List - \(module.moduleName)")
        }
        .navigationDestination(isPresented: $navigateToLesson) {
            if let lesson = selectedLesson {
                LessonView(module: module, lesson: lesson)
            }
        }
    }
}

// MARK: - Lesson Row
struct LessonRow: View {
    let lesson: Lesson
    let module: Module
    let isCompleted: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Lesson number circle
                ZStack {
                    Circle()
                        .fill(isCompleted ? module.swiftUIColor : Color.adaptiveSecondaryBackground)
                        .frame(width: 48, height: 48)

                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("\(lesson.lessonNumber)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.adaptiveTextSecondary)
                    }
                }

                // Lesson info
                VStack(alignment: .leading, spacing: 4) {
                    Text(lesson.title)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.adaptiveTextPrimary)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                        Text("\(lesson.estimatedReadTime) min read")
                    }
                    .font(.caption)
                    .foregroundColor(Color.adaptiveTextSecondary)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 16))
                    .foregroundColor(isCompleted ? module.swiftUIColor : Color.adaptiveTextTertiary)
            }
            .padding(16)
            .background(Color.adaptiveCardBackground)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        if let module = LearnManager.shared.modules.first {
            LessonListView(module: module)
        }
    }
}
