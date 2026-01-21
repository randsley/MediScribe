//
//  DesignSystem.swift
//  MediScribe
//
//  Field-optimized design system tokens
//  Based on Design/FigmaDesignSystem.md specifications
//

import SwiftUI

/// MediScribe field-optimized design system
/// All values optimized for outdoor use, glove-friendly interaction, and high visibility
enum DesignSystem {

    // MARK: - Colors

    enum Colors {

        /// Semantic field colors for clinical context
        enum Field {
            /// Critical/Emergency - Red 600 (#DC2626)
            static let emergency = Color(hex: "#DC2626")

            /// Warning/Caution - Amber 500 (#F59E0B)
            static let warning = Color(hex: "#F59E0B")

            /// Safe/Success/Normal - Green 500 (#10B981)
            static let safe = Color(hex: "#10B981")

            /// Information/Details - Blue 500 (#3B82F6)
            static let info = Color(hex: "#3B82F6")

            /// Locked/Signed - Violet 500 (#8B5CF6)
            static let locked = Color(hex: "#8B5CF6")
        }

        /// Triage colors (START system)
        enum Triage {
            static let red = Color(hex: "#DC2626")      // Immediate
            static let yellow = Color(hex: "#F59E0B")   // Delayed
            static let green = Color(hex: "#10B981")    // Minor
            static let black = Color(hex: "#1F2937")    // Deceased/Expectant
        }

        /// Background colors
        enum Background {
            static let primary = Color(hex: "#FFFFFF")      // White
            static let secondary = Color(hex: "#F9FAFB")    // Gray 50
            static let tertiary = Color(hex: "#F3F4F6")     // Gray 100
        }

        /// Text colors
        enum Text {
            static let primary = Color(hex: "#111827")      // Gray 900
            static let secondary = Color(hex: "#6B7280")    // Gray 500
            static let disabled = Color(hex: "#D1D5DB")     // Gray 300
        }

        /// Border colors
        enum Border {
            static let `default` = Color(hex: "#E5E7EB")    // Gray 200
            static let focus = Color(hex: "#3B82F6")        // Blue 500
        }

        /// Vital-specific colors (for vital type buttons)
        enum Vital {
            static let bloodPressure = Color(hex: "#3B82F6")    // Blue
            static let heartRate = Color(hex: "#EF4444")        // Red
            static let respiratoryRate = Color(hex: "#06B6D4")  // Cyan
            static let spo2 = Color(hex: "#8B5CF6")             // Purple
            static let temperature = Color(hex: "#F59E0B")      // Amber
            static let gcs = Color(hex: "#10B981")              // Green
        }
    }

    // MARK: - Typography

    enum Typography {

        /// Field-optimized text styles (larger than standard iOS)
        enum Field {

            /// 34pt, Bold - Screen titles, major section headers
            static let titleLarge = Font.system(size: 34, weight: .bold, design: .default)

            /// 28pt, Bold - Card titles, sub-sections
            static let titleMedium = Font.system(size: 28, weight: .bold, design: .default)

            /// 20pt, Semibold - Button labels, primary content
            static let bodyLarge = Font.system(size: 20, weight: .semibold, design: .default)

            /// 18pt, Regular - Body text, descriptions
            static let bodyRegular = Font.system(size: 18, weight: .regular, design: .default)

            /// 16pt, Medium - Secondary information
            static let bodySmall = Font.system(size: 16, weight: .medium, design: .default)

            /// 14pt, Medium - Labels, hints, timestamps
            static let caption = Font.system(size: 14, weight: .medium, design: .default)
        }

        /// Vitals-specific typography
        enum Vitals {
            /// 48pt, Bold, Rounded - Large vital sign displays
            static let display = Font.system(size: 48, weight: .bold, design: .rounded)

            /// 64pt, Bold, Rounded - Extra large single value display
            static let displayLarge = Font.system(size: 64, weight: .bold, design: .rounded)

            /// 36pt, Bold, Rounded - Number pad digits
            static let numberPad = Font.system(size: 36, weight: .bold, design: .rounded)

            /// 16pt, Medium - Units (mmHg, bpm, %, °C)
            static let unit = Font.system(size: 16, weight: .medium, design: .default)
        }
    }

    // MARK: - Spacing

    enum Spacing {

        /// Touch target sizes (glove-friendly)
        enum TouchTarget {
            /// Absolute minimum touch target (60pt)
            static let minimum: CGFloat = 60

            /// Recommended comfortable touch target (80pt)
            static let comfortable: CGFloat = 80

            /// Critical action touch target (100pt)
            static let critical: CGFloat = 100
        }

        /// Component spacing
        enum Component {
            /// Tight grouping (8pt)
            static let compact: CGFloat = 8

            /// Default spacing (16pt)
            static let standard: CGFloat = 16

            /// Section spacing (24pt)
            static let relaxed: CGFloat = 24

            /// Major section spacing (32pt)
            static let loose: CGFloat = 32
        }

        /// Screen padding
        enum Screen {
            /// Horizontal screen margins (20pt)
            static let horizontal: CGFloat = 20

            /// Vertical screen padding (24pt)
            static let vertical: CGFloat = 24
        }

        /// Grid spacing
        enum Grid {
            /// Number of columns on iPhone (6)
            static let columnsIPhone: Int = 6

            /// Number of columns on iPad (12)
            static let columnsIPad: Int = 12

            /// Gutter width (16pt)
            static let gutter: CGFloat = 16
        }
    }

    // MARK: - Corner Radius

    enum Radius {
        /// Small radius - Input fields, small cards (8pt)
        static let small: CGFloat = 8

        /// Medium radius - Buttons, cards (12pt)
        static let medium: CGFloat = 12

        /// Large radius - Modals, sheets (16pt)
        static let large: CGFloat = 16

        /// Extra large radius - Hero cards (24pt)
        static let xLarge: CGFloat = 24
    }

    // MARK: - Shadows

    enum Shadow {
        /// Light elevation shadow
        static let light: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (
            color: Color.black.opacity(0.08),
            radius: 8,
            x: 0,
            y: 2
        )

        /// Medium elevation shadow
        static let medium: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (
            color: Color.black.opacity(0.12),
            radius: 16,
            x: 0,
            y: 4
        )
    }

    // MARK: - Animation Durations

    enum Animation {
        /// Button press (100ms)
        static let buttonPress: Double = 0.1

        /// Button release (150ms)
        static let buttonRelease: Double = 0.15

        /// Screen transition (300ms)
        static let transition: Double = 0.3

        /// Range indicator movement (300ms)
        static let rangeIndicator: Double = 0.3

        /// Number entry (150ms)
        static let numberEntry: Double = 0.15
    }
}

// MARK: - Color Extension for Hex

extension Color {
    /// Initialize Color from hex string
    /// - Parameter hex: Hex color string (e.g., "#3B82F6")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
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

// MARK: - Convenience Extensions

extension Color {
    /// Field semantic colors (quick access)
    static let fieldEmergency = DesignSystem.Colors.Field.emergency
    static let fieldWarning = DesignSystem.Colors.Field.warning
    static let fieldSafe = DesignSystem.Colors.Field.safe
    static let fieldInfo = DesignSystem.Colors.Field.info
    static let fieldLocked = DesignSystem.Colors.Field.locked
}

extension Font {
    /// Field typography (quick access)
    static let fieldTitleLarge = DesignSystem.Typography.Field.titleLarge
    static let fieldTitleMedium = DesignSystem.Typography.Field.titleMedium
    static let fieldBodyLarge = DesignSystem.Typography.Field.bodyLarge
    static let fieldBodyRegular = DesignSystem.Typography.Field.bodyRegular
    static let fieldCaption = DesignSystem.Typography.Field.caption
}
