import SwiftUI

struct FieldScene: View {
    var habitat: Int
    var hour: Double
    var placed: [Placed]
    var gains: [Double]
    var envelopes: [Double]
    var aim: Double
    var dishWidth: Double
    var locked: Int?
    var drift: Double
    var revealed: Set<Int>

    var body: some View {
        Canvas { ctx, size in
            let w = Double(size.width), h = Double(size.height)
            let tone = Skies.at(hour)
            let dark = Skies.darkness(hour)
            let sky = Path(CGRect(x: 0, y: 0, width: w, height: h * 0.66))
            ctx.fill(sky, with: .linearGradient(
                Gradient(colors: [tone.high, tone.low]),
                startPoint: .zero, endPoint: CGPoint(x: 0, y: h * 0.66)))
            ctx.fill(Path(CGRect(x: 0, y: h * 0.62, width: w, height: h * 0.38)),
                     with: .linearGradient(Gradient(colors: [tone.mid, tone.near]),
                                           startPoint: CGPoint(x: 0, y: h * 0.62),
                                           endPoint: CGPoint(x: 0, y: h)))

            if dark > 0.30 {
                var star = Spin(seedOf("field-stars-\(habitat)"))
                for i in 0..<120 {
                    let sx = star.unit() * w
                    let sy = star.unit() * h * 0.50
                    let r = star.span(0.4, 1.4)
                    let tw = 0.6 + 0.4 * sin(drift * 1.6 + Double(i))
                    ctx.fill(Path(ellipseIn: CGRect(x: sx, y: sy, width: r, height: r)),
                             with: .color(Color.white.opacity((dark - 0.30) / 0.70 * tw * 0.8)))
                }
                let phase = Clock.moonPhase
                drawMoon(&ctx, at: CGPoint(x: w * (0.14 + 0.66 * phase), y: h * 0.16),
                         radius: min(w, h) * 0.048, phase: phase, lit: Clock.moonLit,
                         alpha: (dark - 0.30) / 0.70)
            }

            drawFar(&ctx, w: w, h: h, tone: tone)
            drawWater(&ctx, w: w, h: h, tone: tone, drift: drift)
            drawMid(&ctx, w: w, h: h, tone: tone)

            let dishY = h * 0.94
            let dishX = w * (0.5 + aim * 0.42)
            var cone = Path()
            let reach = h * 0.80
            let halfAngle = 0.10 + dishWidth * 0.42
            cone.move(to: CGPoint(x: dishX, y: dishY))
            cone.addLine(to: CGPoint(x: dishX - sin(halfAngle) * reach, y: dishY - cos(halfAngle) * reach))
            cone.addLine(to: CGPoint(x: dishX + sin(halfAngle) * reach, y: dishY - cos(halfAngle) * reach))
            cone.closeSubpath()
            ctx.fill(cone, with: .linearGradient(
                Gradient(colors: [Color(red: 0.898, green: 0.925, blue: 0.847).opacity(0.20),
                                  Color(red: 0.898, green: 0.925, blue: 0.847).opacity(0.01)]),
                startPoint: CGPoint(x: dishX, y: dishY),
                endPoint: CGPoint(x: dishX, y: dishY - reach)))
            ctx.stroke(cone, with: .color(Color.white.opacity(0.20)), lineWidth: 0.8)

            for (i, item) in placed.enumerated() {
                let v = Registry.find(item.voiceId)
                let gain = i < gains.count ? gains[i] : 0
                let env = i < envelopes.count ? envelopes[i] : 0
                let px = w * (0.5 + item.x * 0.46)
                let py = h * (0.40 + item.depth * 0.50)
                let scale = 1.0 - item.depth * 0.42
                let known = revealed.contains(i) || locked == i
                let bright = max(known ? 0.34 : 0.09, min(1, gain * (0.30 + env * 3.2)))
                let hue = Nite.groupHue(v.group)
                let rr = (5.0 + 12.0 * bright) * scale
                ctx.fill(Path(ellipseIn: CGRect(x: px - rr, y: py - rr, width: rr * 2, height: rr * 2)),
                         with: .radialGradient(
                            Gradient(colors: [hue.opacity(0.62 * max(bright, known ? 0.35 : 0)),
                                              hue.opacity(0)]),
                            center: CGPoint(x: px, y: py), startRadius: 0, endRadius: rr))
                let core = (2.0 + 3.2 * bright) * scale
                ctx.fill(Path(ellipseIn: CGRect(x: px - core, y: py - core,
                                                width: core * 2, height: core * 2)),
                         with: .color(Color.white.opacity(0.30 + 0.62 * bright)))
                if locked == i {
                    let ring = 16.0 * scale
                    ctx.stroke(Path(ellipseIn: CGRect(x: px - ring, y: py - ring,
                                                      width: ring * 2, height: ring * 2)),
                               with: .color(Nite.moon.opacity(0.85)), lineWidth: 1.4)
                }
            }

            drawNear(&ctx, w: w, h: h, tone: tone)
            drawDish(&ctx, x: dishX, y: dishY, size: min(w, h) * 0.13, tone: tone)
        }
    }

    private func ridge(_ seed: String, _ w: Double, _ base: Double, _ amp: Double,
                       _ steps: Int, _ jag: Double) -> Path {
        var rng = Spin(seedOf(seed))
        var p = Path()
        p.move(to: CGPoint(x: -8, y: base + amp))
        for i in 0...steps {
            let t = Double(i) / Double(steps)
            let x = -8 + (w + 16) * t
            let y = base - amp * (0.35 + 0.65 * abs(sin(t * 7.3 + rng.unit() * 0.4)))
                - rng.span(0, amp * jag)
            p.addLine(to: CGPoint(x: x, y: y))
        }
        p.addLine(to: CGPoint(x: w + 8, y: base + amp))
        p.closeSubpath()
        return p
    }

    private func drawFar(_ ctx: inout GraphicsContext, w: Double, h: Double, tone: SkyTone) {
        switch habitat {
        case 2, 7:
            ctx.fill(ridge("far-trees-\(habitat)", w, h * 0.60, h * 0.24, 46, 0.5),
                     with: .color(tone.far))
        case 4:
            ctx.fill(ridge("far-mesa", w, h * 0.58, h * 0.10, 18, 0.2), with: .color(tone.far))
        case 6:
            ctx.fill(ridge("far-pines", w, h * 0.60, h * 0.16, 40, 0.7), with: .color(tone.far))
        default:
            ctx.fill(ridge("far-line-\(habitat)", w, h * 0.58, h * 0.09, 30, 0.35),
                     with: .color(tone.far))
        }
        if habitat == 3 {
            let fx = w * 0.78
            ctx.fill(Path(CGRect(x: fx, y: h * 0.50, width: w * 0.16, height: h * 0.12)),
                     with: .color(tone.far.opacity(0.9)))
            ctx.fill(Path(CGRect(x: fx + w * 0.04, y: h * 0.53, width: w * 0.035, height: h * 0.045)),
                     with: .color(Color(red: 0.949, green: 0.867, blue: 0.639)
                        .opacity(Skies.darkness(hour) * 0.85)))
        }
    }

    private func drawWater(_ ctx: inout GraphicsContext, w: Double, h: Double,
                           tone: SkyTone, drift: Double) {
        guard habitat == 0 || habitat == 5 || habitat == 7 else { return }
        let top = h * 0.62
        ctx.fill(Path(CGRect(x: 0, y: top, width: w, height: h * 0.22)),
                 with: .linearGradient(Gradient(colors: [tone.far.opacity(0.85), tone.mid]),
                                       startPoint: CGPoint(x: 0, y: top),
                                       endPoint: CGPoint(x: 0, y: top + h * 0.22)))
        var rng = Spin(seedOf("ripple-\(habitat)"))
        for i in 0..<26 {
            let y = top + rng.span(0.01, 0.21) * h
            let x0 = rng.unit() * w
            let len = rng.span(0.05, 0.22) * w
            let shift = sin(drift * 0.8 + Double(i)) * 4
            var line = Path()
            line.move(to: CGPoint(x: x0 + shift, y: y))
            line.addLine(to: CGPoint(x: x0 + len + shift, y: y))
            ctx.stroke(line, with: .color(tone.glow.opacity(0.16 + 0.10 * Skies.darkness(hour))),
                       lineWidth: 0.9)
        }
    }

    private func drawMid(_ ctx: inout GraphicsContext, w: Double, h: Double, tone: SkyTone) {
        var rng = Spin(seedOf("mid-\(habitat)"))
        switch habitat {
        case 0, 5:
            for _ in 0..<48 {
                let x = rng.unit() * w
                let base = h * rng.span(0.80, 0.94)
                let len = h * rng.span(0.12, 0.30)
                let lean = rng.span(-0.16, 0.16)
                var stem = Path()
                stem.move(to: CGPoint(x: x, y: base))
                stem.addLine(to: CGPoint(x: x + lean * len, y: base - len))
                ctx.stroke(stem, with: .color(tone.near.opacity(0.95)), lineWidth: 1.9)
                let hx = x + lean * len
                let hy = base - len
                ctx.fill(Path(roundedRect: CGRect(x: hx - 2.6, y: hy - len * 0.20,
                                                  width: 5.2, height: len * 0.22),
                              cornerRadius: 2.6),
                         with: .color(tone.near.opacity(0.95)))
            }
        case 1:
            for _ in 0..<70 {
                let x = rng.unit() * w
                let base = h * rng.span(0.78, 0.96)
                let len = h * rng.span(0.06, 0.18)
                var stem = Path()
                stem.move(to: CGPoint(x: x, y: base))
                stem.addQuadCurve(to: CGPoint(x: x + rng.span(-14, 14), y: base - len),
                                  control: CGPoint(x: x + rng.span(-6, 6), y: base - len * 0.6))
                ctx.stroke(stem, with: .color(tone.near.opacity(0.9)), lineWidth: 1.5)
            }
        case 2, 7:
            for _ in 0..<7 {
                let x = rng.unit() * w
                let wide = rng.span(10, 26)
                ctx.fill(Path(CGRect(x: x, y: h * 0.30, width: wide, height: h * 0.52)),
                         with: .color(tone.near.opacity(0.92)))
                var branch = Path()
                branch.move(to: CGPoint(x: x + wide / 2, y: h * rng.span(0.36, 0.50)))
                branch.addQuadCurve(to: CGPoint(x: x + rng.span(-90, 90), y: h * rng.span(0.24, 0.36)),
                                    control: CGPoint(x: x + rng.span(-40, 40), y: h * 0.32))
                ctx.stroke(branch, with: .color(tone.near.opacity(0.85)), lineWidth: 3.0)
            }
        case 3:
            ctx.fill(Path(CGRect(x: 0, y: h * 0.70, width: w, height: h * 0.06)),
                     with: .color(tone.near.opacity(0.9)))
            var x = 0.0
            while x < w {
                ctx.fill(Path(CGRect(x: x, y: h * 0.68, width: 4, height: h * 0.12)),
                         with: .color(tone.near.opacity(0.92)))
                x += w / 16
            }
        case 4:
            for _ in 0..<12 {
                let x = rng.unit() * w
                let base = h * rng.span(0.80, 0.94)
                for k in 0..<9 {
                    let a = -Double.pi / 2 + (Double(k) - 4) * 0.26
                    let len = h * rng.span(0.08, 0.17)
                    var blade = Path()
                    blade.move(to: CGPoint(x: x, y: base))
                    blade.addLine(to: CGPoint(x: x + cos(a) * len, y: base + sin(a) * len))
                    ctx.stroke(blade, with: .color(tone.near.opacity(0.92)), lineWidth: 2.2)
                }
            }
        case 6:
            for _ in 0..<10 {
                let x = rng.unit() * w
                let base = h * rng.span(0.76, 0.88)
                let ht = h * rng.span(0.16, 0.30)
                var pine = Path()
                pine.move(to: CGPoint(x: x, y: base - ht))
                pine.addLine(to: CGPoint(x: x - ht * 0.30, y: base))
                pine.addLine(to: CGPoint(x: x + ht * 0.30, y: base))
                pine.closeSubpath()
                ctx.fill(pine, with: .color(tone.near.opacity(0.92)))
            }
        default:
            break
        }
    }

    private func drawNear(_ ctx: inout GraphicsContext, w: Double, h: Double, tone: SkyTone) {
        var rng = Spin(seedOf("near-\(habitat)"))
        for _ in 0..<26 {
            let x = rng.unit() * w
            let len = h * rng.span(0.10, 0.26)
            var blade = Path()
            blade.move(to: CGPoint(x: x, y: h + 6))
            blade.addQuadCurve(to: CGPoint(x: x + rng.span(-30, 30), y: h - len),
                               control: CGPoint(x: x + rng.span(-12, 12), y: h - len * 0.5))
            ctx.stroke(blade, with: .color(Color.black.opacity(0.82)), lineWidth: rng.span(1.6, 3.4))
        }
    }

    private func drawDish(_ ctx: inout GraphicsContext, x: Double, y: Double,
                          size: Double, tone: SkyTone) {
        var bowl = Path()
        let n = 26
        for i in 0...n {
            let t = Double(i) / Double(n) * 2 - 1
            let q = CGPoint(x: x + t * size, y: y - size * 0.62 + t * t * size * 0.62)
            if i == 0 { bowl.move(to: q) } else { bowl.addLine(to: q) }
        }
        for i in stride(from: n, through: 0, by: -1) {
            let t = Double(i) / Double(n) * 2 - 1
            bowl.addLine(to: CGPoint(x: x + t * size, y: y - size * 0.50 + t * t * size * 0.62))
        }
        bowl.closeSubpath()
        ctx.fill(bowl, with: .color(Color(red: 0.847, green: 0.867, blue: 0.855).opacity(0.90)))
        ctx.stroke(bowl, with: .color(Color.black.opacity(0.55)), lineWidth: 1.0)
        var stem = Path()
        stem.move(to: CGPoint(x: x, y: y - size * 0.10))
        stem.addLine(to: CGPoint(x: x, y: y + size * 0.34))
        ctx.stroke(stem, with: .color(Color(red: 0.318, green: 0.302, blue: 0.278)), lineWidth: 3.4)
        ctx.fill(Path(ellipseIn: CGRect(x: x - 4.5, y: y - size * 0.22, width: 9, height: 9)),
                 with: .color(Color(red: 0.220, green: 0.212, blue: 0.196)))
    }
}


struct WaxCylinder: View {
    var voiceId: String
    var quality: Double
    var seed: Int
    var spin: Double
    var temperature: Double
    var cutting: Double

    var body: some View {
        Canvas { ctx, size in
            let w = Double(size.width), h = Double(size.height)
            let v = Registry.find(voiceId)
            let cx = w / 2
            let top = h * 0.16
            let bottom = h * 0.84
            let rx = min(w * 0.32, (bottom - top) * 0.46)
            let ry = rx * 0.32

            var tube = Path()
            tube.move(to: CGPoint(x: cx - rx, y: top))
            tube.addLine(to: CGPoint(x: cx - rx, y: bottom))
            tube.addCurve(to: CGPoint(x: cx + rx, y: bottom),
                          control1: CGPoint(x: cx - rx, y: bottom + ry * 1.34),
                          control2: CGPoint(x: cx + rx, y: bottom + ry * 1.34))
            tube.addLine(to: CGPoint(x: cx + rx, y: top))
            tube.closeSubpath()
            ctx.fill(tube, with: .linearGradient(
                Gradient(colors: [Color(red: 0.404, green: 0.322, blue: 0.220),
                                  Color(red: 0.694, green: 0.596, blue: 0.435),
                                  Color(red: 0.310, green: 0.239, blue: 0.161)]),
                startPoint: CGPoint(x: cx - rx, y: 0), endPoint: CGPoint(x: cx + rx, y: 0)))

            ctx.drawLayer { inner in
                inner.clip(to: tube)
                let turns = max(6, Int((bottom - top) / 5))
                for k in 0..<turns {
                    let t = Double(k) / Double(turns)
                    let y = top + (bottom - top) * t
                    let u = (t + spin).truncatingRemainder(dividingBy: 1)
                    let depth = Trace.grooveDepth(v, temperature, at: u, seed: seed)
                    let done = t <= cutting
                    let amp = done ? depth : 0
                    var groove = Path()
                    let n = 30
                    for i in 0...n {
                        let a = Double(i) / Double(n) * Double.pi
                        let gx = cx - rx + 2 * rx * Double(i) / Double(n)
                        let gy = y + sin(a) * ry * 0.9 + amp * 2.4
                        if i == 0 { groove.move(to: CGPoint(x: gx, y: gy)) }
                        else { groove.addLine(to: CGPoint(x: gx, y: gy)) }
                    }
                    inner.stroke(groove,
                                 with: .color(Color.black.opacity(done ? 0.20 + 0.55 * depth : 0.06)),
                                 lineWidth: done ? 0.9 + 1.4 * depth : 0.5)
                    var high = Path()
                    for i in 0...n {
                        let a = Double(i) / Double(n) * Double.pi
                        let gx = cx - rx + 2 * rx * Double(i) / Double(n)
                        let gy = y + sin(a) * ry * 0.9 + amp * 2.4 - 1.3
                        if i == 0 { high.move(to: CGPoint(x: gx, y: gy)) }
                        else { high.addLine(to: CGPoint(x: gx, y: gy)) }
                    }
                    inner.stroke(high, with: .color(Color.white.opacity(done ? 0.16 * depth : 0)),
                                 lineWidth: 0.7)
                }
                inner.fill(Path(CGRect(x: cx - rx, y: top, width: rx * 0.5, height: bottom - top)),
                           with: .linearGradient(
                            Gradient(colors: [Color.black.opacity(0.34), Color.black.opacity(0)]),
                            startPoint: CGPoint(x: cx - rx, y: 0),
                            endPoint: CGPoint(x: cx - rx * 0.5, y: 0)))
                inner.fill(Path(CGRect(x: cx + rx * 0.42, y: top,
                                       width: rx * 0.58, height: bottom - top)),
                           with: .linearGradient(
                            Gradient(colors: [Color.black.opacity(0), Color.black.opacity(0.40)]),
                            startPoint: CGPoint(x: cx + rx * 0.42, y: 0),
                            endPoint: CGPoint(x: cx + rx, y: 0)))
            }

            let cap = Path(ellipseIn: CGRect(x: cx - rx, y: top - ry, width: rx * 2, height: ry * 2))
            ctx.fill(cap, with: .linearGradient(
                Gradient(colors: [Color(red: 0.749, green: 0.663, blue: 0.502),
                                  Color(red: 0.478, green: 0.396, blue: 0.278)]),
                startPoint: CGPoint(x: cx - rx, y: top - ry),
                endPoint: CGPoint(x: cx + rx, y: top + ry)))
            ctx.stroke(cap, with: .color(Color.black.opacity(0.45)), lineWidth: 1.0)
            let hole = Path(ellipseIn: CGRect(x: cx - rx * 0.34, y: top - ry * 0.42,
                                              width: rx * 0.68, height: ry * 0.84))
            ctx.fill(hole, with: .color(Color(red: 0.129, green: 0.106, blue: 0.078)))
            ctx.stroke(hole, with: .color(Color.white.opacity(0.18)), lineWidth: 0.8)
            let sheen = Path(ellipseIn: CGRect(x: cx - rx * 0.86, y: top - ry * 0.72,
                                               width: rx * 0.5, height: ry * 0.7))
            ctx.fill(sheen, with: .color(Color.white.opacity(0.20)))
        }
    }
}
