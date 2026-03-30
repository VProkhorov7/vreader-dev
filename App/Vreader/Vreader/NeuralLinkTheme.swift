import SwiftUI

struct NeuralLinkTheme: AppTheme {
    let id: ThemeID = .neuralLink
    let isPremium: Bool = true

    let surfaceBase: Color = Color(red: 0.020, green: 0.020, blue: 0.020)
    let surfaceLow: Color = Color(red: 0.047, green: 0.047, blue: 0.047)
    let surfaceMid: Color = Color(red: 0.078, green: 0.078, blue: 0.078)
    let surfaceHigh: Color = Color(red: 0.118, green: 0.118, blue: 0.118)

    let accent: Color = Color(red: 0.000, green: 1.000, blue: 0.255)

    let inkPrimary: Color = Color(red: 0.000, green: 0.953, blue: 0.996)
    let inkMuted: Color = Color(red: 0.200, green: 0.600, blue: 0.200)

    var fontDisplay: Font {
        Font.system(size: 28, weight: .medium, design: .default)
    }

    var fontBody: Font {
        Font.system(size: 17, weight: .regular, design: .default)
    }

    let cornerRadius: CGFloat = 4
    let usesMonospace: Bool = false
    let usesRTLHints: Bool = false
}