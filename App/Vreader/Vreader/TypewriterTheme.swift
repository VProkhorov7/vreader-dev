import SwiftUI

struct TypewriterTheme: AppTheme {
    let id: ThemeID = .typewriter
    let isPremium: Bool = true

    let surfaceBase: Color = Color(red: 0.957, green: 0.941, blue: 0.894)
    let surfaceLow: Color = Color(red: 0.933, green: 0.914, blue: 0.863)
    let surfaceMid: Color = Color(red: 0.906, green: 0.886, blue: 0.831)
    let surfaceHigh: Color = Color(red: 0.878, green: 0.855, blue: 0.796)

    let accent: Color = Color(red: 0.545, green: 0.145, blue: 0.000)

    let inkPrimary: Color = Color(red: 0.133, green: 0.133, blue: 0.133)
    let inkMuted: Color = Color(red: 0.467, green: 0.467, blue: 0.467)

    var fontDisplay: Font {
        Font.custom("AmericanTypewriter", size: 28, relativeTo: .title)
    }

    var fontBody: Font {
        Font.custom("AmericanTypewriter", size: 17, relativeTo: .body)
    }

    let cornerRadius: CGFloat = 2
    let usesMonospace: Bool = true
    let usesRTLHints: Bool = false
}