import SwiftUI

enum PaywallTriggerPoint {
    case diagnosticResults
    case questionsLimit
    case lockedFeature
}

struct PaywallView: View {
    let triggerPoint: PaywallTriggerPoint
    var diagnosticScore: Int?
    var diagnosticTotal: Int?
    var gapPoints: Int?
    var featureName: String?

    @Environment(\.dismiss) var dismiss
    @StateObject private var userAccess = UserAccessManager.shared
    @StateObject private var storeKit = StoreKitManager.shared
    @State private var showingPurchaseError = false
    @State private var errorMessage = ""
    @State private var animateGradient = false
    @State private var isPurchasing = false
    @State private var showSuccessScreen = false

    var body: some View {
        ZStack {
            Color.adaptiveBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xl) {
                    // Header based on trigger point
                    header

                    // CA DMV Licensed Badge
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(Color.adaptiveSuccess)

                        Text("CA DMV Licensed Driver Education Provider • License #E0333")
                            .font(DesignSystem.Typography.bodySmall)
                            .fontWeight(.medium)
                            .foregroundColor(Color.adaptiveSuccess)
                    }
                    .padding(DesignSystem.Spacing.md)
                    .frame(maxWidth: .infinity)
                    .background(Color.adaptiveSuccess.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                            .stroke(Color.adaptiveSuccess.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(DesignSystem.CornerRadius.sm)

                    // Performance section (only for diagnostic results)
                    if triggerPoint == .diagnosticResults {
                        performanceSection
                    }

                    // Features list
                    featuresSection

                    // Action buttons
                    actionButtons
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.vertical, DesignSystem.Spacing.xl)
            }
        }
        .alert("Purchase Error", isPresented: $showingPurchaseError) {
            Button("OK", role: .cancel) {
                showingPurchaseError = false
            }
        } message: {
            Text(errorMessage)
        }
        .overlay {
            if showSuccessScreen {
                PurchaseSuccessView(onDismiss: {
                    showSuccessScreen = false
                    dismiss()
                })
            }
        }
        .onAppear {
            // Track paywall view with improved method
            EventTracker.shared.trackPaywallViewed(
                trigger: triggerPointName,
                score: diagnosticScore,
                testsRemaining: userAccess.testsRemainingThisWeek
            )

            // Animate gradient
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
    }

    // MARK: - Header
    @ViewBuilder
    private var header: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // Star icon (compact)
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.adaptivePrimaryBlue, Color.adaptiveAccentTeal],
                            startPoint: animateGradient ? .topLeading : .bottomTrailing,
                            endPoint: animateGradient ? .bottomTrailing : .topLeading
                        )
                    )
                    .frame(width: 70, height: 70)
                    .shadow(color: Color.adaptivePrimaryBlue.opacity(0.4), radius: 15, x: 0, y: 6)

                Image(systemName: "star.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
                    .accessibilityHidden(true)
            }

            VStack(spacing: DesignSystem.Spacing.xs) {
                // Title
                Text("Unlock Everything")
                    .font(.system(size: 26, weight: .black))
                    .foregroundColor(Color.adaptiveTextPrimary)
                    .multilineTextAlignment(.center)

                // Subtitle
                Text("Pass your CA permit test on the first try")
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(Color.adaptiveTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Unlock Everything. Pass your CA permit test on the first try")
    }

    private var headerIcon: String {
        switch triggerPoint {
        case .diagnosticResults:
            return "chart.line.uptrend.xyaxis"
        case .questionsLimit:
            return "lock.fill"
        case .lockedFeature:
            return "star.fill"
        }
    }

    private var headerTitle: String {
        switch triggerPoint {
        case .diagnosticResults:
            return "Ready to Close the Gap?"
        case .questionsLimit:
            return "You've Used Your 5 Free Practice Tests!"
        case .lockedFeature:
            return "Unlock Premium Features"
        }
    }

    private var headerSubtitle: String {
        switch triggerPoint {
        case .diagnosticResults:
            return "Students who unlock full access pass 3x more often"
        case .questionsLimit:
            return "Upgrade for unlimited practice tests and premium features"
        case .lockedFeature:
            return "Get unlimited practice to maximize your chances of passing"
        }
    }

    // MARK: - Performance Section (Diagnostic Only)
    @ViewBuilder
    private var performanceSection: some View {
        if let score = diagnosticScore, let total = diagnosticTotal, let gap = gapPoints {
            VStack(spacing: DesignSystem.Spacing.lg) {
                Text("Your Performance Reality Check")
                    .font(DesignSystem.Typography.h3)
                    .foregroundColor(Color.adaptiveTextPrimary)

                // Score comparison
                VStack(spacing: DesignSystem.Spacing.md) {
                    HStack {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                            Text("Your Score")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(Color.adaptiveTextSecondary)

                            Text("\(score)/\(total) (\(Int(Double(score)/Double(total) * 100))%)")
                                .font(DesignSystem.Typography.h2)
                                .foregroundColor(Color.adaptiveError)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xxs) {
                            Text("DMV Pass Score")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(Color.adaptiveTextSecondary)

                            Text("38/46 (83%)")
                                .font(DesignSystem.Typography.h2)
                                .foregroundColor(Color.adaptiveSuccess)
                        }
                    }

                    // Visual bars
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        // Your level
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Your Current Level")
                                .font(DesignSystem.Typography.captionSmall)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.adaptiveTextSecondary)

                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.adaptiveSecondaryBackground)
                                        .frame(height: 12)

                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.adaptiveError)
                                        .frame(width: geometry.size.width * Double(score) / Double(total), height: 12)
                                }
                            }
                            .frame(height: 12)
                        }

                        // Required level
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Required to Pass")
                                .font(DesignSystem.Typography.captionSmall)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.adaptiveTextSecondary)

                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.adaptiveSecondaryBackground)
                                        .frame(height: 12)

                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.adaptiveSuccess)
                                        .frame(width: geometry.size.width * 0.83, height: 12)
                                }
                            }
                            .frame(height: 12)
                        }
                    }

                    // Gap indicator
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Color.adaptiveAccentYellow)

                        Text("Gap: \(gap) points")
                            .font(DesignSystem.Typography.bodySmall)
                            .fontWeight(.bold)
                            .foregroundColor(Color.adaptiveTextPrimary)

                        Spacer()
                    }
                    .padding(DesignSystem.Spacing.sm)
                    .background(Color.adaptiveAccentYellow.opacity(0.1))
                    .cornerRadius(DesignSystem.CornerRadius.sm)
                }
            }
            .cardStyle(padding: DesignSystem.Spacing.lg)
            .shadow(color: DesignSystem.Shadow.lg.color, radius: DesignSystem.Shadow.lg.radius, y: DesignSystem.Shadow.lg.y)
        }
    }

    // MARK: - Features Section
    private var featuresSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            FeatureRow(
                icon: "brain.head.profile",
                title: "Scout AI Tutor",
                subtitle: "Get instant explanations for any question, 24/7"
            )

            FeatureRow(
                icon: "infinity",
                title: "Unlimited Practice",
                subtitle: "500+ CA DMV test questions, unlimited practice tests"
            )

            FeatureRow(
                icon: "book.fill",
                title: "Complete Learn Mode",
                subtitle: "45 bite-sized lessons covering every CA driving rule"
            )

            FeatureRow(
                icon: "target",
                title: "Adaptive Practice",
                subtitle: "AI targets your weak areas for faster improvement"
            )

            FeatureRow(
                icon: "chart.xyaxis.line",
                title: "Detailed Analytics",
                subtitle: "Track your progress and readiness by category"
            )
        }
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Primary CTA
            Button(action: {
                handlePurchase()
            }) {
                VStack(spacing: DesignSystem.Spacing.xs) {
                    if isPurchasing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .accessibilityLabel("Purchasing")
                    } else {
                        Text("UNLOCK EVERYTHING - \(storeKit.lifetimePrice())")
                            .font(DesignSystem.Typography.h4)
                            .foregroundColor(.white)

                        Text("One payment • Lifetime access • All features")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.md + 2)
                .background(Color.primaryGradient)
                .cornerRadius(DesignSystem.CornerRadius.md)
                .shadow(color: Color.adaptivePrimaryBlue.opacity(0.4), radius: DesignSystem.Shadow.lg.radius, x: 0, y: DesignSystem.Shadow.lg.y)
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(isPurchasing)
            .accessibilityLabel("Unlock everything for \(storeKit.lifetimePrice())")
            .accessibilityHint("One payment, lifetime access to all features")

            // Continue free option (de-emphasized)
            Button(action: {
                handleContinueFree()
            }) {
                Text(continueButtonText)
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(Color.adaptiveTextSecondary)
                    .underline()
            }

            // Restore purchases
            Button(action: {
                handleRestorePurchases()
            }) {
                Text("Restore Purchase")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(Color.adaptiveTextSecondary)
            }
            .padding(.top, DesignSystem.Spacing.xs)
        }
    }

    private var continueButtonText: String {
        switch triggerPoint {
        case .diagnosticResults:
            return "Continue with Free (5 practice tests/week)"
        case .questionsLimit:
            return "Maybe Later"
        case .lockedFeature:
            return "Maybe Later"
        }
    }

    private var triggerPointName: String {
        switch triggerPoint {
        case .diagnosticResults:
            return "diagnostic_results"
        case .questionsLimit:
            return "questions_limit"
        case .lockedFeature:
            return "locked_feature"
        }
    }

    // MARK: - Actions
    private func handlePurchase() {
        // Track purchase initiated
        EventTracker.shared.trackPurchaseInitiated(trigger: triggerPointName)

        Task {
            do {
                isPurchasing = true

                // Get lifetime product
                guard let product = storeKit.getLifetimeProduct() else {
                    // Products not loaded yet - try loading them
                    await storeKit.loadProducts()
                    guard let product = storeKit.getLifetimeProduct() else {
                        EventTracker.shared.trackPurchaseFailed(
                            error: "Product not available",
                            trigger: triggerPointName
                        )
                        throw StoreKitError.unknown
                    }
                    try await storeKit.purchase(product)
                    isPurchasing = false

                    // Purchase completed is tracked in StoreKitManager

                    dismiss()
                    return
                }

                // Purchase product
                try await storeKit.purchase(product)

                isPurchasing = false

                // Purchase completed is tracked in StoreKitManager

                // Show success screen
                showSuccessScreen = true

            } catch StoreKitError.userCancelled {
                isPurchasing = false
                // Track cancellation
                EventTracker.shared.trackPurchaseCancelled(trigger: triggerPointName)
            } catch {
                isPurchasing = false
                // Track failure
                EventTracker.shared.trackPurchaseFailed(
                    error: error.localizedDescription,
                    trigger: triggerPointName
                )
                errorMessage = error.localizedDescription
                showingPurchaseError = true
            }
        }
    }

    private func handleContinueFree() {
        // Track continued free
        EventTracker.shared.trackEvent(
            name: "continued_free",
            parameters: ["trigger_point": triggerPointName]
        )

        dismiss()
    }

    private func handleRestorePurchases() {
        // Track restore attempt
        EventTracker.shared.trackRestorePurchaseAttempted()

        Task {
            do {
                isPurchasing = true
                try await storeKit.restorePurchases()
                isPurchasing = false

                // Track success
                EventTracker.shared.trackRestorePurchaseSucceeded()

                dismiss()
            } catch StoreKitError.noPurchasesToRestore {
                isPurchasing = false

                // Track failure - no purchases
                EventTracker.shared.trackRestorePurchaseFailed(error: "No previous purchases found")

                errorMessage = "No previous purchases found"
                showingPurchaseError = true
            } catch {
                isPurchasing = false

                // Track failure
                EventTracker.shared.trackRestorePurchaseFailed(error: error.localizedDescription)

                errorMessage = error.localizedDescription
                showingPurchaseError = true
            }
        }
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            // Larger icon with rounded rectangle background
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .fill(Color.adaptivePrimaryBlue.opacity(0.2))
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(Color.adaptivePrimaryBlue)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                Text(title)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.bold)
                    .foregroundColor(Color.adaptiveTextPrimary)

                Text(subtitle)
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(Color.adaptiveTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, DesignSystem.Spacing.xxs)

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(subtitle)")
    }
}

#Preview {
    PaywallView(
        triggerPoint: .diagnosticResults,
        diagnosticScore: 8,
        diagnosticTotal: 15,
        gapPoints: 4
    )
}
