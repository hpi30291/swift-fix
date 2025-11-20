import SwiftUI
import CoreData
#if canImport(FirebaseCore)
import FirebaseCore
#endif

@main
struct CA_DMV_Permit_PrepApp: App {
    let persistenceController = PersistenceController.shared
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Start tracking app launch time
        PerformanceMonitor.shared.markAppLaunchStart()

        #if canImport(FirebaseCore)
        FirebaseApp.configure()
        #endif

        // Set up Crashlytics context
        CrashlyticsManager.shared.setAppContext()

        #if DEBUG
        print(CrashlyticsManager.shared.statusMessage)
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainTabView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .preferredColorScheme(.dark) // Force dark mode for all users

                if showOnboarding {
                    OnboardingFlow()
                        .transition(.move(edge: .bottom))
                        .zIndex(1)
                        .onAppear {
                            EventTracker.shared.trackEvent(name: "onboarding_started", parameters: [:])
                        }
                        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
                            // Check if onboarding was completed
                            if UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
                                withAnimation {
                                    showOnboarding = false
                                }
                            }
                        }
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .background:
                    // Track when app goes to background (for review tracking)
                    UserDefaults.standard.set(Date(), forKey: "lastBackgroundDate")
                case .active:
                    // Track session start
                    EventTracker.shared.trackSessionStart()
                case .inactive:
                    break
                @unknown default:
                    break
                }
            }
        }
    }
}
