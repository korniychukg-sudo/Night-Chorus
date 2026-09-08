import SwiftUI

enum Nite {
    static let paper = Color(red: 0.910, green: 0.902, blue: 0.878)
    static let paperDeep = Color(red: 0.847, green: 0.847, blue: 0.831)
    static let card = Color(red: 0.965, green: 0.961, blue: 0.945)
    static let ink = Color(red: 0.125, green: 0.129, blue: 0.145)
    static let inkSoft = Color(red: 0.310, green: 0.325, blue: 0.361)
    static let inkFaint = Color(red: 0.514, green: 0.529, blue: 0.561)
    static let indigo = Color(red: 0.180, green: 0.216, blue: 0.341)
    static let indigoDeep = Color(red: 0.098, green: 0.118, blue: 0.196)
    static let dusk = Color(red: 0.302, green: 0.322, blue: 0.451)
    static let moss = Color(red: 0.310, green: 0.400, blue: 0.310)
    static let sedge = Color(red: 0.510, green: 0.463, blue: 0.290)
    static let ember = Color(red: 0.694, green: 0.463, blue: 0.278)
    static let brass = Color(red: 0.667, green: 0.541, blue: 0.290)
    static let moon = Color(red: 0.898, green: 0.906, blue: 0.855)
    static let good = Color(red: 0.290, green: 0.451, blue: 0.361)
    static let alarm = Color(red: 0.663, green: 0.302, blue: 0.243)
    static let cool = Color(red: 0.322, green: 0.451, blue: 0.549)

    static func title(_ size: CGFloat) -> Font { .custom("Georgia-Bold", size: size) }
    static func text(_ size: CGFloat) -> Font { .custom("Georgia", size: size) }
    static func aside(_ size: CGFloat) -> Font { .custom("Georgia-Italic", size: size) }

    static var wide: Bool { UIScreen.main.bounds.width >= 700 }
    static var narrow: Bool { UIScreen.main.bounds.width <= 340 }
    static var gutter: CGFloat { wide ? 32 : (narrow ? 13 : 17) }

    static let hues: [Color] = [
        Color(red: 0.353, green: 0.475, blue: 0.373),
        Color(red: 0.549, green: 0.510, blue: 0.318),
        Color(red: 0.427, green: 0.494, blue: 0.290),
        Color(red: 0.612, green: 0.463, blue: 0.267),
        Color(red: 0.400, green: 0.361, blue: 0.290),
        Color(red: 0.518, green: 0.400, blue: 0.318),
        Color(red: 0.322, green: 0.435, blue: 0.510),
        Color(red: 0.588, green: 0.376, blue: 0.290),
        Color(red: 0.478, green: 0.494, blue: 0.529)
    ]

    static func groupHue(_ index: Int) -> Color { hues[index % hues.count] }
}

struct RiseIn: ViewModifier {
    let index: Int
    @State private var shown = false
    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 14)
            .onAppear {
                withAnimation(.easeOut(duration: 0.38).delay(Double(index) * 0.05)) { shown = true }
            }
    }
}

extension View {
    func rising(_ index: Int) -> some View { modifier(RiseIn(index: index)) }
}

enum Knock {
    static func light() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func firm() { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    static func hard() { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
    static func crisp() { UIImpactFeedbackGenerator(style: .rigid).impactOccurred() }
}
