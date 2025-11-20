import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @StateObject private var userAccess = UserAccessManager.shared
    @StateObject private var achievementManager = AchievementManager.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            ContentView()
                .tabItem {
                    Label("Home", systemImage: selectedTab == 0 ? "house.fill" : "house")
                }
                .tag(0)

            // Learn Tab
            ModuleListView()
                .tabItem {
                    Label("Learn", systemImage: selectedTab == 1 ? "book.fill" : "book")
                }
                .tag(1)

            // Practice Tab
            PracticeTabView()
                .tabItem {
                    Label("Practice", systemImage: selectedTab == 2 ? "play.circle.fill" : "play.circle")
                }
                .tag(2)

            // Scout AI Tab
            ScoutView()
                .tabItem {
                    Label("Scout", systemImage: selectedTab == 3 ? "brain.head.profile.fill" : "brain.head.profile")
                }
                .tag(3)

            // Profile Tab
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: selectedTab == 4 ? "person.fill" : "person")
                }
                .tag(4)
        }
        .accentColor(Color.adaptivePrimaryBlue)
        .overlay {
            if let achievement = achievementManager.newlyUnlockedAchievement {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        // Prevent taps from going through
                    }

                AchievementUnlockView(
                    achievement: achievement,
                    onDismiss: {
                        achievementManager.dismissAchievement()
                    }
                )
                .zIndex(999)
            }
        }
    }
}

// MARK: - Practice Tab View
struct PracticeTabView: View {
    @StateObject private var userAccess = UserAccessManager.shared
    @State private var showPaywall = false
    @State private var navigateToQuickPractice = false
    @State private var navigateToFullTest = false
    @State private var navigateToCategoryPractice = false
    private let eventTracker = EventTracker.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.adaptiveBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Text("Practice Tests")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(Color.adaptiveTextPrimary)

                            Text("Test your knowledge and build confidence")
                                .font(.subheadline)
                                .foregroundColor(Color.adaptiveTextSecondary)
                        }
                        .padding(.top, 20)
                        .padding(.horizontal)

                        // Free tests remaining (for free users)
                        if !userAccess.hasActiveSubscription {
                            HStack(spacing: 12) {
                                Image(systemName: "calendar.circle.fill")
                                    .foregroundColor(Color.adaptivePrimaryBlue)
                                    .font(.title3)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(userAccess.testsRemainingThisWeek) of 5 free tests remaining")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color.adaptiveTextPrimary)

                                    if userAccess.testsRemainingThisWeek == 0 {
                                        Text("Resets in \(userAccess.daysUntilWeeklyReset()) days")
                                            .font(.caption)
                                            .foregroundColor(Color.adaptiveTextSecondary)
                                    }
                                }

                                Spacer()
                            }
                            .padding(16)
                            .background(Color.adaptiveCardBackground)
                            .cornerRadius(16)
                            .padding(.horizontal)
                        }

                        // Quick Practice
                        Button(action: {
                            if userAccess.canTakePracticeTest {
                                navigateToQuickPractice = true
                            } else {
                                showPaywall = true
                            }
                        }) {
                            PracticeOptionCard(
                                icon: "play.circle.fill",
                                title: "Quick Practice",
                                subtitle: "10 random questions",
                                color: Color.adaptivePrimaryBlue,
                                isLocked: !userAccess.canTakePracticeTest
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        // Full Practice Test
                        Button(action: {
                            if userAccess.canTakeFullPracticeTest {
                                navigateToFullTest = true
                            } else {
                                showPaywall = true
                            }
                        }) {
                            PracticeOptionCard(
                                icon: "doc.text.fill",
                                title: "Full Practice Test",
                                subtitle: "46 questions • Real DMV format",
                                color: Color.adaptiveAccentTeal,
                                isLocked: !userAccess.canTakeFullPracticeTest
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        // Category Practice
                        Button(action: {
                            if userAccess.canAccessCategoryPractice {
                                navigateToCategoryPractice = true
                            } else {
                                showPaywall = true
                            }
                        }) {
                            PracticeOptionCard(
                                icon: "folder.fill",
                                title: "Practice by Category",
                                subtitle: "Focus on specific topics",
                                color: Color.adaptivePrimaryBlueDark,
                                isLocked: !userAccess.canAccessCategoryPractice
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                eventTracker.trackScreenView(screenName: "Practice Tab")
            }
            .navigationDestination(isPresented: $navigateToQuickPractice) {
                QuizView()
            }
            .navigationDestination(isPresented: $navigateToFullTest) {
                QuizView(questionCount: 46)
            }
            .navigationDestination(isPresented: $navigateToCategoryPractice) {
                CategorySelectionView()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(
                    triggerPoint: .lockedFeature,
                    featureName: "Unlimited Practice Tests"
                )
            }
        }
    }
}

// MARK: - Practice Option Card
struct PracticeOptionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let isLocked: Bool

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.adaptiveTextPrimary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(Color.adaptiveTextSecondary)
            }

            Spacer()

            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.title3)
                    .foregroundColor(Color.adaptiveTextSecondary)
            } else {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(Color.adaptiveTextSecondary)
            }
        }
        .padding(20)
        .background(Color.adaptiveCardBackground)
        .cornerRadius(16)
        .shadow(color: color.opacity(0.15), radius: 12, y: 6)
        .padding(.horizontal)
    }
}

#Preview {
    MainTabView()
}
