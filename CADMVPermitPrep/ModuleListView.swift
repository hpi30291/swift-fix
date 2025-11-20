import SwiftUI

struct ModuleListView: View {
    @StateObject private var learnManager = LearnManager.shared
    @StateObject private var userAccess = UserAccessManager.shared
    @State private var showPaywall = false
    @State private var selectedModule: Module?
    @State private var navigateToLessons = false
    private let eventTracker = EventTracker.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.adaptiveBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 12) {
                                Image(systemName: "book.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(Color.adaptivePrimaryBlue)

                                Text("Learn Mode")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.adaptiveTextPrimary)
                            }

                            Text("Master the rules before you test")
                                .font(.subheadline)
                                .foregroundColor(Color.adaptiveTextSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 20)
                        .padding(.horizontal)

                        // Module cards - ALL 8 modules visible
                        ForEach(Array(learnManager.modules.enumerated()), id: \.element.id) { index, module in
                            ModuleCard(
                                module: module,
                                isFirstModule: index == 0,
                                onTap: {
                                    if userAccess.hasActiveSubscription || index == 0 {
                                        selectedModule = module
                                        navigateToLessons = true
                                    } else {
                                        showPaywall = true
                                    }
                                }
                            )
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            .onAppear {
                // Trigger module loading by accessing totalLessons
                _ = learnManager.totalLessons
                eventTracker.trackScreenView(screenName: "Learn")
            }
            .navigationDestination(isPresented: $navigateToLessons) {
                if let module = selectedModule {
                    LessonListView(module: module)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(
                    triggerPoint: .lockedFeature,
                    featureName: "Learn Mode"
                )
            }
        }
    }
}

// MARK: - Module Card
struct ModuleCard: View {
    let module: Module
    let isFirstModule: Bool
    let onTap: () -> Void

    @StateObject private var learnManager = LearnManager.shared
    @StateObject private var userAccess = UserAccessManager.shared

    private var completedCount: Int {
        learnManager.completedCount(for: module.moduleId)
    }

    private var progress: Double {
        learnManager.progress(for: module.moduleId)
    }

    // First module is always unlocked, rest require premium
    private var isUnlocked: Bool {
        userAccess.hasActiveSubscription || isFirstModule
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 16) {
                    // Module icon with color
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isUnlocked ? module.swiftUIColor.opacity(0.2) : Color.adaptiveSecondaryBackground)
                            .frame(width: 64, height: 64)

                        Image(systemName: module.icon)
                            .font(.system(size: 28))
                            .foregroundColor(isUnlocked ? module.swiftUIColor : Color.adaptiveTextTertiary)
                    }

                    // Module info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(module.moduleName)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.adaptiveTextPrimary)

                                Text("\(module.totalLessons) lessons • \(module.estimatedTime) min")
                                    .font(.subheadline)
                                    .foregroundColor(Color.adaptiveTextSecondary)
                            }

                            Spacer()

                            // FREE badge for first module (free users only)
                            if isFirstModule && !userAccess.hasActiveSubscription {
                                Text("FREE")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.adaptiveSuccess)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.adaptiveSuccess.opacity(0.15))
                                    .cornerRadius(12)
                            }

                            // Lock icon for locked modules
                            if !isUnlocked {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color.adaptiveTextTertiary)
                            }

                            // Chevron for unlocked modules
                            if isUnlocked {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 20))
                                    .foregroundColor(module.swiftUIColor)
                            }
                        }

                        // Progress bar (only for unlocked modules with progress)
                        if isUnlocked {
                            VStack(alignment: .leading, spacing: 6) {
                                // Progress bar
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

                                // Progress text
                                HStack {
                                    Text("\(completedCount)/\(module.totalLessons) complete")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(module.swiftUIColor)

                                    Spacer()

                                    if completedCount == module.totalLessons && module.totalLessons > 0 {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(module.swiftUIColor)
                                    }
                                }
                            }
                            .padding(.top, 8)
                        }

                        // Unlock button for locked modules
                        if !isUnlocked {
                            Button(action: onTap) {
                                Text("Unlock All Lessons")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color.adaptivePrimaryBlue)
                                    .cornerRadius(10)
                            }
                            .padding(.top, 12)
                        }
                    }
                }
                .padding(20)
            }
            .background(isUnlocked ? module.swiftUIColor.opacity(0.08) : Color.adaptiveBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isUnlocked ? module.swiftUIColor.opacity(0.3) : Color.adaptiveSecondaryBackground, lineWidth: 2)
            )
            .cornerRadius(16)
            .opacity(isUnlocked ? 1.0 : 0.6)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
}

#Preview {
    ModuleListView()
}
