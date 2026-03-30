import SwiftUI

struct EditorialDarkTheme: AppTheme {
    let id: ThemeID = .editorialDark
    let isPremium: Bool = false

    let surfaceBase: Color = Color(red: 0.102, green: 0.102, blue: 0.102)
    let surfaceLow: Color = Color(red: 0.145, green: 0.145, blue: 0.145)
    let surfaceMid: Color = Color(red: 0.180, green: 0.180, blue: 0.180)
    let surfaceHigh: Color = Color(red: 0.227, green: 0.227, blue: 0.227)

    let accent: Color = Color(red: 0.784, green: 0.525, blue: 0.102)

    let inkPrimary: Color = Color(red: 0.910, green: 0.878, blue: 0.816)
    let inkMuted: Color = Color(red: 0.400, green: 0.400, blue: 0.400)

    var fontDisplay: Font {
        Font.custom("NewYork", size: 28, relativeTo: .title)
    }

    var fontBody: Font {
        Font.custom("Georgia", size: 17, relativeTo: .body)
    }

    let cornerRadius: CGFloat = 8
    let usesMonospace: Bool = false
    let usesRTLHints: Bool = false
}