import Foundation
import CoreGraphics

let moonBeam = Wash(r: 0.867, g: 0.925, b: 1.000)
let warmLit = Wash(r: 0.933, g: 0.965, b: 0.902)
let pitch = Wash(r: 0.014, g: 0.022, b: 0.037)

func litBy(_ base: Wash, _ level: Double) -> Wash {
    let k = max(0.0, min(1.0, level))
    if k >= 0.50 { return base.mix(warmLit, (k - 0.50) * 1.30) }
    return base.mix(pitch, (0.50 - k) * 1.94)
}

func curveThrough(_ control: [CGPoint], closed: Bool, steps: Int) -> [CGPoint] {
    guard control.count > 2 else { return control }
    var out: [CGPoint] = []
    let n = control.count
    let segs = closed ? n : n - 1
    for s in 0..<segs {
        let p0 = control[(s - 1 + n) % n]
        let p1 = control[s % n]
        let p2 = control[(s + 1) % n]
        let p3 = control[(s + 2) % n]
        for k in 0..<steps {
            let t = Double(k) / Double(steps)
            let t2 = t * t, t3 = t2 * t
            let x = 0.5 * ((2 * Double(p1.x)) +
                           (-Double(p0.x) + Double(p2.x)) * t +
                           (2 * Double(p0.x) - 5 * Double(p1.x) + 4 * Double(p2.x) - Double(p3.x)) * t2 +
                           (-Double(p0.x) + 3 * Double(p1.x) - 3 * Double(p2.x) + Double(p3.x)) * t3)
            let y = 0.5 * ((2 * Double(p1.y)) +
                           (-Double(p0.y) + Double(p2.y)) * t +
                           (2 * Double(p0.y) - 5 * Double(p1.y) + 4 * Double(p2.y) - Double(p3.y)) * t2 +
                           (-Double(p0.y) + 3 * Double(p1.y) - 3 * Double(p2.y) + Double(p3.y)) * t3)
            out.append(CGPoint(x: x, y: y))
        }
    }
    if !closed, let last = control.last { out.append(last) }
    return out
}

func rimRuns(_ pts: [CGPoint], light: Double, threshold: Double = 0.14) -> [[CGPoint]] {
    guard pts.count > 3 else { return [] }
    var twice = 0.0
    for i in 0..<pts.count {
        let a = pts[i], b = pts[(i + 1) % pts.count]
        twice += Double(a.x) * Double(b.y) - Double(b.x) * Double(a.y)
    }
    let turn: Double = twice > 0 ? -(.pi / 2) : (.pi / 2)
    var kept: [Int] = []
    for i in 0..<pts.count {
        let a = pts[i], b = pts[(i + 1) % pts.count]
        let dx = Double(b.x - a.x), dy = Double(b.y - a.y)
        guard dx * dx + dy * dy > 0.0001 else { continue }
        let ang = atan2(dy, dx)
        if cos(ang + turn - light) > threshold { kept.append(i) }
    }
    guard !kept.isEmpty else { return [] }
    var spans: [[Int]] = []
    var current: [Int] = []
    var previous = -99
    for i in kept {
        if current.isEmpty || i == previous + 1 { current.append(i) }
        else { spans.append(current); current = [i] }
        previous = i
    }
    if !current.isEmpty { spans.append(current) }
    if spans.count > 1, spans[0].first == 0,
       spans[spans.count - 1].last == pts.count - 1 {
        let tail = spans.removeLast()
        spans[0] = tail + spans[0]
    }
    return spans.filter { $0.count > 1 }.map { span in span.map { pts[$0] } }
}

func sculpt(_ p: Sheet, _ outline: [CGPoint], base: Wash, light: Double,
            hotAt: Double, seed: UInt64, bands: Int = 74, grain: Bool = true,
            grainCount: Int = 0, grainLen: Double = 34, grainWeight: Double = 2.6,
            falloff: Double = 3.30, ceiling: Double = 0.74, floorLevel: Double = 0.04,
            rim: Bool = true) {
    guard outline.count > 3 else { return }
    p.shape(outline, base.mix(pitch, 0.55))
    let form = pathOf(outline)
    let ax = cos(light), ay = sin(light)
    var lo = Double.greatestFiniteMagnitude
    var hi = -Double.greatestFiniteMagnitude
    for q in outline {
        let v = Double(q.x) * ax + Double(q.y) * ay
        lo = min(lo, v); hi = max(hi, v)
    }
    guard hi > lo else { return }
    let span = hi - lo
    let cross = Double(form.boundingBox.width + form.boundingBox.height)
    let cx = Double(form.boundingBox.midX), cy = Double(form.boundingBox.midY)
    p.inside(form) {
        for s in 0..<bands {
            let u0 = Double(s) / Double(bands)
            let u1 = Double(s + 1) / Double(bands)
            let mid = (u0 + u1) / 2
            let curve = cos((mid - hotAt) * falloff)
            let level = max(0.0, min(1.0, floorLevel + max(0.0, curve) * ceiling))
            let d0 = lo + span * u0 - (cx * ax + cy * ay)
            let d1 = lo + span * u1 - (cx * ax + cy * ay)
            let px = -ay, py = ax
            p.shape([pt(cx + ax * d0 + px * cross, cy + ay * d0 + py * cross),
                     pt(cx + ax * d1 + px * cross, cy + ay * d1 + py * cross),
                     pt(cx + ax * d1 - px * cross, cy + ay * d1 - py * cross),
                     pt(cx + ax * d0 - px * cross, cy + ay * d0 - py * cross)],
                    litBy(base, level))
        }
        if grain {
            var g = Spark(seed &+ 71)
            let area = form.boundingBox
            let n = grainCount > 0 ? grainCount : Int(Double(area.width) * 1.4)
            for _ in 0..<n {
                let x = Double(area.minX) + g.d() * Double(area.width)
                let y = Double(area.minY) + g.d() * Double(area.height)
                let dark = g.odds(0.5)
                let dir = g.r(0.5, 1.1)
                pen(p, [pt(x, y), pt(x + cos(dir) * grainLen * g.r(0.4, 1.5),
                                     y + sin(dir) * grainLen * g.r(0.3, 1.1))],
                    weight: g.r(grainWeight * 0.35, grainWeight),
                    colour: (dark ? base.mix(pitch, g.r(0.20, 0.62))
                             : base.mix(warmLit, g.r(0.08, 0.40))).al(g.r(0.14, 0.46)),
                    wobble: 0.4, taper: true, seed: g.next())
            }
        }
    }
    guard rim else { return }
    for run in rimRuns(outline, light: light) {
        penBroken(p, run, weight: 7.0, colour: base.mix(moonBeam, 0.70).al(0.68),
                  pieces: 3, gap: 0.06, wobble: 0.7, seed: seed &+ 301)
    }
    for run in rimRuns(Array(outline.reversed()), light: light + .pi) {
        pen(p, run, weight: 5.0, colour: pitch.al(0.76),
            wobble: 0.4, taper: true, seed: seed &+ 303)
    }
}

func crescent(_ outline: [CGPoint], light: Double, inset: Double,
              away: Bool) -> [CGPoint] {
    guard outline.count > 3 else { return [] }
    var cx = 0.0, cy = 0.0
    for q in outline { cx += Double(q.x); cy += Double(q.y) }
    cx /= Double(outline.count); cy /= Double(outline.count)
    let lx = cos(light), ly = sin(light)
    var outer: [CGPoint] = []
    var inner: [CGPoint] = []
    for q in outline {
        var dx = Double(q.x) - cx, dy = Double(q.y) - cy
        let len = (dx * dx + dy * dy).squareRoot()
        guard len > 0 else { continue }
        dx /= len; dy /= len
        let facing = dx * lx + dy * ly
        let signed = away ? -facing : facing
        guard signed > 0.02 else { continue }
        let pull = inset * min(1.0, signed)
        outer.append(q)
        inner.append(CGPoint(x: q.x - CGFloat(dx * pull), y: q.y - CGFloat(dy * pull)))
    }
    guard outer.count > 2 else { return [] }
    return outer + inner.reversed()
}

func formPass(_ p: Sheet, _ outline: [CGPoint], light: Double, inset: Double,
              shade: Wash, glow: Wash, seed: UInt64) {
    let form = pathOf(outline)
    let dark = crescent(outline, light: light, inset: inset, away: true)
    if dark.count > 3 {
        p.inside(form) {
            p.shape(dark, shade.al(0.27))
            let tighter = crescent(outline, light: light, inset: inset * 0.52, away: true)
            if tighter.count > 3 { p.shape(tighter, shade.al(0.31)) }
            crossHatch(p, pathOf(dark), depth: 1, spacing: max(3.0, inset * 0.045),
                       colour: shade.al(0.20), bound: form, seed: seed)
        }
    }
    let lit = crescent(outline, light: light, inset: inset * 0.40, away: false)
    if lit.count > 3 {
        p.inside(form) { p.shape(lit, glow.al(0.22)) }
    }
}

func engrave(_ p: Sheet, _ line: [CGPoint], weight: Double, light: Double, seed: UInt64,
             glow: Double = 0.26) {
    let off = weight * 0.9
    let nx = cos(light) * off, ny = sin(light) * off
    penBroken(p, line.map { pt(Double($0.x) - nx, Double($0.y) - ny) }, weight: weight,
              colour: pitch.al(0.70), pieces: 4, gap: 0.05, wobble: 0.8, seed: seed)
    penBroken(p, line.map { pt(Double($0.x) + nx, Double($0.y) + ny) }, weight: weight * 0.60,
              colour: moonBeam.al(glow), pieces: 5, gap: 0.09, wobble: 0.7, seed: seed &+ 17)
}

func softGlow(_ p: Sheet, cx: Double, cy: Double, radius: Double,
              colour: Wash, strength: Double, bias: Double = 0.0) {
    guard radius > 1, let g = CGGradient(
        colorsSpace: rgbSpace,
        colors: [cg(colour.al(strength)), cg(colour.al(strength * 0.34)),
                 cg(colour.al(0))] as CFArray,
        locations: [0, CGFloat(0.44 + bias), 1]) else { return }
    p.ctx.drawRadialGradient(g, startCenter: CGPoint(x: cx, y: cy), startRadius: 0,
                             endCenter: CGPoint(x: cx, y: cy),
                             endRadius: CGFloat(radius), options: [])
}

func toePts(bx: Double, by: Double, angle: Double, length: Double,
            halfWidth: Double, padR: Double, side: Double) -> [CGPoint] {
    let ax = cos(angle), ay = sin(angle)
    let nx = -ay * side, ny = ax * side
    var out: [CGPoint] = []
    func q(_ t: Double, _ w: Double) {
        out.append(pt(bx + ax * t + nx * w, by + ay * t + ny * w))
    }
    q(0, halfWidth * 1.06)
    q(length * 0.30, halfWidth * 0.92)
    q(length * 0.62, halfWidth * 0.86)
    q(length - padR * 0.86, padR * 0.80)
    q(length - padR * 0.18, padR * 1.00)
    q(length + padR * 0.52, padR * 0.74)
    q(length + padR * 0.86, padR * 0.28)
    q(length + padR * 0.88, -padR * 0.28)
    q(length + padR * 0.52, -padR * 0.74)
    q(length - padR * 0.18, -padR * 1.00)
    q(length - padR * 0.86, -padR * 0.80)
    q(length * 0.62, -halfWidth * 0.86)
    q(length * 0.30, -halfWidth * 0.92)
    q(0, -halfWidth * 1.06)
    return out
}

func digits(cx: Double, cy: Double, spread: Double, webR: Double,
            spec: [(Double, Double, Double, Double)], side: Double) -> [CGPoint] {
    var out: [CGPoint] = []
    for (i, s) in spec.enumerated() {
        if i > 0 {
            let mid = (spec[i - 1].0 + s.0) / 2
            out.append(pt(cx + cos(mid) * webR, cy + sin(mid) * webR))
        }
        out += toePts(bx: cx + cos(s.0) * spread, by: cy + sin(s.0) * spread,
                      angle: s.0, length: s.1, halfWidth: s.2, padR: s.3, side: side)
    }
    return out
}

func padSheen(_ p: Sheet, cx: Double, cy: Double, spread: Double,
              spec: [(Double, Double, Double, Double)], light: Double, value: Double,
              seed: UInt64) {
    var rng = Spark(seed)
    for s in spec {
        let tx = cx + cos(s.0) * (spread + s.1)
        let ty = cy + sin(s.0) * (spread + s.1)
        let ring = lump(cx: tx, cy: ty, rx: s.3 * 1.02, ry: s.3 * 0.96,
                        rough: 0.05, steps: 26, seed: rng.next())
        p.shape(ring, pitch.al(0.24 * value))
        p.shape(lump(cx: tx - cos(light) * s.3 * 0.14, cy: ty - sin(light) * s.3 * 0.14,
                     rx: s.3 * 0.84, ry: s.3 * 0.78, rough: 0.05, steps: 24,
                     seed: rng.next()),
                Wash(r: 0.427, g: 0.443, b: 0.353).mix(pitch, 1.0 - value).al(0.50))
        p.shape(lump(cx: tx + cos(light) * s.3 * 0.36, cy: ty + sin(light) * s.3 * 0.36,
                     rx: s.3 * 0.34, ry: s.3 * 0.28, rough: 0.10, steps: 18,
                     seed: rng.next()),
                warmLit.al(0.26 * value))
        penBroken(p, ringPts(cx: tx, cy: ty, rx: s.3 * 0.94, ry: s.3 * 0.88, steps: 24)
                  + [pt(tx + s.3 * 0.94, ty)], weight: 2.8,
                  colour: pitch.al(0.34 * value), pieces: 3, gap: 0.14,
                  wobble: 0.8, seed: rng.next())
    }
}

func frogEye(_ p: Sheet, cx: Double, cy: Double, rx: Double, ry: Double,
             light: Double, seed: UInt64) {
    let dome = lump(cx: cx, cy: cy, rx: rx, ry: ry, rough: 0.012, steps: 64, seed: seed &+ 1)
    let domePath = pathOf(dome)

    softGlow(p, cx: cx + rx * 0.34, cy: cy + ry * 0.50, radius: rx * 2.05,
             colour: pitch, strength: 0.62, bias: 0.16)

    sculpt(p, dome, base: Wash(r: 0.318, g: 0.235, b: 0.106), light: light,
           hotAt: 0.80, seed: seed &+ 3, bands: 54, grain: false,
           falloff: 2.05, ceiling: 0.62, floorLevel: 0.09, rim: false)

    var fibre = Spark(seed &+ 29)
    p.inside(domePath) {
        for _ in 0..<1500 {
            let a = fibre.r(0, 6.283185)
            let r0 = fibre.r(0.20, 0.52)
            let r1 = r0 + fibre.r(0.24, 0.60)
            let lam = max(0.0, cos(a - light))
            let gold = fibre.odds(0.30 + 0.56 * lam)
            pen(p, [pt(cx + cos(a) * rx * r0, cy + sin(a) * ry * r0),
                    pt(cx + cos(a) * rx * r1, cy + sin(a) * ry * r1)],
                weight: fibre.r(0.9, 2.6),
                colour: (gold ? Wash(r: 0.918, g: 0.729, b: 0.286)
                         : Wash(r: 0.239, g: 0.153, b: 0.055)).al(fibre.r(0.16, 0.52)),
                wobble: 0.30, taper: true, seed: fibre.next())
        }
        softGlow(p, cx: cx - rx * 0.34, cy: cy - ry * 0.36, radius: rx * 1.05,
                 colour: Wash(r: 0.984, g: 0.831, b: 0.404), strength: 0.44)
        softGlow(p, cx: cx + rx * 0.46, cy: cy + ry * 0.44, radius: rx * 1.10,
                 colour: pitch, strength: 0.60)
    }

    var upper: [CGPoint] = []
    var lower: [CGPoint] = []
    let pw = rx * 0.74, ph = ry * 0.25
    for k in 0...44 {
        let t = Double(k) / 44.0
        let sw = pow(sin(.pi * t), 0.34)
        upper.append(pt(cx - pw + 2 * pw * t, cy - ph * sw))
        lower.append(pt(cx - pw + 2 * pw * t, cy + ph * sw))
    }
    p.shape(upper + lower.reversed(), Wash(r: 0.012, g: 0.012, b: 0.016))
    pen(p, upper, weight: 3.0, colour: Wash(r: 0.518, g: 0.400, b: 0.157).al(0.34),
        wobble: 0.3, taper: true, seed: seed &+ 41)

    let limbal = ringPts(cx: cx, cy: cy, rx: rx * 0.99, ry: ry * 0.99, steps: 60)
    pen(p, limbal + [limbal[0]], weight: rx * 0.13,
        colour: Wash(r: 0.055, g: 0.039, b: 0.024).al(0.80), wobble: 0.7,
        taper: false, seed: seed &+ 51)
    var lit: [CGPoint] = []
    var a = light - 1.34
    while a <= light + 1.20 {
        lit.append(pt(cx + cos(a) * rx * 0.86, cy + sin(a) * ry * 0.86))
        a += 0.05
    }
    penBroken(p, lit, weight: rx * 0.075, colour: moonBeam.al(0.40),
              pieces: 3, gap: 0.06, wobble: 0.6, seed: seed &+ 53)

    p.inside(domePath) {
        var wet = Spark(seed &+ 67)
        for k in 0..<5 {
            let off = Double(k) * 0.11
            var streak: [CGPoint] = []
            var b = light - 0.92 + off
            while b <= light + 0.30 + off {
                streak.append(pt(cx + cos(b) * rx * (0.60 - Double(k) * 0.07),
                                 cy + sin(b) * ry * (0.60 - Double(k) * 0.07)))
                b += 0.06
            }
            pen(p, streak, weight: wet.r(2.2, 5.4), colour: moonBeam.al(wet.r(0.06, 0.16)),
                wobble: 0.5, taper: true, seed: wet.next())
        }
    }

    p.shape(lump(cx: cx - rx * 0.40, cy: cy - ry * 0.42, rx: rx * 0.20, ry: ry * 0.16,
                 rough: 0.08, steps: 22, seed: seed &+ 71),
            Wash(r: 1.0, g: 1.0, b: 0.980).al(0.94))
    p.shape(lump(cx: cx - rx * 0.30, cy: cy - ry * 0.30, rx: rx * 0.34, ry: ry * 0.28,
                 rough: 0.12, steps: 24, seed: seed &+ 73),
            moonBeam.al(0.16))
    p.shape(lump(cx: cx + rx * 0.36, cy: cy + ry * 0.40, rx: rx * 0.11, ry: ry * 0.09,
                 rough: 0.08, steps: 18, seed: seed &+ 75),
            moonBeam.al(0.20))

    var brow: [CGPoint] = []
    a = light - 1.52
    while a <= light + 1.42 {
        brow.append(pt(cx + cos(a) * rx * 1.10, cy + sin(a) * ry * 1.12))
        a += 0.05
    }
    penBroken(p, brow, weight: 8.0, colour: pitch.al(0.44), pieces: 4, gap: 0.10,
              wobble: 1.1, seed: seed &+ 81)
    var lid: [CGPoint] = []
    a = light + 1.62
    while a <= light + 4.42 {
        lid.append(pt(cx + cos(a) * rx * 1.06, cy + sin(a) * ry * 1.08))
        a += 0.05
    }
    penBroken(p, lid, weight: 10.0, colour: pitch.al(0.66), pieces: 3, gap: 0.06,
              wobble: 1.3, seed: seed &+ 83)
}

func buildIcon(dir: String) {
    let held = sheetScale
    sheetScale = 1.0
    let p = Sheet(1024, 1024)
    p.floodAll(Wash(r: 0.010, g: 0.014, b: 0.027))
    p.flipTopDown()
    let light = 3.80
    p.light = light

    if let g = CGGradient(colorsSpace: rgbSpace,
                          colors: [cg(Wash(r: 0.153, g: 0.208, b: 0.310)),
                                   cg(Wash(r: 0.063, g: 0.098, b: 0.169)),
                                   cg(Wash(r: 0.016, g: 0.031, b: 0.059)),
                                   cg(Wash(r: 0.002, g: 0.006, b: 0.014))] as CFArray,
                          locations: [0, 0.17, 0.48, 1]) {
        p.ctx.drawRadialGradient(g, startCenter: CGPoint(x: 46, y: 26), startRadius: 0,
                                 endCenter: CGPoint(x: 46, y: 26), endRadius: 1210,
                                 options: [.drawsAfterEndLocation])
    }

    var rng = Spark(hashSeed("night-chorus-calling-treefrog"))
    for _ in 0..<3600 {
        let x = rng.d() * 1024, y = rng.d() * 1024
        let far = min(1.0, ((x - 70) * (x - 70) + (y - 44) * (y - 44)).squareRoot() / 1120)
        p.dot(x, y, rng.r(0.5, 2.0),
              Wash(r: 0.898, g: 0.937, b: 1.0).al(rng.r(0.006, 0.050) * (0.32 + far)))
    }

    func stem(_ control: [CGPoint], thick: Double, tone: Wash, seed: UInt64) {
        let spine = resample(curveThrough(control, closed: false, steps: 10), count: 90)
        var upper: [CGPoint] = []
        var lower: [CGPoint] = []
        var wob = Spark(seed)
        for (i, q) in spine.enumerated() {
            let t = Double(i) / Double(spine.count - 1)
            let w = thick * (1.0 - t * 0.62) + wob.r(-1.4, 1.4)
            upper.append(pt(Double(q.x) - w, Double(q.y) - w * 0.18))
            lower.append(pt(Double(q.x) + w, Double(q.y) + w * 0.18))
        }
        let form = upper + lower.reversed()
        p.shape(form, tone)
        for run in rimRuns(form, light: light, threshold: 0.44) {
            penBroken(p, run, weight: 3.2, colour: moonBeam.al(0.16), pieces: 4,
                      gap: 0.16, wobble: 0.8, seed: seed &+ 7)
        }
    }

    stem([pt(1006, 1080), pt(966, 830), pt(944, 560), pt(936, 300), pt(940, 40)],
         thick: 16, tone: Wash(r: 0.031, g: 0.043, b: 0.063), seed: 3101)
    stem([pt(838, 1000), pt(820, 800), pt(818, 600), pt(830, 400)],
         thick: 9, tone: Wash(r: 0.024, g: 0.035, b: 0.055), seed: 3111)
    stem([pt(40, 1060), pt(24, 900), pt(30, 740), pt(52, 600)],
         thick: 11, tone: Wash(r: 0.027, g: 0.039, b: 0.059), seed: 3121)

    let leafEdge = curveThrough([pt(-160, 826), pt(-52, 800), pt(28, 768),
                                 pt(86, 700), pt(154, 676), pt(212, 722),
                                 pt(238, 800), pt(322, 852), pt(452, 882),
                                 pt(612, 902), pt(792, 918), pt(966, 930),
                                 pt(1180, 942)], closed: false, steps: 12)
    let leaf = leafEdge + [pt(1180, 1200), pt(-160, 1200)]
    let leafPath = pathOf(leaf)

    sculpt(p, leaf, base: Wash(r: 0.216, g: 0.290, b: 0.208), light: light,
           hotAt: 0.92, seed: 2201, bands: 96, grainCount: 3200, grainLen: 30,
           grainWeight: 2.2, falloff: 2.35, ceiling: 0.70, floorLevel: 0.03,
           rim: false)

    p.inside(leafPath) {
        softGlow(p, cx: 120, cy: 760, radius: 520,
                 colour: Wash(r: 0.678, g: 0.784, b: 0.694), strength: 0.20)
        softGlow(p, cx: 860, cy: 1080, radius: 640,
                 colour: Wash(r: 0.004, g: 0.008, b: 0.018), strength: 0.62)
        softGlow(p, cx: 500, cy: 1180, radius: 560,
                 colour: Wash(r: 0.004, g: 0.008, b: 0.018), strength: 0.46)
    }

    let midrib = curveThrough([pt(-170, 1052), pt(60, 1002), pt(320, 966),
                               pt(600, 962), pt(880, 984), pt(1190, 1024)],
                              closed: false, steps: 12)
    p.inside(leafPath) {
        var vn = Spark(2301)
        for k in 0..<13 {
            let t = 0.03 + Double(k) * 0.076
            let i = min(midrib.count - 2, Int(t * Double(midrib.count - 1)))
            let bx = Double(midrib[i].x), by = Double(midrib[i].y)
            let up = curveThrough([pt(bx, by),
                                   pt(bx - 42 + vn.r(-16, 16), by - 52),
                                   pt(bx - 96 + vn.r(-20, 20), by - 112)],
                                  closed: false, steps: 8)
            penBroken(p, up, weight: vn.r(3.4, 6.2),
                      colour: pitch.al(vn.r(0.24, 0.44)), pieces: 3, gap: 0.08,
                      wobble: 1.0, seed: vn.next())
            penBroken(p, up.map { pt(Double($0.x) - 6, Double($0.y) - 7) },
                      weight: vn.r(1.8, 3.2), colour: moonBeam.al(vn.r(0.08, 0.20)),
                      pieces: 4, gap: 0.14, wobble: 0.8, seed: vn.next())
            let down = curveThrough([pt(bx, by),
                                     pt(bx + 44 + vn.r(-16, 16), by + 62),
                                     pt(bx + 104 + vn.r(-20, 20), by + 140)],
                                    closed: false, steps: 8)
            penBroken(p, down, weight: vn.r(3.0, 5.6),
                      colour: pitch.al(vn.r(0.20, 0.38)), pieces: 3, gap: 0.10,
                      wobble: 1.0, seed: vn.next())
        }
        penBroken(p, midrib.map { pt(Double($0.x) + 9, Double($0.y) + 11) },
                  weight: 15.0, colour: pitch.al(0.62), pieces: 3, gap: 0.05,
                  wobble: 1.4, seed: 2331)
        penBroken(p, midrib, weight: 11.0,
                  colour: Wash(r: 0.482, g: 0.573, b: 0.435).al(0.46), pieces: 3,
                  gap: 0.05, wobble: 1.2, seed: 2333)
        penBroken(p, midrib.map { pt(Double($0.x) - 8, Double($0.y) - 9) },
                  weight: 5.4, colour: moonBeam.al(0.26), pieces: 4, gap: 0.10,
                  wobble: 1.0, seed: 2335)
    }

    var curlShade = Spark(2401)
    p.inside(leafPath) {
        for k in 0..<6 {
            let step = 44.0 + Double(k) * 22.0
            let band = curveThrough([pt(28 + step * 0.3, 768 + step * 0.86),
                                     pt(90 + step * 0.3, 704 + step * 0.92),
                                     pt(156 + step * 0.26, 682 + step * 0.94),
                                     pt(214 + step * 0.22, 728 + step * 0.90),
                                     pt(240 + step * 0.2, 804 + step * 0.86)],
                                    closed: false, steps: 8)
            penBroken(p, band, weight: curlShade.r(16, 26),
                      colour: pitch.al(0.16), pieces: 2, gap: 0.03, wobble: 1.6,
                      seed: curlShade.next())
        }
    }

    for run in rimRuns(leaf, light: light, threshold: 0.20) {
        penBroken(p, run, weight: 8.2, colour: Wash(r: 0.792, g: 0.878, b: 0.929).al(0.60),
                  pieces: 3, gap: 0.07, wobble: 1.1, seed: 2411)
        penBroken(p, run.map { pt(Double($0.x) + 7, Double($0.y) + 8) }, weight: 4.0,
                  colour: moonBeam.al(0.22), pieces: 4, gap: 0.13, wobble: 0.8, seed: 2413)
    }

    var wetLeaf = Spark(2501)
    p.inside(leafPath) {
        for _ in 0..<26 {
            let x = wetLeaf.r(-60, 1080)
            let y = wetLeaf.r(880, 1180)
            let len = wetLeaf.r(60, 220)
            let dir = 2.98 + wetLeaf.r(-0.16, 0.16)
            pen(p, [pt(x, y), pt(x + cos(dir) * len, y + sin(dir) * len * 0.5)],
                weight: wetLeaf.r(2.4, 7.0), colour: moonBeam.al(wetLeaf.r(0.05, 0.16)),
                wobble: 1.0, taper: true, seed: wetLeaf.next())
        }
        for _ in 0..<15 {
            let x = wetLeaf.r(-40, 1060)
            let y = wetLeaf.r(940, 1180)
            let rad = wetLeaf.r(5, 14)
            p.shape(lump(cx: x, cy: y, rx: rad, ry: rad * 0.86, rough: 0.10,
                         steps: 18, seed: wetLeaf.next()),
                    Wash(r: 0.416, g: 0.518, b: 0.451).al(0.30))
            p.shape(lump(cx: x + rad * 0.5, cy: y + rad * 0.5, rx: rad * 0.7,
                         ry: rad * 0.6, rough: 0.10, steps: 16, seed: wetLeaf.next()),
                    pitch.al(0.34))
            p.dot(x - rad * 0.34, y - rad * 0.36, rad * 0.34,
                  Wash(r: 0.965, g: 0.984, b: 1.0).al(0.78))
        }
    }

    var top: [CGPoint] = []
    top += curveThrough([pt(124, 406), pt(128, 356), pt(148, 320),
                         pt(180, 296), pt(206, 284)], closed: false, steps: 10)
    var ea = 3.34
    while ea <= 6.18 {
        top.append(pt(300 + cos(ea) * 90, 296 + sin(ea) * 84))
        ea += 0.05
    }
    top += curveThrough([pt(390, 286), pt(414, 304), pt(454, 312), pt(508, 292),
                         pt(566, 258), pt(624, 236), pt(686, 240), pt(744, 264),
                         pt(796, 288), pt(828, 306)],
                        closed: false, steps: 9)
    top += curveThrough([pt(828, 318), pt(870, 306), pt(916, 286), pt(958, 262),
                         pt(984, 244), pt(994, 236)], closed: false, steps: 7)
    top += curveThrough([pt(994, 236), pt(1006, 268), pt(1024, 318), pt(1046, 382),
                         pt(1076, 452), pt(1122, 542)], closed: false, steps: 7)
    top += [pt(1178, 656), pt(1150, 744), pt(1078, 758)]
    top += curveThrough([pt(1078, 758), pt(1004, 742), pt(936, 710), pt(882, 668),
                         pt(846, 618), pt(828, 566), pt(820, 518)],
                        closed: false, steps: 8)
    top += curveThrough([pt(820, 518), pt(790, 528), pt(760, 556), pt(734, 594),
                         pt(712, 640), pt(698, 692), pt(682, 746), pt(664, 796),
                         pt(650, 832)], closed: false, steps: 8)

    let nearSpec: [(Double, Double, Double, Double)] = [
        (1.28, 76, 17, 26), (1.90, 88, 18, 29),
        (2.48, 94, 17, 28), (3.00, 84, 15, 25)
    ]
    top += curveThrough([pt(650, 832), pt(642, 848), pt(634, 858)],
                        closed: false, steps: 6)
    top += digits(cx: 606, cy: 860, spread: 32, webR: 27, spec: nearSpec, side: -1)
    top += curveThrough([pt(550, 830), pt(562, 786), pt(578, 728), pt(590, 668),
                         pt(598, 612), pt(596, 560)], closed: false, steps: 8)
    let sacRun = curveThrough([pt(596, 560), pt(578, 608), pt(560, 668), pt(528, 736),
                               pt(474, 798), pt(400, 842), pt(316, 856), pt(232, 838),
                               pt(164, 794), pt(122, 726), pt(106, 646), pt(110, 566),
                               pt(110, 496), pt(116, 448), pt(124, 406)],
                              closed: false, steps: 9)
    top += sacRun

    let frog = top
    let frogPath = pathOf(frog)

    var halo = Spark(4301)
    p.inside(leafPath) {
        for k in 0..<8 {
            let spread = 30.0 + Double(k) * 26.0
            let ghost = frog.map { q -> CGPoint in
                pt(Double(q.x) + spread * 0.60 + halo.r(-5, 5),
                   Double(q.y) + spread * 0.72 + halo.r(-5, 5))
            }
            p.shape(ghost, Wash(r: 0.003, g: 0.006, b: 0.014).al(0.17))
        }
    }

    let hindSpec: [(Double, Double, Double, Double)] = [
        (1.94, 104, 16, 25), (2.46, 122, 17, 27),
        (2.92, 108, 15, 24), (3.32, 84, 13, 21)
    ]
    var hindFoot: [CGPoint] = [pt(1024, 738), pt(982, 762), pt(944, 782)]
    hindFoot += digits(cx: 918, cy: 796, spread: 30, webR: 25, spec: hindSpec, side: -1)
    hindFoot += [pt(888, 748), pt(944, 716), pt(1010, 700)]
    sculpt(p, hindFoot, base: Wash(r: 0.310, g: 0.341, b: 0.278), light: light,
           hotAt: 0.88, seed: 4501, bands: 48, grainCount: 520, grainLen: 20,
           grainWeight: 1.8, falloff: 3.1, ceiling: 0.52, floorLevel: 0.02, rim: false)
    padSheen(p, cx: 918, cy: 796, spread: 30, spec: hindSpec, light: light,
             value: 0.72, seed: 4511)
    for run in rimRuns(hindFoot, light: light, threshold: 0.38) {
        penBroken(p, run, weight: 5.0, colour: moonBeam.al(0.34), pieces: 4,
                  gap: 0.13, wobble: 0.9, seed: 4521)
    }

    let farSpec: [(Double, Double, Double, Double)] = [
        (1.62, 58, 13, 21), (2.24, 70, 14, 22), (2.86, 60, 12, 20)
    ]
    var farHand: [CGPoint] = [pt(268, 700), pt(250, 748), pt(236, 792), pt(226, 820)]
    farHand += digits(cx: 204, cy: 838, spread: 26, webR: 22, spec: farSpec, side: -1)
    farHand += [pt(158, 812), pt(178, 760), pt(210, 706)]
    sculpt(p, farHand, base: Wash(r: 0.259, g: 0.290, b: 0.239), light: light,
           hotAt: 0.90, seed: 4401, bands: 44, grainCount: 320, grainLen: 22,
           grainWeight: 1.8, falloff: 3.0, ceiling: 0.40, floorLevel: 0.02, rim: false)
    padSheen(p, cx: 204, cy: 838, spread: 26, spec: farSpec, light: light,
             value: 0.34, seed: 4411)
    for run in rimRuns(farHand, light: light, threshold: 0.40) {
        penBroken(p, run, weight: 4.4, colour: moonBeam.al(0.26), pieces: 4,
                  gap: 0.14, wobble: 0.9, seed: 4421)
    }

    let skin = Wash(r: 0.404, g: 0.443, b: 0.361)
    sculpt(p, frog, base: skin, light: light, hotAt: 0.86, seed: 5001,
           bands: 122, grainCount: 8400, grainLen: 18, grainWeight: 1.8,
           falloff: 3.95, ceiling: 0.92, floorLevel: 0.05, rim: false)
    formPass(p, frog, light: light, inset: 470, shade: pitch,
             glow: Wash(r: 0.831, g: 0.898, b: 0.965), seed: 5011)

    p.inside(frogPath) {
        softGlow(p, cx: 232, cy: 344, radius: 330,
                 colour: Wash(r: 0.812, g: 0.855, b: 0.749), strength: 0.30)
        softGlow(p, cx: 400, cy: 288, radius: 360,
                 colour: Wash(r: 0.780, g: 0.827, b: 0.722), strength: 0.22)
        softGlow(p, cx: 636, cy: 268, radius: 340,
                 colour: Wash(r: 0.729, g: 0.788, b: 0.706), strength: 0.20)
        softGlow(p, cx: 962, cy: 278, radius: 250,
                 colour: Wash(r: 0.706, g: 0.761, b: 0.714), strength: 0.26)
        softGlow(p, cx: 1000, cy: 600, radius: 470,
                 colour: Wash(r: 0.004, g: 0.008, b: 0.020), strength: 0.62, bias: 0.12)
        softGlow(p, cx: 880, cy: 860, radius: 420,
                 colour: Wash(r: 0.004, g: 0.008, b: 0.020), strength: 0.50)
        softGlow(p, cx: 604, cy: 826, radius: 230,
                 colour: Wash(r: 0.573, g: 0.620, b: 0.529), strength: 0.32)
        softGlow(p, cx: 620, cy: 470, radius: 420,
                 colour: Wash(r: 0.006, g: 0.012, b: 0.026), strength: 0.44)
        softGlow(p, cx: 1050, cy: 380, radius: 380,
                 colour: Wash(r: 0.006, g: 0.012, b: 0.026), strength: 0.40)
    }

    var wart = Spark(5201)
    p.inside(frogPath) {
        for _ in 0..<5200 {
            let x = wart.r(90, 1140)
            let y = wart.r(230, 1000)
            let rad = wart.r(2.4, 8.6)
            let lam = ((x - 560) * cos(light) + (y - 560) * sin(light)) / 620
            let sun = max(0.0, min(1.0, 0.5 + 0.62 * lam))
            p.shape(lump(cx: x + cos(light + .pi) * rad * 0.6,
                         cy: y + sin(light + .pi) * rad * 0.6,
                         rx: rad * 1.02, ry: rad * 0.9, rough: 0.16, steps: 12,
                         seed: wart.next()),
                    pitch.al(wart.r(0.10, 0.34) * (0.30 + 0.70 * sun)))
            p.shape(lump(cx: x, cy: y, rx: rad * 0.86, ry: rad * 0.76, rough: 0.16,
                         steps: 12, seed: wart.next()),
                    skin.mix(warmLit, wart.r(0.18, 0.62)).al(wart.r(0.10, 0.40) * sun))
        }
    }

    var mottle = Spark(5301)
    p.inside(frogPath) {
        for _ in 0..<340 {
            let x = mottle.r(200, 1080)
            let y = mottle.r(240, 760)
            let rad = mottle.r(22, 78)
            var blot: [CGPoint] = []
            let lobes = mottle.r(2.4, 4.4)
            let ph = mottle.r(0, 6.283)
            for k in 0..<30 {
                let a = Double(k) / 30.0 * 6.283185
                let rr = rad * (0.78 + 0.34 * sin(a * lobes + ph))
                blot.append(pt(x + cos(a) * rr, y + sin(a) * rr * 0.74))
            }
            p.shape(blot, (mottle.odds(0.62) ? Wash(r: 0.157, g: 0.184, b: 0.145)
                           : Wash(r: 0.612, g: 0.643, b: 0.541))
                        .al(mottle.r(0.05, 0.16)))
        }
    }

    let dorsal = curveThrough([pt(462, 330), pt(528, 300), pt(586, 320), pt(646, 292),
                               pt(714, 308), pt(766, 350), pt(792, 400), pt(756, 438),
                               pt(692, 424), pt(626, 448), pt(556, 424), pt(500, 384)],
                              closed: true, steps: 11)
    p.inside(frogPath) {
        for k in 0..<4 {
            let sp = 1.0 + Double(k) * 0.055
            let ring = dorsal.map { q -> CGPoint in
                pt(626 + (Double(q.x) - 626) * sp, 372 + (Double(q.y) - 372) * sp)
            }
            p.shape(ring, Wash(r: 0.129, g: 0.153, b: 0.118).al(0.11))
        }
        for run in rimRuns(dorsal, light: light, threshold: 0.30) {
            penBroken(p, run, weight: 4.4, colour: Wash(r: 0.729, g: 0.769, b: 0.667).al(0.22),
                      pieces: 4, gap: 0.18, wobble: 2.0, seed: 5411)
        }
    }

    var backWet = Spark(5501)
    p.inside(frogPath) {
        for k in 0..<13 {
            let off = Double(k) * 14.0
            let streak = curveThrough([pt(378 + off * 0.4, 296 + off),
                                       pt(470 + off * 0.4, 262 + off),
                                       pt(570 + off * 0.4, 244 + off),
                                       pt(668 + off * 0.4, 248 + off),
                                       pt(760 + off * 0.4, 272 + off),
                                       pt(852 + off * 0.4, 300 + off)],
                                      closed: false, steps: 9)
            penBroken(p, streak, weight: backWet.r(3.0, 9.0),
                      colour: moonBeam.al(backWet.r(0.07, 0.24)), pieces: 3,
                      gap: 0.18, wobble: 1.3, seed: backWet.next())
        }
        for k in 0..<5 {
            let off = Double(k) * 17.0
            let streak = curveThrough([pt(206 + off * 0.3, 322 + off),
                                       pt(258 + off * 0.3, 366 + off),
                                       pt(322 + off * 0.3, 396 + off)],
                                      closed: false, steps: 9)
            penBroken(p, streak, weight: backWet.r(2.4, 6.0),
                      colour: moonBeam.al(backWet.r(0.06, 0.18)), pieces: 3,
                      gap: 0.20, wobble: 1.1, seed: backWet.next())
        }
    }

    let creaseControl: [CGPoint] = [pt(130, 438), pt(170, 472), pt(232, 500),
                                    pt(312, 522), pt(404, 540), pt(496, 554),
                                    pt(568, 562), pt(596, 566)]
    let crease = curveThrough(creaseControl, closed: false, steps: 10)
    var sacShape: [CGPoint] = sacRun
    sacShape.removeLast()
    sacShape += crease.reversed()
    let sacPath = pathOf(sacShape)

    let sacTone = Wash(r: 0.522, g: 0.529, b: 0.416)
    let sacCX = 332.0, sacCY = 652.0, sacRX = 236.0, sacRY = 216.0
    p.inside(sacPath) {
        p.shape(sacShape, sacTone.mix(pitch, 0.30))
        if let g = CGGradient(colorsSpace: rgbSpace,
                              colors: [cg(litBy(sacTone, 0.95)),
                                       cg(litBy(sacTone, 0.70)),
                                       cg(litBy(sacTone, 0.34)),
                                       cg(litBy(sacTone, 0.11)),
                                       cg(litBy(sacTone, 0.05))] as CFArray,
                              locations: [0, 0.22, 0.52, 0.80, 1]) {
            p.ctx.drawRadialGradient(
                g, startCenter: CGPoint(x: sacCX + cos(light) * sacRX * 0.54,
                                        y: sacCY + sin(light) * sacRY * 0.56),
                startRadius: 0,
                endCenter: CGPoint(x: sacCX + cos(light) * sacRX * 0.10,
                                   y: sacCY + sin(light) * sacRY * 0.10),
                endRadius: CGFloat(sacRX * 1.36),
                options: [.drawsAfterEndLocation])
        }
        var glowArc: [CGPoint] = []
        var ga = light + 2.30
        while ga <= light + 4.16 {
            glowArc.append(pt(sacCX + cos(ga) * sacRX * 0.93,
                              sacCY + sin(ga) * sacRY * 0.93))
            ga += 0.05
        }
        pen(p, glowArc, weight: 70, colour: Wash(r: 0.804, g: 0.729, b: 0.416).al(0.13),
            wobble: 0.4, taper: true, seed: 6091)
        pen(p, glowArc, weight: 30, colour: Wash(r: 0.902, g: 0.831, b: 0.518).al(0.17),
            wobble: 0.3, taper: true, seed: 6093)

        var band = Spark(6101)
        for k in 0..<26 {
            let t = 0.16 + Double(k) * 0.032
            var arc: [CGPoint] = []
            var a = light - 2.05
            while a <= light + 2.05 {
                arc.append(pt(sacCX + cos(light) * sacRX * (1.0 - t) * 0.42
                              + cos(a) * sacRX * t,
                              sacCY + sin(light) * sacRY * (1.0 - t) * 0.42
                              + sin(a) * sacRY * t))
                a += 0.06
            }
            penBroken(p, arc, weight: band.r(1.2, 3.4),
                      colour: (band.odds(0.5) ? warmLit : pitch).al(band.r(0.04, 0.13)),
                      pieces: 4, gap: 0.18, wobble: 0.9, seed: band.next())
        }
        for _ in 0..<900 {
            let a = band.r(0, 6.283185)
            let t0 = band.r(0.62, 0.88)
            let t1 = t0 + band.r(0.06, 0.16)
            let lam = max(0.0, cos(a - light))
            pen(p, [pt(sacCX + cos(a) * sacRX * t0, sacCY + sin(a) * sacRY * t0),
                    pt(sacCX + cos(a) * sacRX * t1, sacCY + sin(a) * sacRY * t1)],
                weight: band.r(0.9, 2.2),
                colour: (band.odds(0.14 + 0.72 * lam) ? warmLit : pitch)
                    .al(band.r(0.04, 0.16)),
                wobble: 0.3, taper: true, seed: band.next())
        }

        let hx = sacCX + cos(light) * sacRX * 0.50
        let hy = sacCY + sin(light) * sacRY * 0.52
        p.shape(lump(cx: hx, cy: hy, rx: 62, ry: 40, rough: 0.10, steps: 34,
                     seed: 6201), Wash(r: 0.925, g: 0.941, b: 0.906).al(0.20))
        p.shape(lump(cx: hx - 7, cy: hy - 7, rx: 35, ry: 21, rough: 0.12, steps: 28,
                     seed: 6203), Wash(r: 0.976, g: 0.984, b: 0.961).al(0.36))
        p.shape(lump(cx: hx - 12, cy: hy - 11, rx: 17, ry: 10, rough: 0.10, steps: 24,
                     seed: 6205), Wash(r: 1.0, g: 1.0, b: 0.996).al(0.94))
        p.shape(lump(cx: hx + 34, cy: hy + 24, rx: 9, ry: 6, rough: 0.14, steps: 16,
                     seed: 6209), Wash(r: 1.0, g: 1.0, b: 0.992).al(0.52))
        p.shape(lump(cx: sacCX + 22, cy: sacCY + 42, rx: 30, ry: 17, rough: 0.16,
                     steps: 20, seed: 6207),
                Wash(r: 0.937, g: 0.953, b: 0.918).al(0.13))
        var occl = Spark(6231)
        for k in 0..<6 {
            let step = 16.0 + Double(k) * 26.0
            pen(p, crease.map { pt(Double($0.x) + step * 0.34, Double($0.y) + step) },
                weight: occl.r(58, 96), colour: pitch.al(0.042), wobble: 1.6,
                taper: true, seed: occl.next())
        }
    }

    var farLip: [CGPoint] = []
    var fa = light + 2.02
    while fa <= light + 4.34 {
        farLip.append(pt(sacCX + cos(fa) * sacRX * 0.985,
                         sacCY + sin(fa) * sacRY * 0.985))
        fa += 0.04
    }
    penBroken(p, farLip, weight: 8.0, colour: Wash(r: 0.816, g: 0.757, b: 0.478).al(0.34),
              pieces: 3, gap: 0.10, wobble: 1.0, seed: 6311)

    p.inside(frogPath) {
        var chin = Spark(6401)
        for k in 0..<4 {
            let step = Double(k) * 13.0
            penBroken(p, crease.map { pt(Double($0.x) - step * 0.5, Double($0.y) - step) },
                      weight: chin.r(9.0, 17.0), colour: pitch.al(chin.r(0.09, 0.19)),
                      pieces: 3, gap: 0.14, wobble: 2.2, seed: chin.next())
        }
    }

    let mouth = curveThrough([pt(126, 412), pt(168, 428), pt(234, 442), pt(310, 448),
                              pt(378, 438), pt(424, 418), pt(444, 396)],
                             closed: false, steps: 11)
    p.inside(frogPath) {
        penBroken(p, mouth.map { pt(Double($0.x) + 7, Double($0.y) + 8) }, weight: 16.0,
                  colour: pitch.al(0.80), pieces: 2, gap: 0.03, wobble: 1.0, seed: 6501)
        penBroken(p, mouth.map { pt(Double($0.x) - 9, Double($0.y) - 11) }, weight: 7.4,
                  colour: moonBeam.al(0.40), pieces: 3, gap: 0.07, wobble: 0.9, seed: 6503)
    }

    p.inside(frogPath) {
        let tymp = lump(cx: 440, cy: 374, rx: 44, ry: 41, rough: 0.05, steps: 40,
                        seed: 6591)
        p.shape(tymp, Wash(r: 0.169, g: 0.180, b: 0.145).al(0.34))
        penBroken(p, tymp + [tymp[0]], weight: 5.0, colour: pitch.al(0.40),
                  pieces: 5, gap: 0.16, wobble: 1.2, seed: 6601)
        p.shape(lump(cx: 430, cy: 362, rx: 22, ry: 19, rough: 0.10, steps: 24,
                     seed: 6603), moonBeam.al(0.07))
        let band = curveThrough([pt(392, 330), pt(462, 322), pt(534, 340), pt(590, 376)],
                                closed: false, steps: 9)
        penBroken(p, band, weight: 10.0, colour: pitch.al(0.34), pieces: 3, gap: 0.10,
                  wobble: 1.4, seed: 6611)
        p.shape(lump(cx: 356, cy: 452, rx: 48, ry: 22, rough: 0.16, steps: 22,
                     seed: 6621), Wash(r: 0.792, g: 0.812, b: 0.729).al(0.26))
        p.shape(lump(cx: 172, cy: 340, rx: 13, ry: 10, rough: 0.16, steps: 16,
                     seed: 6631), pitch.al(0.80))
        p.shape(lump(cx: 168, cy: 334, rx: 17, ry: 13, rough: 0.14, steps: 18,
                     seed: 6633), moonBeam.al(0.14))
    }

    p.inside(frogPath) {
        let elbow = curveThrough([pt(576, 694), pt(614, 712), pt(658, 706)],
                                 closed: false, steps: 9)
        engrave(p, elbow, weight: 7.0, light: light, seed: 6701, glow: 0.26)
        let shoulder = curveThrough([pt(600, 588), pt(632, 620), pt(652, 664),
                                     pt(660, 712)], closed: false, steps: 9)
        penBroken(p, shoulder, weight: 9.0, colour: pitch.al(0.36), pieces: 3,
                  gap: 0.12, wobble: 1.6, seed: 6703)
        let hip = curveThrough([pt(818, 322), pt(838, 386), pt(842, 452), pt(830, 512)],
                               closed: false, steps: 9)
        engrave(p, hip, weight: 9.0, light: light, seed: 6711, glow: 0.20)
        let knee = curveThrough([pt(946, 288), pt(986, 342), pt(1008, 414), pt(1010, 490)],
                                closed: false, steps: 9)
        engrave(p, knee, weight: 10.0, light: light, seed: 6721, glow: 0.36)
        var bars = Spark(6741)
        let barSpec: [[CGPoint]] = [
            [pt(858, 328), pt(888, 396), pt(896, 470)],
            [pt(930, 320), pt(962, 396), pt(970, 470)],
            [pt(1010, 470), pt(1050, 548), pt(1062, 622)],
            [pt(1078, 550), pt(1118, 626), pt(1130, 700)],
            [pt(628, 258), pt(646, 320), pt(650, 384)],
            [pt(716, 266), pt(742, 328), pt(752, 394)]
        ]
        for spec in barSpec {
            let arc = curveThrough(spec, closed: false, steps: 10)
            penBroken(p, arc, weight: bars.r(20, 34), colour: pitch.al(bars.r(0.20, 0.34)),
                      pieces: 2, gap: 0.05, wobble: 3.0, seed: bars.next())
            penBroken(p, arc.map { pt(Double($0.x) - 16, Double($0.y) - 19) },
                      weight: bars.r(6, 11), colour: moonBeam.al(bars.r(0.07, 0.15)),
                      pieces: 3, gap: 0.14, wobble: 2.0, seed: bars.next())
        }
        let flank = curveThrough([pt(482, 372), pt(556, 430), pt(636, 476), pt(706, 502)],
                                 closed: false, steps: 9)
        penBroken(p, flank, weight: 6.0, colour: pitch.al(0.22), pieces: 5, gap: 0.22,
                  wobble: 2.2, seed: 6731)
    }

    padSheen(p, cx: 606, cy: 860, spread: 32, spec: nearSpec, light: light,
             value: 1.0, seed: 6801)

    p.inside(frogPath) {
        var arm = Spark(6901)
        for _ in 0..<900 {
            let x = arm.r(530, 700)
            let y = arm.r(580, 900)
            let dir = arm.r(1.3, 2.2)
            let len = arm.r(10, 34)
            pen(p, [pt(x, y), pt(x + cos(dir) * len, y + sin(dir) * len)],
                weight: arm.r(1.0, 2.8),
                colour: (arm.odds(0.42) ? warmLit : pitch).al(arm.r(0.06, 0.24)),
                wobble: 0.4, taper: true, seed: arm.next())
        }
    }

    frogEye(p, cx: 300, cy: 296, rx: 88, ry: 82, light: light, seed: 9101)

    for run in rimRuns(frog, light: light, threshold: 0.50) {
        penBroken(p, run, weight: 7.8, colour: Wash(r: 0.914, g: 0.945, b: 1.0).al(0.74),
                  pieces: 3, gap: 0.06, wobble: 1.0, seed: 7401)
        penBroken(p, run.map { pt(Double($0.x) + 8, Double($0.y) + 9) }, weight: 3.6,
                  colour: Wash(r: 0.957, g: 0.965, b: 0.906).al(0.26),
                  pieces: 4, gap: 0.13, wobble: 0.8, seed: 7411)
    }
    for run in rimRuns(frog, light: light + .pi, threshold: 0.24) {
        penBroken(p, run, weight: 6.2, colour: Wash(r: 0.400, g: 0.494, b: 0.643).al(0.50),
                  pieces: 4, gap: 0.15, wobble: 1.2, seed: 7421)
    }

    if let g = CGGradient(colorsSpace: rgbSpace,
                          colors: [cg(Wash(r: 0.741, g: 0.847, b: 1.0).al(0.15)),
                                   cg(Wash(r: 0.6, g: 0.7, b: 1.0).al(0))] as CFArray,
                          locations: [0, 1]) {
        p.ctx.drawRadialGradient(g, startCenter: CGPoint(x: 96, y: 72), startRadius: 0,
                                 endCenter: CGPoint(x: 96, y: 72), endRadius: 600, options: [])
    }

    if let g = CGGradient(colorsSpace: rgbSpace,
                          colors: [cg(Wash(r: 0, g: 0, b: 0, a: 0)),
                                   cg(Wash(r: 0, g: 0, b: 0.008, a: 0.48))] as CFArray,
                          locations: [0.40, 1]) {
        p.ctx.drawRadialGradient(g, startCenter: CGPoint(x: 356, y: 388), startRadius: 0,
                                 endCenter: CGPoint(x: 356, y: 388), endRadius: 960,
                                 options: [.drawsAfterEndLocation])
    }

    p.emitPNG(dir, "AppIcon-1024")
    sheetScale = held
}
