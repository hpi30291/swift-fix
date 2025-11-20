import SwiftUI

// MARK: - Design System
/// Centralized design tokens for consistent UI across the app
/// Based on 8pt grid system

struct DesignSystem {

    // MARK: - Spacing (8pt grid)
    struct Spacing {
        static let xxs: CGFloat = 4      // 0.5x
        static let xs: CGFloat = 8       // 1x
        static let sm: CGFloat = 12      // 1.5x
        static let md: CGFloat = 16      // 2x
        static let lg: CGFloat = 24      // 3x
        static let xl: CGFloat = 32      // 4x
        static let xxl: CGFloat = 40     // 5x
        static let xxxl: CGFloat = 48    // 6x
    }

    // MARK: - Corner Radius
    struct CornerRadius {
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let pill: CGFloat = 999  // For circular buttons
    }

    // MARK: - Typography Scale
    struct Typography {
        // Display
        static let displayLarge = Font.system(size: 36, weight: .black)
        static let displayMedium = Font.system(size: 28, weight: .bold)
        static let displaySmall = Font.system(size: 24, weight: .bold)

        // Headings
        static let h1 = Font.system(size: 22, weight: .bold)
        static let h2 = Font.system(size: 20, weight: .bold)
        static let h3 = Font.system(size: 18, weight: .semibold)
        static let h4 = Font.system(size: 16, weight: .semibold)

        // Body
        static let bodyLarge = Font.system(size: 17, weight: .regular)
        static let body = Font.system(size: 15, weight: .regular)
        static let bodySmall = Font.system(size: 14, weight: .regular)

        // Labels
        static let labelLarge = Font.system(size: 15, weight: .semibold)
        static let label = Font.system(size: 14, weight: .semibold)
        static let labelSmall = Font.system(size: 12, weight: .semibold)

        // Caption
        static let caption = Font.system(size: 12, weight: .regular)
        static let captionSmall = Font.system(size: 11, weight: .regular)
    }

    // MARK: - Shadows
    struct Shadow {
        static let sm = (color: Color.black.opacity(0.08), radius: CGFloat(4), y: CGFloat(2))
        static let md = (color: Color.black.opacity(0.1), radius: CGFloat(8), y: CGFloat(4))
        static let lg = (color: Color.black.opacity(0.12), radius: CGFloat(12), y: CGFloat(6))
        static let xl = (color: Color.black.opacity(0.15), radius: CGFloat(20), y: CGFloat(10))
    }

    // MARK: - Icon Sizes
    struct IconSize {
        static let xs: CGFloat = 16
        static let sm: CGFloat = 20
        static let md: CGFloat = 24
        static let lg: CGFloat = 32
        static let xl: CGFloat = 40
        static let xxl: CGFloat = 48
    }

    // MARK: - Animation Durations
    struct Animation {
        static let fast: Double = 0.2
        static let normal: Double = 0.3
        static let slow: Double = 0.5

        // Standard animations
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.75)
        static let easeOut = SwiftUI.Animation.easeOut(duration: normal)
        static let easeIn = SwiftUI.Animation.easeIn(duration: normal)
        static let smooth = SwiftUI.Animation.interpolatingSpring(stiffness: 300, damping: 30)
    }
}

// MARK: - View Modifiers for Consistency

struct CardStyle: ViewModifier {
    var cornerRadius: CGFloat = DesignSystem.CornerRadius.md
    var padding: CGFloat = DesignSystem.Spacing.md

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.adaptiveCardBackground)
            .cornerRadius(cornerRadius)
            .shadow(
                color: DesignSystem.Shadow.md.color,
                radius: DesignSystem.Shadow.md.radius,
                y: DesignSystem.Shadow.md.y
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.labelLarge)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(
                Group {
                    if isEnabled {
                        Color.primaryGradient
                    } else {
                        Color.adaptiveSecondaryBackground
                    }
                }
            )
            .cornerRadius(DesignSystem.CornerRadius.md)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(DesignSystem.Animation.spring, value: configuration.isPressed)
            .shadow(
                color: isEnabled ? Color.adaptivePrimaryBlue.opacity(0.3) : Color.clear,
                radius: DesignSystem.Shadow.md.radius,
                y: DesignSystem.Shadow.md.y
            )
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.label)
            .foregroundColor(Color.adaptivePrimaryBlue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(Color.adaptivePrimaryBlue.opacity(0.1))
            .cornerRadius(DesignSystem.CornerRadius.sm)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(DesignSystem.Animation.spring, value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle(cornerRadius: CGFloat = DesignSystem.CornerRadius.md, padding: CGFloat = DesignSystem.Spacing.md) -> some View {
        modifier(CardStyle(cornerRadius: cornerRadius, padding: padding))
    }

    func pressAnimation() -> some View {
        self.buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Press Animation Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(DesignSystem.Animation.spring, value: configuration.isPressed)
    }
}

// MARK: - Loading View with Animation
struct LoadingView: View {
    @State private var isAnimating = false
    var message: String = "Loading..."

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(Color.adaptivePrimaryBlue, lineWidth: 3)
                .frame(width: 40, height: 40)
                .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                .animation(
                    Animation.linear(duration: 1.0).repeatForever(autoreverses: false),
                    value: isAnimating
                )

            Text(message)
                .font(DesignSystem.Typography.body)
                .foregroundColor(Color.adaptiveTextSecondary)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Success Animation
struct SuccessCheckmark: View {
    @State private var checkmarkScale: CGFloat = 0
    @State private var circleScale: CGFloat = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.adaptiveSuccess)
                .frame(width: 60, height: 60)
                .scaleEffect(circleScale)

            Image(systemName: "checkmark")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.white)
                .scaleEffect(checkmarkScale)
        }
        .onAppear {
            withAnimation(DesignSystem.Animation.spring.delay(0.1)) {
                circleScale = 1.0
            }
            withAnimation(DesignSystem.Animation.spring.delay(0.3)) {
                checkmarkScale = 1.0
            }
        }
    }
}

// MARK: - Error Animation
struct ErrorCross: View {
    @State private var crossScale: CGFloat = 0
    @State private var circleScale: CGFloat = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.adaptiveError)
                .frame(width: 60, height: 60)
                .scaleEffect(circleScale)

            Image(systemName: "xmark")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.white)
                .scaleEffect(crossScale)
        }
        .onAppear {
            withAnimation(DesignSystem.Animation.spring.delay(0.1)) {
                circleScale = 1.0
            }
            withAnimation(DesignSystem.Animation.spring.delay(0.3)) {
                crossScale = 1.0
            }
        }
    }
}

// MARK: - Shimmer Loading Effect
struct ShimmerView: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.adaptiveSecondaryBackground,
                Color.adaptiveSecondaryBackground.opacity(0.7),
                Color.adaptiveSecondaryBackground
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
        .mask(
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: phase - 0.3),
                            .init(color: .white, location: phase),
                            .init(color: .clear, location: phase + 0.3)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .onAppear {
            withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                phase = 1.3
            }
        }
    }
}

// MARK: - Error State View
struct ErrorStateView: View {
    let title: String
    let message: String
    let icon: String
    let retryAction: (() -> Void)?

    init(title: String = "Something went wrong", message: String, icon: String = "exclamationmark.triangle.fill", retryAction: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.icon = icon
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: DesignSystem.IconSize.xxl))
                .foregroundColor(Color.adaptiveError)
                .accessibilityHidden(true)

            VStack(spacing: DesignSystem.Spacing.xs) {
                Text(title)
                    .font(DesignSystem.Typography.h3)
                    .foregroundColor(Color.adaptiveTextPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(Color.adaptiveTextSecondary)
                    .multilineTextAlignment(.center)
            }

            if let retryAction = retryAction {
                Button(action: {
                    HapticManager.shared.impact(style: .medium)
                    retryAction()
                }) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(DesignSystem.Typography.labelLarge)
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(Color.adaptivePrimaryBlue)
                    .cornerRadius(DesignSystem.CornerRadius.sm)
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("Try again")
                .accessibilityHint("Retry the failed operation")
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
        .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(icon: String, title: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: DesignSystem.IconSize.xxl + 8))
                .foregroundColor(Color.adaptiveTextSecondary)
                .accessibilityHidden(true)

            VStack(spacing: DesignSystem.Spacing.xs) {
                Text(title)
                    .font(DesignSystem.Typography.h3)
                    .foregroundColor(Color.adaptiveTextPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(Color.adaptiveTextSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: {
                    HapticManager.shared.impact(style: .medium)
                    action()
                }) {
                    Text(actionTitle)
                        .font(DesignSystem.Typography.labelLarge)
                        .foregroundColor(.white)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(Color.primaryGradient)
                        .cornerRadius(DesignSystem.CornerRadius.sm)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }
}

// MARK: - Network Error Banner
struct NetworkErrorBanner: View {
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    @State private var isVisible = false

    var body: some View {
        if !networkMonitor.isConnected && isVisible {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: DesignSystem.IconSize.sm))
                    .foregroundColor(.white)
                    .accessibilityHidden(true)

                Text("No internet connection")
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(DesignSystem.Spacing.sm)
            .background(Color.adaptiveError)
            .transition(.move(edge: .top).combined(with: .opacity))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("No internet connection")
            .accessibilityAddTraits(.isStaticText)
        }
    }
}

// MARK: - Haptic Feedback Manager
class HapticManager {
    static let shared = HapticManager()

    private init() {}

    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
