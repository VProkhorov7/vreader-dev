import SwiftUI

enum DesignTokens {

    enum Colors {
        static let surfaceBase: Color = Color(hex: "#1A1A1A")
        static let surfaceLow: Color = Color(hex: "#252525")
        static let surfaceMid: Color = Color(hex: "#2E2E2E")
        static let surfaceHigh: Color = Color(hex: "#3A3A3A")
        static let accent: Color = Color(hex: "#C8861A")
        static let inkPrimary: Color = Color(hex: "#E8E0D0")
        static let inkMuted: Color = Color(hex: "#666666")

        static let surfaceOpacity: Double = 0.85
        static let blurRadius: CGFloat = 20
    }

    enum Typography {
        static let fontDisplay: Font = Font.system(.title2, design: .serif, weight: .medium)
        static let fontBody: Font = Font.system(.body, design: .serif, weight: .regular)
        static let minSize: Font = Font.system(.caption2)
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    enum Radius {
        static let small: CGFloat = 4
        static let medium: CGFloat = 8
        static let large: CGFloat = 16
        static let card: CGFloat = 12

        enum Theme {
            static let neuralLink: CGFloat = 4
            static let typewriter: CGFloat = 2
            static let editorial: CGFloat = 8
            static let curator: CGFloat = 8
        }
    }

    enum Animation {
        static let fast: Double = 0.15
        static let normal: Double = 0.25
        static let slow: Double = 0.4
        static let springDamping: Double = 0.7
        static let springResponse: Double = 0.3

        static let easeInOutFast: SwiftUI.Animation = .easeInOut(duration: DesignTokens.Animation.fast)
        static let easeInOutNormal: SwiftUI.Animation = .easeInOut(duration: DesignTokens.Animation.normal)
        static let easeInOutSlow: SwiftUI.Animation = .easeInOut(duration: DesignTokens.Animation.slow)
        static let springStandard: SwiftUI.Animation = .spring(
            response: DesignTokens.Animation.springResponse,
            dampingFraction: DesignTokens.Animation.springDamping
        )
    }

    enum Reader {
        static let memoryBudgetPerPage: Int = 50 * 1024 * 1024
        static let maxPagesInMemory: Int = 3
        static let defaultFontSize: CGFloat = 17
        static let minFontSize: CGFloat = 12
        static let maxFontSize: CGFloat = 32
    }
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let length = cleaned.count
        let r: Double
        let g: Double
        let b: Double
        let a: Double

        if length == 8 {
            r = Double((value >> 24) & 0xFF) / 255.0
            g = Double((value >> 16) & 0xFF) / 255.0
            b = Double((value >> 8) & 0xFF) / 255.0
            a = Double(value & 0xFF) / 255.0
        } else {
            r = Double((value >> 16) & 0xFF) / 255.0
            g = Double((value >> 8) & 0xFF) / 255.0
            b = Double(value & 0xFF) / 255.0
            a = 1.0
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }
}