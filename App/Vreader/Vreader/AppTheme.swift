import SwiftUI

protocol AppTheme {
    var id: ThemeID { get }
    var isPremium: Bool { get }

    var surfaceBase: Color { get }
    var surfaceLow: Color { get }
    var surfaceMid: Color { get }
    var surfaceHigh: Color { get }

    var accent: Color { get }

    var inkPrimary: Color { get }
    var inkMuted: Color { get }

    var fontDisplay: Font { get }
    var fontBody: Font { get }

    var cornerRadius: CGFloat { get }
    var usesMonospace: Bool { get }
    var usesRTLHints: Bool { get }
}

struct AppThemeKey: EnvironmentKey {
    static let defaultValue: any AppTheme = EditorialDarkTheme()
}

extension EnvironmentValues {
    var appTheme: any AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}