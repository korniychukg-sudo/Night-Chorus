import Foundation
import CoreGraphics

let moonBeam = Wash(r: 0.886, g: 0.929, b: 1.000)
let warmLit = Wash(r: 0.980, g: 0.886, b: 0.686)
let pitch = Wash(r: 0.020, g: 0.027, b: 0.043)

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

func featherFan(_ p: Sheet, cx: Double, cy: Double, rx: Double, ry: Double,
                count: Int, lengthMin: Double, lengthMax: Double, light: Double,
                dark: Wash, pale: Wash, seed: UInt64) {
    var rng = Spark(seed)
    for _ in 0..<count {
        let a = rng.r(0, 6.283185)
        let t = pow(rng.d(), 0.62)
        let x = cx + cos(a) * rx * t
        let y = cy + sin(a) * ry * t
        let out = atan2((y - cy) / max(1.0, ry * 0.62), (x - cx) / max(1.0, rx * 0.62))
        let fade = max(0.0, 1.0 - pow(t, 2.6))
        let axis = ((x - cx) / rx) * cos(light) + ((y - cy) / ry) * sin(light)
        let sun = max(0.0, min(1.0, 0.5 + 0.74 * axis))
        let len = rng.r(lengthMin, lengthMax) * (0.48 + 0.86 * t)
        let bend = rng.r(-0.20, 0.20)
        let shade = rng.odds(0.05 + 0.80 * sun)
            ? pale.al(rng.r(0.05, 0.30) * fade * (0.16 + 0.94 * sun))
            : dark.al(rng.r(0.10, 0.48) * fade * (0.52 + 0.78 * (1.0 - sun)))
        pen(p, [pt(x, y),
                pt(x + cos(out + bend * 0.3) * len * 0.52,
                   y + sin(out + bend * 0.3) * len * 0.52),
                pt(x + cos(out + bend) * len, y + sin(out + bend) * len)],
            weight: rng.r(0.9, 2.7), colour: shade, wobble: 0.34, taper: true,
            seed: rng.next())
    }
}

func owlEye(_ p: Sheet, cx: Double, cy: Double, rad: Double, light: Double,
            value: Double, gaze: Double, jitter: UInt64) {
    softGlow(p, cx: cx, cy: cy + rad * 0.08, radius: rad * 2.30,
             colour: Wash(r: 0.055, g: 0.043, b: 0.035), strength: 0.80, bias: 0.14)
    p.shape(lump(cx: cx, cy: cy + rad * 0.02, rx: rad * 1.15, ry: rad * 1.20,
                 rough: 0.105, steps: 38, seed: 8801),
            Wash(r: 0.055, g: 0.043, b: 0.035).al(0.40))

    var ring = Spark(jitter &+ 11)
    for _ in 0..<280 {
        let a = ring.r(0, 6.283185)
        let r0 = rad * ring.r(1.16, 1.50)
        let len = rad * ring.r(0.18, 0.58)
        let lam = max(0.0, cos(a - light))
        pen(p, [pt(cx + cos(a) * r0 * 1.04, cy + sin(a) * r0),
                pt(cx + cos(a) * (r0 + len) * 1.04, cy + sin(a) * (r0 + len))],
            weight: ring.r(0.8, 2.5),
            colour: (ring.odds(0.20 + 0.56 * lam) ? moonBeam : pitch)
                .al(ring.r(0.10, 0.38) * (0.30 + 0.80 * value)),
            wobble: 0.3, taper: true, seed: ring.next())
    }

    let opening = lump(cx: cx, cy: cy, rx: rad, ry: rad * 0.96,
                       rough: 0.030, steps: 44, seed: 8811)
    let amber = Wash(r: 0.988, g: 0.769, b: 0.129).mix(pitch, 1.0 - value)
    sculpt(p, opening, base: amber, light: light, hotAt: 0.84, seed: 8813,
           bands: 48, grain: false, falloff: 1.70, ceiling: 0.62, floorLevel: 0.40,
           rim: false)

    var fibre = Spark(jitter &+ 29)
    p.inside(pathOf(opening)) {
        for _ in 0..<260 {
            let a = fibre.r(0, 6.283185)
            let warm = fibre.odds(0.5)
            pen(p, [pt(cx + cos(a) * rad * 0.30, cy + sin(a) * rad * 0.30),
                    pt(cx + cos(a) * rad * 1.02, cy + sin(a) * rad * 1.02)],
                weight: fibre.r(0.8, 2.3),
                colour: (warm ? Wash(r: 0.529, g: 0.361, b: 0.043).mix(pitch, 1.0 - value)
                         : Wash(r: 1.0, g: 0.949, b: 0.667).mix(pitch, 1.0 - value))
                    .al(fibre.r(0.14, 0.48) * (0.42 + 0.62 * value)),
                wobble: 0.28, taper: true, seed: fibre.next())
        }
    }

    let limbal = ringPts(cx: cx, cy: cy, rx: rad * 0.93, ry: rad * 0.89, steps: 52)
    pen(p, limbal + [limbal[0]], weight: rad * 0.17,
        colour: Wash(r: 0.204, g: 0.129, b: 0.031).mix(pitch, 1.0 - value).al(0.56),
        wobble: 0.6, taper: false, seed: 8821)
    let rimEdge = ringPts(cx: cx, cy: cy, rx: rad * 1.02, ry: rad * 0.98, steps: 56)
    pen(p, rimEdge + [rimEdge[0]], weight: rad * 0.09,
        colour: Wash(r: 0.043, g: 0.031, b: 0.024).al(0.70), wobble: 0.9,
        taper: false, seed: 8823)

    p.shape(lump(cx: cx + gaze, cy: cy + rad * 0.04, rx: rad * 0.35, ry: rad * 0.36,
                 rough: 0.038, steps: 30, seed: 8831),
            Wash(r: 0.020, g: 0.016, b: 0.012))

    var lid: [CGPoint] = []
    var a = 3.24
    while a <= 6.16 {
        lid.append(pt(cx + cos(a) * rad * 1.03, cy + sin(a) * rad * 0.99))
        a += 0.10
    }
    var back: [CGPoint] = []
    a = 6.16
    while a >= 3.24 {
        back.append(pt(cx + cos(a) * rad * 0.99, cy + sin(a) * rad * 0.97 + rad * 0.26))
        a -= 0.10
    }
    p.shape(lid + back, Wash(r: 0.063, g: 0.047, b: 0.039).al(0.42 + 0.30 * (1.0 - value)))

    p.shape(lump(cx: cx + gaze - rad * 0.19, cy: cy - rad * 0.17,
                 rx: rad * 0.14, ry: rad * 0.12, rough: 0.06, steps: 22, seed: 8841),
            Wash(r: 1.0, g: 1.0, b: 0.988).al(0.26 + 0.68 * value))
    p.shape(lump(cx: cx + gaze + rad * 0.17, cy: cy + rad * 0.19,
                 rx: rad * 0.07, ry: rad * 0.06, rough: 0.05, steps: 16, seed: 8843),
            moonBeam.al(0.10 + 0.34 * value))
}

func buildIcon(dir: String) {
    let held = sheetScale
    sheetScale = 1.0
    let p = Sheet(1024, 1024)
    p.floodAll(Wash(r: 0.012, g: 0.016, b: 0.031))
    p.flipTopDown()
    let light = 3.80
    p.light = light

    if let g = CGGradient(colorsSpace: rgbSpace,
                          colors: [cg(Wash(r: 0.157, g: 0.200, b: 0.310)),
                                   cg(Wash(r: 0.063, g: 0.086, b: 0.153)),
                                   cg(Wash(r: 0.016, g: 0.024, b: 0.047)),
                                   cg(Wash(r: 0.002, g: 0.004, b: 0.010))] as CFArray,
                          locations: [0, 0.18, 0.50, 1]) {
        p.ctx.drawRadialGradient(g, startCenter: CGPoint(x: 40, y: 20), startRadius: 0,
                                 endCenter: CGPoint(x: 40, y: 20), endRadius: 1180,
                                 options: [.drawsAfterEndLocation])
    }

    var rng = Spark(hashSeed("night-chorus-horned-owl"))
    for _ in 0..<3400 {
        let x = rng.d() * 1024, y = rng.d() * 1024
        let far = min(1.0, ((x - 76) * (x - 76) + (y - 48) * (y - 48)).squareRoot() / 1100)
        p.dot(x, y, rng.r(0.5, 2.1),
              Wash(r: 0.906, g: 0.937, b: 1.0).al(rng.r(0.006, 0.052) * (0.35 + far)))
    }

    func limb(_ control: [CGPoint], thick: Double, seed: UInt64, tone: Wash) {
        let spine = resample(curveThrough(control, closed: false, steps: 12), count: 120)
        var upper: [CGPoint] = []
        var lower: [CGPoint] = []
        var wob = Spark(seed)
        for (i, q) in spine.enumerated() {
            let t = Double(i) / Double(spine.count - 1)
            let w = thick * (1.0 - t * 0.58) * (0.90 + 0.16 * sin(t * 13 + 1.2)) + wob.r(-1.8, 1.8)
            upper.append(pt(Double(q.x) - w, Double(q.y) - w * 0.34))
            lower.append(pt(Double(q.x) + w, Double(q.y) + w * 0.34))
        }
        let form = upper + lower.reversed()
        sculpt(p, form, base: tone, light: light, hotAt: 0.88, seed: seed &+ 3,
               bands: 54, grainCount: 380, grainLen: 46, grainWeight: 2.4,
               falloff: 3.20, ceiling: 0.60, floorLevel: 0.03)
        formPass(p, form, light: light, inset: thick * 1.10,
                 shade: pitch, glow: moonBeam, seed: seed &+ 9)
    }

    limb([pt(946, 1180), pt(930, 960), pt(902, 700), pt(884, 430),
          pt(872, 180), pt(866, -140)],
         thick: 44, seed: 4101, tone: Wash(r: 0.129, g: 0.114, b: 0.102))
    limb([pt(900, 640), pt(1000, 560), pt(1096, 522), pt(1220, 508)],
         thick: 19, seed: 4131, tone: Wash(r: 0.114, g: 0.102, b: 0.094))
    limb([pt(878, 300), pt(966, 226), pt(1064, 190), pt(1200, 172)],
         thick: 15, seed: 4141, tone: Wash(r: 0.110, g: 0.098, b: 0.090))
    limb([pt(884, 402), pt(796, 372), pt(716, 386), pt(646, 428)],
         thick: 13, seed: 4151, tone: Wash(r: 0.102, g: 0.094, b: 0.086))

    let control: [CGPoint] = [
        pt(-210, 1210), pt(-206, 1000), pt(-150, 848), pt(-40, 748),
        pt(74, 682), pt(160, 646), pt(190, 618),
        pt(152, 528), pt(128, 420), pt(154, 330),
        pt(196, 262),
        pt(44, 0), pt(-60, -184), pt(110, -232),
        pt(262, 0), pt(400, 210),
        pt(474, 250),
        pt(556, 208), pt(672, 0),
        pt(800, -232), pt(960, -184),
        pt(853, 0), pt(700, 258),
        pt(748, 312), pt(776, 414), pt(762, 548), pt(706, 660),
        pt(676, 766),
        pt(730, 792), pt(866, 848), pt(1014, 920), pt(1170, 1010),
        pt(1240, 1210)
    ]
    let bird = curveThrough(control, closed: true, steps: 9)
    let birdPath = pathOf(bird)

    let headControl: [CGPoint] = [
        pt(196, 610), pt(158, 520), pt(130, 418), pt(154, 330),
        pt(216, 270), pt(312, 238), pt(432, 228), pt(556, 238),
        pt(664, 266), pt(742, 330), pt(778, 430), pt(760, 556),
        pt(700, 672), pt(586, 742), pt(444, 770), pt(310, 726)
    ]
    let headCurve = curveThrough(headControl, closed: true, steps: 10)

    let jawControl: [CGPoint] = [
        pt(778, 430), pt(760, 562), pt(702, 678), pt(590, 750), pt(446, 778),
        pt(310, 734), pt(226, 654), pt(166, 530), pt(142, 418),
        pt(-360, 418), pt(-360, 1280), pt(1400, 1280), pt(1400, 430)
    ]
    let underHead = curveThrough(jawControl, closed: true, steps: 8)

    var halo = Spark(4301)
    for k in 0..<7 {
        let spread = 26.0 + Double(k) * 24.0
        let ghost = bird.map { q -> CGPoint in
            pt(Double(q.x) + spread * 0.52 + halo.r(-4, 4),
               Double(q.y) + spread * 0.56 + halo.r(-4, 4))
        }
        p.shape(ghost, Wash(r: 0.004, g: 0.006, b: 0.014).al(0.16))
    }

    sculpt(p, bird, base: Wash(r: 0.522, g: 0.373, b: 0.220), light: light,
           hotAt: 0.85, seed: 5001, bands: 118, grainCount: 9200, grainLen: 20,
           grainWeight: 1.9, falloff: 4.05, ceiling: 0.94, floorLevel: 0.08,
           rim: false)
    formPass(p, bird, light: light, inset: 460, shade: pitch,
             glow: Wash(r: 0.812, g: 0.875, b: 0.984), seed: 5011)

    p.inside(birdPath) {
        softGlow(p, cx: 236, cy: 292, radius: 430,
                 colour: Wash(r: 0.855, g: 0.812, b: 0.729), strength: 0.16)
        softGlow(p, cx: 906, cy: 830, radius: 760,
                 colour: Wash(r: 0.004, g: 0.008, b: 0.020), strength: 0.54, bias: 0.10)
        softGlow(p, cx: 420, cy: 1090, radius: 600,
                 colour: Wash(r: 0.004, g: 0.008, b: 0.020), strength: 0.62)
        softGlow(p, cx: 20, cy: 980, radius: 560,
                 colour: Wash(r: 0.006, g: 0.010, b: 0.024), strength: 0.42)
        softGlow(p, cx: 880, cy: 462, radius: 500,
                 colour: Wash(r: 0.004, g: 0.008, b: 0.020), strength: 0.48)
    }

    var scale = Spark(5101)
    p.inside(birdPath) {
        for _ in 0..<960 {
            let x = scale.r(-140, 1200)
            let y = scale.r(690, 1160)
            let rad = scale.r(18, 58)
            let a0 = light + .pi * 0.34
            var arc: [CGPoint] = []
            for k in 0...9 {
                let a = a0 + Double(k) / 9.0 * 2.3
                arc.append(pt(x + cos(a) * rad, y + sin(a) * rad * 0.70))
            }
            pen(p, arc, weight: scale.r(1.2, 3.2),
                colour: (scale.odds(0.60) ? pitch : moonBeam).al(scale.r(0.05, 0.16)),
                wobble: 0.5, taper: true, seed: scale.next())
        }
    }

    var bar = Spark(6001)
    p.inside(birdPath) {
        for k in 0..<24 {
            let y = 828.0 + Double(k) * 26.0
            let sweep = curveThrough([pt(-160 + bar.r(-40, 40), y - 40),
                                      pt(180, y + bar.r(0, 26)),
                                      pt(520, y + bar.r(18, 52)),
                                      pt(860, y + bar.r(36, 84)),
                                      pt(1200, y + bar.r(56, 116))], closed: false, steps: 9)
            penBroken(p, sweep, weight: bar.r(6.0, 13.0),
                      colour: pitch.al(bar.r(0.34, 0.66)), pieces: 3, gap: 0.10,
                      wobble: 1.9, seed: 6100 &+ UInt64(k))
            penBroken(p, sweep.map { pt(Double($0.x) - 9, Double($0.y) - 11) },
                      weight: bar.r(2.4, 5.4), colour: moonBeam.al(bar.r(0.10, 0.30)),
                      pieces: 3, gap: 0.12, wobble: 1.4, seed: 6200 &+ UInt64(k))
        }
    }

    var bibr = Spark(5701)
    p.inside(birdPath) {
        for _ in 0..<2200 {
            let a = bibr.r(0, 6.283185)
            let rad = pow(bibr.d(), 0.58)
            let x = 424.0 + cos(a) * rad * 158
            let y = 854.0 + sin(a) * rad * 56
            let fade = max(0.0, 1.0 - rad * rad * rad)
            let dir = bibr.r(0.42, 2.72)
            let len = bibr.r(16, 50)
            let warm = (x - 424) * cos(light) + (y - 854) * sin(light)
            let bright = bibr.odds(0.58 + (warm > 0 ? 0.28 : -0.20))
            pen(p, [pt(x, y), pt(x + cos(dir) * len, y + sin(dir) * len)],
                weight: bibr.r(1.2, 3.8),
                colour: (bright ? Wash(r: 0.859, g: 0.827, b: 0.749)
                         : Wash(r: 0.180, g: 0.153, b: 0.125)).al(bibr.r(0.10, 0.40) * fade),
                wobble: 0.6, taper: true, seed: bibr.next())
        }
    }

    p.inside(birdPath) {
        p.inside(pathOf(underHead)) {
            var wide: [CGPoint] = []
            for k in 0..<7 {
                let step = 168.0 - Double(k) * 20.0
                let cast = headCurve.map { pt(Double($0.x) + step * 0.78,
                                              Double($0.y) + step * 0.86) }
                p.shape(cast, Wash(r: 0.004, g: 0.008, b: 0.018).al(0.13))
                if k == 3 { wide = cast }
            }
            crossHatch(p, pathOf(wide), depth: 1, spacing: 15.0,
                       colour: pitch.al(0.09), bound: birdPath, seed: 6701)
        }
    }

    p.inside(birdPath) {
        formPass(p, headCurve, light: light, inset: 292, shade: pitch,
                 glow: Wash(r: 0.855, g: 0.902, b: 0.988), seed: 5051)
        softGlow(p, cx: 262, cy: 388, radius: 340,
                 colour: Wash(r: 0.976, g: 0.886, b: 0.706), strength: 0.38)
        softGlow(p, cx: 358, cy: 528, radius: 300,
                 colour: Wash(r: 0.965, g: 0.867, b: 0.694), strength: 0.24)
        softGlow(p, cx: 748, cy: 566, radius: 420,
                 colour: Wash(r: 0.004, g: 0.008, b: 0.020), strength: 0.44)
        softGlow(p, cx: 800, cy: -80, radius: 460,
                 colour: Wash(r: 0.006, g: 0.010, b: 0.024), strength: 0.46)
        softGlow(p, cx: 726, cy: 356, radius: 470,
                 colour: Wash(r: 0.271, g: 0.271, b: 0.302), strength: 0.24)
        softGlow(p, cx: 774, cy: 30, radius: 340,
                 colour: Wash(r: 0.271, g: 0.290, b: 0.353), strength: 0.26)
        softGlow(p, cx: 464, cy: 228, radius: 360,
                 colour: Wash(r: 0.016, g: 0.020, b: 0.039), strength: 0.40)
        softGlow(p, cx: 210, cy: 96, radius: 360,
                 colour: Wash(r: 0.020, g: 0.024, b: 0.043), strength: 0.44)
        softGlow(p, cx: 760, cy: 40, radius: 300,
                 colour: Wash(r: 0.020, g: 0.024, b: 0.043), strength: 0.30)
    }

    p.inside(birdPath) {
        featherFan(p, cx: 412, cy: 496, rx: 336, ry: 306, count: 3000,
                   lengthMin: 20, lengthMax: 64, light: light,
                   dark: Wash(r: 0.125, g: 0.090, b: 0.063),
                   pale: Wash(r: 0.965, g: 0.863, b: 0.647), seed: 5321)
        featherFan(p, cx: 412, cy: 496, rx: 216, ry: 200, count: 1000,
                   lengthMin: 14, lengthMax: 42, light: light,
                   dark: Wash(r: 0.153, g: 0.110, b: 0.078),
                   pale: Wash(r: 0.988, g: 0.906, b: 0.714), seed: 5341)
    }

    var ruff = Spark(5351)
    p.inside(birdPath) {
        for k in 0..<4 {
            let scaleR = 0.98 + Double(k) * 0.042
            var arc: [CGPoint] = []
            var a = 0.16
            while a <= 3.00 {
                arc.append(pt(412 + cos(a) * 332 * scaleR, 496 + sin(a) * 304 * scaleR))
                a += 0.055
            }
            penBroken(p, arc, weight: ruff.r(5.0, 11.0),
                      colour: pitch.al(ruff.r(0.22, 0.46)), pieces: 5, gap: 0.17,
                      wobble: 2.6, seed: 5361 &+ UInt64(k))
        }
        var arcL: [CGPoint] = []
        var a = 3.30
        while a <= 4.34 {
            arcL.append(pt(412 + cos(a) * 328, 496 + sin(a) * 300))
            a += 0.05
        }
        penBroken(p, arcL, weight: 5.4, colour: moonBeam.al(0.24),
                  pieces: 5, gap: 0.24, wobble: 2.0, seed: 5371)
        var arcR: [CGPoint] = []
        a = 4.90
        while a <= 6.05 {
            arcR.append(pt(412 + cos(a) * 330, 496 + sin(a) * 302))
            a += 0.05
        }
        penBroken(p, arcR, weight: 6.4, colour: pitch.al(0.40),
                  pieces: 5, gap: 0.20, wobble: 2.2, seed: 5373)
    }

    let browNear = curveThrough([pt(158, 412), pt(208, 332), pt(300, 312), pt(374, 368)],
                                closed: false, steps: 11)
    engrave(p, browNear, weight: 7.4, light: light, seed: 5311, glow: 0.32)
    let browFar = curveThrough([pt(450, 384), pt(510, 328), pt(594, 332), pt(654, 402)],
                               closed: false, steps: 11)
    engrave(p, browFar, weight: 5.6, light: light, seed: 5313, glow: 0.07)

    var vee = Spark(5381)
    for _ in 0..<130 {
        let t = vee.d()
        let x = 424.0 + vee.r(-30, 30)
        let y = 362.0 + t * 156
        let dir = 1.57 + vee.r(-0.34, 0.34)
        let len = vee.r(22, 54)
        pen(p, [pt(x, y), pt(x + cos(dir) * len * 0.4, y + sin(dir) * len)],
            weight: vee.r(1.0, 2.8),
            colour: (vee.odds(0.48) ? Wash(r: 0.882, g: 0.839, b: 0.769)
                     : Wash(r: 0.157, g: 0.122, b: 0.094)).al(vee.r(0.08, 0.26)),
            wobble: 0.4, taper: true, seed: vee.next())
    }

    let bill: [CGPoint] = curveThrough([pt(406, 524), pt(448, 536), pt(462, 574),
                                        pt(440, 634), pt(414, 650), pt(408, 602),
                                        pt(392, 558)],
                                       closed: true, steps: 12)
    sculpt(p, bill, base: Wash(r: 0.137, g: 0.125, b: 0.118), light: light,
           hotAt: 0.90, seed: 5601, bands: 46, grain: false, falloff: 2.9,
           ceiling: 0.44, floorLevel: 0.02)
    pen(p, curveThrough([pt(410, 532), pt(436, 562), pt(428, 628)], closed: false, steps: 9),
        weight: 2.2, colour: warmLit.al(0.20), wobble: 0.3, taper: true, seed: 5603)
    penBroken(p, curveThrough([pt(456, 582), pt(444, 626), pt(418, 648)],
                              closed: false, steps: 9),
              weight: 5.0, colour: pitch.al(0.66), pieces: 3, gap: 0.06,
              wobble: 0.5, seed: 5605)

    owlEye(p, cx: 278, cy: 452, rad: 88, light: light, value: 1.0,
           gaze: -26.0, jitter: 9101)
    owlEye(p, cx: 552, cy: 468, rad: 88, light: light, value: 0.46,
           gaze: -26.0, jitter: 9201)

    var chin = Spark(5391)
    p.inside(birdPath) {
        for _ in 0..<620 {
            let a = chin.r(0, 6.283185)
            let t = pow(chin.d(), 0.55)
            let x = 434.0 + cos(a) * t * 142
            let y = 704.0 + sin(a) * t * 78
            let fade = max(0.0, 1.0 - t * t)
            let dir = chin.r(1.05, 2.10)
            let len = chin.r(18, 54)
            pen(p, [pt(x, y), pt(x + cos(dir) * len * 0.5, y + sin(dir) * len)],
                weight: chin.r(1.4, 3.6),
                colour: pitch.al(chin.r(0.14, 0.40) * fade),
                wobble: 0.7, taper: true, seed: chin.next())
        }
    }

    var tuft = Spark(6301)
    for _ in 0..<1500 {
        let side = tuft.odds(0.5)
        let by = tuft.r(-244, 268)
        let t = max(0.0, min(1.0, (by + 240) / 510))
        let bx = side ? tuft.r(-60 + t * 256, 110 + t * 290)
                      : tuft.r(800 - t * 244, 960 - t * 260)
        let dir = side ? tuft.r(0.88, 1.18) : tuft.r(1.96, 2.26)
        let len = tuft.r(40, 158)
        let bend = tuft.r(-0.32, 0.32)
        let bright = side ? tuft.odds(0.48) : tuft.odds(0.34)
        pen(p, [pt(bx, by),
                pt(bx - cos(dir + bend * 0.4) * len * 0.34, by - sin(dir + bend * 0.4) * len * 0.55),
                pt(bx - cos(dir + bend) * len * 0.58, by - sin(dir + bend) * len)],
            weight: tuft.r(1.3, 3.8),
            colour: (bright
                     ? (side ? Wash(r: 0.925, g: 0.878, b: 0.784).al(tuft.r(0.10, 0.34))
                        : Wash(r: 0.427, g: 0.451, b: 0.518).al(tuft.r(0.08, 0.24)))
                     : pitch.al(tuft.r(0.22, 0.60))),
            wobble: 0.9, taper: true, seed: tuft.next())
    }

    for run in rimRuns(bird, light: light, threshold: 0.56) {
        penBroken(p, run, weight: 7.4, colour: Wash(r: 0.898, g: 0.933, b: 1.0).al(0.72),
                  pieces: 3, gap: 0.07, wobble: 1.0, seed: 6401)
        penBroken(p, run.map { pt(Double($0.x) + 8, Double($0.y) + 9) }, weight: 3.6,
                  colour: Wash(r: 0.965, g: 0.933, b: 0.855).al(0.26),
                  pieces: 4, gap: 0.13, wobble: 0.7, seed: 6411)
    }
    for run in rimRuns(bird, light: light + .pi, threshold: 0.20) {
        penBroken(p, run, weight: 6.0, colour: Wash(r: 0.494, g: 0.573, b: 0.729).al(0.56),
                  pieces: 4, gap: 0.15, wobble: 1.2, seed: 6402)
    }

    if let g = CGGradient(colorsSpace: rgbSpace,
                          colors: [cg(Wash(r: 0.741, g: 0.839, b: 1.0).al(0.16)),
                                   cg(Wash(r: 0.6, g: 0.7, b: 1.0).al(0))] as CFArray,
                          locations: [0, 1]) {
        p.ctx.drawRadialGradient(g, startCenter: CGPoint(x: 108, y: 84), startRadius: 0,
                                 endCenter: CGPoint(x: 108, y: 84), endRadius: 620, options: [])
    }

    if let g = CGGradient(colorsSpace: rgbSpace,
                          colors: [cg(Wash(r: 0, g: 0, b: 0, a: 0)),
                                   cg(Wash(r: 0, g: 0, b: 0.008, a: 0.46))] as CFArray,
                          locations: [0.40, 1]) {
        p.ctx.drawRadialGradient(g, startCenter: CGPoint(x: 340, y: 372), startRadius: 0,
                                 endCenter: CGPoint(x: 340, y: 372), endRadius: 940,
                                 options: [.drawsAfterEndLocation])
    }

    p.emitPNG(dir, "AppIcon-1024")
    sheetScale = held
}
