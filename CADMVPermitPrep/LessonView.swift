import SwiftUI

struct LessonView: View {
    let module: Module
    let lesson: Lesson

    @Environment(\.dismiss) var dismiss
    @StateObject private var learnManager = LearnManager.shared
    @State private var isCompleted: Bool = false
    @State private var navigateToPractice = false
    @State private var showCompletionAnimation = false
    @State private var scrollOffset: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @State private var hasReached90Percent: Bool = false

    private var lessonIndex: Int {
        module.lessons.firstIndex(where: { $0.lessonNumber == lesson.lessonNumber }) ?? 0
    }

    private var previousLesson: Lesson? {
        guard lessonIndex > 0 else { return nil }
        return module.lessons[lessonIndex - 1]
    }

    private var nextLesson: Lesson? {
        guard lessonIndex < module.lessons.count - 1 else { return nil }
        return module.lessons[lessonIndex + 1]
    }

    var body: some View {
        ZStack {
            Color.adaptiveBackground
                .ignoresSafeArea()

            GeometryReader { outerGeometry in
                ScrollView {
                    GeometryReader { innerGeometry in
                        Color.clear
                            .preference(key: ScrollOffsetPreferenceKey.self, value: innerGeometry.frame(in: .named("scroll")).minY)
                    }
                    .frame(height: 0)

                    VStack(alignment: .leading, spacing: 24) {
                    // Progress indicator
                    VStack(spacing: 8) {
                        HStack {
                            Text("Lesson \(lesson.lessonNumber)/\(module.totalLessons)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.adaptiveTextSecondary)

                            Spacer()

                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption)
                                Text("\(lesson.estimatedReadTime) min read")
                                    .font(.caption)
                            }
                            .foregroundColor(Color.adaptiveTextSecondary)
                        }

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.adaptiveSecondaryBackground)
                                    .frame(height: 4)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(module.swiftUIColor)
                                    .frame(width: geometry.size.width * (Double(lesson.lessonNumber) / Double(module.totalLessons)), height: 4)
                            }
                        }
                        .frame(height: 4)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Module badge
                    HStack(spacing: 8) {
                        Image(systemName: module.icon)
                            .font(.caption)
                            .foregroundColor(module.swiftUIColor)

                        Text(module.moduleName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(module.swiftUIColor)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(module.swiftUIColor.opacity(0.15))
                    .cornerRadius(20)
                    .padding(.horizontal)

                    // Title
                    HStack(spacing: 12) {
                        Image(systemName: lesson.icon)
                            .font(.title)
                            .foregroundColor(module.swiftUIColor)

                        Text(lesson.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.adaptiveTextPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal)

                    // Overview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Overview")
                            .font(.headline)
                            .foregroundColor(Color.adaptiveTextPrimary)

                        Text(lesson.overview)
                            .font(.body)
                            .foregroundColor(Color.adaptiveTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.adaptiveCardBackground)
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // Key Points
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Key Points")
                            .font(.headline)
                            .foregroundColor(Color.adaptiveTextPrimary)

                        ForEach(lesson.keyPoints, id: \.self) { point in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.body)
                                    .foregroundColor(module.swiftUIColor)

                                Text(point)
                                    .font(.body)
                                    .foregroundColor(Color.adaptiveTextSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.adaptiveCardBackground)
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // Detailed Content
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Learn More")
                            .font(.headline)
                            .foregroundColor(Color.adaptiveTextPrimary)

                        Text(lesson.detailedContent)
                            .font(.body)
                            .foregroundColor(Color.adaptiveTextSecondary)
                            .lineSpacing(6)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.adaptiveCardBackground)
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // Real-World Example
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(Color.adaptiveAccentYellow)
                            Text("Real-World Example")
                                .font(.headline)
                                .foregroundColor(Color.adaptiveTextPrimary)
                        }

                        Text(lesson.example)
                            .font(.body)
                            .foregroundColor(Color.adaptiveTextSecondary)
                            .italic()
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.adaptiveAccentYellow.opacity(0.1))
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // Memory Tip
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(Color.adaptivePrimaryBlue)
                            Text("Memory Tip")
                                .font(.headline)
                                .foregroundColor(Color.adaptiveTextPrimary)
                        }

                        Text(lesson.memoryTip)
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.adaptivePrimaryBlue)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.adaptivePrimaryBlue.opacity(0.1))
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // Mark as Complete button
                    Button(action: {
                        markAsComplete()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.title3)

                            Text(isCompleted ? "Lesson Complete" : "Mark as Complete")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(isCompleted ? Color.adaptiveSuccess : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isCompleted ? Color.adaptiveSuccess.opacity(0.2) : module.swiftUIColor)
                        .cornerRadius(16)
                    }
                    .disabled(isCompleted)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Navigation buttons
                    HStack(spacing: 12) {
                        if let prev = previousLesson {
                            NavigationLink(destination: LessonView(module: module, lesson: prev)) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text("Previous")
                                }
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.adaptivePrimaryBlue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.adaptivePrimaryBlue.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }

                        if let next = nextLesson {
                            NavigationLink(destination: LessonView(module: module, lesson: next)) {
                                HStack {
                                    Text("Next")
                                    Image(systemName: "chevron.right")
                                }
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(module.swiftUIColor)
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)

                    GeometryReader { contentGeometry in
                        Color.clear
                            .preference(key: ContentHeightPreferenceKey.self, value: contentGeometry.size.height)
                    }
                    .frame(height: 0)
                }
                .background(
                    GeometryReader { scrollGeometry in
                        Color.clear
                            .onAppear {
                                contentHeight = scrollGeometry.size.height
                            }
                    }
                )
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
                checkScrollProgress(viewportHeight: outerGeometry.size.height)
            }
            .onPreferenceChange(ContentHeightPreferenceKey.self) { value in
                contentHeight = value
            }
        }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    if hasReached90Percent {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color.adaptiveSuccess)
                            .transition(.scale.combined(with: .opacity))
                    }
                    Text(lesson.title)
                        .font(.headline)
                        .foregroundColor(Color.adaptiveTextPrimary)
                        .lineLimit(1)
                }
            }
        }
        .onAppear {
            isCompleted = learnManager.isLessonCompleted(moduleId: module.moduleId, lessonNumber: lesson.lessonNumber)

            EventTracker.shared.trackEvent(
                name: "lesson_viewed",
                parameters: [
                    "module_id": module.moduleId,
                    "lesson_number": lesson.lessonNumber,
                    "lesson_title": lesson.title
                ]
            )
        }
    }

    private func checkScrollProgress(viewportHeight: CGFloat) {
        // Calculate scroll percentage
        // scrollOffset starts at 0 and becomes negative as we scroll down
        let scrolledDistance = abs(scrollOffset)
        let totalScrollableDistance = max(contentHeight - viewportHeight, 0)

        guard totalScrollableDistance > 0 else { return }

        let scrollPercentage = (scrolledDistance / totalScrollableDistance) * 100

        // Check if user has scrolled to 90%
        if scrollPercentage >= 90 && !hasReached90Percent {
            withAnimation(.spring()) {
                hasReached90Percent = true
            }

            // Auto-mark as complete
            markAsComplete()
        }
    }

    private func markAsComplete() {
        if !isCompleted {
            withAnimation {
                learnManager.markLessonCompleted(moduleId: module.moduleId, lessonNumber: lesson.lessonNumber)
                isCompleted = true
            }

            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            // Show success animation
            showCompletionAnimation = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showCompletionAnimation = false
            }
        }
    }
}

// MARK: - Preference Keys for Scroll Tracking
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
