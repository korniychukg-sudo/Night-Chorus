import Foundation
import CoreGraphics

let moonBeam = Wash(r: 0.878, g: 0.925, b: 1.000)
let pitch = Wash(r: 0.024, g: 0.031, b: 0.047)

func litBy(_ base: Wash, _ level: Double) -> Wash {
    let k = max(0.0, min(1.0, level))
    if k >= 0.50 { return base.mix(moonBeam, (k - 0.50) * 1.30) }
    return base.mix(pitch, (0.50 - k) * 1.72)
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
        let ang = atan2(Double(b.y - a.y), Double(b.x - a.x))
        if cos(ang + turn - light) > threshold { kept.append(i) }
    }
    guard !kept.isEmpty else { return [] }
    var runs: [[CGPoint]] = []
    var current: [CGPoint] = []
    var previous = -99
    for i in kept {
        if i == previous + 1 || current.isEmpty { current.append(pts[i]) }
        else { if current.count > 1 { runs.append(current) }; current = [pts[i]] }
        previous = i
    }
    if current.count > 1 { runs.append(current) }
    if let first = kept.first, let last = kept.last,
       first == 0, last == pts.count - 1, runs.count > 1 {
        let tail = runs.removeLast()
        runs[0] = tail + runs[0]
    }
    return runs
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
                    colour: (dark ? base.mix(pitch, g.r(0.20, 0.58))
                             : base.mix(moonBeam, g.r(0.08, 0.34))).al(g.r(0.14, 0.44)),
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
            p.shape(dark, shade.al(0.34))
            let tighter = crescent(outline, light: light, inset: inset * 0.52, away: true)
            if tighter.count > 3 { p.shape(tighter, shade.al(0.40)) }
            crossHatch(p, pathOf(dark), depth: 2, spacing: max(3.0, inset * 0.09),
                       colour: shade.al(0.42), bound: form, seed: seed)
        }
    }
    let lit = crescent(outline, light: light, inset: inset * 0.42, away: false)
    if lit.count > 3 {
        p.inside(form) { p.shape(lit, glow.al(0.20)) }
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


func buildIcon(dir: String) {
    let held = sheetScale
    sheetScale = 1.0
    let p = Sheet(1024, 1024)
    p.floodAll(Wash(r: 0.027, g: 0.035, b: 0.055))
    p.flipTopDown()
    let light = 3.90
    p.light = light

    if let g = CGGradient(colorsSpace: rgbSpace,
                          colors: [cg(Wash(r: 0.235, g: 0.282, b: 0.404)),
                                   cg(Wash(r: 0.075, g: 0.094, b: 0.161)),
                                   cg(Wash(r: 0.012, g: 0.016, b: 0.031))] as CFArray,
                          locations: [0, 0.40, 1]) {
        p.ctx.drawRadialGradient(g, startCenter: CGPoint(x: 150, y: 110), startRadius: 0,
                                 endCenter: CGPoint(x: 330, y: 380), endRadius: 1010,
                                 options: [.drawsAfterEndLocation])
    }

    var rng = Spark(hashSeed("night-chorus-owl-2"))
    for _ in 0..<3000 {
        p.dot(rng.d() * 1024, rng.d() * 1024, rng.r(0.5, 2.0),
              Wash(r: 0.898, g: 0.933, b: 1.0).al(rng.r(0.004, 0.036)))
    }

    func limb(_ control: [CGPoint], thick: Double, seed: UInt64, tone: Wash) {
        let spine = resample(curveThrough(control, closed: false, steps: 12), count: 110)
        var upper: [CGPoint] = []
        var lower: [CGPoint] = []
        var wob = Spark(seed)
        for (i, q) in spine.enumerated() {
            let t = Double(i) / Double(spine.count - 1)
            let w = thick * (1.0 - t * 0.62) * (0.90 + 0.16 * sin(t * 13 + 1.2)) + wob.r(-1.6, 1.6)
            upper.append(pt(Double(q.x) - w * 0.30, Double(q.y) - w))
            lower.append(pt(Double(q.x) + w * 0.30, Double(q.y) + w))
        }
        let form = upper + lower.reversed()
        sculpt(p, form, base: tone, light: light, hotAt: 0.86, seed: seed &+ 3,
               bands: 52, grainCount: 320, grainLen: 44, grainWeight: 2.4,
               falloff: 3.10, ceiling: 0.62)
        formPass(p, form, light: light, inset: thick * 1.05,
                 shade: pitch, glow: moonBeam, seed: seed &+ 9)
    }

    limb([pt(1090, 214), pt(884, 268), pt(686, 344), pt(470, 452), pt(232, 596), pt(-90, 742)],
         thick: 34, seed: 4101, tone: Wash(r: 0.243, g: 0.220, b: 0.204))
    limb([pt(742, 322), pt(806, 218), pt(858, 118), pt(884, -70)],
         thick: 15, seed: 4131, tone: Wash(r: 0.204, g: 0.184, b: 0.176))
    limb([pt(430, 468), pt(486, 392), pt(520, 292), pt(516, 170)],
         thick: 12, seed: 4141, tone: Wash(r: 0.192, g: 0.176, b: 0.169))
    limb([pt(1090, 508), pt(930, 560), pt(806, 640), pt(724, 754)],
         thick: 19, seed: 4151, tone: Wash(r: 0.216, g: 0.196, b: 0.188))

    let control: [CGPoint] = [
        pt(-124, -96), pt(28, -96),
        pt(126, 128), pt(214, 196), pt(336, 176), pt(452, 190), pt(524, 118),
        pt(606, -96), pt(714, -96),
        pt(738, 158), pt(778, 336), pt(788, 486),
        pt(756, 632), pt(684, 742), pt(614, 812),
        pt(596, 866), pt(676, 906), pt(792, 950),
        pt(902, 1004), pt(1010, 1076), pt(1124, 1124),
        pt(-124, 1124), pt(-124, 902), pt(-116, 700), pt(-122, 472), pt(-130, 236)
    ]
    let bird = curveThrough(control, closed: true, steps: 9)

    let castPool = lump(cx: 470, cy: 946, rx: 470, ry: 78, rough: 0.14, steps: 32, seed: 4201)
    p.shape(castPool, Wash(r: 0.006, g: 0.010, b: 0.020).al(0.80))

    sculpt(p, bird, base: Wash(r: 0.412, g: 0.341, b: 0.271), light: light,
           hotAt: 0.94, seed: 5001, bands: 108, grainCount: 7200, grainLen: 19,
           grainWeight: 1.9, falloff: 3.40, ceiling: 0.70)
    formPass(p, bird, light: light, inset: 300, shade: pitch,
             glow: Wash(r: 0.804, g: 0.867, b: 0.980), seed: 5011)

    var scale = Spark(5101)
    p.inside(pathOf(bird)) {
        for _ in 0..<900 {
            let x = scale.r(-120, 1120), y = scale.r(-90, 1120)
            let rad = scale.r(14, 46)
            let a0 = light + .pi * 0.35
            var arc: [CGPoint] = []
            for k in 0...9 {
                let a = a0 + Double(k) / 9.0 * 2.3
                arc.append(pt(x + cos(a) * rad, y + sin(a) * rad * 0.72))
            }
            pen(p, arc, weight: scale.r(1.1, 3.0),
                colour: (scale.odds(0.62) ? pitch : moonBeam).al(scale.r(0.04, 0.13)),
                wobble: 0.5, taper: true, seed: scale.next())
        }
    }

    let faceControl: [CGPoint] = [
        pt(206, 262), pt(318, 232), pt(430, 262), pt(508, 344),
        pt(552, 452), pt(546, 566), pt(496, 668), pt(400, 742),
        pt(288, 756), pt(184, 700), pt(126, 574), pt(114, 410)
    ]
    let facialDisc = curveThrough(faceControl, closed: true, steps: 10)
    sculpt(p, facialDisc, base: Wash(r: 0.541, g: 0.427, b: 0.322), light: light,
           hotAt: 0.90, seed: 5201, bands: 78, grainCount: 2600, grainLen: 15,
           grainWeight: 1.6, falloff: 3.20, ceiling: 0.72, rim: false)
    formPass(p, facialDisc, light: light, inset: 176, shade: pitch,
             glow: Wash(r: 0.847, g: 0.898, b: 0.988), seed: 5211)
    engrave(p, facialDisc + [facialDisc[0]], weight: 6.4, light: light, seed: 5301, glow: 0.16)
    p.inside(pathOf(facialDisc)) {
        let far = crescent(facialDisc, light: light, inset: 260, away: true)
        if far.count > 3 { p.shape(far, pitch.al(0.30)) }
    }

    var fan = Spark(5321)
    let discPath = pathOf(facialDisc)
    p.inside(discPath) {
        for _ in 0..<1600 {
            let ang = fan.r(0, 6.283)
            let rad = fan.r(30, 240)
            let cx = 330.0 + cos(ang) * rad * 0.92
            let cy = 500.0 + sin(ang) * rad
            let out = atan2(cy - 500, cx - 330)
            let len = fan.r(16, 44)
            pen(p, [pt(cx, cy), pt(cx + cos(out) * len, cy + sin(out) * len)],
                weight: fan.r(0.9, 2.4),
                colour: (fan.odds(0.52) ? pitch : moonBeam).al(fan.r(0.08, 0.26)),
                wobble: 0.4, taper: true, seed: fan.next())
        }
    }

    let browLeft = curveThrough([pt(128, 372), pt(196, 306), pt(286, 302), pt(330, 372)],
                                closed: false, steps: 11)
    engrave(p, browLeft, weight: 8.0, light: light, seed: 5311)
    let browRight = curveThrough([pt(330, 372), pt(388, 306), pt(468, 314), pt(516, 384)],
                                 closed: false, steps: 11)
    engrave(p, browRight, weight: 6.4, light: light, seed: 5313)
    engrave(p, curveThrough([pt(330, 366), pt(336, 452), pt(340, 528)], closed: false, steps: 10),
            weight: 5.0, light: light, seed: 5315)
    engrave(p, curveThrough([pt(140, 540), pt(206, 656), pt(310, 716), pt(414, 706)],
                            closed: false, steps: 11), weight: 5.0, light: light, seed: 5317)

    let socketNear = lump(cx: 242, cy: 452, rx: 96, ry: 88, rough: 0.045, steps: 34, seed: 5401)
    sculpt(p, socketNear, base: Wash(r: 0.145, g: 0.118, b: 0.098), light: light,
           hotAt: 0.24, seed: 5403, bands: 40, grain: false, falloff: 3.0,
           ceiling: 0.46, rim: false)
    let irisNear = curveThrough([pt(158, 450), pt(240, 372), pt(324, 452), pt(240, 532)],
                                closed: true, steps: 14)
    sculpt(p, irisNear, base: Wash(r: 0.867, g: 0.667, b: 0.176), light: light,
           hotAt: 0.86, seed: 5405, bands: 52, grain: false, falloff: 2.6, ceiling: 0.68)
    var iris = Spark(5406)
    p.inside(pathOf(irisNear)) {
        for _ in 0..<220 {
            let a = iris.r(0, 6.283)
            pen(p, [pt(240 + cos(a) * 24, 452 + sin(a) * 24),
                    pt(240 + cos(a) * 74, 452 + sin(a) * 74)],
                weight: iris.r(0.8, 2.2),
                colour: (iris.odds(0.5) ? Wash(r: 0.404, g: 0.278, b: 0.043)
                         : Wash(r: 0.988, g: 0.906, b: 0.529)).al(iris.r(0.14, 0.40)),
                wobble: 0.3, taper: true, seed: iris.next())
        }
    }
    p.shape(lump(cx: 240, cy: 452, rx: 27, ry: 28, rough: 0.04, steps: 26, seed: 5407),
            Wash(r: 0.027, g: 0.022, b: 0.016))
    p.shape(lump(cx: 216, cy: 428, rx: 15, ry: 12, rough: 0.06, steps: 22, seed: 5409),
            Wash(r: 0.988, g: 0.996, b: 1.0).al(0.96))
    p.shape(lump(cx: 262, cy: 480, rx: 7, ry: 6, rough: 0.05, steps: 16, seed: 5411),
            moonBeam.al(0.44))

    let socketFar = lump(cx: 470, cy: 468, rx: 62, ry: 60, rough: 0.05, steps: 30, seed: 5501)
    sculpt(p, socketFar, base: Wash(r: 0.086, g: 0.071, b: 0.063), light: light,
           hotAt: 0.18, seed: 5503, bands: 30, grain: false, falloff: 2.8,
           ceiling: 0.34, rim: false)
    let irisFar = curveThrough([pt(420, 468), pt(468, 420), pt(518, 470), pt(468, 516)],
                               closed: true, steps: 12)
    sculpt(p, irisFar, base: Wash(r: 0.784, g: 0.588, b: 0.161), light: light,
           hotAt: 0.62, seed: 5505, bands: 30, grain: false, falloff: 2.2,
           ceiling: 0.74, rim: false)
    p.shape(lump(cx: 470, cy: 470, rx: 16, ry: 17, rough: 0.04, steps: 20, seed: 5507),
            Wash(r: 0.020, g: 0.016, b: 0.012))

    let beak: [CGPoint] = curveThrough([pt(322, 520), pt(372, 540), pt(384, 596),
                                        pt(354, 664), pt(330, 622), pt(312, 566)],
                                       closed: true, steps: 12)
    sculpt(p, beak, base: Wash(r: 0.216, g: 0.204, b: 0.204), light: light,
           hotAt: 0.90, seed: 5601, bands: 44, grain: false, falloff: 3.0, ceiling: 0.66)
    pen(p, curveThrough([pt(326, 528), pt(360, 560), pt(352, 640)], closed: false, steps: 9),
        weight: 4.6, colour: moonBeam.al(0.46), wobble: 0.3, taper: true, seed: 5603)

    var bibr = Spark(5701)
    let bibCentre = pt(330, 800)
    p.inside(pathOf(bird)) {
        for _ in 0..<2200 {
            let a = bibr.r(0, 6.283)
            let rad = bibr.r(0, 1.0)
            let x = Double(bibCentre.x) + cos(a) * rad * 138
            let y = Double(bibCentre.y) + sin(a) * rad * 82
            let fade = max(0.0, 1.0 - rad * rad)
            let dir = bibr.r(0.85, 2.30)
            let len = bibr.r(16, 52)
            pen(p, [pt(x, y), pt(x + cos(dir) * len, y + sin(dir) * len)],
                weight: bibr.r(1.2, 3.6),
                colour: (bibr.odds(0.72) ? Wash(r: 0.831, g: 0.839, b: 0.808)
                         : Wash(r: 0.243, g: 0.227, b: 0.204)).al(bibr.r(0.12, 0.58) * fade),
                wobble: 0.6, taper: true, seed: bibr.next())
        }
    }

    var bar = Spark(6001)
    p.inside(pathOf(bird)) {
        for k in 0..<20 {
            let y = 848.0 + Double(k) * 30.0
            let sweep = curveThrough([pt(120 + bar.r(-40, 40), y),
                                      pt(420, y + bar.r(14, 44)),
                                      pt(720, y + bar.r(30, 74)),
                                      pt(1040, y + bar.r(50, 104))], closed: false, steps: 9)
            penBroken(p, sweep, weight: bar.r(6.0, 12.0),
                      colour: pitch.al(bar.r(0.30, 0.60)), pieces: 3, gap: 0.09,
                      wobble: 1.8, seed: 6100 &+ UInt64(k))
            penBroken(p, sweep.map { pt(Double($0.x) - 8, Double($0.y) - 10) },
                      weight: bar.r(2.4, 5.2), colour: moonBeam.al(bar.r(0.10, 0.26)),
                      pieces: 3, gap: 0.11, wobble: 1.4, seed: 6200 &+ UInt64(k))
        }
    }

    var tuft = Spark(6301)
    for _ in 0..<760 {
        let side = tuft.odds(0.5)
        let bx = side ? tuft.r(-110, 170) : tuft.r(490, 720)
        let by = tuft.r(-60, 230)
        let dir = side ? tuft.r(0.86, 1.62) : tuft.r(1.52, 2.32)
        let len = tuft.r(26, 96)
        let bend = tuft.r(-0.34, 0.34)
        pen(p, [pt(bx, by),
                pt(bx - cos(dir + bend * 0.4) * len * 0.34, by - sin(dir + bend * 0.4) * len * 0.55),
                pt(bx - cos(dir + bend) * len * 0.60, by - sin(dir + bend) * len)],
            weight: tuft.r(1.2, 3.6),
            colour: (tuft.odds(0.38) ? Wash(r: 0.831, g: 0.871, b: 0.941).al(tuft.r(0.06, 0.24))
                     : pitch.al(tuft.r(0.20, 0.54))),
            wobble: 0.9, taper: true, seed: tuft.next())
    }

    for run in rimRuns(bird, light: light, threshold: 0.52) {
        penBroken(p, run, weight: 9.0, colour: Wash(r: 0.859, g: 0.906, b: 0.984).al(0.68),
                  pieces: 3, gap: 0.05, wobble: 0.9, seed: 6401)
    }
    for run in rimRuns(bird, light: light + .pi, threshold: 0.34) {
        penBroken(p, run, weight: 3.8, colour: Wash(r: 0.431, g: 0.510, b: 0.667).al(0.30),
                  pieces: 4, gap: 0.16, wobble: 1.0, seed: 6402)
    }
    for run in rimRuns(facialDisc, light: light, threshold: 0.36) {
        penBroken(p, run, weight: 4.6, colour: Wash(r: 0.878, g: 0.918, b: 0.976).al(0.38),
                  pieces: 4, gap: 0.10, wobble: 0.7, seed: 6403)
    }

    if let g = CGGradient(colorsSpace: rgbSpace,
                          colors: [cg(Wash(r: 0.729, g: 0.827, b: 1.0).al(0.17)),
                                   cg(Wash(r: 0.6, g: 0.7, b: 1.0).al(0))] as CFArray,
                          locations: [0, 1]) {
        p.ctx.drawRadialGradient(g, startCenter: CGPoint(x: 168, y: 156), startRadius: 0,
                                 endCenter: CGPoint(x: 168, y: 156), endRadius: 560, options: [])
    }

    if let g = CGGradient(colorsSpace: rgbSpace,
                          colors: [cg(Wash(r: 0, g: 0, b: 0, a: 0)),
                                   cg(Wash(r: 0, g: 0, b: 0.008, a: 0.58))] as CFArray,
                          locations: [0.42, 1]) {
        p.ctx.drawRadialGradient(g, startCenter: CGPoint(x: 380, y: 400), startRadius: 0,
                                 endCenter: CGPoint(x: 380, y: 400), endRadius: 900,
                                 options: [.drawsAfterEndLocation])
    }
    _ = rng.next()
    p.emitPNG(dir, "AppIcon-1024")
    sheetScale = held
}
