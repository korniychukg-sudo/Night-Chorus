import SwiftUI

struct SkyTone {
    var high: Color
    var low: Color
    var far: Color
    var mid: Color
    var near: Color
    var glow: Color
    var ink: Color

    static func blend(_ a: SkyTone, _ b: SkyTone, _ t: Double) -> SkyTone {
        func mix(_ x: Color, _ y: Color) -> Color {
            let u = UIColor(x), v = UIColor(y)
            var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
            var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
            u.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
            v.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
            let f = CGFloat(max(0, min(1, t)))
            return Color(red: Double(r1 + (r2 - r1) * f),
                         green: Double(g1 + (g2 - g1) * f),
                         blue: Double(b1 + (b2 - b1) * f))
        }
        return SkyTone(high: mix(a.high, b.high), low: mix(a.low, b.low),
                       far: mix(a.far, b.far), mid: mix(a.mid, b.mid),
                       near: mix(a.near, b.near), glow: mix(a.glow, b.glow),
                       ink: mix(a.ink, b.ink))
    }
}

enum Skies {
    static let keys: [SkyTone] = [
        SkyTone(high: Color(red: 0.286, green: 0.318, blue: 0.376),
                low: Color(red: 0.545, green: 0.549, blue: 0.529),
                far: Color(red: 0.302, green: 0.325, blue: 0.337),
                mid: Color(red: 0.208, green: 0.235, blue: 0.235),
                near: Color(red: 0.125, green: 0.145, blue: 0.145),
                glow: Color(red: 0.686, green: 0.671, blue: 0.612),
                ink: Color(red: 0.859, green: 0.867, blue: 0.855)),
        SkyTone(high: Color(red: 0.404, green: 0.510, blue: 0.612),
                low: Color(red: 0.749, green: 0.749, blue: 0.694),
                far: Color(red: 0.400, green: 0.435, blue: 0.416),
                mid: Color(red: 0.318, green: 0.373, blue: 0.318),
                near: Color(red: 0.196, green: 0.243, blue: 0.204),
                glow: Color(red: 0.933, green: 0.898, blue: 0.784),
                ink: Color(red: 0.145, green: 0.161, blue: 0.161)),
        SkyTone(high: Color(red: 0.376, green: 0.510, blue: 0.667),
                low: Color(red: 0.729, green: 0.792, blue: 0.816),
                far: Color(red: 0.451, green: 0.494, blue: 0.451),
                mid: Color(red: 0.365, green: 0.435, blue: 0.353),
                near: Color(red: 0.239, green: 0.302, blue: 0.239),
                glow: Color(red: 0.976, green: 0.965, blue: 0.898),
                ink: Color(red: 0.145, green: 0.161, blue: 0.161)),
        SkyTone(high: Color(red: 0.463, green: 0.510, blue: 0.596),
                low: Color(red: 0.882, green: 0.749, blue: 0.529),
                far: Color(red: 0.478, green: 0.435, blue: 0.353),
                mid: Color(red: 0.361, green: 0.353, blue: 0.259),
                near: Color(red: 0.212, green: 0.212, blue: 0.157),
                glow: Color(red: 0.976, green: 0.855, blue: 0.612),
                ink: Color(red: 0.180, green: 0.169, blue: 0.145)),
        SkyTone(high: Color(red: 0.204, green: 0.243, blue: 0.376),
                low: Color(red: 0.663, green: 0.478, blue: 0.361),
                far: Color(red: 0.243, green: 0.231, blue: 0.251),
                mid: Color(red: 0.145, green: 0.157, blue: 0.157),
                near: Color(red: 0.071, green: 0.082, blue: 0.086),
                glow: Color(red: 0.902, green: 0.694, blue: 0.463),
                ink: Color(red: 0.882, green: 0.855, blue: 0.804)),
        SkyTone(high: Color(red: 0.078, green: 0.098, blue: 0.169),
                low: Color(red: 0.306, green: 0.349, blue: 0.443),
                far: Color(red: 0.176, green: 0.196, blue: 0.235),
                mid: Color(red: 0.106, green: 0.122, blue: 0.137),
                near: Color(red: 0.043, green: 0.055, blue: 0.063),
                glow: Color(red: 0.808, green: 0.831, blue: 0.855),
                ink: Color(red: 0.827, green: 0.851, blue: 0.878)),
        SkyTone(high: Color(red: 0.055, green: 0.071, blue: 0.129),
                low: Color(red: 0.271, green: 0.310, blue: 0.400),
                far: Color(red: 0.153, green: 0.169, blue: 0.208),
                mid: Color(red: 0.086, green: 0.102, blue: 0.114),
                near: Color(red: 0.035, green: 0.043, blue: 0.051),
                glow: Color(red: 0.671, green: 0.706, blue: 0.749),
                ink: Color(red: 0.749, green: 0.780, blue: 0.816))
    ]

    static let anchors: [Double] = [5.0, 8.0, 13.0, 17.5, 20.0, 22.5, 26.5]

    static func at(_ hour: Double) -> SkyTone {
        var h = hour
        if h < 4 { h += 24 }
        if h <= anchors[0] { return keys[0] }
        if h >= anchors[anchors.count - 1] { return keys[keys.count - 1] }
        for i in 0..<(anchors.count - 1) where h >= anchors[i] && h <= anchors[i + 1] {
            let t = (h - anchors[i]) / (anchors[i + 1] - anchors[i])
            return SkyTone.blend(keys[i], keys[i + 1], t)
        }
        return keys[keys.count - 1]
    }

    static func darkness(_ hour: Double) -> Double {
        var h = hour
        if h < 4 { h += 24 }
        if h < 6 { return 0.55 }
        if h < 17 { return 0.05 }
        if h < 20 { return 0.35 }
        if h < 21.5 { return 0.75 }
        return 1.0
    }
}

struct SkyOverlay: View {
    var hour: Double
    var moonPhase: Double
    var season: Int
    var drift: Double

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let dark = Skies.darkness(hour)
            let tone = Skies.at(hour)
            ctx.fill(Path(CGRect(origin: .zero, size: size)),
                     with: .linearGradient(Gradient(colors: [tone.high.opacity(0.72 * dark + 0.10),
                                                             tone.low.opacity(0.30 * dark)]),
                                           startPoint: .zero,
                                           endPoint: CGPoint(x: 0, y: h * 0.72)))
            if dark > 0.30 {
                var star = Spin(seedOf("stars-\(season)"))
                for i in 0..<170 {
                    let sx = star.unit() * Double(w)
                    let sy = star.unit() * Double(h) * 0.60
                    let base = star.span(0.4, 1.5)
                    let tw = 0.55 + 0.45 * sin(drift * 1.7 + Double(i) * 0.9)
                    let a = (dark - 0.30) / 0.70 * tw * star.span(0.30, 0.95)
                    ctx.fill(Path(ellipseIn: CGRect(x: sx, y: sy, width: base, height: base)),
                             with: .color(Color.white.opacity(a)))
                }
            }
            if dark > 0.25 {
                let lit = (1 - cos(moonPhase * 2 * Double.pi)) / 2
                let mx = w * (0.16 + 0.62 * moonPhase)
                let my = h * (0.30 - 0.16 * sin(moonPhase * Double.pi))
                let r = min(w, h) * 0.062
                drawMoon(&ctx, at: CGPoint(x: mx, y: my), radius: r,
                         phase: moonPhase, lit: lit, alpha: (dark - 0.25) / 0.75)
            }
            if season == 1 && hour > 19.5 && hour < 23 {
                var fly = Spin(seedOf("fireflies"))
                for i in 0..<26 {
                    let bx = fly.unit()
                    let by = fly.span(0.50, 0.94)
                    let t = drift * 0.55 + Double(i) * 1.7
                    let px = Double(w) * (bx + 0.035 * sin(t * 0.7))
                    let py = Double(h) * (by + 0.020 * sin(t * 1.1 + 1.0))
                    let pulse = max(0, sin(t * 1.9))
                    let a = pow(pulse, 4) * 0.92
                    if a > 0.02 {
                        ctx.fill(Path(ellipseIn: CGRect(x: px - 3, y: py - 3, width: 6, height: 6)),
                                 with: .color(Color(red: 0.847, green: 0.933, blue: 0.545).opacity(a)))
                        ctx.fill(Path(ellipseIn: CGRect(x: px - 1.2, y: py - 1.2, width: 2.4, height: 2.4)),
                                 with: .color(Color.white.opacity(a)))
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

func drawMoon(_ ctx: inout GraphicsContext, at centre: CGPoint, radius: Double,
              phase: Double, lit: Double, alpha: Double) {
    let disc = Path(ellipseIn: CGRect(x: centre.x - radius, y: centre.y - radius,
                                      width: radius * 2, height: radius * 2))
    ctx.fill(disc, with: .color(Color(red: 0.145, green: 0.161, blue: 0.204).opacity(alpha * 0.55)))
    var shape = Path()
    let steps = 48
    let waxing = phase < 0.5
    let cosTerm = cos(phase * 2 * Double.pi)
    for i in 0...steps {
        let a = Double(i) / Double(steps) * Double.pi - Double.pi / 2
        let x = centre.x + CGFloat((waxing ? 1 : -1) * cos(a) * radius)
        let y = centre.y + CGFloat(sin(a) * radius)
        if i == 0 { shape.move(to: CGPoint(x: x, y: y)) } else { shape.addLine(to: CGPoint(x: x, y: y)) }
    }
    for i in stride(from: steps, through: 0, by: -1) {
        let a = Double(i) / Double(steps) * Double.pi - Double.pi / 2
        let x = centre.x + CGFloat((waxing ? 1 : -1) * cos(a) * radius * -cosTerm)
        let y = centre.y + CGFloat(sin(a) * radius)
        shape.addLine(to: CGPoint(x: x, y: y))
    }
    shape.closeSubpath()
    ctx.fill(shape, with: .color(Color(red: 0.949, green: 0.945, blue: 0.898)
        .opacity(alpha * (0.35 + 0.65 * lit))))
    var pit = Spin(seedOf("moonface"))
    var face = ctx
    face.clip(to: shape)
    for _ in 0..<14 {
        let a = pit.span(0, 6.283)
        let d = pit.span(0, radius * 0.78)
        let rr = pit.span(radius * 0.06, radius * 0.20)
        face.fill(Path(ellipseIn: CGRect(x: centre.x + CGFloat(cos(a) * d - rr),
                                         y: centre.y + CGFloat(sin(a) * d - rr),
                                         width: rr * 2, height: rr * 2)),
                  with: .color(Color(red: 0.784, green: 0.784, blue: 0.749).opacity(alpha * 0.55)))
    }
}

struct Spectrogram: View {
    var placed: [Placed]
    var gains: [Double]
    var temperature: Double
    var windowLow: Double
    var windowHigh: Double
    var clock: Double
    var span: Double = 4.0
    var soloIndex: Int?
    var showGrid: Bool = true

    private func yFor(_ f: Double, _ h: Double) -> Double {
        let lo = log(90.0), hi = log(17000.0)
        let v = (log(max(90, min(17000, f))) - lo) / (hi - lo)
        return h * (1 - v)
    }

    var body: some View {
        Canvas { ctx, size in
            let w = Double(size.width), h = Double(size.height)
            ctx.fill(Path(CGRect(origin: .zero, size: size)),
                     with: .color(Color(red: 0.086, green: 0.098, blue: 0.129)))
            if showGrid {
                for f in [100.0, 250.0, 500.0, 1000.0, 2000.0, 4000.0, 8000.0, 16000.0] {
                    let y = yFor(f, h)
                    var line = Path()
                    line.move(to: CGPoint(x: 0, y: y))
                    line.addLine(to: CGPoint(x: w, y: y))
                    ctx.stroke(line, with: .color(Color.white.opacity(0.10)), lineWidth: 0.6)
                    ctx.draw(Text(verbatim: f >= 1000 ? "\(Int(f / 1000))k" : "\(Int(f))")
                                .font(Nite.text(8.5))
                                .foregroundColor(Color.white.opacity(0.34)),
                             at: CGPoint(x: 14, y: y - 6))
                }
            }
            let yLow = yFor(windowHigh, h)
            let yHigh = yFor(windowLow, h)
            ctx.fill(Path(CGRect(x: 0, y: 0, width: w, height: max(0, yLow))),
                     with: .color(Color.black.opacity(0.52)))
            ctx.fill(Path(CGRect(x: 0, y: yHigh, width: w, height: max(0, h - yHigh))),
                     with: .color(Color.black.opacity(0.52)))

            for (i, item) in placed.enumerated() {
                let v = Registry.find(item.voiceId)
                let gain = i < gains.count ? gains[i] : 1
                var strength = gain
                if let s = soloIndex { strength = (s == i) ? 1.0 : gain * 0.12 }
                if strength < 0.035 { continue }
                let inWindow = v.carrier >= windowLow && v.carrier <= windowHigh
                let hue = Nite.groupHue(v.group)
                let alphaBase = strength * (inWindow ? 1.0 : 0.22)
                let y = yFor(v.carrier, h)
                let sp = Trace.spread(v) * h * 0.5
                let rate = v.rate(temperature)
                let from = clock - span
                if rate <= 42 {
                    let starts = Trace.pulseStarts(v, temperature, from: from, to: clock)
                    let dur = min(v.pulse, 1 / max(0.05, rate) * 0.94)
                    for s in starts {
                        let x0 = (s - from) / span * w
                        let x1 = (s + dur - from) / span * w
                        let bw = max(1.4, x1 - x0)
                        let sweepShift = v.sweep != 0
                            ? (yFor(v.carrier + v.sweep, h) - y) : 0
                        var blob = Path()
                        blob.move(to: CGPoint(x: x0, y: y - sp))
                        blob.addLine(to: CGPoint(x: x0 + bw, y: y - sp + sweepShift))
                        blob.addLine(to: CGPoint(x: x0 + bw, y: y + sp + sweepShift))
                        blob.addLine(to: CGPoint(x: x0, y: y + sp))
                        blob.closeSubpath()
                        ctx.fill(blob, with: .color(hue.opacity(alphaBase * 0.90)))
                        if v.harm > 1 {
                            let y2 = yFor(v.carrier * 2, h)
                            ctx.fill(Path(CGRect(x: x0, y: y2 - sp * 0.6,
                                                 width: bw, height: sp * 1.2)),
                                     with: .color(hue.opacity(alphaBase * 0.42)))
                        }
                        if v.harm > 2 {
                            let y3 = yFor(v.carrier * 3, h)
                            ctx.fill(Path(CGRect(x: x0, y: y3 - sp * 0.45,
                                                 width: bw, height: sp * 0.9)),
                                     with: .color(hue.opacity(alphaBase * 0.24)))
                        }
                    }
                } else {
                    let steps = 90
                    for k in 0..<steps {
                        let t = from + span * Double(k) / Double(steps)
                        let e = Trace.envelope(v, temperature, at: t)
                        if e < 0.02 { continue }
                        let x = Double(k) / Double(steps) * w
                        let bw = w / Double(steps) + 1.0
                        ctx.fill(Path(CGRect(x: x, y: y - sp, width: bw, height: sp * 2)),
                                 with: .color(hue.opacity(alphaBase * (0.30 + 0.60 * e))))
                    }
                    var comb = 0.0
                    while comb < span {
                        let x = comb / span * w
                        let t = from + comb
                        if Trace.envelope(v, temperature, at: t) > 0.05 {
                            ctx.fill(Path(CGRect(x: x, y: y - sp * 1.15, width: 0.9, height: sp * 2.3)),
                                     with: .color(hue.opacity(alphaBase * 0.55)))
                        }
                        comb += span / 120
                    }
                }
            }
        }
    }
}

struct VoiceTrace: View {
    var voice: Voice
    var temperature: Double
    var progress: Double
    var tone: Color

    private func yFor(_ f: Double, _ h: Double) -> Double {
        let lo = log(90.0), hi = log(17000.0)
        let v = (log(max(90, min(17000, f))) - lo) / (hi - lo)
        return h * (1 - v)
    }

    var body: some View {
        Canvas { ctx, size in
            let w = Double(size.width), h = Double(size.height)
            ctx.fill(Path(CGRect(origin: .zero, size: size)),
                     with: .color(Color(red: 0.078, green: 0.090, blue: 0.118)))
            for f in [250.0, 1000.0, 4000.0, 16000.0] {
                let y = yFor(f, h)
                var line = Path()
                line.move(to: CGPoint(x: 0, y: y))
                line.addLine(to: CGPoint(x: w, y: y))
                ctx.stroke(line, with: .color(Color.white.opacity(0.12)), lineWidth: 0.6)
                ctx.draw(Text(verbatim: f >= 1000 ? "\(Int(f / 1000)) kHz" : "\(Int(f)) Hz")
                            .font(Nite.text(8.5))
                            .foregroundColor(Color.white.opacity(0.34)),
                         at: CGPoint(x: 22, y: y - 6))
            }
            let span = max(0.55, min(5.0, Trace.cycle(voice, temperature) * 1.25))
            let cut = span * max(0, min(1, progress))
            let y = yFor(voice.carrier, h)
            let sp = Trace.spread(voice) * h * 0.5
            let rate = voice.rate(temperature)
            if rate <= 42 {
                for s in Trace.pulseStarts(voice, temperature, from: 0, to: cut) {
                    let dur = min(voice.pulse, 1 / max(0.05, rate) * 0.94)
                    let x0 = s / span * w
                    let bw = max(1.6, dur / span * w)
                    let shift = voice.sweep != 0 ? (yFor(voice.carrier + voice.sweep, h) - y) : 0
                    var blob = Path()
                    blob.move(to: CGPoint(x: x0, y: y - sp))
                    blob.addLine(to: CGPoint(x: x0 + bw, y: y - sp + shift))
                    blob.addLine(to: CGPoint(x: x0 + bw, y: y + sp + shift))
                    blob.addLine(to: CGPoint(x: x0, y: y + sp))
                    blob.closeSubpath()
                    ctx.fill(blob, with: .color(tone.opacity(0.92)))
                    if voice.harm > 1 {
                        let y2 = yFor(voice.carrier * 2, h)
                        ctx.fill(Path(CGRect(x: x0, y: y2 - sp * 0.6, width: bw, height: sp * 1.2)),
                                 with: .color(tone.opacity(0.44)))
                    }
                    if voice.harm > 2 {
                        let y3 = yFor(voice.carrier * 3, h)
                        ctx.fill(Path(CGRect(x: x0, y: y3 - sp * 0.45, width: bw, height: sp * 0.9)),
                                 with: .color(tone.opacity(0.26)))
                    }
                }
            } else {
                let steps = 150
                for k in 0..<steps {
                    let t = span * Double(k) / Double(steps)
                    if t > cut { break }
                    let e = Trace.envelope(voice, temperature, at: t)
                    if e < 0.02 { continue }
                    let x = Double(k) / Double(steps) * w
                    ctx.fill(Path(CGRect(x: x, y: y - sp, width: w / Double(steps) + 1,
                                         height: sp * 2)),
                             with: .color(tone.opacity(0.34 + 0.58 * e)))
                }
            }
            var wave = Path()
            let n = 260
            for k in 0...n {
                let t = span * Double(k) / Double(n)
                let x = Double(k) / Double(n) * w
                let a = t <= cut ? Trace.envelope(voice, temperature, at: t) : 0
                let yy = h - 12 - a * h * 0.16
                if k == 0 { wave.move(to: CGPoint(x: x, y: yy)) } else { wave.addLine(to: CGPoint(x: x, y: yy)) }
            }
            ctx.stroke(wave, with: .color(Color.white.opacity(0.42)), lineWidth: 1.1)
        }
    }
}
