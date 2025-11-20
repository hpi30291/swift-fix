import XCTest
import SwiftUI
@testable import CADMVPermitPrep

final class ColorExtensionsTests: XCTestCase {

    // MARK: - Hex Color Initialization Tests

    func testHexColorWith6Characters() {
        let color = Color(hex: "FF5733")
        let uiColor = UIColor(color)

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        XCTAssertEqual(red, 1.0, accuracy: 0.01, "Red should be 255/255")
        XCTAssertEqual(green, 87.0/255.0, accuracy: 0.01, "Green should be 87/255")
        XCTAssertEqual(blue, 51.0/255.0, accuracy: 0.01, "Blue should be 51/255")
        XCTAssertEqual(alpha, 1.0, accuracy: 0.01, "Alpha should be 1.0 (opaque)")
    }

    func testHexColorWith3Characters() {
        let color = Color(hex: "F53")
        let uiColor = UIColor(color)

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        // F53 expands to FF5533
        XCTAssertEqual(red, 1.0, accuracy: 0.01, "Red should be FF")
        XCTAssertEqual(green, 85.0/255.0, accuracy: 0.01, "Green should be 55")
        XCTAssertEqual(blue, 51.0/255.0, accuracy: 0.01, "Blue should be 33")
        XCTAssertEqual(alpha, 1.0, accuracy: 0.01, "Alpha should be 1.0")
    }

    func testHexColorWith8CharactersIncludingAlpha() {
        let color = Color(hex: "80FF5733") // 50% alpha
        let uiColor = UIColor(color)

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        XCTAssertEqual(alpha, 128.0/255.0, accuracy: 0.01, "Alpha should be 128/255 (50%)")
        XCTAssertEqual(red, 1.0, accuracy: 0.01, "Red should be 255/255")
    }

    func testHexColorWithHashPrefix() {
        let color = Color(hex: "#FF5733")
        let uiColor = UIColor(color)

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        XCTAssertEqual(red, 1.0, accuracy: 0.01, "Should handle # prefix")
        XCTAssertEqual(green, 87.0/255.0, accuracy: 0.01)
    }

    func testHexColorWithLowercaseLetters() {
        let color = Color(hex: "ff5733")
        let uiColor = UIColor(color)

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        XCTAssertEqual(red, 1.0, accuracy: 0.01, "Should handle lowercase")
        XCTAssertEqual(green, 87.0/255.0, accuracy: 0.01)
        XCTAssertEqual(blue, 51.0/255.0, accuracy: 0.01)
    }

    func testHexColorWithInvalidLength() {
        let color = Color(hex: "FF57") // Invalid: 4 characters
        let uiColor = UIColor(color)

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        // Should fall back to default (1, 1, 1, 0) -> black
        XCTAssertEqual(red, 1.0/255.0, accuracy: 0.01, "Should use fallback")
        XCTAssertEqual(green, 1.0/255.0, accuracy: 0.01)
        XCTAssertEqual(blue, 1.0/255.0, accuracy: 0.01)
    }

    func testHexColorWithEmptyString() {
        let color = Color(hex: "")
        let uiColor = UIColor(color)

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        // Should handle empty string gracefully
        XCTAssertNotNil(color, "Should create a color even with empty string")
    }

    func testHexColorPureWhite() {
        let color = Color(hex: "FFFFFF")
        let uiColor = UIColor(color)

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        XCTAssertEqual(red, 1.0, accuracy: 0.01, "Red should be 1.0")
        XCTAssertEqual(green, 1.0, accuracy: 0.01, "Green should be 1.0")
        XCTAssertEqual(blue, 1.0, accuracy: 0.01, "Blue should be 1.0")
        XCTAssertEqual(alpha, 1.0, accuracy: 0.01, "Alpha should be 1.0")
    }

    func testHexColorPureBlack() {
        let color = Color(hex: "000000")
        let uiColor = UIColor(color)

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        XCTAssertEqual(red, 0.0, accuracy: 0.01, "Red should be 0.0")
        XCTAssertEqual(green, 0.0, accuracy: 0.01, "Green should be 0.0")
        XCTAssertEqual(blue, 0.0, accuracy: 0.01, "Blue should be 0.0")
        XCTAssertEqual(alpha, 1.0, accuracy: 0.01, "Alpha should be 1.0")
    }

    func testHexColorWithSpecialCharacters() {
        let color = Color(hex: "$#@FF5733!@#")
        let uiColor = UIColor(color)

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        // Should strip special characters and process FF5733
        XCTAssertEqual(red, 1.0, accuracy: 0.01, "Should strip special characters")
    }

    // MARK: - Adaptive Color Tests

    func testAdaptivePrimaryBlueExists() {
        let color = Color.adaptivePrimaryBlue
        XCTAssertNotNil(color, "Adaptive primary blue should exist")
    }

    func testAdaptiveAccentTealExists() {
        let color = Color.adaptiveAccentTeal
        XCTAssertNotNil(color, "Adaptive accent teal should exist")
    }

    func testAdaptiveSuccessExists() {
        let color = Color.adaptiveSuccess
        XCTAssertNotNil(color, "Adaptive success color should exist")
    }

    func testAdaptiveErrorExists() {
        let color = Color.adaptiveError
        XCTAssertNotNil(color, "Adaptive error color should exist")
    }

    func testAdaptiveBackgroundExists() {
        let color = Color.adaptiveBackground
        XCTAssertNotNil(color, "Adaptive background should exist")
    }

    func testAdaptiveTextPrimaryExists() {
        let color = Color.adaptiveTextPrimary
        XCTAssertNotNil(color, "Adaptive text primary should exist")
    }

    // MARK: - Light/Dark Mode Tests

    func testColorLightDarkInitialization() {
        let lightColor = Color.red
        let darkColor = Color.blue
        let adaptiveColor = Color(light: lightColor, dark: darkColor)

        XCTAssertNotNil(adaptiveColor, "Should create adaptive color")
    }

    func testUIColorLightDarkInitialization() {
        let lightColor = UIColor.red
        let darkColor = UIColor.blue
        let adaptiveColor = UIColor(light: lightColor, dark: darkColor)

        XCTAssertNotNil(adaptiveColor, "Should create adaptive UIColor")
    }

    func testUIColorReturnsLightInLightMode() {
        let lightColor = UIColor.red
        let darkColor = UIColor.blue
        let adaptiveColor = UIColor(light: lightColor, dark: darkColor)

        // Create light trait collection
        let lightTraits = UITraitCollection(userInterfaceStyle: .light)
        let resolvedColor = adaptiveColor.resolvedColor(with: lightTraits)

        var red: CGFloat = 0
        var blue: CGFloat = 0
        resolvedColor.getRed(&red, green: nil, blue: &blue, alpha: nil)

        XCTAssertGreaterThan(red, 0.9, "Should be close to red in light mode")
        XCTAssertLessThan(blue, 0.1, "Should not be blue in light mode")
    }

    func testUIColorReturnsDarkInDarkMode() {
        let lightColor = UIColor.red
        let darkColor = UIColor.blue
        let adaptiveColor = UIColor(light: lightColor, dark: darkColor)

        // Create dark trait collection
        let darkTraits = UITraitCollection(userInterfaceStyle: .dark)
        let resolvedColor = adaptiveColor.resolvedColor(with: darkTraits)

        var red: CGFloat = 0
        var blue: CGFloat = 0
        resolvedColor.getRed(&red, green: nil, blue: &blue, alpha: nil)

        XCTAssertLessThan(red, 0.1, "Should not be red in dark mode")
        XCTAssertGreaterThan(blue, 0.9, "Should be close to blue in dark mode")
    }

    // MARK: - Theme Colors Tests

    func testThemeColorsExist() {
        let theme = ThemeColors()

        XCTAssertNotNil(theme.primaryBlue, "Primary blue should exist")
        XCTAssertNotNil(theme.primaryBlueDark, "Primary blue dark should exist")
        XCTAssertNotNil(theme.accentTeal, "Accent teal should exist")
        XCTAssertNotNil(theme.accentYellow, "Accent yellow should exist")
        XCTAssertNotNil(theme.accentRed, "Accent red should exist")
        XCTAssertNotNil(theme.success, "Success should exist")
        XCTAssertNotNil(theme.error, "Error should exist")
        XCTAssertNotNil(theme.background, "Background should exist")
        XCTAssertNotNil(theme.cardBackground, "Card background should exist")
        XCTAssertNotNil(theme.textPrimary, "Text primary should exist")
        XCTAssertNotNil(theme.textSecondary, "Text secondary should exist")
        XCTAssertNotNil(theme.textOnPrimary, "Text on primary should exist")
    }

    func testThemeAccessibleViaColorExtension() {
        let theme = Color.theme
        XCTAssertNotNil(theme, "Should access theme via Color.theme")
        XCTAssertNotNil(theme.primaryBlue)
    }

    // MARK: - Real-world Hex Values Tests

    func testAppPrimaryBlueHexValue() {
        let color = Color(hex: "3A8FC8")
        XCTAssertNotNil(color, "Should create color from app's primary blue hex")
    }

    func testAppAccentTealHexValue() {
        let color = Color(hex: "12C0C5")
        XCTAssertNotNil(color, "Should create color from app's accent teal hex")
    }

    func testAppAccentYellowHexValue() {
        let color = Color(hex: "FCB60C")
        XCTAssertNotNil(color, "Should create color from app's accent yellow hex")
    }

    func testAppAccentRedHexValue() {
        let color = Color(hex: "FE8B7B")
        XCTAssertNotNil(color, "Should create color from app's accent red hex")
    }

    // MARK: - Edge Cases

    func testHexColorWithWhitespace() {
        let color = Color(hex: "  FF5733  ")
        let uiColor = UIColor(color)

        var red: CGFloat = 0
        uiColor.getRed(&red, green: nil, blue: nil, alpha: nil)

        XCTAssertEqual(red, 1.0, accuracy: 0.01, "Should trim whitespace")
    }

    func testHexColorWithMixedCaseAndPrefix() {
        let color = Color(hex: "#Ff5733")
        let uiColor = UIColor(color)

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: nil)

        XCTAssertEqual(red, 1.0, accuracy: 0.01, "Should handle mixed case")
        XCTAssertEqual(green, 87.0/255.0, accuracy: 0.01)
        XCTAssertEqual(blue, 51.0/255.0, accuracy: 0.01)
    }

    func testHexColorConsistency() {
        let color1 = Color(hex: "FF5733")
        let color2 = Color(hex: "FF5733")

        let uiColor1 = UIColor(color1)
        let uiColor2 = UIColor(color2)

        var red1: CGFloat = 0, red2: CGFloat = 0
        uiColor1.getRed(&red1, green: nil, blue: nil, alpha: nil)
        uiColor2.getRed(&red2, green: nil, blue: nil, alpha: nil)

        XCTAssertEqual(red1, red2, accuracy: 0.001, "Same hex should produce same color")
    }

    // MARK: - Performance Tests

    func testHexColorInitializationPerformance() {
        measure {
            for _ in 0..<100 {
                _ = Color(hex: "FF5733")
            }
        }
    }

    func testAdaptiveColorCreationPerformance() {
        measure {
            for _ in 0..<100 {
                _ = Color(light: Color.red, dark: Color.blue)
            }
        }
    }
}
