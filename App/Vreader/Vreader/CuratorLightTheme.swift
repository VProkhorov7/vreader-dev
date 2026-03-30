import SwiftUI

struct CuratorLightTheme: AppTheme {
    let id: ThemeID = .curatorLight
    let isPremium: Bool = false

    let surfaceBase: Color = Color(red: 0.961, green: 0.941, blue: 0.910)
    let surfaceLow: Color = Color(red: 0.941, green: 0.918, blue: 0.882)
    let surfaceMid: Color = Color(red: 0.918, green: 0.894, blue: 0.855)
    let surfaceHigh: Color = Color(red: 0.894, green: 0.867, blue: 0.824)

    let accent: Color = Color(red: 0.784, green: 0.525, blue: 0.102)

    let inkPrimary: Color = Color(red: 0.133, green: 0.133, blue: 0.133)
    let inkMuted: Color = Color(red: 0.467, green: 0.467, blue: 0.467)

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