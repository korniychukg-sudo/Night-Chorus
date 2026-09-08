import Foundation
import CoreGraphics

struct SkyKey {
    var high: Wash
    var low: Wash
    var stars: Double
    var glow: Double
    var ground: Double
}

func skyKey(_ phase: Int) -> SkyKey {
    switch phase {
    case 0:
        return SkyKey(high: Ink.gloam, low: Ink.dawnPale, stars: 0.18, glow: 0.30, ground: 0.42)
    case 1:
        return SkyKey(high: Ink.duskBlue, low: Ink.dawnPale, stars: 0.0, glow: 0.16, ground: 0.20)
    case 2:
        return SkyKey(high: Ink.leafBlue, low: Ink.dawnPale, stars: 0.0, glow: 0.06, ground: 0.10)
    case 3:
        return SkyKey(high: Ink.duskViolet, low: Ink.goldWarm, stars: 0.0, glow: 0.34, ground: 0.24)
    case 4:
        return SkyKey(high: Ink.indigo, low: Ink.emberSky, stars: 0.34, glow: 0.52, ground: 0.44)
    case 5:
        return SkyKey(high: Ink.nightDeep, low: Ink.midnight, stars: 1.0, glow: 0.30, ground: 0.72)
    default:
        return SkyKey(high: Ink.nightDeep, low: Ink.night, stars: 0.86, glow: 0.18, ground: 0.80)
    }
}

func skyFor(_ p: Sheet, phase: Int, horizon: Double, seed: UInt64) {
    let key = skyKey(phase)
    var rng = Spark(seed)
    poolBand(p, from: -20, to: horizon * 0.50, key.high, strength: 0.76, seed: seed &+ 1)
    poolBand(p, from: horizon * 0.40, to: horizon + 6, key.low, strength: 0.50, seed: seed &+ 2)
    if key.stars > 0.02 {
        let count = Int(240 * key.stars)
        for _ in 0..<count {
            let x = rng.d() * p.w
            let y = rng.r(16, horizon * 0.94)
            let fade = 1.0 - y / max(1.0, horizon)
            p.dot(x, y, rng.r(0.8, 2.3), Ink.starWhite.al(rng.r(0.12, 0.62) * (0.4 + fade)))
        }
        for k in 0..<Int(6 * key.stars) {
            let x = rng.d() * p.w
            let y = rng.r(40, horizon * 0.55)
            p.dot(x, y, rng.r(2.6, 4.4), Ink.starWhite.al(0.70))
            for j in 0..<4 {
                let a = Double(j) * 1.5708 + 0.34
                let far = rng.r(10, 20)
                pen(p, [pt(x, y), pt(x + cos(a) * far, y + sin(a) * far)],
                    weight: 1.5, colour: Ink.starWhite.al(0.38), wobble: 0.2,
                    taper: true, seed: seed &+ UInt64(k * 7 + j))
            }
        }
    }
    if key.glow > 0.05 {
        let gx = p.w * 0.68
        for k in 0..<9 {
            let rad = 40.0 + Double(k) * 46
            let ring = ringPts(cx: gx, cy: horizon - 8, rx: rad * 1.5, ry: rad, steps: 40)
            pool(p, ring, key.low.up(0.16), strength: key.glow * 0.10, bleed: 12,
                 seed: seed &+ UInt64(90 + k))
        }
    }
    for k in 0..<5 {
        let y = horizon * rng.r(0.16, 0.74)
        let len = rng.r(p.w * 0.30, p.w * 0.85)
        let x0 = rng.r(-60, p.w * 0.5)
        let band = [pt(x0, y), pt(x0 + len, y - rng.r(8, 26)),
                    pt(x0 + len, y + rng.r(16, 40)), pt(x0, y + rng.r(20, 46))]
        pool(p, band, key.high.down(0.20), strength: 0.20, bleed: 10,
             seed: seed &+ UInt64(140 + k))
    }
}

func moonDisc(_ p: Sheet, cx: Double, cy: Double, rad: Double, lit: Double,
              waxing: Bool, seed: UInt64) {
    let disc = ringPts(cx: cx, cy: cy, rx: rad, ry: rad, steps: 72)
    for k in 0..<7 {
        let halo = ringPts(cx: cx, cy: cy, rx: rad * (1.25 + Double(k) * 0.30),
                           ry: rad * (1.25 + Double(k) * 0.30), steps: 44)
        pool(p, halo, Ink.moonlit, strength: 0.052 * lit + 0.010, bleed: 14,
             seed: seed &+ UInt64(k))
    }
    var face: [CGPoint] = []
    let steps = 96
    for i in 0...steps {
        let t = Double(i) / Double(steps)
        let a = -Double.pi / 2 + t * Double.pi
        face.append(pt(cx + cos(a) * rad, cy + sin(a) * rad))
    }
    let term = (1.0 - 2.0 * lit) * rad
    for i in stride(from: steps, through: 0, by: -1) {
        let t = Double(i) / Double(steps)
        let a = -Double.pi / 2 + t * Double.pi
        face.append(pt(cx + cos(a) * term, cy + sin(a) * rad))
    }
    let shown = waxing ? face : face.map { pt(2 * cx - Double($0.x), Double($0.y)) }
    if lit > 0.02 {
        p.shape(shown, Ink.moonlit)
        p.inside(pathOf(shown)) {
            var rng = Spark(seed &+ 31)
            for _ in 0..<26 {
                let a = rng.r(0, 6.2832)
                let d = rng.r(0, rad * 0.86)
                let mare = lump(cx: cx + cos(a) * d, cy: cy + sin(a) * d,
                                rx: rng.r(rad * 0.08, rad * 0.30),
                                ry: rng.r(rad * 0.07, rad * 0.24),
                                rough: 0.24, steps: 22, seed: rng.next())
                pool(p, mare, Ink.slate, strength: rng.r(0.14, 0.36), bleed: 5, seed: rng.next())
            }
            for _ in 0..<34 {
                let a = rng.r(0, 6.2832)
                let d = rng.r(0, rad * 0.92)
                let cr = rng.r(rad * 0.02, rad * 0.09)
                let ring = ringPts(cx: cx + cos(a) * d, cy: cy + sin(a) * d,
                                   rx: cr, ry: cr * 0.94, steps: 16)
                penEdge(p, ring, weight: 1.4, colour: Ink.slate.al(0.42), seed: rng.next())
            }
            crossHatch(p, pathOf(disc), depth: 1, spacing: 7.0,
                       colour: Ink.slate.al(0.14), seed: seed &+ 47)
        }
    }
    penEdge(p, disc, weight: 2.0, colour: Ink.moonCool.al(lit > 0.04 ? 0.62 : 0.34),
            seed: seed &+ 51)
}

func litterAt(_ p: Sheet, top: Double, bottom: Double, tone: Wash, count: Int, seed: UInt64) {
    var rng = Spark(seed)
    for _ in 0..<count {
        let x = rng.r(-40, p.w + 40)
        let y = rng.r(top, bottom)
        let scale = 12.0 + (y - top) / max(1.0, bottom - top) * 34.0
        let a = rng.r(0, 3.14159)
        let leaf = [pt(x, y),
                    pt(x + cos(a) * scale - sin(a) * scale * 0.5,
                       y + sin(a) * scale + cos(a) * scale * 0.5),
                    pt(x + cos(a) * scale * 2.2, y + sin(a) * scale * 2.2),
                    pt(x + cos(a) * scale + sin(a) * scale * 0.5,
                       y + sin(a) * scale - cos(a) * scale * 0.5)]
        p.shape(leaf, tone.down(rng.r(0.0, 0.36)).al(0.78))
        penEdge(p, leaf, weight: 1.5, colour: Ink.jet.al(rng.r(0.28, 0.62)), seed: rng.next())
        pen(p, [leaf[0], leaf[2]], weight: 1.3, colour: Ink.jet.al(0.34),
            wobble: 0.4, taper: true, seed: rng.next())
    }
}

func grassField(_ p: Sheet, top: Double, bottom: Double, tone: Wash, dense: Int,
                heads: Bool, seed: UInt64) {
    var rng = Spark(seed)
    poolBand(p, from: top, to: bottom, tone, strength: 0.52, seed: seed &+ 1)
    for k in 0..<dense {
        let x = rng.r(-30, p.w + 30)
        let baseY = rng.r(top + 10, bottom + 40)
        let depth = (baseY - top) / max(1.0, bottom - top)
        let len = (34.0 + depth * 150.0) * rng.r(0.6, 1.4)
        let lean = rng.pm() * 0.34
        let tip = pt(x + lean * len, baseY - len)
        pen(p, [pt(x, baseY), pt(x + lean * len * 0.4, baseY - len * 0.6), tip],
            weight: 1.4 + depth * 3.2, colour: tone.down(rng.r(0.10, 0.55)).al(rng.r(0.5, 0.95)),
            wobble: 0.8, taper: true, seed: seed &+ UInt64(k))
        if heads && rng.odds(0.16) {
            let hl = len * 0.20
            for j in 0..<5 {
                let t = Double(j) / 4.0
                pen(p, [pt(Double(tip.x), Double(tip.y) + hl * t),
                        pt(Double(tip.x) + rng.pm() * hl * 0.7,
                           Double(tip.y) + hl * t - hl * 0.34)],
                    weight: 1.6, colour: tone.up(0.24).al(0.72), wobble: 0.4,
                    taper: true, seed: rng.next())
            }
        }
    }
}

func fencePost(_ p: Sheet, x: Double, baseY: Double, height: Double, seed: UInt64) {
    let wide = height * 0.11
    let form = [pt(x - wide, baseY), pt(x - wide * 0.86, baseY - height),
                pt(x + wide * 0.86, baseY - height), pt(x + wide, baseY)]
    pool(p, form, Ink.timberDeep, strength: 0.76, bleed: 4, seed: seed &+ 1)
    formShade(p, form, inset: wide * 0.8, depth: 3, spacing: 4.0,
              colour: Ink.jet.al(0.60), seed: seed &+ 3)
    var rng = Spark(seed &+ 7)
    for _ in 0..<14 {
        let xx = x + rng.pm() * wide * 0.7
        let y0 = baseY - rng.r(0, height)
        pen(p, [pt(xx, y0), pt(xx + rng.pm() * 3, y0 - rng.r(20, height * 0.5))],
            weight: rng.r(1.0, 2.4), colour: Ink.jet.al(rng.r(0.20, 0.50)),
            wobble: 0.5, taper: true, seed: rng.next())
    }
    penEdge(p, form, weight: 2.8, colour: Ink.jet.al(0.88), seed: seed &+ 11)
    for k in 0..<2 {
        let y = baseY - height * (0.30 + Double(k) * 0.38)
        pen(p, [pt(x - 320, y + 12), pt(x, y), pt(x + 340, y + 16)],
            weight: 3.4, colour: Ink.jet.al(0.66), wobble: 1.4, taper: false,
            seed: seed &+ UInt64(13 + k))
    }
}

func cattailStand(_ p: Sheet, count: Int, baseY: Double, height: Double, seed: UInt64) {
    var rng = Spark(seed)
    for k in 0..<count {
        let x = rng.r(-40, p.w + 40)
        let len = height * rng.r(0.5, 1.25)
        let lean = rng.pm() * 0.18
        let top = pt(x + lean * len, baseY - len)
        pen(p, [pt(x, baseY), pt(x + lean * len * 0.5, baseY - len * 0.55), top],
            weight: rng.r(3.0, 6.4), colour: Ink.reed.down(rng.r(0.0, 0.45)),
            wobble: 0.7, taper: true, seed: seed &+ UInt64(k))
        if rng.odds(0.44) {
            let hl = len * rng.r(0.10, 0.17)
            let head = [pt(Double(top.x) - hl * 0.22, Double(top.y) + hl * 0.2),
                        pt(Double(top.x) - hl * 0.26, Double(top.y) + hl * 1.5),
                        pt(Double(top.x) + hl * 0.26, Double(top.y) + hl * 1.5),
                        pt(Double(top.x) + hl * 0.22, Double(top.y) + hl * 0.2)]
            pool(p, head, Ink.barkDeep, strength: 0.82, bleed: 3, seed: rng.next())
            crossHatch(p, pathOf(head), depth: 2, spacing: 3.2,
                       colour: Ink.jet.al(0.40), seed: rng.next())
            penEdge(p, head, weight: 2.0, colour: Ink.jet.al(0.86), seed: rng.next())
            pen(p, [pt(Double(top.x), Double(top.y) + hl * 0.2),
                    pt(Double(top.x) + rng.pm() * 6, Double(top.y) - hl * 1.1)],
                weight: 2.2, colour: Ink.reed.down(0.2), wobble: 0.5, taper: true,
                seed: rng.next())
        }
        if rng.odds(0.5) {
            let bladeLen = len * rng.r(0.4, 0.8)
            let side = rng.odds(0.5) ? 1.0 : -1.0
            pen(p, [pt(x, baseY - len * 0.15),
                    pt(x + side * bladeLen * 0.5, baseY - len * 0.55),
                    pt(x + side * bladeLen * 0.42, baseY - len * 0.86)],
                weight: rng.r(2.6, 5.0), colour: Ink.sedge.down(rng.r(0.1, 0.5)),
                wobble: 0.9, taper: true, seed: rng.next())
        }
    }
}

func pineRow(_ p: Sheet, baseY: Double, height: Double, count: Int, seed: UInt64) {
    var rng = Spark(seed)
    for _ in 0..<count {
        let x = rng.r(-40, p.w + 40)
        let len = height * rng.r(0.6, 1.3)
        var form: [CGPoint] = [pt(x, baseY - len)]
        let tiers = 7
        for j in 0..<tiers {
            let t = Double(j + 1) / Double(tiers)
            let spanX = len * 0.30 * t
            form.append(pt(x + spanX * rng.r(0.7, 1.1), baseY - len * (1 - t) - len * 0.06))
            form.append(pt(x + spanX * 0.5, baseY - len * (1 - t)))
        }
        form.append(pt(x + len * 0.06, baseY))
        form.append(pt(x - len * 0.06, baseY))
        for j in stride(from: tiers - 1, through: 0, by: -1) {
            let t = Double(j + 1) / Double(tiers)
            let spanX = len * 0.30 * t
            form.append(pt(x - spanX * 0.5, baseY - len * (1 - t)))
            form.append(pt(x - spanX * rng.r(0.7, 1.1), baseY - len * (1 - t) - len * 0.06))
        }
        pool(p, form, Ink.nightDeep, strength: 0.74, bleed: 4, seed: rng.next())
        penEdge(p, form, weight: 2.2, colour: Ink.jet.al(0.80), seed: rng.next())
    }
}

func boulderAt(_ p: Sheet, cx: Double, cy: Double, rx: Double, ry: Double, seed: UInt64) {
    let form = lump(cx: cx, cy: cy, rx: rx, ry: ry, rough: 0.22, steps: 22, seed: seed)
    pool(p, form, Ink.stone, strength: 0.62, bleed: 5, seed: seed &+ 3)
    formShade(p, form, inset: rx * 0.42, depth: 3, spacing: 4.6,
              colour: Ink.jet.al(0.52), seed: seed &+ 5)
    stipple(p, pathOf(form), density: 0.0018, sizeMin: 1.0, sizeMax: 3.0,
            colour: Ink.jet.al(0.32), seed: seed &+ 7)
    for run in rimRuns(form, light: p.light, threshold: 0.28) {
        penBroken(p, run, weight: 3.0, colour: Ink.moonlit.al(0.36),
                  pieces: 2, gap: 0.08, wobble: 0.7, seed: seed &+ 9)
    }
    penEdge(p, form, weight: 2.6, colour: Ink.jet.al(0.86), seed: seed &+ 11)
}

func canopyMass(_ p: Sheet, top: Double, depth: Double, seed: UInt64) {
    var rng = Spark(seed)
    var edge: [CGPoint] = []
    var x = -40.0
    while x <= p.w + 40 {
        edge.append(pt(x, top + depth * (0.35 + 0.65 * abs(sin(x / p.w * 7.3 + 1.1)))
                       + rng.r(-18, 18)))
        x += p.w / 34
    }
    var region = edge
    region.append(pt(p.w + 40, top - 200))
    region.append(pt(-40, top - 200))
    pool(p, region, Ink.nightDeep, strength: 0.84, bleed: 6, seed: seed &+ 3)
    for _ in 0..<220 {
        let xx = rng.r(-30, p.w + 30)
        let yy = rng.r(top - 160, top + depth * 0.9)
        let cl = lump(cx: xx, cy: yy, rx: rng.r(24, 74), ry: rng.r(16, 46),
                      rough: 0.34, steps: 16, seed: rng.next())
        penEdge(p, cl, weight: rng.r(1.4, 2.8), colour: Ink.jet.al(rng.r(0.24, 0.62)),
                seed: rng.next())
    }
    penBroken(p, edge, weight: 3.0, colour: Ink.jet.al(0.72), pieces: 6, gap: 0.05,
              wobble: 1.6, seed: seed &+ 9)
}

func groundFor(_ p: Sheet, kind: Int, horizon: Double, dim: Double, seed: UInt64) {
    let base = p.h
    switch kind {
    case 0:
        farRidge(p, base: horizon + 8, amp: 78, kind: 2, seed: seed &+ 5)
        waterPlane(p, top: horizon, bottom: base - 220, seed: seed &+ 11)
        poolBand(p, from: base - 250, to: base + 20, Ink.mud, strength: 0.66, seed: seed &+ 13)
        cattailStand(p, count: 26, baseY: base - 190, height: 300, seed: seed &+ 17)
        stemsAt(p, count: 34, baseY: base - 60, height: 260, tone: Ink.grassDeep,
                seed: seed &+ 19, heads: true)
    case 1:
        farRidge(p, base: horizon + 6, amp: 54, kind: 0, seed: seed &+ 5)
        grassField(p, top: horizon - 4, bottom: base + 30, tone: Ink.grassMid,
                   dense: 340, heads: true, seed: seed &+ 11)
        fencePost(p, x: p.w * 0.82, baseY: base - 130, height: 300, seed: seed &+ 21)
    case 2:
        canopyMass(p, top: 40, depth: 260, seed: seed &+ 5)
        poolBand(p, from: horizon - 20, to: base + 20, Ink.barkDeep, strength: 0.62,
                 seed: seed &+ 11)
        trunkAt(p, x: p.w * 0.10, width: 122, top: -30, bottom: base - 40,
                tone: Ink.bark, seed: seed &+ 13)
        trunkAt(p, x: p.w * 0.93, width: 96, top: -30, bottom: base - 70,
                tone: Ink.barkDeep, seed: seed &+ 17)
        litterAt(p, top: base - 300, bottom: base + 20, tone: Ink.barkPale,
                 count: 90, seed: seed &+ 19)
    case 3:
        farRidge(p, base: horizon + 4, amp: 40, kind: 0, seed: seed &+ 5)
        poolBand(p, from: horizon - 30, to: horizon + 90, Ink.grassDeep, strength: 0.74,
                 seed: seed &+ 7)
        grassField(p, top: horizon + 60, bottom: base + 30, tone: Ink.grassPale,
                   dense: 190, heads: false, seed: seed &+ 11)
        fencePost(p, x: p.w * 0.16, baseY: base - 210, height: 340, seed: seed &+ 21)
        do {
            let lx = p.w * 0.86
            let ly = horizon - 130
            for k in 0..<6 {
                let rad = 30.0 + Double(k) * 30
                pool(p, ringPts(cx: lx, cy: ly, rx: rad, ry: rad, steps: 30),
                     Ink.goldWarm, strength: 0.10, bleed: 10, seed: seed &+ UInt64(30 + k))
            }
            let shade = [pt(lx - 46, ly + 26), pt(lx - 30, ly - 30),
                         pt(lx + 30, ly - 30), pt(lx + 46, ly + 26)]
            pool(p, shade, Ink.iron, strength: 0.80, bleed: 3, seed: seed &+ 41)
            p.shape(lump(cx: lx, cy: ly + 8, rx: 22, ry: 18, rough: 0.06, steps: 18,
                         seed: seed &+ 43), Ink.goldWarm.up(0.4))
            penEdge(p, shade, weight: 2.6, colour: Ink.jet.al(0.86), seed: seed &+ 45)
            pen(p, [pt(lx, ly + 26), pt(lx, base - 150)], weight: 8.0,
                colour: Ink.jet.al(0.82), wobble: 0.5, taper: false, seed: seed &+ 47)
        }
    case 4:
        farRidge(p, base: horizon + 10, amp: 96, kind: 2, seed: seed &+ 5)
        poolBand(p, from: horizon - 10, to: base + 20, Ink.sand.down(0.30),
                 strength: 0.60, seed: seed &+ 11)
        do {
            var rng = Spark(seed &+ 13)
            for _ in 0..<7 {
                let y = rng.r(horizon + 40, base - 30)
                penBroken(p, [pt(-30, y), pt(p.w * 0.5, y + rng.r(-20, 20)),
                              pt(p.w + 30, y + rng.r(-30, 30))],
                          weight: rng.r(2.6, 6.0), colour: Ink.jet.al(rng.r(0.24, 0.50)),
                          pieces: 4, gap: 0.08, wobble: 2.2, seed: rng.next())
            }
            for _ in 0..<9 {
                boulderAt(p, cx: rng.r(0, p.w), cy: rng.r(horizon + 60, base - 20),
                          rx: rng.r(30, 88), ry: rng.r(20, 54), seed: rng.next())
            }
            for _ in 0..<6 {
                let x = rng.r(0, p.w)
                let y = rng.r(horizon + 40, base - 80)
                for j in 0..<11 {
                    let a = -1.5 + Double(j) / 10.0 * 3.0
                    pen(p, [pt(x, y), pt(x + sin(a) * rng.r(50, 120),
                                         y - cos(a) * rng.r(60, 150))],
                        weight: 3.4, colour: Ink.sedge.down(0.30), wobble: 0.7,
                        taper: true, seed: rng.next())
                }
            }
        }
    case 5:
        farRidge(p, base: horizon + 6, amp: 44, kind: 1, seed: seed &+ 5)
        waterPlane(p, top: horizon, bottom: base - 120, seed: seed &+ 11)
        cattailStand(p, count: 54, baseY: base - 90, height: 460, seed: seed &+ 17)
        cattailStand(p, count: 22, baseY: base + 30, height: 620, seed: seed &+ 23)
    case 6:
        farRidge(p, base: horizon + 4, amp: 40, kind: 0, seed: seed &+ 5)
        pineRow(p, baseY: horizon + 20, height: 300, count: 16, seed: seed &+ 7)
        poolBand(p, from: horizon, to: base + 20, Ink.sand.down(0.42), strength: 0.58,
                 seed: seed &+ 11)
        stemsAt(p, count: 60, baseY: base - 40, height: 150, tone: Ink.sedge,
                seed: seed &+ 13, heads: false)
        do {
            var rng = Spark(seed &+ 17)
            for _ in 0..<140 {
                let x = rng.r(0, p.w)
                let y = rng.r(horizon + 30, base)
                pen(p, [pt(x, y), pt(x + rng.pm() * 18, y - rng.r(10, 34))],
                    weight: rng.r(1.2, 2.6), colour: Ink.jet.al(rng.r(0.16, 0.40)),
                    wobble: 0.4, taper: true, seed: rng.next())
            }
        }
    default:
        canopyMass(p, top: 20, depth: 190, seed: seed &+ 5)
        trunkAt(p, x: p.w * 0.06, width: 100, top: -30, bottom: horizon + 130,
                tone: Ink.bark, seed: seed &+ 7)
        waterPlane(p, top: horizon + 40, bottom: base - 190, seed: seed &+ 11)
        do {
            var rng = Spark(seed &+ 13)
            for _ in 0..<26 {
                let y = rng.r(horizon + 60, base - 200)
                pen(p, [pt(rng.r(-20, p.w), y), pt(rng.r(0, p.w + 20), y + rng.r(-4, 4))],
                    weight: rng.r(2.0, 5.0), colour: Ink.moonCool.al(rng.r(0.14, 0.42)),
                    wobble: 0.9, taper: true, seed: rng.next())
            }
        }
        poolBand(p, from: base - 210, to: base + 20, Ink.mud, strength: 0.68, seed: seed &+ 19)
        do {
            let logY = base - 210.0
            let log = [pt(-40, logY), pt(p.w * 0.62, logY - 44),
                       pt(p.w * 0.62, logY + 26), pt(-40, logY + 70)]
            pool(p, log, Ink.timberDeep, strength: 0.80, bleed: 4, seed: seed &+ 23)
            formShade(p, log, inset: 24, depth: 3, spacing: 4.4, colour: Ink.jet.al(0.56),
                      seed: seed &+ 25)
            var rng = Spark(seed &+ 27)
            for _ in 0..<26 {
                let t = rng.d()
                let x = -40 + t * (p.w * 0.62 + 40)
                pen(p, [pt(x, logY - 40 * t + rng.r(0, 60)),
                        pt(x + rng.r(40, 130), logY - 40 * t + rng.r(0, 60))],
                    weight: rng.r(1.2, 2.8), colour: Ink.jet.al(rng.r(0.20, 0.48)),
                    wobble: 0.6, taper: true, seed: rng.next())
            }
            penEdge(p, log, weight: 3.0, colour: Ink.jet.al(0.88), seed: seed &+ 29)
        }
        litterAt(p, top: base - 190, bottom: base + 20, tone: Ink.barkPale,
                 count: 44, seed: seed &+ 31)
    }
    if dim > 0.02 {
        poolBand(p, from: horizon - 40, to: base + 20, Ink.nightDeep, strength: dim * 0.30,
                 seed: seed &+ 91)
    }
    for k in 0..<5 {
        let y0 = base - 620 + Double(k) * 124
        poolBand(p, from: y0, to: base + 30, Ink.nightDeep, strength: 0.13,
                 seed: seed &+ UInt64(95 + k))
    }
}

func sceneBack(_ p: Sheet, scene: Int, seed: UInt64) {
    let horizon = 520.0
    nightPaper(p, seed: seed)
    skyBand(p, horizon: horizon, seed: seed &+ 3)
    groundFor(p, kind: scene, horizon: horizon, dim: 0.22, seed: seed &+ 101)
}

func seasonGrass(_ season: Int) -> Wash {
    switch season {
    case 0: return Ink.grassMid
    case 1: return Ink.grassDeep
    case 2: return Ink.sedge
    default: return Ink.dawnGrey
    }
}

func meadowPlate(_ season: Int, _ phase: Int, dir: String) {
    let p = Sheet(1240, 720)
    let seed = hashSeed("meadow-\(season)-\(phase)")
    let key = skyKey(phase)
    layPaper(p, seed: seed, tone: phase == 2 ? Ink.leafGrey : Ink.leafBlue)
    p.flipTopDown()
    p.light = phase == 5 || phase == 6 ? 3.90 : 2.40
    let horizon = 386.0
    skyFor(p, phase: phase, horizon: horizon, seed: seed &+ 3)

    farRidge(p, base: horizon + 6, amp: 62, kind: season == 3 ? 0 : 2, seed: seed &+ 11)

    do {
        let tx = 210.0
        let baseY = horizon + 118
        trunkAt(p, x: tx, width: 44, top: horizon - 168, bottom: baseY,
                tone: season == 3 ? Ink.barkDeep : Ink.bark, seed: seed &+ 13)
        var rng = Spark(seed &+ 17)
        for k in 0..<7 {
            let a = -2.5 + Double(k) / 6.0 * 2.0
            let tip = pt(tx + cos(a) * rng.r(80, 165), horizon - 168 + sin(a) * rng.r(40, 96))
            pen(p, [pt(tx, horizon - 150), tip], weight: rng.r(4.0, 9.0),
                colour: Ink.jet.al(0.80), wobble: 1.2, taper: true, seed: rng.next())
            if season != 3 && season != 0 {
                for _ in 0..<26 {
                    let t = rng.r(0.2, 1.0)
                    let lx = tx + (Double(tip.x) - tx) * t + rng.pm() * 28
                    let ly = (horizon - 150) + (Double(tip.y) - (horizon - 150)) * t + rng.pm() * 26
                    let cl = lump(cx: lx, cy: ly, rx: rng.r(10, 22), ry: rng.r(7, 15),
                                  rough: 0.30, steps: 12, seed: rng.next())
                    penEdge(p, cl, weight: 1.6,
                            colour: (season == 2 ? Ink.sedge : Ink.grassDeep).al(rng.r(0.4, 0.8)),
                            seed: rng.next())
                }
            }
        }
    }

    let grassTone = seasonGrass(season)
    if season == 3 {
        poolBand(p, from: horizon - 6, to: p.h + 20, Ink.dawnPale, strength: 0.50,
                 seed: seed &+ 21)
        grassField(p, top: horizon + 20, bottom: p.h + 20, tone: grassTone,
                   dense: 120, heads: false, seed: seed &+ 23)
        var rng = Spark(seed &+ 27)
        for _ in 0..<160 {
            let y = rng.r(horizon + 10, p.h)
            let x = rng.r(-20, p.w + 20)
            let drift = lump(cx: x, cy: y, rx: rng.r(30, 110), ry: rng.r(8, 24),
                             rough: 0.18, steps: 18, seed: rng.next())
            pool(p, drift, Ink.moonlit, strength: rng.r(0.10, 0.30), bleed: 6, seed: rng.next())
        }
    } else {
        grassField(p, top: horizon - 4, bottom: p.h + 30, tone: grassTone,
                   dense: season == 0 ? 260 : 400, heads: season != 0, seed: seed &+ 23)
    }

    fencePost(p, x: 1030, baseY: p.h - 40, height: 270, seed: seed &+ 31)

    if season == 1 && key.stars > 0.3 {
        var rng = Spark(seed &+ 41)
        for _ in 0..<30 {
            let x = rng.r(0, p.w)
            let y = rng.r(horizon - 20, p.h - 60)
            for k in 0..<4 {
                let rad = 4.0 + Double(k) * 5
                pool(p, ringPts(cx: x, cy: y, rx: rad, ry: rad, steps: 14),
                     Ink.goldWarm, strength: 0.16, bleed: 4, seed: rng.next())
            }
            p.dot(x, y, 3.0, Ink.starWhite.al(0.86))
        }
    }

    if key.ground > 0.3 {
        poolBand(p, from: horizon - 30, to: p.h + 20, Ink.nightDeep,
                 strength: key.ground * 0.30, seed: seed &+ 51)
    }
    nearFrame(p, seed: seed &+ 61)
    p.emit(dir, "sc_\(season)_\(phase)")
}

func habitatPlate(_ index: Int, dir: String) {
    let p = Sheet(1240, 700)
    let seed = hashSeed("habitat-\(index)")
    nightPaper(p, seed: seed)
    let horizon = 300.0
    skyFor(p, phase: 5, horizon: horizon, seed: seed &+ 3)
    moonDisc(p, cx: 210, cy: 110, rad: 46, lit: 0.72, waxing: index % 2 == 0, seed: seed &+ 5)
    groundFor(p, kind: index, horizon: horizon, dim: 0.16, seed: seed &+ 11)
    nearFrame(p, seed: seed &+ 21)
    borderRule(p, inset: 22, seed: seed &+ 31, colour: Ink.jet.al(0.42))
    p.emit(dir, "hb_" + groundKeys[index])
}

let groundKeys = ["pond", "meadow", "hardwood", "garden", "wash", "marsh", "barren", "bottom"]

func moonPlate(_ index: Int, dir: String) {
    let p = Sheet(1240, 560)
    let seed = hashSeed("moon-\(index)")
    nightPaper(p, seed: seed)
    skyFor(p, phase: 6, horizon: 460, seed: seed &+ 3)
    let lit = (1.0 - cos(Double(index) / 8.0 * 6.283185)) / 2.0
    moonDisc(p, cx: p.w * 0.5, cy: 250, rad: 150, lit: lit,
             waxing: index < 4, seed: seed &+ 7)
    farRidge(p, base: p.h + 10, amp: 96, kind: 2, seed: seed &+ 11)
    var rng = Spark(seed &+ 21)
    for k in 0..<5 {
        let x = rng.r(80, p.w - 80)
        let y = rng.r(p.h - 130, p.h - 20)
        pen(p, [pt(x, y), pt(x + rng.pm() * 40, y - rng.r(60, 150))],
            weight: rng.r(3.0, 6.0), colour: Ink.jet.al(0.82), wobble: 1.2,
            taper: true, seed: seed &+ UInt64(k))
    }
    let names = ["New moon", "Waxing crescent", "First quarter", "Waxing gibbous",
                 "Full moon", "Waning gibbous", "Last quarter", "Waning crescent"]
    letter(p, names[index], at: p.w * 0.5, p.h - 44, size: 34,
           colour: Ink.moonlit.al(0.80), align: .centre, tracking: 3)
    p.emit(dir, "mn_\(index)")
}
