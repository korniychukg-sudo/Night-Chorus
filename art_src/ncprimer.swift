import Foundation
import CoreGraphics

func chartPanel(_ p: Sheet, _ x: Double, _ y: Double, _ w: Double, _ h: Double,
                seed: UInt64) -> [CGPoint] {
    let form = [pt(x, y), pt(x + w, y), pt(x + w, y + h), pt(x, y + h)]
    pool(p, form, Ink.midnight, strength: 0.72, bleed: 6, seed: seed &+ 1)
    var rng = Spark(seed &+ 3)
    for _ in 0..<600 {
        let px = rng.r(x, x + w)
        let py = rng.r(y, y + h)
        p.dot(px, py, rng.r(0.5, 1.6), Ink.moonCool.al(rng.r(0.04, 0.14)))
    }
    penEdge(p, form, weight: 2.6, colour: Ink.moonlit.al(0.52), seed: seed &+ 5)
    return form
}

func axisTicks(_ p: Sheet, _ x: Double, _ y: Double, _ w: Double, _ h: Double,
               cols: Int, rows: Int, seed: UInt64) {
    for i in 1..<cols {
        let px = x + w * Double(i) / Double(cols)
        pen(p, [pt(px, y), pt(px, y + h)], weight: 1.0,
            colour: Ink.moonCool.al(0.14), wobble: 0.3, taper: false,
            seed: seed &+ UInt64(i))
        pen(p, [pt(px, y + h), pt(px, y + h + 12)], weight: 1.8,
            colour: Ink.moonlit.al(0.56), wobble: 0.2, taper: false,
            seed: seed &+ UInt64(40 + i))
    }
    for i in 1..<rows {
        let py = y + h * Double(i) / Double(rows)
        pen(p, [pt(x, py), pt(x + w, py)], weight: 1.0,
            colour: Ink.moonCool.al(0.14), wobble: 0.3, taper: false,
            seed: seed &+ UInt64(80 + i))
        pen(p, [pt(x - 12, py), pt(x, py)], weight: 1.8,
            colour: Ink.moonlit.al(0.56), wobble: 0.2, taper: false,
            seed: seed &+ UInt64(120 + i))
    }
}

func bandTrace(_ p: Sheet, x: Double, y: Double, w: Double, thick: Double,
               pulses: Int, duty: Double, wobbleAmp: Double, colour: Wash, seed: UInt64) {
    var rng = Spark(seed)
    let each = w / Double(max(1, pulses))
    for k in 0..<pulses {
        let x0 = x + Double(k) * each
        let x1 = x0 + each * duty
        let yy = y + sin(Double(k) * 0.8) * wobbleAmp
        var spine: [CGPoint] = []
        var i = 0.0
        while i <= 1.0 {
            spine.append(pt(x0 + (x1 - x0) * i, yy + rng.pm() * 1.6))
            i += 0.2
        }
        pen(p, spine, weight: thick, colour: colour, wobble: 0.5, taper: false,
            seed: rng.next())
        for _ in 0..<Int(thick * 3) {
            let t = rng.d()
            p.dot(x0 + (x1 - x0) * t, yy + rng.pm() * thick * 0.9,
                  rng.r(0.6, 1.8), colour.al(0.34))
        }
    }
}

func primerPlate(_ index: Int, dir: String) {
    let p = Sheet(1240, 700)
    let seed = hashSeed("primer-\(index)")
    nightPaper(p, seed: seed)
    poolBand(p, from: -20, to: p.h + 20, Ink.nightDeep, strength: 0.44, seed: seed &+ 1)
    borderRule(p, inset: 24, seed: seed &+ 3, colour: Ink.moonCool.al(0.34))

    switch index {
    case 0:
        let px = 130.0, py = 110.0, pw = 980.0, ph = 430.0
        _ = chartPanel(p, px, py, pw, ph, seed: seed &+ 11)
        axisTicks(p, px, py, pw, ph, cols: 8, rows: 5, seed: seed &+ 13)
        bandTrace(p, x: px + 40, y: py + ph * 0.34, w: 400, thick: 13,
                  pulses: 16, duty: 0.55, wobbleAmp: 3, colour: Ink.moonlit.al(0.86),
                  seed: seed &+ 17)
        bandTrace(p, x: px + 520, y: py + ph * 0.62, w: 400, thick: 26,
                  pulses: 5, duty: 0.72, wobbleAmp: 8, colour: Ink.moonCool.al(0.74),
                  seed: seed &+ 19)
        letter(p, "frequency", at: px - 34, py + ph * 0.5, size: 26,
               colour: Ink.moonlit.al(0.72), align: .centre, rotate: -1.5708)
        letter(p, "time", at: px + pw * 0.5, py + ph + 46, size: 26,
               colour: Ink.moonlit.al(0.72), align: .centre)
        letter(p, "a trill: one band, pulses too fast to separate",
               at: p.w * 0.5, py + ph + 96, size: 30, colour: Ink.moonlit.al(0.86),
               align: .centre)
        letter(p, "a churr: broad, slow, every pulse visible",
               at: p.w * 0.5, py + ph + 138, size: 30, colour: Ink.moonCool.al(0.78),
               align: .centre)
    case 1:
        let px = 130.0, py = 130.0, pw = 980.0, ph = 300.0
        _ = chartPanel(p, px, py, pw, ph, seed: seed &+ 11)
        var rng = Spark(seed &+ 13)
        for k in 0..<14 {
            let x = px + 40 + Double(k) * 66
            let hgt = 90.0 + rng.r(-14, 14)
            pen(p, [pt(x, py + ph * 0.5 + hgt), pt(x, py + ph * 0.5 - hgt)],
                weight: 7.0, colour: Ink.moonlit.al(0.86), wobble: 0.5, taper: true,
                seed: rng.next())
            pen(p, [pt(x, py + ph + 16), pt(x, py + ph + 40)], weight: 2.0,
                colour: Ink.moonCool.al(0.62), wobble: 0.2, taper: false, seed: rng.next())
        }
        pen(p, [pt(px + 40, py + ph + 70), pt(px + 40 + 13 * 66, py + ph + 70)],
            weight: 3.0, colour: Ink.goldWarm.al(0.86), wobble: 0.4, taper: false,
            seed: seed &+ 21)
        for k in 0..<2 {
            let x = px + 40 + Double(k) * 13 * 66
            pen(p, [pt(x, py + ph + 52), pt(x, py + ph + 88)], weight: 3.0,
                colour: Ink.goldWarm.al(0.86), wobble: 0.2, taper: false,
                seed: seed &+ UInt64(23 + k))
        }
        letter(p, "count the pulses in one second", at: p.w * 0.5, py + ph + 148,
               size: 32, colour: Ink.moonlit.al(0.88), align: .centre)
        letter(p, "fourteen here, and the temperature decides it",
               at: p.w * 0.5, py + ph + 194, size: 28, colour: Ink.moonCool.al(0.74),
               align: .centre)
    case 2:
        let px = 150.0, py = 110.0, pw = 940.0, ph = 440.0
        _ = chartPanel(p, px, py, pw, ph, seed: seed &+ 11)
        axisTicks(p, px, py, pw, ph, cols: 6, rows: 8, seed: seed &+ 13)
        let labels = ["18 kHz", "12 kHz", "8 kHz", "5 kHz", "3 kHz", "1.5 kHz", "600 Hz"]
        for (k, name) in labels.enumerated() {
            let y = py + 34 + Double(k) * (ph - 70) / 6.0
            bandTrace(p, x: px + 190, y: y, w: 620, thick: 9,
                      pulses: 3 + k * 2, duty: 0.6, wobbleAmp: 2,
                      colour: Ink.moonlit.al(k < 2 ? 0.34 : 0.82), seed: seed &+ UInt64(20 + k))
            letter(p, name, at: px + 160, y + 10, size: 22,
                   colour: Ink.moonCool.al(k < 2 ? 0.42 : 0.80), align: .right)
        }
        let lost = [pt(px, py), pt(px + pw, py), pt(px + pw, py + 108), pt(px, py + 108)]
        pool(p, lost, Ink.jet, strength: 0.44, bleed: 8, seed: seed &+ 41)
        rule(p, pathOf(lost), angle: 0.8, spacing: 11, weight: 1.4,
             colour: Ink.moonCool.al(0.28), coverage: 0.8, seed: seed &+ 43)
        penEdge(p, lost, weight: 2.2, colour: Ink.moonCool.al(0.52), seed: seed &+ 45)
        letter(p, "what most adult ears have already lost", at: p.w * 0.5, py + 74,
               size: 28, colour: Ink.moonlit.al(0.80), align: .centre)
        letter(p, "a conehead sits above it. you will never hear one.",
               at: p.w * 0.5, py + ph + 74, size: 30, colour: Ink.moonlit.al(0.86),
               align: .centre)
    case 3:
        let px = 260.0, py = 110.0, pw = 800.0, ph = 400.0
        _ = chartPanel(p, px, py, pw, ph, seed: seed &+ 11)
        axisTicks(p, px, py, pw, ph, cols: 6, rows: 5, seed: seed &+ 13)
        var line: [CGPoint] = []
        for k in 0...40 {
            let t = Double(k) / 40.0
            line.append(pt(px + t * pw, py + ph - 40 - t * (ph - 110)))
        }
        pen(p, line, weight: 5.0, colour: Ink.goldWarm.al(0.90), wobble: 0.8,
            taper: false, seed: seed &+ 17)
        var rng = Spark(seed &+ 19)
        for k in 0...12 {
            let t = Double(k) / 12.0
            let x = px + t * pw
            let y = py + ph - 40 - t * (ph - 110) + rng.pm() * 26
            let ring = ringPts(cx: x, cy: y, rx: 9, ry: 9, steps: 14)
            p.shape(ring, Ink.nightDeep)
            penEdge(p, ring, weight: 2.4, colour: Ink.moonlit.al(0.88), seed: rng.next())
        }
        do {
            let tx = 150.0
            let tube = [pt(tx - 22, py + 30), pt(tx + 22, py + 30),
                        pt(tx + 22, py + ph - 40), pt(tx - 22, py + ph - 40)]
            pool(p, tube, Ink.moonCool, strength: 0.34, bleed: 4, seed: seed &+ 51)
            penEdge(p, tube, weight: 2.6, colour: Ink.moonlit.al(0.80), seed: seed &+ 53)
            let bulb = ringPts(cx: tx, cy: py + ph, rx: 40, ry: 40, steps: 30)
            pool(p, bulb, Ink.emberSky, strength: 0.78, bleed: 4, seed: seed &+ 55)
            penEdge(p, bulb, weight: 2.6, colour: Ink.moonlit.al(0.80), seed: seed &+ 57)
            let col = [pt(tx - 11, py + 190), pt(tx + 11, py + 190),
                       pt(tx + 11, py + ph), pt(tx - 11, py + ph)]
            pool(p, col, Ink.emberSky, strength: 0.80, bleed: 3, seed: seed &+ 59)
            for k in 0..<11 {
                let y = py + 60 + Double(k) * (ph - 100) / 10.0
                pen(p, [pt(tx + 24, y), pt(tx + 44, y)], weight: 2.0,
                    colour: Ink.moonlit.al(0.66), wobble: 0.2, taper: false,
                    seed: seed &+ UInt64(61 + k))
            }
        }
        letter(p, "count in fifteen seconds, add forty", at: p.w * 0.5, py + ph + 74,
               size: 32, colour: Ink.moonlit.al(0.88), align: .centre)
        letter(p, "that is the temperature in Fahrenheit", at: p.w * 0.5, py + ph + 120,
               size: 28, colour: Ink.moonCool.al(0.76), align: .centre)
    case 4:
        let cx = 400.0
        let cy = 350.0
        var curve: [CGPoint] = []
        for k in 0...60 {
            let t = -1.0 + Double(k) / 30.0
            curve.append(pt(cx + t * t * 210, cy + t * 260))
        }
        var shell = curve
        for q in curve.reversed() { shell.append(pt(Double(q.x) - 26, Double(q.y))) }
        pool(p, shell, Ink.brass, strength: 0.66, bleed: 5, seed: seed &+ 11)
        formShade(p, shell, inset: 22, depth: 3, spacing: 4.4,
                  colour: Ink.jet.al(0.56), seed: seed &+ 13)
        for run in rimRuns(shell, light: p.light, threshold: 0.30) {
            penBroken(p, run, weight: 4.2, colour: Ink.brassLit.al(0.68),
                      pieces: 2, gap: 0.08, wobble: 0.6, seed: seed &+ 15)
        }
        penEdge(p, shell, weight: 3.0, colour: Ink.jet.al(0.88), seed: seed &+ 17)
        let focus = pt(cx + 108, cy)
        var rng = Spark(seed &+ 21)
        for k in 0..<11 {
            let t = -1.0 + Double(k) / 5.0
            let hit = pt(cx + t * t * 210, cy + t * 260)
            pen(p, [pt(p.w - 40, cy + t * 260 + rng.pm() * 4), hit],
                weight: 2.4, colour: Ink.moonlit.al(0.50), wobble: 0.4, taper: false,
                seed: rng.next())
            pen(p, [hit, focus], weight: 2.4, colour: Ink.goldWarm.al(0.76),
                wobble: 0.4, taper: false, seed: rng.next())
            let ax = Double(hit.x) - 40
            let ay = Double(hit.y)
            pen(p, [pt(ax + 26, ay - 9), pt(ax + 44, ay), pt(ax + 26, ay + 9)],
                weight: 2.4, colour: Ink.moonlit.al(0.62), wobble: 0.3, taper: false,
                seed: rng.next())
        }
        let mic = ringPts(cx: Double(focus.x), cy: Double(focus.y), rx: 30, ry: 30, steps: 26)
        pool(p, mic, Ink.iron, strength: 0.84, bleed: 3, seed: seed &+ 41)
        crossHatch(p, pathOf(mic), depth: 2, spacing: 4.0, colour: Ink.jet.al(0.50),
                   seed: seed &+ 43)
        penEdge(p, mic, weight: 3.0, colour: Ink.moonlit.al(0.76), seed: seed &+ 45)
        pen(p, [focus, pt(cx + 30, cy)], weight: 8.0, colour: Ink.iron,
            wobble: 0.3, taper: false, seed: seed &+ 47)
        letter(p, "every ray parallel to the axis lands on one point",
               at: p.w * 0.5, 636, size: 30, colour: Ink.moonlit.al(0.86), align: .centre)
        letter(p, "off axis, it does not", at: p.w * 0.5, 676, size: 28,
               colour: Ink.moonCool.al(0.74), align: .centre)
    default:
        let cx = 620.0
        let cy = 320.0
        let rx = 380.0
        let ry = 150.0
        let barrel = [pt(cx - rx, cy - ry), pt(cx + rx, cy - ry),
                      pt(cx + rx, cy + ry), pt(cx - rx, cy + ry)]
        pool(p, barrel, Ink.waxPale, strength: 0.70, bleed: 6, seed: seed &+ 11)
        for k in 0..<52 {
            let y = cy - ry + Double(k) * (ry * 2) / 51.0
            let amp = 5.0 + 5.0 * abs(sin(Double(k) * 0.42))
            var groove: [CGPoint] = []
            var i = 0.0
            while i <= 1.0 {
                let x = cx - rx + i * rx * 2
                groove.append(pt(x, y + sin(i * 46.0 + Double(k)) * amp * 0.5))
                i += 0.014
            }
            pen(p, groove, weight: 2.0, colour: Ink.waxDeep.down(0.28).al(0.80),
                wobble: 0.2, taper: false, seed: seed &+ UInt64(20 + k))
        }
        formShade(p, barrel, inset: 60, depth: 3, spacing: 5.0,
                  colour: Ink.jet.al(0.40), seed: seed &+ 71)
        let capL = ringPts(cx: cx - rx, cy: cy, rx: 42, ry: ry, steps: 40)
        let capR = ringPts(cx: cx + rx, cy: cy, rx: 42, ry: ry, steps: 40)
        pool(p, capR, Ink.waxPale.up(0.10), strength: 0.72, bleed: 4, seed: seed &+ 73)
        penEdge(p, capR, weight: 3.0, colour: Ink.jet.al(0.80), seed: seed &+ 75)
        p.shape(ringPts(cx: cx + rx, cy: cy, rx: 22, ry: ry * 0.52, steps: 30),
                Ink.barkDeep)
        penEdge(p, capL, weight: 2.4, colour: Ink.jet.al(0.62), seed: seed &+ 77)
        penEdge(p, barrel, weight: 3.0, colour: Ink.jet.al(0.86), seed: seed &+ 79)
        do {
            let sx = cx + 60.0
            let arm = [pt(sx - 16, cy - ry - 210), pt(sx + 16, cy - ry - 210),
                       pt(sx + 10, cy - ry - 26), pt(sx - 10, cy - ry - 26)]
            pool(p, arm, Ink.iron, strength: 0.84, bleed: 3, seed: seed &+ 81)
            penEdge(p, arm, weight: 2.6, colour: Ink.jet.al(0.86), seed: seed &+ 83)
            let tip = [pt(sx - 10, cy - ry - 26), pt(sx + 10, cy - ry - 26),
                       pt(sx, cy - ry + 6)]
            p.shape(tip, Ink.moonlit)
            penEdge(p, tip, weight: 2.2, colour: Ink.jet.al(0.86), seed: seed &+ 85)
            pen(p, [pt(sx - 90, cy - ry - 200), pt(sx + 90, cy - ry - 196)],
                weight: 7.0, colour: Ink.iron, wobble: 0.4, taper: false, seed: seed &+ 87)
        }
        letter(p, "the groove is the waveform, at reading size",
               at: p.w * 0.5, 588, size: 32, colour: Ink.moonlit.al(0.88), align: .centre)
        letter(p, "a rasping voice cuts a wide, ragged track",
               at: p.w * 0.5, 634, size: 28, colour: Ink.moonCool.al(0.76), align: .centre)
    }
    p.emit(dir, "pr_\(index)")
}

func introPlate(_ index: Int, dir: String) {
    let p = Sheet(1240, 760)
    let seed = hashSeed("intro-\(index)")
    nightPaper(p, seed: seed)

    switch index {
    case 0:
        let horizon = 400.0
        skyFor(p, phase: 5, horizon: horizon, seed: seed &+ 3)
        moonDisc(p, cx: 1000, cy: 130, rad: 62, lit: 0.86, waxing: true, seed: seed &+ 5)
        farRidge(p, base: horizon + 8, amp: 78, kind: 2, seed: seed &+ 7)
        waterPlane(p, top: horizon, bottom: p.h - 230, seed: seed &+ 11)
        cattailStand(p, count: 40, baseY: p.h - 160, height: 420, seed: seed &+ 13)
        grassField(p, top: p.h - 230, bottom: p.h + 30, tone: Ink.grassDeep,
                   dense: 220, heads: true, seed: seed &+ 17)
        var rng = Spark(seed &+ 21)
        for _ in 0..<15 {
            let x = rng.r(80, p.w - 80)
            let y = rng.r(horizon + 40, p.h - 120)
            for k in 0..<4 {
                let rad = 22.0 + Double(k) * 20
                let ring = ringPts(cx: x, cy: y, rx: rad * 1.3, ry: rad * 0.7, steps: 30)
                penBroken(p, ring, weight: 2.2,
                          colour: Ink.moonlit.al(0.34 - Double(k) * 0.06),
                          pieces: 3, gap: 0.16, wobble: 1.0, seed: rng.next())
            }
            p.dot(x, y, 5.0, Ink.starWhite.al(0.62))
        }
        nearFrame(p, seed: seed &+ 31)
    case 1:
        poolBand(p, from: -20, to: p.h + 20, Ink.nightDeep, strength: 0.60, seed: seed &+ 3)
        skyFor(p, phase: 6, horizon: 420, seed: seed &+ 5)
        farRidge(p, base: p.h - 90, amp: 96, kind: 2, seed: seed &+ 7)
        let cx = 470.0
        let cy = 400.0
        var curve: [CGPoint] = []
        for k in 0...70 {
            let t = -1.0 + Double(k) / 35.0
            curve.append(pt(cx + t * t * 190, cy + t * 300))
        }
        var shell = curve
        for q in curve.reversed() { shell.append(pt(Double(q.x) - 30, Double(q.y))) }
        pool(p, shell, Ink.brass, strength: 0.70, bleed: 5, seed: seed &+ 11)
        formShade(p, shell, inset: 26, depth: 3, spacing: 4.4,
                  colour: Ink.jet.al(0.60), seed: seed &+ 13)
        stipple(p, pathOf(shell), density: 0.0016, sizeMin: 0.8, sizeMax: 2.4,
                colour: Ink.brassLit.al(0.34), seed: seed &+ 15)
        for run in rimRuns(shell, light: p.light, threshold: 0.28) {
            penBroken(p, run, weight: 4.4, colour: Ink.brassLit.al(0.70),
                      pieces: 2, gap: 0.06, wobble: 0.6, seed: seed &+ 17)
        }
        penEdge(p, shell, weight: 3.2, colour: Ink.jet.al(0.88), seed: seed &+ 19)
        do {
            let gx = cx - 40.0
            let grip = [pt(gx, cy - 26), pt(gx - 200, cy + 70),
                        pt(gx - 196, cy + 128), pt(gx + 4, cy + 40)]
            pool(p, grip, Ink.timberDeep, strength: 0.86, bleed: 4, seed: seed &+ 21)
            formShade(p, grip, inset: 20, depth: 3, spacing: 4.0,
                      colour: Ink.jet.al(0.60), seed: seed &+ 23)
            penEdge(p, grip, weight: 3.0, colour: Ink.jet.al(0.90), seed: seed &+ 25)
        }
        var rng = Spark(seed &+ 31)
        for k in 0..<9 {
            let t = -1.0 + Double(k) / 4.0
            let y = cy + t * 300
            penBroken(p, [pt(cx + 40, y), pt(p.w - 40, y + rng.pm() * 40)],
                      weight: 2.6, colour: Ink.moonlit.al(0.30), pieces: 4, gap: 0.14,
                      wobble: 1.4, seed: seed &+ UInt64(33 + k))
        }
        for _ in 0..<40 {
            let x = rng.r(cx + 120, p.w)
            let y = rng.r(70, p.h - 120)
            p.dot(x, y, rng.r(1.0, 2.6), Ink.starWhite.al(rng.r(0.10, 0.46)))
        }
    case 2:
        poolBand(p, from: -20, to: p.h + 20, Ink.barkDeep, strength: 0.62, seed: seed &+ 3)
        var rng = Spark(seed &+ 5)
        for _ in 0..<70 {
            let y = rng.r(0, p.h)
            pen(p, [pt(-20, y), pt(p.w + 20, y + rng.pm() * 18)], weight: rng.r(1.4, 4.0),
                colour: Ink.jet.al(rng.r(0.10, 0.30)), wobble: 1.0, taper: true,
                seed: rng.next())
        }
        let sx = 150.0, sy = 90.0, sw = 830.0, sh = 470.0
        let sheet = [pt(sx, sy), pt(sx + sw, sy - 14), pt(sx + sw + 12, sy + sh),
                     pt(sx - 8, sy + sh + 16)]
        pool(p, sheet, Ink.leafGrey, strength: 0.84, bleed: 6, seed: seed &+ 11)
        penEdge(p, sheet, weight: 2.6, colour: Ink.jet.al(0.72), seed: seed &+ 13)
        p.inside(pathOf(sheet)) {
            for k in 1..<7 {
                let y = sy + sh * Double(k) / 7.0
                pen(p, [pt(sx, y), pt(sx + sw, y - 8)], weight: 1.2,
                    colour: Ink.jet.al(0.24), wobble: 0.4, taper: false,
                    seed: seed &+ UInt64(20 + k))
            }
            bandTrace(p, x: sx + 60, y: sy + 140, w: 380, thick: 12,
                      pulses: 18, duty: 0.5, wobbleAmp: 3, colour: Ink.jet.al(0.80),
                      seed: seed &+ 31)
            bandTrace(p, x: sx + 500, y: sy + 250, w: 300, thick: 22,
                      pulses: 4, duty: 0.7, wobbleAmp: 7, colour: Ink.jetSoft.al(0.74),
                      seed: seed &+ 33)
            bandTrace(p, x: sx + 90, y: sy + 370, w: 620, thick: 8,
                      pulses: 30, duty: 0.4, wobbleAmp: 2, colour: Ink.iron.al(0.72),
                      seed: seed &+ 35)
        }
        do {
            let hx = 880.0
            let hy = 520.0
            for k in 0..<2 {
                let a = -0.42 + Double(k) * 0.84
                let leg = [pt(hx, hy - 250), pt(hx + sin(a) * 250, hy + cos(a) * 40)]
                pen(p, leg, weight: 13.0, colour: Ink.iron, wobble: 0.3, taper: true,
                    seed: seed &+ UInt64(41 + k))
                pen(p, [pt(Double(leg[0].x) - 4, Double(leg[0].y) - 4),
                        pt(Double(leg[1].x) - 4, Double(leg[1].y) - 4)],
                    weight: 3.4, colour: Ink.moonlit.al(0.40), wobble: 0.2, taper: true,
                    seed: seed &+ UInt64(51 + k))
            }
            let head = ringPts(cx: hx, cy: hy - 258, rx: 26, ry: 26, steps: 22)
            pool(p, head, Ink.brass, strength: 0.82, bleed: 3, seed: seed &+ 61)
            penEdge(p, head, weight: 2.8, colour: Ink.jet.al(0.86), seed: seed &+ 63)
        }
        do {
            let px = 320.0
            let py = 660.0
            let body = [pt(px, py - 16), pt(px + 420, py - 34),
                        pt(px + 420, py + 6), pt(px, py + 24)]
            pool(p, body, Ink.timber, strength: 0.86, bleed: 3, seed: seed &+ 71)
            formShade(p, body, inset: 12, depth: 2, spacing: 3.4,
                      colour: Ink.jet.al(0.54), seed: seed &+ 73)
            penEdge(p, body, weight: 2.4, colour: Ink.jet.al(0.86), seed: seed &+ 75)
            let nib = [pt(px, py - 16), pt(px - 66, py + 2), pt(px, py + 24)]
            p.shape(nib, Ink.leafGrey)
            penEdge(p, nib, weight: 2.2, colour: Ink.jet.al(0.86), seed: seed &+ 77)
            p.shape([pt(px - 66, py + 2), pt(px - 34, py - 7), pt(px - 34, py + 12)], Ink.jet)
        }
    default:
        poolBand(p, from: -20, to: p.h + 20, Ink.nightDeep, strength: 0.66, seed: seed &+ 3)
        do {
            var rng = Spark(seed &+ 5)
            for _ in 0..<120 {
                let x = rng.r(-20, p.w + 20)
                let y = rng.r(-20, p.h + 20)
                pen(p, [pt(x, y), pt(x + rng.r(40, 160), y + rng.pm() * 12)],
                    weight: rng.r(1.2, 3.0), colour: Ink.jet.al(rng.r(0.14, 0.36)),
                    wobble: 0.6, taper: true, seed: rng.next())
            }
        }
        let cx = 600.0
        let cy = 360.0
        let rx = 340.0
        let ry = 168.0
        let barrel = [pt(cx - rx, cy - ry), pt(cx + rx, cy - ry),
                      pt(cx + rx, cy + ry), pt(cx - rx, cy + ry)]
        pool(p, barrel, Ink.waxPale, strength: 0.72, bleed: 6, seed: seed &+ 11)
        for k in 0..<60 {
            let y = cy - ry + Double(k) * (ry * 2) / 59.0
            var groove: [CGPoint] = []
            var i = 0.0
            while i <= 1.0 {
                let x = cx - rx + i * rx * 2
                groove.append(pt(x, y + sin(i * 52.0 + Double(k) * 0.7) * 4.4))
                i += 0.012
            }
            pen(p, groove, weight: 2.0, colour: Ink.waxDeep.down(0.24).al(0.78),
                wobble: 0.2, taper: false, seed: seed &+ UInt64(20 + k))
        }
        formShade(p, barrel, inset: 70, depth: 3, spacing: 5.4,
                  colour: Ink.jet.al(0.42), seed: seed &+ 91)
        let capR = ringPts(cx: cx + rx, cy: cy, rx: 46, ry: ry, steps: 40)
        pool(p, capR, Ink.waxPale.up(0.12), strength: 0.74, bleed: 4, seed: seed &+ 93)
        penEdge(p, capR, weight: 3.0, colour: Ink.jet.al(0.82), seed: seed &+ 95)
        penEdge(p, ringPts(cx: cx - rx, cy: cy, rx: 46, ry: ry, steps: 40),
                weight: 2.4, colour: Ink.jet.al(0.60), seed: seed &+ 97)
        penEdge(p, barrel, weight: 3.2, colour: Ink.jet.al(0.88), seed: seed &+ 99)
        do {
            let mand = [pt(cx - rx - 130, cy - 16), pt(cx + rx + 130, cy - 16),
                        pt(cx + rx + 130, cy + 16), pt(cx - rx - 130, cy + 16)]
            pool(p, mand, Ink.brass, strength: 0.60, bleed: 3, seed: seed &+ 101)
            penEdge(p, mand, weight: 2.4, colour: Ink.jet.al(0.72), seed: seed &+ 103)
        }
        do {
            let sx = cx + 130.0
            let arm = [pt(sx - 18, cy - ry - 250), pt(sx + 18, cy - ry - 250),
                       pt(sx + 11, cy - ry - 30), pt(sx - 11, cy - ry - 30)]
            pool(p, arm, Ink.iron, strength: 0.86, bleed: 3, seed: seed &+ 111)
            formShade(p, arm, inset: 8, depth: 2, spacing: 3.0,
                      colour: Ink.jet.al(0.56), seed: seed &+ 113)
            penEdge(p, arm, weight: 2.8, colour: Ink.jet.al(0.88), seed: seed &+ 115)
            let tip = [pt(sx - 11, cy - ry - 30), pt(sx + 11, cy - ry - 30),
                       pt(sx, cy - ry + 10)]
            p.shape(tip, Ink.moonlit)
            penEdge(p, tip, weight: 2.2, colour: Ink.jet.al(0.86), seed: seed &+ 117)
            var rng = Spark(seed &+ 121)
            for _ in 0..<26 {
                let x = sx + rng.pm() * 40
                let y = cy - ry + rng.r(10, 60)
                pen(p, [pt(x, y), pt(x + rng.pm() * 30, y + rng.r(20, 70))],
                    weight: rng.r(1.0, 2.4), colour: Ink.waxPale.al(rng.r(0.30, 0.70)),
                    wobble: 0.8, taper: true, seed: rng.next())
            }
        }
        letter(p, "one cylinder, one voice", at: p.w * 0.5, p.h - 70, size: 34,
               colour: Ink.moonlit.al(0.80), align: .centre, tracking: 3)
    }
    borderRule(p, inset: 20, seed: seed &+ 201, colour: Ink.jet.al(0.50))
    p.emit(dir, "in_\(index)")
}

func sceneJobs(dir: String) -> [() -> Void] {
    var jobs: [() -> Void] = []
    for season in 0..<4 {
        for phase in 0..<7 {
            jobs.append { meadowPlate(season, phase, dir: dir) }
        }
    }
    for index in 0..<8 { jobs.append { habitatPlate(index, dir: dir) } }
    for index in 0..<8 { jobs.append { moonPlate(index, dir: dir) } }
    for index in 0..<6 { jobs.append { primerPlate(index, dir: dir) } }
    for index in 0..<4 { jobs.append { introPlate(index, dir: dir) } }
    return jobs
}
