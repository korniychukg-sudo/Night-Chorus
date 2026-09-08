import SwiftUI

struct MoonMark: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            var disc = Path()
            let r = min(w, h) * 0.38
            let cx = w * 0.52, cy = h * 0.42
            for i in 0...40 {
                let a = Double(i) / 40 * 2 * Double.pi
                let p = CGPoint(x: cx + cos(a) * r, y: cy + sin(a) * r)
                if i == 0 { disc.move(to: p) } else { disc.addLine(to: p) }
            }
            disc.closeSubpath()
            ctx.stroke(disc, with: .color(color), lineWidth: w * 0.075)
            var bite = Path()
            for i in 0...24 {
                let a = -Double.pi / 2 + Double(i) / 24 * Double.pi
                let q = CGPoint(x: cx + cos(a) * r * 0.30, y: cy + sin(a) * r)
                if i == 0 { bite.move(to: q) } else { bite.addLine(to: q) }
            }
            ctx.stroke(bite, with: .color(color.opacity(0.75)), lineWidth: w * 0.055)
            var ground = Path()
            ground.move(to: CGPoint(x: w * 0.08, y: h * 0.86))
            ground.addQuadCurve(to: CGPoint(x: w * 0.92, y: h * 0.86),
                                control: CGPoint(x: w * 0.5, y: h * 0.78))
            ctx.stroke(ground, with: .color(color), lineWidth: w * 0.07)
        }
        .frame(width: size, height: size)
    }
}

struct DishMark: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            var bowl = Path()
            for i in 0...24 {
                let t = Double(i) / 24 * 2 - 1
                let p = CGPoint(x: w * (0.5 + t * 0.40), y: h * (0.24 + t * t * 0.36))
                if i == 0 { bowl.move(to: p) } else { bowl.addLine(to: p) }
            }
            ctx.stroke(bowl, with: .color(color), style: StrokeStyle(lineWidth: w * 0.085, lineCap: .round))
            var stem = Path()
            stem.move(to: CGPoint(x: w * 0.5, y: h * 0.34))
            stem.addLine(to: CGPoint(x: w * 0.5, y: h * 0.86))
            ctx.stroke(stem, with: .color(color), style: StrokeStyle(lineWidth: w * 0.075, lineCap: .round))
            var wave = Path()
            wave.addArc(center: CGPoint(x: w * 0.5, y: h * 0.34), radius: w * 0.15,
                        startAngle: .degrees(200), endAngle: .degrees(340), clockwise: false)
            ctx.stroke(wave, with: .color(color.opacity(0.7)), lineWidth: w * 0.055)
        }
        .frame(width: size, height: size)
    }
}

struct CabinetMark: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            let box = Path(CGRect(x: w * 0.10, y: h * 0.16, width: w * 0.80, height: h * 0.68))
            ctx.stroke(box, with: .color(color), lineWidth: w * 0.075)
            for r in 1..<3 {
                var line = Path()
                let y = h * (0.16 + 0.68 * Double(r) / 3)
                line.move(to: CGPoint(x: w * 0.10, y: y))
                line.addLine(to: CGPoint(x: w * 0.90, y: y))
                ctx.stroke(line, with: .color(color), lineWidth: w * 0.055)
            }
            for c in 1..<3 {
                var line = Path()
                let x = w * (0.10 + 0.80 * Double(c) / 3)
                line.move(to: CGPoint(x: x, y: h * 0.16))
                line.addLine(to: CGPoint(x: x, y: h * 0.84))
                ctx.stroke(line, with: .color(color), lineWidth: w * 0.055)
            }
            ctx.fill(Path(CGRect(x: w * 0.17, y: h * 0.26, width: w * 0.13, height: h * 0.11)),
                     with: .color(color.opacity(0.8)))
        }
        .frame(width: size, height: size)
    }
}

struct FeatherMark: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            var shaft = Path()
            shaft.move(to: CGPoint(x: w * 0.28, y: h * 0.88))
            shaft.addQuadCurve(to: CGPoint(x: w * 0.72, y: h * 0.12),
                               control: CGPoint(x: w * 0.44, y: h * 0.44))
            ctx.stroke(shaft, with: .color(color), style: StrokeStyle(lineWidth: w * 0.075, lineCap: .round))
            for k in 0..<6 {
                let t = 0.16 + Double(k) * 0.13
                let x = w * (0.28 + (0.72 - 0.28) * t + 0.10 * t * t)
                let y = h * (0.88 - (0.88 - 0.12) * t)
                let len = w * (0.24 - 0.02 * Double(k))
                var barb = Path()
                barb.move(to: CGPoint(x: x, y: y))
                barb.addQuadCurve(to: CGPoint(x: x - len, y: y - len * 0.30),
                                  control: CGPoint(x: x - len * 0.6, y: y + len * 0.10))
                ctx.stroke(barb, with: .color(color.opacity(0.85)), lineWidth: w * 0.05)
                var barb2 = Path()
                barb2.move(to: CGPoint(x: x, y: y))
                barb2.addQuadCurve(to: CGPoint(x: x + len * 0.72, y: y + len * 0.30),
                                   control: CGPoint(x: x + len * 0.42, y: y + len * 0.02))
                ctx.stroke(barb2, with: .color(color.opacity(0.65)), lineWidth: w * 0.045)
            }
        }
        .frame(width: size, height: size)
    }
}

struct GridMark: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            var frame = Path()
            frame.move(to: CGPoint(x: w * 0.14, y: h * 0.14))
            frame.addLine(to: CGPoint(x: w * 0.14, y: h * 0.86))
            frame.addLine(to: CGPoint(x: w * 0.88, y: h * 0.86))
            ctx.stroke(frame, with: .color(color), style: StrokeStyle(lineWidth: w * 0.075, lineCap: .round))
            var rng = Spin(seedOf("gridmark"))
            for k in 0..<7 {
                let x = w * (0.24 + Double(k) * 0.095)
                let y = h * (0.30 + rng.span(0, 0.34))
                let bar = Path(CGRect(x: x, y: y, width: w * 0.055, height: h * 0.10 + rng.span(0, h * 0.14)))
                ctx.fill(bar, with: .color(color.opacity(0.55 + rng.span(0, 0.4))))
            }
        }
        .frame(width: size, height: size)
    }
}

struct CrossMark: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            var p = Path()
            p.move(to: CGPoint(x: w * 0.22, y: h * 0.22))
            p.addLine(to: CGPoint(x: w * 0.78, y: h * 0.78))
            p.move(to: CGPoint(x: w * 0.78, y: h * 0.22))
            p.addLine(to: CGPoint(x: w * 0.22, y: h * 0.78))
            ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: w * 0.11, lineCap: .round))
        }
        .frame(width: size, height: size)
    }
}

struct BackChev: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            var p = Path()
            p.move(to: CGPoint(x: w * 0.64, y: h * 0.18))
            p.addLine(to: CGPoint(x: w * 0.32, y: h * 0.50))
            p.addLine(to: CGPoint(x: w * 0.64, y: h * 0.82))
            ctx.stroke(p, with: .color(color),
                       style: StrokeStyle(lineWidth: w * 0.12, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

struct NextChev: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            var p = Path()
            p.move(to: CGPoint(x: w * 0.38, y: h * 0.18))
            p.addLine(to: CGPoint(x: w * 0.70, y: h * 0.50))
            p.addLine(to: CGPoint(x: w * 0.38, y: h * 0.82))
            ctx.stroke(p, with: .color(color),
                       style: StrokeStyle(lineWidth: w * 0.12, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

struct PlayMark: View {
    var size: CGFloat
    var color: Color
    var playing: Bool
    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            if playing {
                ctx.fill(Path(CGRect(x: w * 0.28, y: h * 0.24, width: w * 0.15, height: h * 0.52)),
                         with: .color(color))
                ctx.fill(Path(CGRect(x: w * 0.57, y: h * 0.24, width: w * 0.15, height: h * 0.52)),
                         with: .color(color))
            } else {
                var p = Path()
                p.move(to: CGPoint(x: w * 0.32, y: h * 0.20))
                p.addLine(to: CGPoint(x: w * 0.78, y: h * 0.50))
                p.addLine(to: CGPoint(x: w * 0.32, y: h * 0.80))
                p.closeSubpath()
                ctx.fill(p, with: .color(color))
            }
        }
        .frame(width: size, height: size)
    }
}

struct TickMark: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            var p = Path()
            p.move(to: CGPoint(x: w * 0.20, y: h * 0.52))
            p.addLine(to: CGPoint(x: w * 0.42, y: h * 0.74))
            p.addLine(to: CGPoint(x: w * 0.80, y: h * 0.26))
            ctx.stroke(p, with: .color(color),
                       style: StrokeStyle(lineWidth: w * 0.13, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

struct LensMark: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            let r = w * 0.26
            ctx.stroke(Path(ellipseIn: CGRect(x: w * 0.16, y: h * 0.16, width: r * 2, height: r * 2)),
                       with: .color(color), lineWidth: w * 0.10)
            var p = Path()
            p.move(to: CGPoint(x: w * 0.62, y: h * 0.62))
            p.addLine(to: CGPoint(x: w * 0.84, y: h * 0.84))
            ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: w * 0.12, lineCap: .round))
        }
        .frame(width: size, height: size)
    }
}

struct Thermometer: View {
    var celsius: Double
    var tint: Color = Nite.ember

    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            let cx = w * 0.44
            let bulbR = w * 0.20
            let tubeW = w * 0.20
            let top = h * 0.08
            let bulbY = h - bulbR - 2
            let tubeTop = top
            let tubeBottom = bulbY - bulbR * 0.2

            let tube = Path(roundedRect: CGRect(x: cx - tubeW / 2, y: tubeTop,
                                                width: tubeW, height: tubeBottom - tubeTop + tubeW),
                            cornerRadius: tubeW / 2)
            ctx.fill(tube, with: .color(Color(red: 0.914, green: 0.925, blue: 0.918)))
            ctx.stroke(tube, with: .color(Nite.ink.opacity(0.42)), lineWidth: 1.0)
            let bulb = Path(ellipseIn: CGRect(x: cx - bulbR, y: bulbY - bulbR,
                                              width: bulbR * 2, height: bulbR * 2))
            ctx.fill(bulb, with: .color(tint))
            ctx.stroke(bulb, with: .color(Nite.ink.opacity(0.42)), lineWidth: 1.0)

            let frac = max(0, min(1, (celsius + 4) / 42))
            let colTop = tubeBottom - (tubeBottom - tubeTop) * frac
            let column = Path(roundedRect: CGRect(x: cx - tubeW * 0.28, y: colTop,
                                                  width: tubeW * 0.56,
                                                  height: tubeBottom - colTop + tubeW * 0.4),
                              cornerRadius: tubeW * 0.28)
            ctx.fill(column, with: .color(tint))

            for k in 0...8 {
                let v = Double(k) * 5 - 4
                let f = max(0, min(1, (v + 4) / 42))
                let y = tubeBottom - (tubeBottom - tubeTop) * f
                var tick = Path()
                tick.move(to: CGPoint(x: cx + tubeW * 0.55, y: y))
                tick.addLine(to: CGPoint(x: cx + tubeW * (k % 2 == 0 ? 1.15 : 0.85), y: y))
                ctx.stroke(tick, with: .color(Nite.ink.opacity(0.55)), lineWidth: 0.9)
                if k % 2 == 0 {
                    ctx.draw(Text(verbatim: "\(Int(v))")
                                .font(Nite.text(8))
                                .foregroundColor(Nite.inkFaint),
                             at: CGPoint(x: cx + tubeW * 1.9, y: y))
                }
            }
            let sheen = Path(roundedRect: CGRect(x: cx - tubeW * 0.42, y: tubeTop + 4,
                                                 width: tubeW * 0.16,
                                                 height: tubeBottom - tubeTop - 6),
                             cornerRadius: tubeW * 0.08)
            ctx.fill(sheen, with: .color(Color.white.opacity(0.60)))
        }
    }
}

struct CabinetWall: View {
    var columns: Int
    var rows: Int
    var filled: [Int: Cylinder]
    var temperature: Double
    var spin: Double
    var onTap: (Int) -> Void

    var body: some View {
        GeometryReader { geo in
            let cw = geo.size.width / CGFloat(columns)
            let ch = geo.size.height / CGFloat(rows)
            ZStack(alignment: .topLeading) {
                Color(red: 0.322, green: 0.239, blue: 0.161)
                Canvas { ctx, size in
                    var rng = Spin(seedOf("cabinet-grain"))
                    for _ in 0..<420 {
                        let x = rng.unit() * Double(size.width)
                        let y = rng.unit() * Double(size.height)
                        let len = rng.span(8, 46)
                        var p = Path()
                        p.move(to: CGPoint(x: x, y: y))
                        p.addLine(to: CGPoint(x: x + len, y: y + rng.span(-1.6, 1.6)))
                        ctx.stroke(p, with: .color(Color.black.opacity(rng.span(0.04, 0.16))),
                                   lineWidth: rng.span(0.5, 1.6))
                    }
                }
                ForEach(0..<(columns * rows), id: \.self) { slot in
                    let col = slot % columns
                    let row = slot / columns
                    Button(action: { onTap(slot) }) {
                        Pigeonhole(cylinder: filled[slot], temperature: temperature, spin: spin)
                            .frame(width: cw, height: ch)
                    }
                    .buttonStyle(.plain)
                    .offset(x: cw * CGFloat(col), y: ch * CGFloat(row))
                }
            }
        }
    }
}

struct Pigeonhole: View {
    var cylinder: Cylinder?
    var temperature: Double
    var spin: Double

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Rectangle()
                    .fill(Color(red: 0.098, green: 0.075, blue: 0.055))
                    .overlay(
                        Rectangle()
                            .fill(LinearGradient(colors: [Color.black.opacity(0.55),
                                                          Color.black.opacity(0.05)],
                                                 startPoint: .top, endPoint: .bottom))
                    )
                if let c = cylinder {
                    WaxCylinder(voiceId: c.voiceId, quality: c.quality, seed: c.seed,
                                spin: spin, temperature: temperature, cutting: 1.0)
                        .frame(width: w * 0.62, height: h * 0.66)
                        .offset(y: -h * 0.04)
                    VStack {
                        Spacer()
                        Text(Registry.find(c.voiceId).name)
                            .font(Nite.text(min(9, w * 0.10)))
                            .foregroundColor(Color(red: 0.180, green: 0.161, blue: 0.129))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .padding(.horizontal, 3)
                            .padding(.vertical, 1.5)
                            .frame(maxWidth: w * 0.88)
                            .background(Color(red: 0.878, green: 0.855, blue: 0.784))
                            .rotationEffect(.degrees(-1.2))
                            .padding(.bottom, h * 0.06)
                    }
                } else {
                    Canvas { ctx, size in
                        var rng = Spin(seedOf("dust"))
                        for _ in 0..<24 {
                            let x = rng.unit() * Double(size.width)
                            let y = rng.span(0.55, 0.95) * Double(size.height)
                            ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.4, height: 1.0)),
                                     with: .color(Color.white.opacity(rng.span(0.03, 0.10))))
                        }
                    }
                }
            }
            .frame(width: w, height: h)
            .overlay(
                Rectangle()
                    .strokeBorder(Color(red: 0.451, green: 0.361, blue: 0.251), lineWidth: 2)
            )
            .padding(1.5)
        }
    }
}
