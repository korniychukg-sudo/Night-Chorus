import SwiftUI

enum Plates {
    private static var cache: [String: UIImage] = [:]

    static func load(_ name: String) -> UIImage? {
        if let hit = cache[name] { return hit }
        guard let path = Bundle.main.path(forResource: name, ofType: "jpg", inDirectory: "Art"),
              let image = UIImage(contentsOfFile: path) else { return nil }
        if cache.count > 40 { cache.removeAll() }
        cache[name] = image
        return image
    }

    static func exists(_ name: String) -> Bool {
        Bundle.main.path(forResource: name, ofType: "jpg", inDirectory: "Art") != nil
    }

    static func scene(_ season: Int, _ phase: Int) -> String { "sc_\(season)_\(phase)" }
    static func habitat(_ index: Int) -> String { "hb_" + Ground.keys[index] }
    static func moon(_ index: Int) -> String { "mn_\(index)" }
    static func primer(_ index: Int) -> String { "pr_\(index)" }
    static func intro(_ index: Int) -> String { "in_\(index)" }
}

struct PlateBox: View {
    let name: String
    var height: CGFloat
    var corner: CGFloat = 4
    var overlayed: AnyView? = nil

    var body: some View {
        Color.clear
            .overlay(
                Group {
                    if let image = Plates.load(name) {
                        Image(uiImage: image).resizable().scaledToFill()
                    } else {
                        Nite.indigoDeep
                    }
                }
            )
            .overlay(overlayed)
            .frame(height: height)
            .clipped()
            .cornerRadius(corner)
            .overlay(
                RoundedRectangle(cornerRadius: corner)
                    .stroke(Nite.ink.opacity(0.20), lineWidth: 0.8)
            )
    }
}

struct PaperCard<Content: View>: View {
    var padding: CGFloat = 15
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Nite.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Nite.ink.opacity(0.14), lineWidth: 0.9)
                    )
                    .shadow(color: Nite.ink.opacity(0.07), radius: 5, x: 0, y: 3)
            )
    }
}

struct RuleLine: View {
    let text: String
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(text.uppercased())
                .font(Nite.title(11.5))
                .tracking(1.5)
                .foregroundColor(Nite.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            Rectangle()
                .fill(Nite.ink.opacity(0.18))
                .frame(height: 0.8)
            if let trailing = trailing {
                Text(trailing)
                    .font(Nite.text(11.5))
                    .foregroundColor(Nite.inkFaint)
                    .fixedSize()
            }
        }
    }
}

struct PressBtn: View {
    let title: String
    var tone: Color = Nite.ink
    var filled: Bool = true
    var enabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: { if enabled { Knock.light(); action() } }) {
            Text(title)
                .font(Nite.title(15))
                .foregroundColor(filled ? Nite.card : tone)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(filled ? tone : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(tone.opacity(filled ? 0 : 0.55), lineWidth: 1.1)
                        )
                )
                .opacity(enabled ? 1 : 0.42)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

struct MeterBar: View {
    var label: String
    var value: Double
    var tone: Color = Nite.brass
    var caption: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(label)
                    .font(Nite.text(12.5))
                    .foregroundColor(Nite.inkSoft)
                Spacer()
                Text("\(Int(min(1, max(0, value)) * 100))")
                    .font(Nite.title(12.5))
                    .foregroundColor(Nite.ink)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Nite.ink.opacity(0.10))
                    Capsule().fill(tone)
                        .frame(width: max(2, geo.size.width * CGFloat(min(1, max(0, value)))))
                }
            }
            .frame(height: 6)
            if let caption = caption {
                Text(caption)
                    .font(Nite.aside(11))
                    .foregroundColor(Nite.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct NoteBanner: View {
    var text: String
    var tone: Color = Nite.brass
    var action: (String, () -> Void)? = nil

    var body: some View {
        HStack(spacing: 10) {
            Rectangle().fill(tone).frame(width: 3)
            Text(text)
                .font(Nite.text(12.5))
                .foregroundColor(Nite.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 4)
            if let action = action {
                Button(action: { Knock.light(); action.1() }) {
                    Text(action.0)
                        .font(Nite.title(11.5))
                        .foregroundColor(tone)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(tone.opacity(0.6), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 6).fill(tone.opacity(0.10)))
    }
}

struct SheetBar: View {
    var title: String
    var subtitle: String? = nil
    var onClose: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(Nite.title(19))
                    .foregroundColor(Nite.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(Nite.aside(12.5))
                        .foregroundColor(Nite.inkFaint)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            Button(action: { Knock.light(); onClose() }) {
                CrossMark(size: 16, color: Nite.inkSoft)
                    .padding(9)
                    .background(Circle().fill(Nite.ink.opacity(0.07)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Nite.gutter)
        .padding(.top, 16)
        .padding(.bottom, 9)
    }
}

struct StatChip: View {
    var value: String
    var label: String
    var tone: Color = Nite.ink

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(Nite.title(17))
                .foregroundColor(tone)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
            Text(label.uppercased())
                .font(Nite.text(9))
                .tracking(0.9)
                .foregroundColor(Nite.inkFaint)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(RoundedRectangle(cornerRadius: 6).fill(Nite.ink.opacity(0.045)))
    }
}

struct KeyValue: View {
    var key: String
    var value: String
    var body: some View {
        HStack(alignment: .top) {
            Text(key)
                .font(Nite.text(12.5))
                .foregroundColor(Nite.inkFaint)
            Spacer(minLength: 12)
            Text(value)
                .font(Nite.text(12.5))
                .foregroundColor(Nite.ink)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct Stamp: View {
    var text: String
    var tone: Color
    var body: some View {
        Text(text.uppercased())
            .font(Nite.title(9.5))
            .tracking(1.2)
            .foregroundColor(tone)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(tone.opacity(0.7), lineWidth: 1))
    }
}

struct Column<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            VStack(spacing: 15) { content() }
                .frame(maxWidth: Nite.wide ? 700 : .infinity)
            Spacer(minLength: 0)
        }
    }
}

struct SegRow: View {
    var titles: [String]
    @Binding var index: Int
    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(titles.enumerated()), id: \.offset) { i, title in
                Button(action: { Knock.light(); withAnimation(.easeOut(duration: 0.2)) { index = i } }) {
                    Text(title)
                        .font(Nite.title(11))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .foregroundColor(index == i ? Nite.card : Nite.inkSoft)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(RoundedRectangle(cornerRadius: 5)
                            .fill(index == i ? Nite.ink : Nite.ink.opacity(0.06)))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct DragSlider: View {
    var value: Double
    var range: ClosedRange<Double>
    var tone: Color = Nite.indigo
    var onChange: (Double) -> Void

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let frac = CGFloat((value - range.lowerBound) / max(0.0001, range.upperBound - range.lowerBound))
            ZStack(alignment: .leading) {
                Capsule().fill(Nite.ink.opacity(0.10)).frame(height: 5)
                Capsule().fill(tone.opacity(0.72))
                    .frame(width: max(5, w * frac), height: 5)
                Circle()
                    .fill(Nite.card)
                    .overlay(Circle().stroke(tone, lineWidth: 2))
                    .frame(width: 20, height: 20)
                    .offset(x: max(0, min(w - 20, w * frac - 10)))
            }
            .frame(height: 26)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        let f = max(0, min(1, Double(g.location.x / max(1, w))))
                        onChange(range.lowerBound + f * (range.upperBound - range.lowerBound))
                    }
            )
        }
        .frame(height: 26)
    }
}
