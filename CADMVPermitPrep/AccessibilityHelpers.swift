import SwiftUI

// MARK: - Accessibility Helpers
extension View {
    /// Adds comprehensive accessibility support for buttons
    func accessibleButton(label: String, hint: String? = nil, traits: AccessibilityTraits = .isButton) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }

    /// Adds accessibility support for interactive elements
    func accessibleElement(label: String, value: String? = nil, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityValue(value ?? "")
            .accessibilityHint(hint ?? "")
    }

    /// Marks decorative elements that should be hidden from VoiceOver
    func decorative() -> some View {
        self.accessibilityHidden(true)
    }

    /// Groups accessibility elements together
    func accessibleGroup(label: String? = nil) -> some View {
        Group {
            if let label = label {
                self
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(label)
            } else {
                self.accessibilityElement(children: .combine)
            }
        }
    }
}

// MARK: - Dynamic Type Support
extension Font {
    /// Returns a scaled font that respects Dynamic Type settings
    static func scaledFont(size: CGFloat, weight: Weight = .regular, design: Design = .default) -> Font {
        return .system(size: size, weight: weight, design: design)
    }

    /// Custom text styles that scale with Dynamic Type
    static var dynamicTitle: Font {
        .system(.title, design: .default)
    }

    static var dynamicHeadline: Font {
        .system(.headline, design: .default)
    }

    static var dynamicBody: Font {
        .system(.body, design: .default)
    }

    static var dynamicSubheadline: Font {
        .system(.subheadline, design: .default)
    }

    static var dynamicCaption: Font {
        .system(.caption, design: .default)
    }
}

// MARK: - Dynamic Type View Modifier
struct DynamicTypeModifier: ViewModifier {
    @Environment(\.sizeCategory) var sizeCategory

    func body(content: Content) -> some View {
        content
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge) // Limit max size for layout
    }
}

extension View {
    /// Enables Dynamic Type with reasonable limits
    func supportsDynamicType() -> some View {
        modifier(DynamicTypeModifier())
    }
}

// MARK: - Minimum Tap Target Size
struct MinimumTapTarget: ViewModifier {
    var minSize: CGFloat = 44 // Apple's recommended minimum

    func body(content: Content) -> some View {
        content
            .frame(minWidth: minSize, minHeight: minSize)
    }
}

extension View {
    /// Ensures minimum tap target size for accessibility
    func minimumTapTarget(size: CGFloat = 44) -> some View {
        modifier(MinimumTapTarget(minSize: size))
    }
}

// MARK: - Accessibility Announcements
struct AccessibilityAnnouncement {
    static func announce(_ message: String, isPolite: Bool = true) {
        let announcement = isPolite ?
            NSAttributedString(string: message, attributes: [.accessibilitySpeechQueueAnnouncement: true]) :
            NSAttributedString(string: message, attributes: [:])

        UIAccessibility.post(notification: .announcement, argument: announcement)
    }

    static func announceLayoutChange(for element: Any? = nil) {
        UIAccessibility.post(notification: .layoutChanged, argument: element)
    }

    static func announceScreenChange(for element: Any? = nil) {
        UIAccessibility.post(notification: .screenChanged, argument: element)
    }
}
