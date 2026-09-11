import SwiftUI
import DepremOlduDomain

enum AppColor {
    static let primary = Color(hex: 0xEB455F)
    static let secondary = Color(hex: 0x2B3467)
    static let cream = Color(hex: 0xFCFFE7)

    static let small = Color(hex: 0xFDE047)
    static let medium = Color(hex: 0xEF4444)
    static let large = Color(hex: 0x7F1D1D)
    static let veryLarge = Color(hex: 0x27272A)
}

enum AppFont {
    static func regular(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom("OpenSans-Regular", size: size, relativeTo: style)
    }

    static func medium(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom("OpenSans-Medium", size: size, relativeTo: style)
    }

    static func semiBold(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom("OpenSans-SemiBold", size: size, relativeTo: style)
    }

    static func bold(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom("OpenSans-Bold", size: size, relativeTo: style)
    }
}

struct MagnitudePalette {
    let accent: Color
    let badgeForeground: Color

    var badgeBackground: Color { accent }

    func rowGradient(for colorScheme: ColorScheme) -> LinearGradient {
        let leading = accent.opacity(colorScheme == .dark ? 0.22 : 0.085)
        let trailing = colorScheme == .dark
            ? Color(uiColor: .systemBackground)
            : Color.white
        return LinearGradient(
            stops: [
                .init(color: leading, location: 0.2),
                .init(color: trailing, location: 0.9),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

extension MagnitudeClass {
    var palette: MagnitudePalette {
        switch self {
        case .small:
            MagnitudePalette(accent: AppColor.small, badgeForeground: .black)
        case .medium:
            MagnitudePalette(accent: AppColor.medium, badgeForeground: .white)
        case .large:
            MagnitudePalette(accent: AppColor.large, badgeForeground: .white)
        case .veryLarge:
            MagnitudePalette(accent: AppColor.veryLarge, badgeForeground: .white)
        }
    }

    var markerRadius: CGFloat {
        switch self {
        case .small: 5
        case .medium: 7
        case .large: 9
        case .veryLarge: 11
        }
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }

    init(faultHex: String) {
        let value = UInt32(faultHex, radix: 16) ?? 0xF87171
        self.init(hex: value)
    }
}

extension View {
    @ViewBuilder
    func appGlassSurface(cornerRadius: CGFloat) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            self
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
                )
        }
    }
}
