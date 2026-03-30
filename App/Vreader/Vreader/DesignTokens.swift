import SwiftUI

enum DesignTokens {

    // MARK: - Colors

    enum Colors {

        static let accent         = Color(hex: "#C8861A")
        static let accentMuted    = Color(hex: "#C8861A").opacity(0.15)

        enum Surface {
            static let base       = Color(hex: "#FEF9EF")
            static let low        = Color(hex: "#F8F3E9")
            static let mid        = Color(hex: "#F2EDE3")
            static let high       = Color(hex: "#E7E2D8")
        }

        enum Theme {
            enum CuratorLight {
                static let background   = Color(hex: "#F5F0E8")
                static let surface      = Color(hex: "#EDE8DE")
                static let text         = Color(hex: "#1A1614")
                static let textSecond   = Color(hex: "#9A8E80")
                static let separator    = Color(hex: "#D8D0C4")
            }
            enum EditorialDark {
                static let background   = Color(hex: "#1A1A1A")
                static let surface      = Color(hex: "#252525")
                static let text         = Color(hex: "#E8E0D0")
                static let textSecond   = Color(hex: "#666666")
                static let separator    = Color(hex: "#333333")
            }
            enum SepiaClassic {
                static let background   = Color(hex: "#F4ECD8")
                static let surface      = Color(hex: "#EDE3CC")
                static let text         = Color(hex: "#3B2A1A")
                static let textSecond   = Color(hex: "#8A7A64")
                static let separator    = Color(hex: "#DDD0B8")
            }
            enum Typewriter {
                static let background   = Color(hex: "#F4F0E4")
                static let surface      = Color(hex: "#EBE7D8")
                static let text         = Color(hex: "#8B2500")
                static let textSecond   = Color(hex: "#8B6A50")
                static let separator    = Color(hex: "#DDD8C8")
            }
            enum ForestNight {
                static let background   = Color(hex: "#0D1F0F")
                static let surface      = Color(hex: "#142B16")
                static let text         = Color(hex: "#C8D8C0")
                static let textSecond   = Color(hex: "#4A7A50")
                static let separator    = Color(hex: "#1A3A1C")
            }
        }

        enum Cover {
            static let palette: [Color] = [
                Color(hex: "#C8861A"),
                Color(hex: "#4A6741"),
                Color(hex: "#5A4A7A"),
                Color(hex: "#2D4A6A"),
                Color(hex: "#7A3A2A"),
                Color(hex: "#3A5A5A"),
                Color(hex: "#6A4A2A"),
                Color(hex: "#2A4A3A"),
            ]
        }
    }

    // MARK: - Typography

    enum Typography {

        enum BookText {
            static let regular    = Font.custom("Georgia", size: 17)
            static let small      = Font.custom("Georgia", size: 15)
            static let large      = Font.custom("Georgia", size: 20)

            static func sized(_ size: CGFloat) -> Font {
                Font.custom("Georgia", size: size)
            }
        }

        enum Typewriter {
            static let regular    = Font.custom("Courier New", size: 17)
            static func sized(_ size: CGFloat) -> Font {
                Font.custom("Courier New", size: size)
            }
        }

        enum UI {
            static let largeTitle = Font.system(.largeTitle, design: .default, weight: .medium)
            static let title      = Font.system(.title2,     design: .default, weight: .medium)
            static let headline   = Font.system(.headline,   design: .default, weight: .medium)
            static let body       = Font.system(.body,       design: .default, weight: .regular)
            static let subhead    = Font.system(.subheadline,design: .default, weight: .regular)
            static let caption    = Font.system(.caption,    design: .default, weight: .regular)
            static let caption2   = Font.system(.caption2,   design: .default, weight: .regular)
            static let micro      = Font.system(size: 9,     weight: .medium)
        }

        enum LineSpacing {
            static let tight:   CGFloat = 1.2
            static let normal:  CGFloat = 1.5
            static let relaxed: CGFloat = 1.7
            static let loose:   CGFloat = 2.0
        }
    }

    // MARK: - Spacing

    enum Spacing {
        static let xxs:  CGFloat = 2
        static let xs:   CGFloat = 4
        static let s:    CGFloat = 8
        static let m:    CGFloat = 12
        static let l:    CGFloat = 16
        static let xl:   CGFloat = 20
        static let xxl:  CGFloat = 24
        static let xxxl: CGFloat = 32
    }

    // MARK: - Radius

    enum Radius {
        static let xs:     CGFloat = 4
        static let s:      CGFloat = 6
        static let m:      CGFloat = 8
        static let card:   CGFloat = 10
        static let l:      CGFloat = 12
        static let screen: CGFloat = 16
        static let pill:   CGFloat = 999
    }

    // MARK: - Shadow

    enum Shadow {
        struct Style {
            let color:  Color
            let radius: CGFloat
            let x:      CGFloat
            let y:      CGFloat
        }
        static let card    = Style(color: .black.opacity(0.12), radius: 8,  x: 0, y: 3)
        static let cover   = Style(color: .black.opacity(0.18), radius: 6,  x: 0, y: 3)
        static let panel   = Style(color: .black.opacity(0.15), radius: 12, x: 4, y: 0)
        static let toolbar = Style(color: .black.opacity(0.08), radius: 4,  x: 0, y: 1)
    }

    // MARK: - Animation

    enum Animation {
        static let fast:     SwiftUI.Animation = .easeInOut(duration: 0.15)
        static let standard: SwiftUI.Animation = .easeInOut(duration: 0.25)
        static let slow:     SwiftUI.Animation = .easeInOut(duration: 0.35)
        static let spring:   SwiftUI.Animation = .spring(response: 0.3, dampingFraction: 0.7)
    }

    // MARK: - Layout

    enum Layout {
        static let coverAspectRatio: CGFloat = 2.0 / 3.0
        static let cardMinWidth:     CGFloat = 100
        static let cardMaxWidth:     CGFloat = 160
        static let coverThumbWidth:  CGFloat = 48
        static let coverThumbHeight: CGFloat = 64
        static let readerHPadding:   CGFloat = 24
        static let readerVPadding:   CGFloat = 16
        static let topBarHeight:     CGFloat = 44
        static let bottomBarHeight:  CGFloat = 60
        static let panelWidth:       CGFloat = 280
        static let edgeGestureZone:  CGFloat = 44
        static let deadZone:         CGFloat = 20
    }

    // MARK: - Badge (format + cloud)

    enum Badge {
        static let formatBackground = Color.black.opacity(0.35)
        static let formatText       = Color.white
        static let cloudDownloaded  = Color.white.opacity(0.9)
        static let cloudOnly        = Color.white.opacity(0.25)
        static let size:    CGFloat = 14
        static let padding: CGFloat = 5
    }
}

// MARK: - Color hex init

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: h).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >>  8) & 0xFF) / 255
        let b = Double( rgb        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - View helpers

extension View {
    func shadowStyle(_ s: DesignTokens.Shadow.Style) -> some View {
        shadow(color: s.color, radius: s.radius, x: s.x, y: s.y)
    }
}
