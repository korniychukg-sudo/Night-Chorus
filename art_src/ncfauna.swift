import Foundation
import CoreGraphics

func perchSlab(_ p: Sheet, cx: Double, cy: Double, wide: Double, kind: Int,
               seed: UInt64) {
    var rng = Spark(seed)
    if kind == 2 {
        var leaf: [CGPoint] = []
        for k in 0...26 {
            let t = Double(k) / 26.0
            let a = -Double.pi * 0.5 + t * Double.pi
            leaf.append(pt(cx + sin(a) * wide, cy - cos(a) * wide * 0.30 - 20))
        }
        for k in 0...26 {
            let t = Double(k) / 26.0
            let a = Double.pi * 0.5 - t * Double.pi
            leaf.append(pt(cx + sin(a) * wide, cy + cos(a) * wide * 0.20 + 26))
        }
        pool(p, leaf, Ink.mossWet, strength: 0.54, bleed: 7, seed: seed &+ 1)
        crossHatch(p, pathOf(leaf), depth: 2, spacing: 20, colour: Ink.jet.al(0.44),
                   seed: seed &+ 3)
        p.inside(pathOf(leaf)) {
            pen(p, [pt(cx - wide, cy + 10), pt(cx, cy - 6), pt(cx + wide, cy + 14)],
                weight: 8.0, colour: Ink.jet.al(0.72), wobble: 1.2, taper: true,
                seed: seed &+ 5)
            for k in 0..<11 {
                let t = -0.86 + Double(k) / 10.0 * 1.72
                let x = cx + t * wide
                pen(p, [pt(x, cy + 4), pt(x + wide * 0.16, cy - wide * 0.20)],
                    weight: 3.6, colour: Ink.jet.al(0.50), wobble: 0.8, taper: true,
                    seed: rng.next())
                pen(p, [pt(x, cy + 4), pt(x + wide * 0.13, cy + wide * 0.16)],
                    weight: 3.2, colour: Ink.jet.al(0.46), wobble: 0.8, taper: true,
                    seed: rng.next())
            }
            for _ in 0..<40 {
                let x = rng.r(cx - wide, cx + wide)
                let y = rng.r(cy - wide * 0.26, cy + wide * 0.20)
                p.dot(x, y, rng.r(2.4, 6.0), Ink.moonlit.al(rng.r(0.18, 0.52)))
            }
        }
        penEdge(p, leaf, weight: 6.0, colour: Ink.jet.al(0.92), seed: seed &+ 9)
        return
    }
    let slab = lump(cx: cx, cy: cy + 30, rx: wide, ry: wide * 0.26, rough: 0.16,
                    steps: 26, seed: seed &+ 1)
    pool(p, slab, kind == 1 ? Ink.sand.down(0.30) : Ink.mud, strength: 0.56,
         bleed: 8, seed: seed &+ 3)
    crossHatch(p, pathOf(slab), depth: 3, spacing: 19, colour: Ink.jet.al(0.46),
               seed: seed &+ 5)
    formShade(p, slab, inset: wide * 0.22, depth: 2, spacing: 14,
              colour: Ink.jet.al(0.62), seed: seed &+ 7)
    p.inside(pathOf(slab)) {
        for _ in 0..<70 {
            let x = rng.r(cx - wide, cx + wide)
            let y = rng.r(cy - wide * 0.20, cy + wide * 0.30)
            pen(p, [pt(x, y), pt(x + rng.r(30, 110), y + rng.r(-8, 8))],
                weight: rng.r(2.0, 5.0), colour: Ink.jet.al(rng.r(0.24, 0.52)),
                wobble: 0.8, taper: true, seed: rng.next())
        }
    }
    for run in rimRuns(slab, light: p.light, threshold: 0.30) {
        penBroken(p, run, weight: 5.0, colour: Ink.moonlit.al(0.40), pieces: 2,
                  gap: 0.10, wobble: 1.0, seed: seed &+ 11)
    }
    penEdge(p, slab, weight: 6.0, colour: Ink.jet.al(0.92), seed: seed &+ 13)
}

func furEdge(_ p: Sheet, _ outline: [CGPoint], length: Double, tone: Wash, seed: UInt64) {
    var rng = Spark(seed)
    let ring = resample(outline + [outline[0]], count: 150)
    for i in 0..<(ring.count - 1) {
        let a = ring[i]
        let b = ring[i + 1]
        let dx = Double(b.x) - Double(a.x)
        let dy = Double(b.y) - Double(a.y)
        let len = max(0.001, (dx * dx + dy * dy).squareRoot())
        let nx = -dy / len
        let ny = dx / len
        let out = length * rng.r(0.5, 1.5)
        pen(p, [pt(Double(a.x) - nx * out * 0.35, Double(a.y) - ny * out * 0.35),
                pt(Double(a.x) + nx * out + dx * rng.r(0.6, 2.4),
                   Double(a.y) + ny * out + dy * rng.r(0.6, 2.4))],
            weight: rng.r(1.4, 3.2), colour: tone.down(rng.r(0.0, 0.42)).al(rng.r(0.44, 0.92)),
            wobble: 0.5, taper: true, seed: rng.next())
    }
}

func featherRows(_ p: Sheet, _ form: CGPath, rows: Int, spacing: Double,
                 wide: Double, tone: Wash, seed: UInt64) {
    guard !form.isEmpty else { return }
    let box = form.boundingBox
    var rng = Spark(seed)
    p.inside(form) {
        for r in 0..<rows {
            let y = Double(box.minY) + Double(box.height) * Double(r) / Double(rows)
            var x = Double(box.minX) - wide
            while x < Double(box.maxX) + wide {
                let scallop = [pt(x, y),
                               pt(x + wide * 0.5, y + spacing * 0.9),
                               pt(x + wide, y)]
                pen(p, scallop, weight: rng.r(1.4, 2.8),
                    colour: tone.down(rng.r(0.10, 0.50)).al(rng.r(0.30, 0.72)),
                    wobble: 0.5, taper: true, seed: rng.next())
                x += wide * rng.r(0.72, 0.96)
            }
        }
    }
}

func flightFeathers(_ p: Sheet, from a: CGPoint, spread: Double, count: Int,
                    a0: Double, a1: Double, tone: Wash, seed: UInt64) {
    var rng = Spark(seed)
    for k in 0..<count {
        let t = Double(k) / Double(max(1, count - 1))
        let ang = a0 + (a1 - a0) * t
        let len = spread * (0.62 + 0.38 * sin(t * 3.14159))
        let tip = pt(Double(a.x) + cos(ang) * len, Double(a.y) + sin(ang) * len)
        let mid = pt(Double(a.x) + cos(ang + 0.10) * len * 0.5,
                     Double(a.y) + sin(ang + 0.10) * len * 0.5)
        pen(p, [a, mid, tip], weight: rng.r(6.0, 11.0),
            colour: tone.down(rng.r(0.0, 0.34)), wobble: 0.7, taper: true, seed: rng.next())
        pen(p, [a, mid, tip], weight: 2.0, colour: Ink.jet.al(0.44),
            wobble: 0.4, taper: true, seed: rng.next())
    }
}

func antenna(_ p: Sheet, from a: CGPoint, length: Double, curl: Double,
             tone: Wash, seed: UInt64) {
    var spine: [CGPoint] = []
    for k in 0...26 {
        let t = Double(k) / 26.0
        let x = Double(a.x) + t * length
        let y = Double(a.y) - sin(t * 1.5) * length * curl
        spine.append(pt(x, y))
    }
    pen(p, spine, weight: 5.6, colour: tone.down(0.24), wobble: 0.7, taper: true, seed: seed)
    pen(p, spine, weight: 1.8, colour: Ink.moonCool.al(0.28), wobble: 0.4,
        taper: true, seed: seed &+ 3)
}

func insectLeg(_ p: Sheet, hip: CGPoint, knee: CGPoint, foot: CGPoint,
               femur: Double, tone: Wash, spines: Bool, seed: UInt64) {
    let thigh = [hip, pt((Double(hip.x) + Double(knee.x)) / 2,
                         (Double(hip.y) + Double(knee.y)) / 2 - femur * 0.5), knee]
    var swell: [CGPoint] = []
    let spine = resample(thigh, count: 24)
    for (i, q) in spine.enumerated() {
        let t = Double(i) / Double(spine.count - 1)
        let wdt = femur * (0.35 + 0.65 * sin(t * 3.14159 * 0.9 + 0.2))
        swell.append(pt(Double(q.x), Double(q.y) - wdt))
    }
    for (i, q) in spine.enumerated().reversed() {
        let t = Double(i) / Double(spine.count - 1)
        let wdt = femur * (0.35 + 0.65 * sin(t * 3.14159 * 0.9 + 0.2))
        swell.append(pt(Double(q.x), Double(q.y) + wdt))
    }
    pool(p, swell, tone, strength: 0.68, bleed: 3, seed: seed &+ 1)
    formShade(p, swell, inset: femur * 0.7, depth: 2, spacing: 3.4,
              colour: tone.down(0.50), seed: seed &+ 3)
    penEdge(p, swell, weight: 2.4, colour: Ink.jet.al(0.86), seed: seed &+ 5)
    pen(p, [knee, foot], weight: femur * 0.30, colour: tone.down(0.20),
        wobble: 0.5, taper: true, seed: seed &+ 7)
    pen(p, [knee, foot], weight: femur * 0.10, colour: Ink.moonCool.al(0.30),
        wobble: 0.3, taper: true, seed: seed &+ 9)
    if spines {
        var rng = Spark(seed &+ 11)
        for k in 0..<9 {
            let t = Double(k) / 9.0
            let x = Double(knee.x) + (Double(foot.x) - Double(knee.x)) * t
            let y = Double(knee.y) + (Double(foot.y) - Double(knee.y)) * t
            pen(p, [pt(x, y), pt(x + rng.r(-24, -8), y + rng.r(-16, 16))],
                weight: 2.6, colour: Ink.jet.al(0.72), wobble: 0.3, taper: true,
                seed: rng.next())
        }
    }
}

func stemPerch(_ p: Sheet, from a: CGPoint, to b: CGPoint, thick: Double, seed: UInt64) {
    var rng = Spark(seed)
    let spine = resample([a, pt((Double(a.x) + Double(b.x)) / 2,
                                (Double(a.y) + Double(b.y)) / 2 + thick * 2.0), b], count: 30)
    var form: [CGPoint] = []
    for q in spine { form.append(pt(Double(q.x), Double(q.y) - thick)) }
    for q in spine.reversed() { form.append(pt(Double(q.x), Double(q.y) + thick)) }
    pool(p, form, Ink.grassMid, strength: 0.56, bleed: 5, seed: seed &+ 1)
    crossHatch(p, pathOf(form), depth: 2, spacing: 15, colour: Ink.jet.al(0.46),
               seed: seed &+ 3)
    formShade(p, form, inset: thick * 0.9, depth: 2, spacing: 11,
              colour: Ink.jet.al(0.62), seed: seed &+ 5)
    for run in rimRuns(form, light: p.light, threshold: 0.30) {
        penBroken(p, run, weight: 3.4, colour: Ink.moonlit.al(0.40), pieces: 2,
                  gap: 0.10, wobble: 0.8, seed: seed &+ 7)
    }
    penEdge(p, form, weight: 5.0, colour: Ink.jet.al(0.90), seed: seed &+ 9)
    for k in 0..<3 {
        let t = 0.2 + Double(k) * 0.3
        let i = Int(t * Double(spine.count - 1))
        let q = spine[i]
        pen(p, [q, pt(Double(q.x) + rng.r(-190, 190), Double(q.y) - rng.r(160, 420))],
            weight: thick * 0.9, colour: Ink.grassDeep.down(0.20), wobble: 1.4,
            taper: true, seed: rng.next())
    }
}

func insectPlate(_ p: Sheet, _ art: VoiceArt, form: Int, seed: UInt64) {
    let tone = hueWash(art.hue)
    let cx = 600.0
    let cy = 860.0
    let tilt = form == 3 ? 0.0 : -0.13
    func at(_ x: Double, _ y: Double) -> CGPoint {
        pt(cx + x * cos(tilt) - y * sin(tilt), cy + x * sin(tilt) + y * cos(tilt))
    }

    if form != 3 {
        stemPerch(p, from: pt(-40, 1292), to: pt(1280, 1148), thick: 21, seed: seed &+ 3)
    } else {
        trunkAt(p, x: 250, width: 190, top: -30, bottom: 1600, tone: Ink.bark,
                seed: seed &+ 3)
    }

    let abdoLong = form == 2 ? 300.0 : (form == 3 ? 220.0 : 250.0)
    let abdoTall = form == 3 ? 118.0 : 84.0
    var abdomen: [CGPoint] = []
    for k in 0...30 {
        let t = Double(k) / 30.0
        let x = -30 + t * abdoLong
        let taper = sin((1.0 - t * 0.86) * 1.5708)
        abdomen.append(at(x, -abdoTall * taper))
    }
    for k in stride(from: 30, through: 0, by: -1) {
        let t = Double(k) / 30.0
        let x = -30 + t * abdoLong
        let taper = sin((1.0 - t * 0.86) * 1.5708)
        abdomen.append(at(x, abdoTall * taper))
    }
    modelBody(p, abdomen, tone: tone.down(0.16), depth: 3, spacing: 13, seed: seed &+ 5)
    p.inside(pathOf(abdomen)) {
        for k in 0..<8 {
            let x = -10 + Double(k) * abdoLong / 8.5
            penBroken(p, [at(x, -abdoTall), at(x + 14, abdoTall)], weight: 5.0,
                      colour: Ink.jet.al(0.54), pieces: 2, gap: 0.10, wobble: 1.4,
                      seed: seed &+ UInt64(7 + k))
        }
    }

    let thorax = [at(-160, -96), at(-40, -108), at(-10, 66), at(-150, 84)]
    modelBody(p, thorax, tone: tone, depth: 3, spacing: 12, seed: seed &+ 21)
    let pronotum = [at(-190, -86), at(-70, -100), at(-52, 40), at(-186, 52)]
    modelBody(p, pronotum, tone: tone.up(0.10), depth: 3, spacing: 11,
              seed: seed &+ 23, edge: 4.0)

    let headC = at(-286, -34)
    let head = lump(cx: Double(headC.x), cy: Double(headC.y), rx: 96,
                    ry: form == 3 ? 96 : 84, rough: 0.05, steps: 26, seed: seed &+ 31)
    modelBody(p, head, tone: tone.up(0.06), depth: 3, spacing: 11, seed: seed &+ 33)

    if form == 2 {
        let cone = [at(-330, -84), at(-486, -30), at(-330, 26)]
        modelBody(p, cone, tone: tone.up(0.16), depth: 2, spacing: 9,
                  seed: seed &+ 35, edge: 4.0)
    }

    let hips: [(Double, Double, Bool)] = [(-150, 70, false), (-40, 76, false), (70, 66, true)]
    for (k, hip) in hips.enumerated() {
        let big = hip.2
        let root = at(hip.0, hip.1)
        let knee = big ? at(hip.0 + 250, hip.1 - 150) : at(hip.0 + 60, hip.1 + 150)
        let foot = big ? at(hip.0 + 70, hip.1 + 310) : at(hip.0 + 190, hip.1 + 290)
        insectLeg(p, hip: root, knee: knee, foot: foot,
                  femur: big ? 62 : 20, tone: tone.down(0.10), spines: big,
                  seed: seed &+ UInt64(41 + k * 6))
        for j in 0..<2 {
            let a = -0.4 + Double(j) * 0.9
            pen(p, [foot, pt(Double(foot.x) + sin(a) * 54, Double(foot.y) + cos(a) * 30)],
                weight: 6.0, colour: Ink.jet.al(0.80), wobble: 0.5, taper: true,
                seed: seed &+ UInt64(51 + k * 4 + j))
        }
    }

    if form == 3 {
        for side in 0..<2 {
            let drop = Double(side) * 44.0
            let wing = [at(-150, -70 + drop), at(120, -150 + drop),
                        at(470, -20 + drop), at(300, 76 + drop), at(-120, 10 + drop)]
            pool(p, wing, Ink.wingClear, strength: 0.24, bleed: 7,
                 seed: seed &+ UInt64(61 + side))
            p.inside(pathOf(wing)) {
                var rng = Spark(seed &+ UInt64(65 + side))
                for j in 0..<14 {
                    let t = Double(j) / 13.0
                    pen(p, [at(-140, -60 + drop + t * 60),
                            at(450 - t * 90, -10 + drop + t * 70)],
                        weight: rng.r(2.6, 4.6), colour: Ink.jet.al(rng.r(0.34, 0.62)),
                        wobble: 0.8, taper: true, seed: rng.next())
                }
                for j in 0..<7 {
                    let t = Double(j) / 6.0
                    pen(p, [at(-110 + t * 520, -130 + drop), at(-70 + t * 470, 60 + drop)],
                        weight: 2.4, colour: Ink.jet.al(0.40), wobble: 1.0, taper: true,
                        seed: rng.next())
                }
            }
            penEdge(p, wing, weight: 5.0, colour: Ink.jet.al(0.86),
                    seed: seed &+ UInt64(71 + side))
        }
    } else {
        let reach = form == 1 ? 470.0 : (form == 2 ? 520.0 : 380.0)
        let deep = form == 1 ? 150.0 : 96.0
        let wing = [at(-176, -110), at(-40, -110 - deep * 0.5),
                    at(reach * 0.62, -deep), at(reach, -10),
                    at(reach * 0.70, deep * 0.62), at(-150, 30)]
        modelBody(p, wing, tone: form == 1 ? Ink.wingGreen : tone.up(0.04),
                  depth: 3, spacing: 15, seed: seed &+ 61, edge: 5.0)
        p.inside(pathOf(wing)) {
            var rng = Spark(seed &+ 67)
            pen(p, [at(-170, -96), at(reach * 0.5, -deep * 0.86), at(reach * 0.96, -16)],
                weight: 9.0, colour: Ink.jet.al(0.76), wobble: 1.2, taper: true,
                seed: seed &+ 69)
            for j in 0..<15 {
                let t = Double(j) / 14.0
                pen(p, [at(-150 + t * reach * 0.96, -deep * 0.86),
                        at(-110 + t * reach * 0.90, deep * 0.60)],
                    weight: rng.r(2.6, 5.0), colour: Ink.jet.al(rng.r(0.32, 0.60)),
                    wobble: 1.0, taper: true, seed: rng.next())
            }
            if form == 0 || form == 2 {
                for j in 0..<9 {
                    let t = Double(j) / 8.0
                    penBroken(p, [at(-160 + t * 40, -100 + t * 120),
                                  at(20 + t * 40, -70 + t * 110)],
                              weight: 4.4, colour: Ink.moonCool.al(0.40), pieces: 2,
                              gap: 0.12, wobble: 1.2, seed: rng.next())
                }
            }
        }
    }

    eyeAt(p, Double(headC.x) - 34, Double(headC.y) - 30, form == 3 ? 40 : 30,
          iris: form == 3 ? Ink.plumeRust : Ink.jetPale, seed: seed &+ 81)
    if form == 3 {
        eyeAt(p, Double(headC.x) + 50, Double(headC.y) - 46, 28,
              iris: Ink.plumeRust.down(0.24), seed: seed &+ 83)
    }
    pen(p, [at(-360, 20), at(-300, 52), at(-240, 40)], weight: 8.0,
        colour: Ink.jet.al(0.78), wobble: 0.8, taper: true, seed: seed &+ 85)

    if form != 3 {
        let curl = form == 1 ? 0.34 : 0.20
        antenna(p, from: at(-340, -70), length: 780, curl: curl, tone: tone,
                seed: seed &+ 91)
        antenna(p, from: at(-330, -20), length: 690, curl: curl * 0.62,
                tone: tone.down(0.18), seed: seed &+ 93)
    } else {
        antenna(p, from: at(-340, -60), length: 170, curl: 0.5, tone: tone,
                seed: seed &+ 91)
    }

    if form == 0 || form == 2 {
        for k in 0..<2 {
            let y = 40.0 + Double(k) * 34
            pen(p, [at(abdoLong - 40, y), at(abdoLong + 200, y + Double(k) * 60 - 30)],
                weight: 9.0, colour: tone.down(0.30), wobble: 0.8, taper: true,
                seed: seed &+ UInt64(101 + k))
        }
    }
}

func owlPlate(_ p: Sheet, _ art: VoiceArt, seed: UInt64) {
    let tone = hueWash(art.hue)
    let cx = 620.0
    let cy = 940.0
    let big = art.variant == 0 || art.variant == 1 ? 1.14 : (art.variant == 3 ? 0.78 : 1.0)
    let perchY = cy + 340 * big

    branchAt(p, from: pt(-40, perchY + 40), to: pt(p.w + 40, perchY - 20),
             thick: 30 * big, tone: Ink.barkDeep, seed: seed &+ 3)

    var body: [CGPoint] = []
    let steps = 46
    for i in 0...steps {
        let t = Double(i) / Double(steps)
        let a = -Double.pi / 2 + t * 6.283185
        let rx = 240.0 * big * (1.0 + 0.12 * sin(a * 2))
        let ry = 330.0 * big
        body.append(pt(cx + cos(a) * rx, cy + sin(a) * ry * (a > 0 ? 1.05 : 0.86)))
    }
    modelBody(p, body, tone: tone, depth: 3, spacing: 5.4, seed: seed &+ 5)
    featherRows(p, pathOf(body), rows: 13, spacing: 22 * big, wide: 62 * big,
                tone: tone, seed: seed &+ 7)

    let wing = [pt(cx + 60 * big, cy - 250 * big), pt(cx + 250 * big, cy - 80 * big),
                pt(cx + 240 * big, cy + 190 * big), pt(cx + 100 * big, cy + 300 * big),
                pt(cx + 20 * big, cy + 100 * big)]
    pool(p, wing, tone.down(0.20), strength: 0.44, bleed: 5, seed: seed &+ 11)
    featherRows(p, pathOf(wing), rows: 8, spacing: 26 * big, wide: 74 * big,
                tone: tone.down(0.24), seed: seed &+ 13)
    penEdge(p, wing, weight: 2.6, colour: Ink.jet.al(0.62), seed: seed &+ 15)

    let headY = cy - 330 * big
    let disc = lump(cx: cx, cy: headY, rx: 236 * big, ry: 210 * big,
                    rough: 0.04, steps: 40, seed: seed &+ 17)
    modelBody(p, disc, tone: tone.up(0.10), depth: 3, spacing: 4.4, seed: seed &+ 19)
    p.inside(pathOf(disc)) {
        var rng = Spark(seed &+ 21)
        for k in 0..<70 {
            let a = Double(k) / 70.0 * 6.283185
            pen(p, [pt(cx + cos(a) * 40 * big, headY + sin(a) * 40 * big),
                    pt(cx + cos(a) * 250 * big, headY + sin(a) * 226 * big)],
                weight: rng.r(1.6, 3.4), colour: tone.down(rng.r(0.14, 0.52)).al(0.72),
                wobble: 0.6, taper: true, seed: rng.next())
        }
    }
    let ringL = ringPts(cx: cx - 108 * big, cy: headY - 10 * big, rx: 116 * big,
                        ry: 120 * big, steps: 34)
    let ringR = ringPts(cx: cx + 108 * big, cy: headY - 10 * big, rx: 116 * big,
                        ry: 120 * big, steps: 34)
    penEdge(p, ringL, weight: 3.4, colour: Ink.jet.al(0.60), seed: seed &+ 23)
    penEdge(p, ringR, weight: 3.4, colour: Ink.jet.al(0.60), seed: seed &+ 25)

    let irisTable: [Wash] = [Ink.eyeAmber, Ink.eyeDark.up(0.10), Ink.eyeAmber,
                             Ink.eyeAmber, Ink.eyeDark.up(0.10), Ink.eyeAmber, Ink.eyeAmber]
    let iris = irisTable[art.variant % irisTable.count]
    eyeAt(p, cx - 108 * big, headY - 12 * big, 62 * big, iris: iris, seed: seed &+ 31)
    eyeAt(p, cx + 108 * big, headY - 12 * big, 62 * big, iris: iris, seed: seed &+ 33)

    let beak = [pt(cx - 34 * big, headY + 54 * big), pt(cx + 34 * big, headY + 54 * big),
                pt(cx + 10 * big, headY + 168 * big), pt(cx - 14 * big, headY + 160 * big)]
    modelBody(p, beak, tone: Ink.beak.up(0.18), depth: 2, spacing: 3.0,
              seed: seed &+ 41, edge: 2.4)
    pen(p, [pt(cx, headY + 60 * big), pt(cx, headY + 150 * big)], weight: 2.4,
        colour: Ink.jet.al(0.60), wobble: 0.3, taper: true, seed: seed &+ 43)

    if art.variant == 0 || art.variant == 2 || art.variant == 5 {
        for side in 0..<2 {
            let sx = cx + (side == 0 ? -1 : 1) * 168 * big
            let tuft = [pt(sx, headY - 150 * big),
                        pt(sx + (side == 0 ? -70 : 70) * big, headY - 300 * big),
                        pt(sx + (side == 0 ? 34 : -34) * big, headY - 130 * big)]
            modelBody(p, tuft, tone: tone.down(0.16), depth: 2, spacing: 3.4,
                      seed: seed &+ UInt64(51 + side), edge: 2.4)
        }
    }

    for side in 0..<2 {
        let fx = cx + (side == 0 ? -100 : 90) * big
        pen(p, [pt(fx, cy + 280 * big), pt(fx, perchY - 20)], weight: 26 * big,
            colour: Ink.beak.up(0.30), wobble: 0.4, taper: false,
            seed: seed &+ UInt64(61 + side))
        for k in 0..<3 {
            let a = -0.7 + Double(k) * 0.7
            let tip = pt(fx + sin(a) * 74 * big, perchY + 10 + cos(a) * 26 * big)
            pen(p, [pt(fx, perchY - 16), tip], weight: 13 * big,
                colour: Ink.beak.up(0.24), wobble: 0.4, taper: true,
                seed: seed &+ UInt64(71 + side * 4 + k))
            pen(p, [tip, pt(Double(tip.x) + sin(a) * 30 * big, Double(tip.y) + 40 * big)],
                weight: 6 * big, colour: Ink.jet, wobble: 0.3, taper: true,
                seed: seed &+ UInt64(81 + side * 4 + k))
        }
    }

    if art.variant == 1 || art.variant == 4 {
        p.inside(pathOf(body)) {
            var rng = Spark(seed &+ 91)
            for k in 0..<11 {
                let y = cy - 260 * big + Double(k) * 56 * big
                penBroken(p, [pt(cx - 250 * big, y), pt(cx, y + 22 * big),
                              pt(cx + 250 * big, y)],
                          weight: 8.0, colour: Ink.jet.al(0.36), pieces: 3, gap: 0.12,
                          wobble: 2.0, seed: rng.next())
            }
        }
    }
}

func nightjarPlate(_ p: Sheet, _ art: VoiceArt, seed: UInt64) {
    let tone = hueWash(art.hue)
    let cx = 600.0
    let cy = 900.0
    let perchY = cy + 190.0
    branchAt(p, from: pt(-40, perchY + 30), to: pt(p.w + 40, perchY - 10),
             thick: 26, tone: Ink.barkDeep, seed: seed &+ 3)

    var body: [CGPoint] = []
    let steps = 44
    for i in 0...steps {
        let t = Double(i) / Double(steps)
        let a = -Double.pi / 2 + t * 6.283185
        body.append(pt(cx + cos(a) * 400, cy + sin(a) * 150 * (a > 0 ? 1.1 : 0.9)))
    }
    modelBody(p, body, tone: tone, depth: 3, spacing: 5.0, seed: seed &+ 5)
    featherRows(p, pathOf(body), rows: 9, spacing: 20, wide: 58, tone: tone,
                seed: seed &+ 7)
    p.inside(pathOf(body)) {
        var rng = Spark(seed &+ 11)
        for _ in 0..<220 {
            let x = rng.r(cx - 400, cx + 400)
            let y = rng.r(cy - 150, cy + 150)
            let blot = lump(cx: x, cy: y, rx: rng.r(10, 34), ry: rng.r(7, 22),
                            rough: 0.30, steps: 14, seed: rng.next())
            pool(p, blot, Ink.jet, strength: rng.r(0.18, 0.44), bleed: 3, seed: rng.next())
        }
        for k in 0..<9 {
            let x = cx - 260 + Double(k) * 78
            penBroken(p, [pt(x, cy - 150), pt(x + 30, cy + 150)], weight: 5.0,
                      colour: Ink.moonCool.al(0.30), pieces: 3, gap: 0.14, wobble: 1.6,
                      seed: seed &+ UInt64(21 + k))
        }
    }

    let tail = [pt(cx + 340, cy - 90), pt(cx + 660, cy - 30),
                pt(cx + 660, cy + 90), pt(cx + 330, cy + 110)]
    pool(p, tail, tone.down(0.20), strength: 0.56, bleed: 5, seed: seed &+ 31)
    for k in 0..<7 {
        let t = Double(k) / 6.0
        pen(p, [pt(cx + 340, cy - 80 + t * 180),
                pt(cx + 650, cy - 30 + t * 120)],
            weight: 8.0, colour: Ink.jet.al(0.46), wobble: 0.6, taper: true,
            seed: seed &+ UInt64(33 + k))
    }
    if art.variant == 0 {
        pen(p, [pt(cx + 560, cy - 20), pt(cx + 640, cy - 8)], weight: 18,
            colour: Ink.moonlit.al(0.66), wobble: 0.5, taper: true, seed: seed &+ 41)
    }
    penEdge(p, tail, weight: 2.6, colour: Ink.jet.al(0.76), seed: seed &+ 43)

    let headX = cx - 350.0
    let headY = cy - 66.0
    let head = lump(cx: headX, cy: headY, rx: 156, ry: 128, rough: 0.05, steps: 30,
                    seed: seed &+ 51)
    modelBody(p, head, tone: tone.up(0.08), depth: 3, spacing: 4.0, seed: seed &+ 53)
    eyeAt(p, headX - 40, headY - 34, 54, iris: Ink.eyeDark.up(0.18), seed: seed &+ 55)
    let gape = [pt(headX - 150, headY + 32), pt(headX - 40, headY + 58),
                pt(headX + 90, headY + 44), pt(headX - 40, headY + 84)]
    p.shape(gape, Ink.jet)
    penEdge(p, gape, weight: 2.4, colour: Ink.moonCool.al(0.44), seed: seed &+ 57)
    var rng = Spark(seed &+ 61)
    for k in 0..<9 {
        let a = -1.3 + Double(k) / 8.0 * 1.2
        pen(p, [pt(headX - 120, headY + 26),
                pt(headX - 120 + cos(a) * 150, headY + 26 + sin(a) * 90)],
            weight: 2.6, colour: Ink.jet.al(0.80), wobble: 0.5, taper: true,
            seed: rng.next())
    }
    for side in 0..<2 {
        let fx = cx - 60 + Double(side) * 130
        pen(p, [pt(fx, cy + 130), pt(fx + 8, perchY - 8)], weight: 14,
            colour: Ink.beak.up(0.24), wobble: 0.3, taper: false,
            seed: seed &+ UInt64(71 + side))
    }
}

func waderPlate(_ p: Sheet, _ art: VoiceArt, seed: UInt64) {
    let tone = hueWash(art.hue)
    let cx = 620.0
    let cy = 880.0
    let waterY = cy + 330.0
    let upright = art.variant == 3
    let tall = art.variant == 3 || art.variant == 4 ? 1.20 : 0.90

    let body = lump(cx: cx, cy: cy, rx: 250 * tall, ry: 176 * tall, rough: 0.05,
                    steps: 34, seed: seed &+ 5)
    modelBody(p, body, tone: tone, depth: 3, spacing: 5.0, seed: seed &+ 7)
    featherRows(p, pathOf(body), rows: 9, spacing: 22, wide: 60, tone: tone,
                seed: seed &+ 9)

    let wing = [pt(cx - 120 * tall, cy - 120 * tall), pt(cx + 200 * tall, cy - 40 * tall),
                pt(cx + 250 * tall, cy + 110 * tall), pt(cx - 60 * tall, cy + 130 * tall)]
    pool(p, wing, tone.down(0.22), strength: 0.42, bleed: 5, seed: seed &+ 11)
    featherRows(p, pathOf(wing), rows: 6, spacing: 26, wide: 76, tone: tone.down(0.26),
                seed: seed &+ 13)
    penEdge(p, wing, weight: 2.4, colour: Ink.jet.al(0.60), seed: seed &+ 15)

    let neckTop = upright ? cy - 560 * tall : cy - 380 * tall
    let neckX = upright ? cx - 130 * tall : cx - 200 * tall
    var neck: [CGPoint] = []
    for k in 0...20 {
        let t = Double(k) / 20.0
        let x = cx - 130 * tall + (neckX - cx + 130 * tall) * t
            + (upright ? 0 : sin(t * 3.14159) * 90 * tall)
        neck.append(pt(x, cy - 120 * tall + (neckTop - cy + 120 * tall) * t))
    }
    var neckForm: [CGPoint] = []
    for (i, q) in neck.enumerated() {
        let t = Double(i) / Double(neck.count - 1)
        neckForm.append(pt(Double(q.x) - (76 - t * 30) * tall, Double(q.y)))
    }
    for (i, q) in neck.enumerated().reversed() {
        let t = Double(i) / Double(neck.count - 1)
        neckForm.append(pt(Double(q.x) + (76 - t * 30) * tall, Double(q.y)))
    }
    modelBody(p, neckForm, tone: tone.up(0.06), depth: 3, spacing: 4.2, seed: seed &+ 21)
    if art.variant == 3 {
        p.inside(pathOf(neckForm)) {
            for k in 0..<5 {
                let x = neckX - 60 + Double(k) * 30
                pen(p, [pt(x, cy - 120 * tall), pt(x + 20, neckTop)], weight: 9.0,
                    colour: Ink.jet.al(0.44), wobble: 1.0, taper: true,
                    seed: seed &+ UInt64(23 + k))
            }
        }
    }

    let headX = Double(neck[neck.count - 1].x)
    let headY = neckTop - 20
    let head = lump(cx: headX, cy: headY, rx: 96 * tall, ry: 80 * tall,
                    rough: 0.05, steps: 24, seed: seed &+ 31)
    modelBody(p, head, tone: tone.up(0.12), depth: 2, spacing: 3.6, seed: seed &+ 33)
    eyeAt(p, headX - 30 * tall, headY - 14 * tall, 26 * tall,
          iris: art.variant == 4 ? Ink.plumeRust : Ink.eyeAmber, seed: seed &+ 35)

    let billLen = (art.variant == 0 || art.variant == 3) ? 330.0 : 190.0
    let billUp = upright ? -230.0 : -30.0
    let bill = [pt(headX - 70 * tall, headY - 22 * tall),
                pt(headX - 70 * tall - billLen, headY + billUp),
                pt(headX - 66 * tall - billLen * 0.98, headY + billUp + 30),
                pt(headX - 60 * tall, headY + 30 * tall)]
    modelBody(p, bill, tone: Ink.beak.up(0.22), depth: 2, spacing: 3.0,
              seed: seed &+ 41, edge: 2.4)

    for side in 0..<2 {
        let lx = cx + (side == 0 ? -60 : 70) * tall
        pen(p, [pt(lx, cy + 150 * tall), pt(lx + 20, cy + 280 * tall),
                pt(lx - 10, waterY)],
            weight: 20 * tall, colour: Ink.plumeRust.down(0.24), wobble: 0.5,
            taper: false, seed: seed &+ UInt64(51 + side))
        pen(p, [pt(lx - 6, cy + 150 * tall), pt(lx + 14, cy + 280 * tall)],
            weight: 5.0, colour: Ink.moonCool.al(0.30), wobble: 0.3, taper: true,
            seed: seed &+ UInt64(61 + side))
    }

    poolBand(p, from: waterY - 20, to: waterY + 90, Ink.water, strength: 0.50,
             seed: seed &+ 71)
    var rng = Spark(seed &+ 73)
    for k in 0..<7 {
        let rad = 60.0 + Double(k) * 62
        penBroken(p, ringPts(cx: cx, cy: waterY + 10, rx: rad * 1.7, ry: rad * 0.34,
                             steps: 40),
                  weight: 2.6, colour: Ink.moonlit.al(0.34 - Double(k) * 0.03),
                  pieces: 3, gap: 0.20, wobble: 1.2, seed: rng.next())
    }
}

func aerialPlate(_ p: Sheet, _ art: VoiceArt, seed: UInt64) {
    let tone = hueWash(art.hue)
    let cx = 620.0
    let cy = art.variant == 0 ? 720.0 : 900.0

    if art.variant == 0 {
        moonDisc(p, cx: 930, cy: 430, rad: 190, lit: 0.92, waxing: true, seed: seed &+ 3)
        let body = lump(cx: cx, cy: cy, rx: 190, ry: 78, rough: 0.05, steps: 28,
                        seed: seed &+ 5)
        modelBody(p, body, tone: tone, depth: 3, spacing: 4.4, seed: seed &+ 7)
        for side in 0..<2 {
            let dir = side == 0 ? -1.0 : 1.0
            let root = pt(cx + dir * 120, cy - 30)
            let bend = pt(cx + dir * 400, cy - 250)
            let tip = pt(cx + dir * 700, cy - 130)
            let wing = [root, bend, tip,
                        pt(cx + dir * 420, cy - 110), pt(cx + dir * 130, cy + 40)]
            modelBody(p, wing, tone: tone.down(0.10), depth: 3, spacing: 16,
                      seed: seed &+ UInt64(11 + side), edge: 4.0)
            featherRows(p, pathOf(wing), rows: 5, spacing: 26, wide: 92,
                        tone: tone.down(0.30), seed: seed &+ UInt64(15 + side))
            pen(p, [pt(cx + dir * 300, cy - 190), pt(cx + dir * 470, cy - 150)],
                weight: 22, colour: Ink.moonlit.al(0.74), wobble: 0.5, taper: true,
                seed: seed &+ UInt64(19 + side))
            penEdge(p, wing, weight: 3.0, colour: Ink.jet.al(0.84),
                    seed: seed &+ UInt64(23 + side))
        }
        let tail = [pt(cx + 170, cy - 40), pt(cx + 430, cy + 20),
                    pt(cx + 420, cy + 90), pt(cx + 160, cy + 60)]
        modelBody(p, tail, tone: tone.down(0.20), depth: 2, spacing: 4.0,
                  seed: seed &+ 31, edge: 2.6)
        let head = lump(cx: cx - 200, cy: cy - 24, rx: 96, ry: 78, rough: 0.05,
                        steps: 24, seed: seed &+ 41)
        modelBody(p, head, tone: tone.up(0.10), depth: 2, spacing: 3.4, seed: seed &+ 43)
        eyeAt(p, cx - 244, cy - 44, 34, iris: Ink.eyeDark.up(0.16), seed: seed &+ 45)
        return
    }

    let perchY = cy + 300.0
    branchAt(p, from: pt(-40, perchY + 40), to: pt(p.w + 40, perchY - 30),
             thick: 24, tone: Ink.barkDeep, seed: seed &+ 3)
    let stand = art.variant == 2 ? 1.0 : 0.9
    let body = lump(cx: cx, cy: cy, rx: 230 * stand, ry: 190 * stand, rough: 0.05,
                    steps: 32, seed: seed &+ 5)
    modelBody(p, body, tone: tone, depth: 3, spacing: 5.0, seed: seed &+ 7)
    featherRows(p, pathOf(body), rows: 10, spacing: 22, wide: 60, tone: tone,
                seed: seed &+ 9)
    if art.variant == 2 {
        p.inside(pathOf(body)) {
            for k in 0..<2 {
                let y = cy - 30 + Double(k) * 96
                let band = [pt(cx - 240, y), pt(cx + 240, y - 12),
                            pt(cx + 240, y + 44), pt(cx - 240, y + 56)]
                pool(p, band, Ink.jet, strength: 0.62, bleed: 4,
                     seed: seed &+ UInt64(11 + k))
            }
        }
    } else {
        p.inside(pathOf(body)) {
            var rng = Spark(seed &+ 13)
            for _ in 0..<70 {
                let x = rng.r(cx - 200, cx + 200)
                let y = rng.r(cy - 60, cy + 180)
                let spot = lump(cx: x, cy: y, rx: rng.r(12, 26), ry: rng.r(9, 18),
                                rough: 0.26, steps: 14, seed: rng.next())
                pool(p, spot, Ink.jet, strength: 0.44, bleed: 3, seed: rng.next())
            }
        }
    }
    let wing = [pt(cx - 40, cy - 170 * stand), pt(cx + 220 * stand, cy - 40),
                pt(cx + 250 * stand, cy + 140), pt(cx - 20, cy + 170)]
    pool(p, wing, tone.down(0.22), strength: 0.44, bleed: 5, seed: seed &+ 21)
    featherRows(p, pathOf(wing), rows: 6, spacing: 26, wide: 74, tone: tone.down(0.26),
                seed: seed &+ 23)
    penEdge(p, wing, weight: 2.4, colour: Ink.jet.al(0.60), seed: seed &+ 25)
    let tail = [pt(cx + 190 * stand, cy + 40), pt(cx + 470, cy + 150),
                pt(cx + 450, cy + 220), pt(cx + 170 * stand, cy + 170)]
    modelBody(p, tail, tone: tone.down(0.18), depth: 2, spacing: 4.0,
              seed: seed &+ 31, edge: 2.6)

    let headX = cx - 220 * stand
    let headY = cy - 210 * stand
    let head = lump(cx: headX, cy: headY, rx: 128, ry: 112, rough: 0.05, steps: 26,
                    seed: seed &+ 41)
    modelBody(p, head, tone: tone.up(0.10), depth: 2, spacing: 3.6, seed: seed &+ 43)
    eyeAt(p, headX - 40, headY - 20, 32, iris: Ink.eyeDark.up(0.14), seed: seed &+ 45)
    let bill = [pt(headX - 100, headY + 4), pt(headX - 240, headY + 26),
                pt(headX - 96, headY + 48)]
    modelBody(p, bill, tone: Ink.beak.up(0.20), depth: 2, spacing: 2.6,
              seed: seed &+ 47, edge: 2.2)
    for side in 0..<2 {
        let lx = cx + (side == 0 ? -70 : 60)
        pen(p, [pt(lx, cy + 160), pt(lx + 14, perchY - 12)], weight: 15,
            colour: Ink.beak.up(0.26), wobble: 0.4, taper: false,
            seed: seed &+ UInt64(51 + side))
        for k in 0..<3 {
            let a = -0.7 + Double(k) * 0.7
            pen(p, [pt(lx + 14, perchY - 12),
                    pt(lx + 14 + sin(a) * 56, perchY + 6 + cos(a) * 20)],
                weight: 7.0, colour: Ink.beak.up(0.20), wobble: 0.3, taper: true,
                seed: seed &+ UInt64(61 + side * 4 + k))
        }
    }
}

func canidPlate(_ p: Sheet, _ art: VoiceArt, seed: UInt64) {
    let tone = hueWash(art.hue)
    let cx = 600.0
    let cy = 900.0
    let low = art.variant == 3
    let groundY = cy + 400.0

    poolBand(p, from: groundY - 40, to: p.h, Ink.mud, strength: 0.50, seed: seed &+ 3)

    let body = lump(cx: cx, cy: cy, rx: 340, ry: low ? 200 : 168, rough: 0.06,
                    steps: 34, seed: seed &+ 5)
    modelBody(p, body, tone: tone, depth: 3, spacing: 5.4, seed: seed &+ 7)
    furEdge(p, body, length: 26, tone: tone, seed: seed &+ 9)
    p.inside(pathOf(body)) {
        var rng = Spark(seed &+ 11)
        for _ in 0..<260 {
            let x = rng.r(cx - 340, cx + 340)
            let y = rng.r(cy - 200, cy + 200)
            pen(p, [pt(x, y), pt(x + rng.r(20, 70), y + rng.r(-16, 16))],
                weight: rng.r(1.4, 3.4),
                colour: (rng.odds(0.6) ? tone.down(rng.r(0.16, 0.52)) : Ink.moonCool)
                    .al(rng.r(0.14, 0.44)),
                wobble: 0.5, taper: true, seed: rng.next())
        }
        if low {
            for k in 0..<4 {
                let x = cx - 200 + Double(k) * 130
                let mask = [pt(x, cy - 200), pt(x + 70, cy - 200),
                            pt(x + 70, cy + 200), pt(x, cy + 200)]
                pool(p, mask, Ink.jet, strength: 0.30, bleed: 5,
                     seed: seed &+ UInt64(21 + k))
            }
        }
    }

    let tailBase = pt(cx + 300, cy - 30)
    let tailTip = low ? pt(cx + 700, cy - 210) : pt(cx + 720, cy - 320)
    var spine: [CGPoint] = []
    for k in 0...20 {
        let t = Double(k) / 20.0
        spine.append(pt(Double(tailBase.x) + (Double(tailTip.x) - Double(tailBase.x)) * t,
                        Double(tailBase.y) + (Double(tailTip.y) - Double(tailBase.y)) * t
                            + sin(t * 3.14159) * 90))
    }
    var brush: [CGPoint] = []
    for (i, q) in spine.enumerated() {
        let t = Double(i) / Double(spine.count - 1)
        brush.append(pt(Double(q.x), Double(q.y) - (60 + 60 * sin(t * 2.6))))
    }
    for (i, q) in spine.enumerated().reversed() {
        let t = Double(i) / Double(spine.count - 1)
        brush.append(pt(Double(q.x), Double(q.y) + (60 + 60 * sin(t * 2.6))))
    }
    modelBody(p, brush, tone: tone.down(0.10), depth: 3, spacing: 5.0, seed: seed &+ 31)
    furEdge(p, brush, length: 34, tone: tone.down(0.10), seed: seed &+ 33)
    if low {
        p.inside(pathOf(brush)) {
            for k in 0..<5 {
                let t = 0.1 + Double(k) * 0.18
                let a = pt(Double(tailBase.x) + (Double(tailTip.x) - Double(tailBase.x)) * t,
                           Double(tailBase.y) + (Double(tailTip.y) - Double(tailBase.y)) * t)
                pen(p, [pt(Double(a.x), Double(a.y) - 160), pt(Double(a.x) + 40, Double(a.y) + 160)],
                    weight: 40, colour: Ink.jet.al(0.44), wobble: 1.0, taper: false,
                    seed: seed &+ UInt64(41 + k))
            }
        }
    }

    let neckUp = low ? 90.0 : 250.0
    let headX = cx - 330.0
    let headY = cy - neckUp
    let neck = [pt(cx - 200, cy - 120), pt(headX + 40, headY - 100),
                pt(headX + 120, headY + 90), pt(cx - 130, cy + 110)]
    modelBody(p, neck, tone: tone.up(0.04), depth: 3, spacing: 5.0, seed: seed &+ 51)
    furEdge(p, neck, length: 30, tone: tone, seed: seed &+ 53)

    let head = lump(cx: headX, cy: headY, rx: 150, ry: 128, rough: 0.06, steps: 28,
                    seed: seed &+ 61)
    modelBody(p, head, tone: tone.up(0.08), depth: 3, spacing: 4.0, seed: seed &+ 63)
    let muzzleTip = low ? pt(headX - 250, headY + 90) : pt(headX - 300, headY - 130)
    let muzzle = [pt(headX - 40, headY - 40), muzzleTip,
                  pt(Double(muzzleTip.x) + 30, Double(muzzleTip.y) + 60),
                  pt(headX - 20, headY + 90)]
    modelBody(p, muzzle, tone: tone.up(0.02), depth: 3, spacing: 4.0, seed: seed &+ 65)
    furEdge(p, muzzle, length: 20, tone: tone, seed: seed &+ 67)
    p.shape(lump(cx: Double(muzzleTip.x) + 6, cy: Double(muzzleTip.y) + 16, rx: 34, ry: 26,
                 rough: 0.10, steps: 18, seed: seed &+ 69), Ink.jet)

    for side in 0..<2 {
        let ex = headX + Double(side) * 96 + 20
        let ey = headY - 130 - Double(side) * 16
        let ear = [pt(ex - 60, ey + 60), pt(ex + 10, ey - 150), pt(ex + 76, ey + 50)]
        modelBody(p, ear, tone: tone.down(0.10), depth: 2, spacing: 3.4,
                  seed: seed &+ UInt64(71 + side), edge: 2.6)
        p.shape([pt(ex - 30, ey + 40), pt(ex + 10, ey - 96), pt(ex + 46, ey + 34)],
                Ink.jet.al(0.44))
        furEdge(p, ear, length: 18, tone: tone.down(0.12), seed: seed &+ UInt64(75 + side))
    }
    eyeAt(p, headX - 60, headY - 34, 30, iris: Ink.eyeAmber, seed: seed &+ 81)
    eyeAt(p, headX + 70, headY - 44, 24, iris: Ink.eyeAmber.down(0.2), seed: seed &+ 83)

    if !low {
        let mouth = [pt(Double(muzzleTip.x) + 34, Double(muzzleTip.y) + 70),
                     pt(headX - 130, headY - 10), pt(headX - 40, headY + 40)]
        p.shape(mouth, Ink.jet)
        penEdge(p, mouth, weight: 2.4, colour: Ink.moonCool.al(0.36), seed: seed &+ 85)
    }

    for k in 0..<4 {
        let front = k < 2
        let lx = cx + (front ? -230.0 : 190.0) + Double(k % 2) * 70
        legLine(p, [pt(lx, cy + 130), pt(lx + (front ? -30 : 30), cy + 280),
                    pt(lx + (front ? 20 : -10), groundY)],
                weight: 62, tone: tone.down(0.14 + Double(k % 2) * 0.12),
                seed: seed &+ UInt64(91 + k))
        legLine(p, [pt(lx + (front ? 20 : -10), groundY - 20),
                    pt(lx + (front ? 74 : 44), groundY + 6)],
                weight: 34, tone: tone.down(0.24), seed: seed &+ UInt64(101 + k))
    }
}

func critterPlate(_ p: Sheet, _ art: VoiceArt, seed: UInt64) {
    let tone = hueWash(art.hue)
    let cx = 620.0
    let cy = 860.0
    let bat = art.variant == 1

    if bat {
        let body = lump(cx: cx, cy: cy, rx: 116, ry: 200, rough: 0.06, steps: 28,
                        seed: seed &+ 5)
        modelBody(p, body, tone: tone, depth: 3, spacing: 4.6, seed: seed &+ 7)
        furEdge(p, body, length: 22, tone: tone, seed: seed &+ 9)
        for side in 0..<2 {
            let dir = side == 0 ? -1.0 : 1.0
            let shoulder = pt(cx + dir * 70, cy - 130)
            let angles = [-0.30, 0.10, 0.55, 1.00]
            var tips: [CGPoint] = []
            for a in angles {
                let len = 470.0 - abs(a) * 90
                tips.append(pt(cx + dir * (150 + cos(a) * len),
                               cy - 130 + sin(a) * len))
            }
            let membrane = [shoulder, tips[0], tips[1], tips[2], tips[3],
                            pt(cx + dir * 60, cy + 190)]
            pool(p, membrane, tone.down(0.34), strength: 0.52, bleed: 6,
                 seed: seed &+ UInt64(11 + side))
            p.inside(pathOf(membrane)) {
                var rng = Spark(seed &+ UInt64(13 + side))
                for _ in 0..<90 {
                    let t = rng.d()
                    let u = rng.d()
                    let x = cx + dir * (60 + t * 520)
                    let y = cy - 130 + (u - 0.4) * 420
                    pen(p, [pt(x, y), pt(x + dir * rng.r(20, 60), y + rng.r(-14, 14))],
                        weight: rng.r(1.0, 2.2), colour: Ink.jet.al(rng.r(0.14, 0.34)),
                        wobble: 0.4, taper: true, seed: rng.next())
                }
            }
            for tip in tips {
                pen(p, [shoulder, pt((Double(shoulder.x) + Double(tip.x)) / 2,
                                     (Double(shoulder.y) + Double(tip.y)) / 2 - 30), tip],
                    weight: 11, colour: tone.down(0.16), wobble: 0.5, taper: true,
                    seed: seed &+ UInt64(21 + side))
                pen(p, [shoulder, tip], weight: 3.0, colour: Ink.moonCool.al(0.28),
                    wobble: 0.3, taper: true, seed: seed &+ UInt64(31 + side))
            }
            penEdge(p, membrane, weight: 3.0, colour: Ink.jet.al(0.84),
                    seed: seed &+ UInt64(41 + side))
        }
        let head = lump(cx: cx, cy: cy - 250, rx: 108, ry: 92, rough: 0.06, steps: 24,
                        seed: seed &+ 51)
        modelBody(p, head, tone: tone.up(0.10), depth: 2, spacing: 3.4, seed: seed &+ 53)
        furEdge(p, head, length: 18, tone: tone, seed: seed &+ 55)
        for side in 0..<2 {
            let dir = side == 0 ? -1.0 : 1.0
            let ear = [pt(cx + dir * 40, cy - 300), pt(cx + dir * 96, cy - 440),
                       pt(cx + dir * 130, cy - 280)]
            modelBody(p, ear, tone: tone.down(0.12), depth: 2, spacing: 3.0,
                      seed: seed &+ UInt64(61 + side), edge: 2.6)
        }
        eyeAt(p, cx - 44, cy - 268, 22, iris: Ink.eyeDark.up(0.20), seed: seed &+ 71)
        eyeAt(p, cx + 44, cy - 268, 22, iris: Ink.eyeDark.up(0.20), seed: seed &+ 73)
        p.shape(lump(cx: cx, cy: cy - 186, rx: 30, ry: 22, rough: 0.10, steps: 16,
                     seed: seed &+ 75), Ink.jet)
        return
    }

    branchAt(p, from: pt(-40, cy - 420), to: pt(400, cy - 300), thick: 34,
             tone: Ink.barkDeep, seed: seed &+ 3)
    let body = lump(cx: cx, cy: cy, rx: 300, ry: 150, rough: 0.06, steps: 30,
                    seed: seed &+ 5)
    modelBody(p, body, tone: tone, depth: 3, spacing: 5.0, seed: seed &+ 7)
    furEdge(p, body, length: 24, tone: tone, seed: seed &+ 9)
    for side in 0..<2 {
        let up = side == 0
        let yOff = up ? -1.0 : 1.0
        let flap = [pt(cx - 300, cy + yOff * 60),
                    pt(cx - 120, cy + yOff * 250),
                    pt(cx + 240, cy + yOff * 230),
                    pt(cx + 300, cy + yOff * 60)]
        pool(p, flap, tone.down(0.16), strength: 0.56, bleed: 6,
             seed: seed &+ UInt64(11 + side))
        p.inside(pathOf(flap)) {
            var rng = Spark(seed &+ UInt64(13 + side))
            for _ in 0..<160 {
                let x = rng.r(cx - 300, cx + 300)
                let y = cy + yOff * rng.r(40, 250)
                pen(p, [pt(x, y), pt(x + rng.r(-40, 40), y + yOff * rng.r(20, 70))],
                    weight: rng.r(1.2, 2.8), colour: tone.down(rng.r(0.10, 0.50)).al(0.60),
                    wobble: 0.5, taper: true, seed: rng.next())
            }
        }
        penEdge(p, flap, weight: 3.0, colour: Ink.jet.al(0.82),
                seed: seed &+ UInt64(21 + side))
        furEdge(p, flap, length: 20, tone: tone.down(0.14), seed: seed &+ UInt64(23 + side))
    }
    let tail = [pt(cx + 260, cy - 130), pt(cx + 700, cy - 210),
                pt(cx + 700, cy + 130), pt(cx + 250, cy + 120)]
    pool(p, tail, tone.down(0.10), strength: 0.54, bleed: 6, seed: seed &+ 31)
    furEdge(p, tail, length: 44, tone: tone.down(0.06), seed: seed &+ 33)
    p.inside(pathOf(tail)) {
        var rng = Spark(seed &+ 35)
        for _ in 0..<200 {
            let x = rng.r(cx + 250, cx + 700)
            let y = rng.r(cy - 200, cy + 130)
            pen(p, [pt(x, y), pt(x + rng.r(40, 120), y + rng.r(-24, 24))],
                weight: rng.r(1.4, 3.0), colour: tone.down(rng.r(0.10, 0.46)).al(0.62),
                wobble: 0.6, taper: true, seed: rng.next())
        }
    }
    let headX = cx - 300.0
    let headY = cy - 60.0
    let head = lump(cx: headX, cy: headY, rx: 140, ry: 120, rough: 0.06, steps: 26,
                    seed: seed &+ 41)
    modelBody(p, head, tone: tone.up(0.10), depth: 2, spacing: 3.8, seed: seed &+ 43)
    furEdge(p, head, length: 18, tone: tone, seed: seed &+ 45)
    eyeAt(p, headX - 44, headY - 30, 46, iris: Ink.eyeDark.up(0.14), seed: seed &+ 47)
    for side in 0..<2 {
        let ex = headX + 20 + Double(side) * 100
        let ey = headY - 120 + Double(side) * 12
        let ear = ringPts(cx: ex, cy: ey, rx: 52, ry: 62, steps: 20)
        modelBody(p, ear, tone: tone.down(0.10), depth: 2, spacing: 3.0,
                  seed: seed &+ UInt64(51 + side), edge: 2.4)
    }
    p.shape(lump(cx: headX - 128, cy: headY + 16, rx: 26, ry: 20, rough: 0.10,
                 steps: 16, seed: seed &+ 61), Ink.jet)
    var rng = Spark(seed &+ 63)
    for k in 0..<10 {
        let a = -0.9 + Double(k) / 9.0 * 1.8
        pen(p, [pt(headX - 120, headY + 20),
                pt(headX - 120 + cos(a) * -200, headY + 20 + sin(a) * 120)],
            weight: 2.2, colour: Ink.moonlit.al(0.44), wobble: 0.4, taper: true,
            seed: rng.next())
    }
}

func loonPlate(_ p: Sheet, _ art: VoiceArt, seed: UInt64) {
    let tone = Ink.plumeDark
    let cx = 620.0
    let cy = 940.0
    let waterY = cy + 120.0

    let body = lump(cx: cx + 40, cy: cy, rx: 400, ry: 150, rough: 0.05, steps: 34,
                    seed: seed &+ 5)
    modelBody(p, body, tone: tone, depth: 3, spacing: 5.0, seed: seed &+ 7)
    p.inside(pathOf(body)) {
        var rng = Spark(seed &+ 11)
        for row in 0..<8 {
            for col in 0..<26 {
                let x = cx - 350 + Double(col) * 32 + Double(row % 2) * 16
                let y = cy - 130 + Double(row) * 30
                if rng.odds(0.62) {
                    let sq = [pt(x - 9, y - 7), pt(x + 9, y - 7),
                              pt(x + 9, y + 7), pt(x - 9, y + 7)]
                    p.shape(sq, Ink.moonlit.al(rng.r(0.44, 0.86)))
                }
            }
        }
    }
    let neckX = cx - 340.0
    let neck = [pt(neckX + 90, cy - 60), pt(neckX - 40, cy - 420),
                pt(neckX + 130, cy - 430), pt(neckX + 240, cy - 40)]
    modelBody(p, neck, tone: tone.up(0.04), depth: 3, spacing: 4.4, seed: seed &+ 21)
    p.inside(pathOf(neck)) {
        for k in 0..<9 {
            let y = cy - 300 + Double(k) * 22
            pen(p, [pt(neckX - 30, y), pt(neckX + 200, y - 8)], weight: 8.0,
                colour: Ink.moonlit.al(0.62), wobble: 0.6, taper: true,
                seed: seed &+ UInt64(23 + k))
        }
    }
    let headX = neckX + 40
    let headY = cy - 470.0
    let head = lump(cx: headX, cy: headY, rx: 128, ry: 104, rough: 0.05, steps: 26,
                    seed: seed &+ 31)
    modelBody(p, head, tone: tone.up(0.02), depth: 2, spacing: 3.6, seed: seed &+ 33)
    eyeAt(p, headX - 30, headY - 20, 30, iris: Wash(r: 0.686, g: 0.208, b: 0.157),
          seed: seed &+ 35)
    let bill = [pt(headX - 100, headY - 16), pt(headX - 350, headY + 26),
                pt(headX - 96, headY + 52)]
    modelBody(p, bill, tone: Ink.jet.up(0.20), depth: 2, spacing: 2.8,
              seed: seed &+ 41, edge: 2.6)

    poolBand(p, from: waterY - 10, to: p.h, Ink.water, strength: 0.62, seed: seed &+ 51)
    var rng = Spark(seed &+ 53)
    for k in 0..<9 {
        let rad = 80.0 + Double(k) * 90
        penBroken(p, ringPts(cx: cx, cy: waterY + 20, rx: rad * 1.9, ry: rad * 0.30,
                             steps: 44),
                  weight: 3.0, colour: Ink.moonlit.al(0.36 - Double(k) * 0.03),
                  pieces: 3, gap: 0.18, wobble: 1.4, seed: rng.next())
    }
    for _ in 0..<40 {
        let y = rng.r(waterY, p.h)
        let x = rng.r(0, p.w)
        pen(p, [pt(x, y), pt(x + rng.r(40, 150), y + rng.r(-3, 3))],
            weight: rng.r(1.6, 4.0), colour: Ink.moonCool.al(rng.r(0.10, 0.36)),
            wobble: 0.6, taper: true, seed: rng.next())
    }
    let refl = [pt(cx - 300, waterY + 40), pt(cx + 300, waterY + 40),
                pt(cx + 240, p.h - 60), pt(cx - 240, p.h - 60)]
    pool(p, refl, Ink.jet, strength: 0.30, bleed: 10, seed: seed &+ 61)
}

func objectPlate(_ p: Sheet, _ art: VoiceArt, seed: UInt64) {
    let cx = 620.0
    let cy = 880.0
    switch art.variant {
    case 0:
        poolBand(p, from: cy + 280, to: p.h, Ink.mud, strength: 0.56, seed: seed &+ 3)
        for k in 0..<2 {
            let y = cy + 300 + Double(k) * 60
            pen(p, [pt(-40, y + 26), pt(p.w + 40, y - 10)], weight: 12,
                colour: Ink.iron, wobble: 0.4, taper: false, seed: seed &+ UInt64(5 + k))
            pen(p, [pt(-40, y + 22), pt(p.w + 40, y - 14)], weight: 4,
                colour: Ink.moonlit.al(0.44), wobble: 0.3, taper: false,
                seed: seed &+ UInt64(9 + k))
        }
        for k in 0..<3 {
            let x0 = -220.0 + Double(k) * 520
            let car = [pt(x0, cy - 190), pt(x0 + 470, cy - 210),
                       pt(x0 + 470, cy + 250), pt(x0, cy + 264)]
            pool(p, car, Ink.barkDeep, strength: 0.86, bleed: 5, seed: seed &+ UInt64(11 + k))
            formShade(p, car, inset: 40, depth: 3, spacing: 5.0,
                      colour: Ink.jet.al(0.56), seed: seed &+ UInt64(15 + k))
            var rng = Spark(seed &+ UInt64(19 + k))
            for j in 0..<9 {
                let x = x0 + 30 + Double(j) * 50
                pen(p, [pt(x, cy - 180), pt(x + 6, cy + 240)], weight: rng.r(2.0, 4.4),
                    colour: Ink.jet.al(rng.r(0.24, 0.52)), wobble: 0.6, taper: true,
                    seed: rng.next())
            }
            if k == 1 {
                let win = [pt(x0 + 130, cy - 130), pt(x0 + 300, cy - 136),
                           pt(x0 + 300, cy - 20), pt(x0 + 130, cy - 14)]
                pool(p, win, Ink.goldWarm, strength: 0.80, bleed: 4, seed: seed &+ 31)
                penEdge(p, win, weight: 3.0, colour: Ink.jet.al(0.86), seed: seed &+ 33)
                for j in 0..<7 {
                    let rad = 60.0 + Double(j) * 46
                    pool(p, ringPts(cx: x0 + 215, cy: cy - 76, rx: rad * 1.4, ry: rad,
                                    steps: 30),
                         Ink.goldWarm, strength: 0.06, bleed: 12,
                         seed: seed &+ UInt64(41 + j))
                }
            }
            penEdge(p, car, weight: 3.2, colour: Ink.jet.al(0.90), seed: seed &+ UInt64(51 + k))
            for j in 0..<4 {
                let wx = x0 + 90 + Double(j) * 100
                let wheel = ringPts(cx: wx, cy: cy + 290, rx: 46, ry: 46, steps: 24)
                pool(p, wheel, Ink.iron, strength: 0.86, bleed: 3, seed: seed &+ UInt64(61 + j))
                penEdge(p, wheel, weight: 3.0, colour: Ink.jet.al(0.88),
                        seed: seed &+ UInt64(71 + j))
            }
        }
    case 1:
        poolBand(p, from: cy + 300, to: p.h, Ink.grassDeep, strength: 0.50, seed: seed &+ 3)
        let frame = [pt(cx - 330, cy - 140), pt(cx + 330, cy - 170),
                     pt(cx + 330, cy + 250), pt(cx - 330, cy + 270)]
        pool(p, frame, Ink.iron, strength: 0.82, bleed: 5, seed: seed &+ 5)
        formShade(p, frame, inset: 50, depth: 3, spacing: 5.0,
                  colour: Ink.jet.al(0.58), seed: seed &+ 7)
        for run in rimRuns(frame, light: p.light, threshold: 0.28) {
            penBroken(p, run, weight: 4.0, colour: Ink.moonlit.al(0.44), pieces: 2,
                      gap: 0.08, wobble: 0.6, seed: seed &+ 9)
        }
        penEdge(p, frame, weight: 3.2, colour: Ink.jet.al(0.90), seed: seed &+ 11)
        let grill = [pt(cx - 250, cy - 90), pt(cx - 10, cy - 100),
                     pt(cx - 10, cy + 120), pt(cx - 250, cy + 130)]
        pool(p, grill, Ink.jet, strength: 0.66, bleed: 4, seed: seed &+ 13)
        for k in 0..<11 {
            let y = cy - 90 + Double(k) * 20
            pen(p, [pt(cx - 244, y), pt(cx - 16, y - 6)], weight: 4.0,
                colour: Ink.moonCool.al(0.34), wobble: 0.3, taper: false,
                seed: seed &+ UInt64(15 + k))
        }
        penEdge(p, grill, weight: 2.6, colour: Ink.jet.al(0.82), seed: seed &+ 31)
        let drum = ringPts(cx: cx + 170, cy: cy + 10, rx: 130, ry: 130, steps: 40)
        pool(p, drum, Ink.brass, strength: 0.72, bleed: 5, seed: seed &+ 33)
        formShade(p, drum, inset: 60, depth: 3, spacing: 4.6,
                  colour: Ink.jet.al(0.54), seed: seed &+ 35)
        penEdge(p, drum, weight: 3.0, colour: Ink.jet.al(0.86), seed: seed &+ 37)
        for k in 0..<3 {
            penEdge(p, ringPts(cx: cx + 170, cy: cy + 10, rx: 130 - Double(k) * 34,
                               ry: 130 - Double(k) * 34, steps: 30),
                    weight: 2.2, colour: Ink.jet.al(0.52), seed: seed &+ UInt64(41 + k))
        }
        let pipe = [pt(cx + 250, cy - 150), pt(cx + 300, cy - 160),
                    pt(cx + 300, cy - 330), pt(cx + 250, cy - 320)]
        pool(p, pipe, Ink.iron.down(0.2), strength: 0.86, bleed: 3, seed: seed &+ 51)
        penEdge(p, pipe, weight: 2.8, colour: Ink.jet.al(0.88), seed: seed &+ 53)
        var rng = Spark(seed &+ 61)
        for _ in 0..<26 {
            let x = cx + rng.r(230, 340)
            let y = rng.r(cy - 520, cy - 330)
            let puff = lump(cx: x, cy: y, rx: rng.r(24, 70), ry: rng.r(18, 50),
                            rough: 0.28, steps: 18, seed: rng.next())
            pool(p, puff, Ink.dawnGrey, strength: rng.r(0.10, 0.26), bleed: 8,
                 seed: rng.next())
        }
        let handle = [pt(cx - 340, cy - 170), pt(cx + 60, cy - 300),
                      pt(cx + 66, cy - 260), pt(cx - 334, cy - 130)]
        pool(p, handle, Ink.iron, strength: 0.84, bleed: 3, seed: seed &+ 71)
        penEdge(p, handle, weight: 2.6, colour: Ink.jet.al(0.86), seed: seed &+ 73)
    case 2:
        grassField(p, top: cy + 200, bottom: p.h, tone: Ink.grassMid, dense: 180,
                   heads: false, seed: seed &+ 3)
        let stem = [pt(cx - 24, cy + 300), pt(cx + 24, cy + 300),
                    pt(cx + 18, cy - 120), pt(cx - 18, cy - 120)]
        pool(p, stem, Ink.iron, strength: 0.84, bleed: 3, seed: seed &+ 5)
        formShade(p, stem, inset: 12, depth: 3, spacing: 3.6,
                  colour: Ink.jet.al(0.56), seed: seed &+ 7)
        penEdge(p, stem, weight: 2.8, colour: Ink.jet.al(0.88), seed: seed &+ 9)
        let head = [pt(cx - 74, cy - 120), pt(cx + 74, cy - 130),
                    pt(cx + 40, cy - 250), pt(cx - 40, cy - 244)]
        pool(p, head, Ink.brass, strength: 0.78, bleed: 4, seed: seed &+ 11)
        formShade(p, head, inset: 24, depth: 3, spacing: 3.6,
                  colour: Ink.jet.al(0.54), seed: seed &+ 13)
        penEdge(p, head, weight: 3.0, colour: Ink.jet.al(0.88), seed: seed &+ 15)
        let arm = [pt(cx + 20, cy - 250), pt(cx + 300, cy - 400),
                   pt(cx + 316, cy - 356), pt(cx + 36, cy - 210)]
        pool(p, arm, Ink.iron, strength: 0.86, bleed: 3, seed: seed &+ 21)
        penEdge(p, arm, weight: 2.6, colour: Ink.jet.al(0.88), seed: seed &+ 23)
        var rng = Spark(seed &+ 31)
        for k in 0..<9 {
            let a = -1.35 + Double(k) / 8.0 * 1.10
            var arc: [CGPoint] = []
            for j in 0...20 {
                let t = Double(j) / 20.0
                let dist = t * 620
                arc.append(pt(cx - 40 - cos(a) * dist,
                              cy - 250 + sin(a) * dist + t * t * 340))
            }
            penBroken(p, arc, weight: rng.r(2.0, 4.4), colour: Ink.moonlit.al(rng.r(0.30, 0.62)),
                      pieces: 4, gap: 0.10, wobble: 1.4, seed: rng.next())
        }
        for _ in 0..<170 {
            let t = rng.d()
            let a = rng.r(-1.35, -0.25)
            let dist = t * 620
            p.dot(cx - 40 - cos(a) * dist, cy - 250 + sin(a) * dist + t * t * 340,
                  rng.r(1.4, 4.0), Ink.moonlit.al(rng.r(0.24, 0.66)))
        }
    case 3:
        poolBand(p, from: -20, to: p.h + 20, Ink.nightDeep, strength: 0.40, seed: seed &+ 3)
        let post = [pt(cx - 400, cy - 500), pt(cx - 300, cy - 510),
                    pt(cx - 300, cy + 480), pt(cx - 400, cy + 470)]
        pool(p, post, Ink.timberDeep, strength: 0.86, bleed: 5, seed: seed &+ 5)
        formShade(p, post, inset: 30, depth: 3, spacing: 4.4,
                  colour: Ink.jet.al(0.60), seed: seed &+ 7)
        var rng = Spark(seed &+ 9)
        for _ in 0..<40 {
            let x = cx - 400 + rng.d() * 100
            let y = rng.r(cy - 500, cy + 470)
            pen(p, [pt(x, y), pt(x + rng.pm() * 6, y + rng.r(60, 300))],
                weight: rng.r(1.4, 3.0), colour: Ink.jet.al(rng.r(0.24, 0.52)),
                wobble: 0.5, taper: true, seed: rng.next())
        }
        penEdge(p, post, weight: 3.2, colour: Ink.jet.al(0.90), seed: seed &+ 11)
        for k in 0..<3 {
            let y = cy - 260 + Double(k) * 260
            let rail = [pt(cx - 320, y), pt(cx + 420, y - 40),
                        pt(cx + 420, y + 40), pt(cx - 320, y + 74)]
            pool(p, rail, Ink.timber, strength: 0.80, bleed: 4, seed: seed &+ UInt64(21 + k))
            formShade(p, rail, inset: 20, depth: 2, spacing: 4.0,
                      colour: Ink.jet.al(0.52), seed: seed &+ UInt64(25 + k))
            penEdge(p, rail, weight: 2.8, colour: Ink.jet.al(0.86), seed: seed &+ UInt64(31 + k))
        }
        let plateA = [pt(cx - 360, cy - 200), pt(cx - 130, cy - 236),
                      pt(cx - 130, cy - 130), pt(cx - 360, cy - 96)]
        pool(p, plateA, Ink.iron, strength: 0.88, bleed: 3, seed: seed &+ 41)
        formShade(p, plateA, inset: 18, depth: 3, spacing: 3.4,
                  colour: Ink.jet.al(0.58), seed: seed &+ 43)
        for run in rimRuns(plateA, light: p.light, threshold: 0.26) {
            penBroken(p, run, weight: 4.0, colour: Ink.moonlit.al(0.50),
                      pieces: 2, gap: 0.06, wobble: 0.5, seed: seed &+ 45)
        }
        penEdge(p, plateA, weight: 3.0, colour: Ink.jet.al(0.90), seed: seed &+ 47)
        for k in 0..<4 {
            let bx = cx - 330 + Double(k % 2) * 160
            let by = cy - 200 + Double(k / 2) * 76
            let bolt = ringPts(cx: bx, cy: by, rx: 16, ry: 16, steps: 14)
            pool(p, bolt, Ink.brass, strength: 0.84, bleed: 2, seed: seed &+ UInt64(51 + k))
            penEdge(p, bolt, weight: 2.2, colour: Ink.jet.al(0.86), seed: seed &+ UInt64(61 + k))
        }
        let pin = [pt(cx - 400, cy - 300), pt(cx - 356, cy - 306),
                   pt(cx - 356, cy - 40), pt(cx - 400, cy - 34)]
        pool(p, pin, Ink.brassLit, strength: 0.76, bleed: 3, seed: seed &+ 71)
        penEdge(p, pin, weight: 2.6, colour: Ink.jet.al(0.86), seed: seed &+ 73)
        for k in 0..<6 {
            let rad = 60.0 + Double(k) * 54
            penBroken(p, ringPts(cx: cx - 378, cy: cy - 170, rx: rad, ry: rad, steps: 34),
                      weight: 2.4, colour: Ink.moonlit.al(0.34 - Double(k) * 0.045),
                      pieces: 3, gap: 0.24, wobble: 1.6, seed: seed &+ UInt64(81 + k))
        }
    default:
        poolBand(p, from: -20, to: p.h + 20, Ink.nightDeep, strength: 0.52, seed: seed &+ 3)
        let stem = [pt(cx - 46, cy + 420), pt(cx + 46, cy + 420),
                    pt(cx + 40, cy + 120), pt(cx - 40, cy + 120)]
        pool(p, stem, Ink.brass, strength: 0.76, bleed: 4, seed: seed &+ 5)
        formShade(p, stem, inset: 22, depth: 3, spacing: 4.0,
                  colour: Ink.jet.al(0.54), seed: seed &+ 7)
        penEdge(p, stem, weight: 3.0, colour: Ink.jet.al(0.88), seed: seed &+ 9)
        for side in 0..<2 {
            let dir = side == 0 ? -1.0 : 1.0
            let tine = [pt(cx + dir * 40, cy + 130), pt(cx + dir * 150, cy + 60),
                        pt(cx + dir * 150, cy - 480), pt(cx + dir * 62, cy - 480),
                        pt(cx + dir * 62, cy + 40)]
            pool(p, tine, Ink.brass, strength: 0.74, bleed: 4,
                 seed: seed &+ UInt64(11 + side))
            formShade(p, tine, inset: 24, depth: 3, spacing: 4.2,
                      colour: Ink.jet.al(0.54), seed: seed &+ UInt64(15 + side))
            for run in rimRuns(tine, light: p.light, threshold: 0.28) {
                penBroken(p, run, weight: 4.2, colour: Ink.brassLit.al(0.66),
                          pieces: 2, gap: 0.08, wobble: 0.5, seed: seed &+ UInt64(19 + side))
            }
            penEdge(p, tine, weight: 3.0, colour: Ink.jet.al(0.90),
                    seed: seed &+ UInt64(23 + side))
        }
        var rng = Spark(seed &+ 31)
        for k in 0..<7 {
            let rad = 240.0 + Double(k) * 90
            penBroken(p, ringPts(cx: cx, cy: cy - 220, rx: rad, ry: rad * 0.86, steps: 44),
                      weight: rng.r(2.0, 3.6), colour: Ink.moonlit.al(0.30 - Double(k) * 0.035),
                      pieces: 4, gap: 0.22, wobble: 1.8, seed: rng.next())
        }
    }
}

func voicePlate(_ art: VoiceArt, dir: String) {
    let p = Sheet(Int(plateW), Int(plateH))
    let seed = hashSeed(art.key)
    sceneBack(p, scene: art.scene, seed: seed)
    switch art.kind {
    case 0:
        perchSlab(p, cx: 600, cy: 1235, wide: 470, kind: 0, seed: seed &+ 991)
        frogPlate(p, art, seed: seed &+ 1001)
    case 1:
        perchSlab(p, cx: 610, cy: 1230, wide: 490, kind: 1, seed: seed &+ 993)
        toadPlate(p, art, seed: seed &+ 1003)
    case 2:
        perchSlab(p, cx: 560, cy: 1180, wide: 430, kind: 2, seed: seed &+ 995)
        treeFrogPlate(p, art, seed: seed &+ 1007)
    case 3: insectPlate(p, art, form: 0, seed: seed &+ 1009)
    case 4: insectPlate(p, art, form: 1, seed: seed &+ 1013)
    case 5: insectPlate(p, art, form: 2, seed: seed &+ 1019)
    case 6: insectPlate(p, art, form: 3, seed: seed &+ 1021)
    case 7: owlPlate(p, art, seed: seed &+ 1031)
    case 8: nightjarPlate(p, art, seed: seed &+ 1033)
    case 9: waderPlate(p, art, seed: seed &+ 1039)
    case 10: aerialPlate(p, art, seed: seed &+ 1049)
    case 11: canidPlate(p, art, seed: seed &+ 1051)
    case 12: critterPlate(p, art, seed: seed &+ 1061)
    case 13: objectPlate(p, art, seed: seed &+ 1063)
    default: loonPlate(p, art, seed: seed &+ 1069)
    }
    nearFrame(p, seed: seed &+ 2003)
    poolBand(p, from: p.h - 250, to: p.h + 20, Ink.nightDeep, strength: 0.62,
             seed: seed &+ 2011)
    plateCaption(p, name: art.name, latin: art.latin)
    borderRule(p, inset: 26, seed: seed &+ 2017, colour: Ink.jet.al(0.44))
    p.emit(dir, "vo_" + art.key)
}
