import SwiftUI

// MARK: - Hex Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Adaptive Theme Colors
extension Color {
    static let theme = ThemeColors()
}

struct ThemeColors {
    // Primary colors
    let primaryBlue = Color("PrimaryBlue")
    let primaryBlueDark = Color("PrimaryBlueDark")
    let accentTeal = Color("AccentTeal")
    let accentYellow = Color("AccentYellow")
    let accentRed = Color("AccentRed")
    let accentRedLight = Color("AccentRedLight")
    
    // Success/Error
    let success = Color("SuccessGreen")
    let error = Color("ErrorRed")
    
    // Backgrounds
    let background = Color("Background")
    let cardBackground = Color("CardBackground")
    let secondaryBackground = Color("SecondaryBackground")
    
    // Text
    let textPrimary = Color("TextPrimary")
    let textSecondary = Color("TextSecondary")
    let textOnPrimary = Color.white
}

// Modern dark theme colors matching style guide
extension Color {
    // Primary brand colors - Purple to Cyan gradient theme
    static var adaptivePrimaryBlue: Color {
        Color(light: Color(hex: "7C3AED"), dark: Color(hex: "7C3AED")) // Violet-600
    }

    static var adaptivePrimaryBlueDark: Color {
        Color(light: Color(hex: "6D28D9"), dark: Color(hex: "6D28D9")) // Violet-700
    }

    static var adaptiveAccentTeal: Color {
        Color(light: Color(hex: "06B6D4"), dark: Color(hex: "06B6D4")) // Cyan-600
    }

    static var adaptiveAccentYellow: Color {
        Color(light: Color(hex: "F59E0B"), dark: Color(hex: "F59E0B")) // Amber-500
    }

    static var adaptiveAccentRed: Color {
        Color(light: Color(hex: "EF4444"), dark: Color(hex: "EF4444")) // Red-500
    }

    static var adaptiveAccentPink: Color {
        Color(light: Color(hex: "FF6B9D"), dark: Color(hex: "FF6B9D")) // Pink accent
    }

    static var adaptiveSuccess: Color {
        Color(light: Color(hex: "10B981"), dark: Color(hex: "10B981")) // Emerald-500
    }

    static var adaptiveError: Color {
        Color(light: Color(hex: "EF4444"), dark: Color(hex: "EF4444")) // Red-500
    }

    // Dark theme backgrounds
    static var adaptiveBackground: Color {
        Color(light: Color(hex: "F9FAFB"), dark: Color(hex: "0F0F1A")) // Very dark base
    }

    static var adaptiveCardBackground: Color {
        Color(light: Color.white, dark: Color(hex: "1A1A2E")) // Dark card
    }

    static var adaptiveSecondaryBackground: Color {
        Color(light: Color(hex: "F3F4F6"), dark: Color(hex: "2D2D44")) // Secondary elements
    }

    static var adaptiveInnerBackground: Color {
        Color(light: Color(hex: "F9FAFB"), dark: Color(hex: "0F0F1A")) // Inner card elements
    }

    // Text colors - WCAG AA Compliant
    static var adaptiveTextPrimary: Color {
        Color(light: Color(hex: "111827"), dark: Color(hex: "F9FAFB")) // Gray-900 in light, almost white in dark
    }

    static var adaptiveTextSecondary: Color {
        Color(light: Color(hex: "4B5563"), dark: Color(hex: "D1D5DB")) // Gray-600 in light, Gray-300 in dark - Better contrast
    }

    static var adaptiveTextTertiary: Color {
        Color(light: Color(hex: "6B7280"), dark: Color(hex: "9CA3AF")) // Gray-500 in light, Gray-400 in dark
    }

    // Gradient helper
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "7C3AED"), Color(hex: "06B6D4")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var primaryGradientHorizontal: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "7C3AED"), Color(hex: "06B6D4")],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    init(light: Color, dark: Color) {
        self.init(UIColor(light: UIColor(light), dark: UIColor(dark)))
    }
}

extension UIColor {
    convenience init(light: UIColor, dark: UIColor) {
        self.init { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return dark
            default:
                return light
            }
        }
    }
}

// MARK: - WCAG Contrast Checker
extension Color {
    /// Calculate relative luminance for WCAG contrast calculations
    private func relativeLuminance() -> Double {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        #if os(iOS)
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        #endif

        func adjustColor(_ component: CGFloat) -> Double {
            let c = Double(component)
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }

        let rL = adjustColor(r)
        let gL = adjustColor(g)
        let bL = adjustColor(b)

        return 0.2126 * rL + 0.7152 * gL + 0.0722 * bL
    }

    /// Calculate contrast ratio between two colors (WCAG formula)
    func contrastRatio(with otherColor: Color) -> Double {
        let l1 = self.relativeLuminance()
        let l2 = otherColor.relativeLuminance()

        let lighter = max(l1, l2)
        let darker = min(l1, l2)

        return (lighter + 0.05) / (darker + 0.05)
    }

    /// Check if color combination meets WCAG AA standard (4.5:1 for normal text)
    func meetsWCAG_AA(against background: Color) -> Bool {
        return contrastRatio(with: background) >= 4.5
    }

    /// Check if color combination meets WCAG AAA standard (7:1 for normal text)
    func meetsWCAG_AAA(against background: Color) -> Bool {
        return contrastRatio(with: background) >= 7.0
    }
}
