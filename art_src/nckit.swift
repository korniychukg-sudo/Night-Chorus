import Foundation
import CoreGraphics
import CoreText
import ImageIO
import UniformTypeIdentifiers

struct Spark {
    var s: UInt64
    init(_ seed: UInt64) { s = seed == 0 ? 0xD1B54A32D192ED03 : seed }
    mutating func next() -> UInt64 { s ^= s << 13; s ^= s >> 7; s ^= s << 17; return s }
    mutating func d() -> Double { Double(next() % 1_000_000) / 1_000_000.0 }
    mutating func r(_ a: Double, _ b: Double) -> Double { a + d() * (b - a) }
    mutating func i(_ a: Int, _ b: Int) -> Int { a + Int(next() % UInt64(max(1, b - a + 1))) }
    mutating func odds(_ p: Double) -> Bool { d() < p }
    mutating func pm() -> Double { d() * 2 - 1 }
}

func bits(_ v: Int) -> UInt64 { UInt64(bitPattern: Int64(v)) }

func hashSeed(_ name: String) -> UInt64 {
    var h: UInt64 = 14695981039346656037
    for b in name.utf8 { h = (h ^ UInt64(b)) &* 1099511628211 }
    return h
}

struct Wash {
    var r: Double, g: Double, b: Double, a: Double = 1
    func al(_ v: Double) -> Wash { Wash(r: r, g: g, b: b, a: v) }
    func mix(_ o: Wash, _ t: Double) -> Wash {
        Wash(r: r + (o.r - r) * t, g: g + (o.g - g) * t, b: b + (o.b - b) * t, a: a + (o.a - a) * t)
    }
    func up(_ t: Double) -> Wash { mix(Wash(r: 1, g: 1, b: 1, a: a), t) }
    func down(_ t: Double) -> Wash { mix(Wash(r: 0, g: 0, b: 0, a: a), t) }
}

let rgbSpace = CGColorSpaceCreateDeviceRGB()

func cg(_ c: Wash) -> CGColor {
    CGColor(colorSpace: rgbSpace, components: [CGFloat(c.r), CGFloat(c.g), CGFloat(c.b), CGFloat(c.a)])!
}

enum Ink {
    static let leaf       = Wash(r: 0.902, g: 0.882, b: 0.839)
    static let leafCool   = Wash(r: 0.855, g: 0.867, b: 0.867)
    static let leafBlue   = Wash(r: 0.804, g: 0.827, b: 0.851)
    static let leafGrey   = Wash(r: 0.839, g: 0.839, b: 0.827)
    static let leafDusk   = Wash(r: 0.788, g: 0.796, b: 0.808)

    static let jet        = Wash(r: 0.086, g: 0.086, b: 0.098)
    static let jetSoft    = Wash(r: 0.208, g: 0.212, b: 0.235)
    static let jetPale    = Wash(r: 0.388, g: 0.400, b: 0.435)
    static let iron       = Wash(r: 0.271, g: 0.290, b: 0.325)
    static let slate      = Wash(r: 0.318, g: 0.353, b: 0.408)

    static let night      = Wash(r: 0.106, g: 0.133, b: 0.204)
    static let nightDeep  = Wash(r: 0.055, g: 0.071, b: 0.118)
    static let midnight   = Wash(r: 0.078, g: 0.098, b: 0.157)
    static let indigo     = Wash(r: 0.161, g: 0.196, b: 0.310)
    static let duskBlue   = Wash(r: 0.235, g: 0.290, b: 0.400)
    static let duskViolet = Wash(r: 0.294, g: 0.271, b: 0.373)
    static let gloam      = Wash(r: 0.376, g: 0.396, b: 0.478)
    static let horizon    = Wash(r: 0.545, g: 0.522, b: 0.475)
    static let goldLow    = Wash(r: 0.729, g: 0.588, b: 0.365)
    static let goldWarm   = Wash(r: 0.831, g: 0.702, b: 0.451)
    static let emberSky   = Wash(r: 0.647, g: 0.435, b: 0.322)
    static let dawnGrey   = Wash(r: 0.588, g: 0.612, b: 0.635)
    static let dawnPale   = Wash(r: 0.729, g: 0.741, b: 0.741)

    static let moonlit    = Wash(r: 0.898, g: 0.906, b: 0.867)
    static let moonCool   = Wash(r: 0.792, g: 0.827, b: 0.847)
    static let starWhite  = Wash(r: 0.965, g: 0.965, b: 0.929)

    static let grassDeep  = Wash(r: 0.180, g: 0.243, b: 0.204)
    static let grassMid   = Wash(r: 0.271, g: 0.341, b: 0.271)
    static let grassPale  = Wash(r: 0.400, g: 0.463, b: 0.365)
    static let sedge      = Wash(r: 0.451, g: 0.435, b: 0.310)
    static let reed       = Wash(r: 0.400, g: 0.376, b: 0.271)
    static let mossWet    = Wash(r: 0.259, g: 0.318, b: 0.267)

    static let bark       = Wash(r: 0.310, g: 0.267, b: 0.220)
    static let barkDeep   = Wash(r: 0.176, g: 0.145, b: 0.118)
    static let barkPale   = Wash(r: 0.451, g: 0.396, b: 0.325)
    static let timber     = Wash(r: 0.400, g: 0.290, b: 0.180)
    static let timberDeep = Wash(r: 0.235, g: 0.161, b: 0.094)
    static let waxPale    = Wash(r: 0.749, g: 0.686, b: 0.518)
    static let waxDeep    = Wash(r: 0.545, g: 0.463, b: 0.318)

    static let water      = Wash(r: 0.227, g: 0.278, b: 0.310)
    static let waterLit   = Wash(r: 0.435, g: 0.494, b: 0.510)
    static let mud        = Wash(r: 0.259, g: 0.227, b: 0.192)
    static let sand       = Wash(r: 0.545, g: 0.494, b: 0.400)
    static let stone      = Wash(r: 0.443, g: 0.443, b: 0.427)

    static let frogGreen  = Wash(r: 0.353, g: 0.451, b: 0.294)
    static let frogOlive  = Wash(r: 0.427, g: 0.427, b: 0.290)
    static let frogTan    = Wash(r: 0.549, g: 0.463, b: 0.341)
    static let frogGrey   = Wash(r: 0.478, g: 0.494, b: 0.463)
    static let frogWet    = Wash(r: 0.290, g: 0.365, b: 0.341)
    static let toadBrown  = Wash(r: 0.412, g: 0.337, b: 0.243)

    static let chitin     = Wash(r: 0.361, g: 0.322, b: 0.220)
    static let chitinPale = Wash(r: 0.514, g: 0.475, b: 0.337)
    static let wingGreen  = Wash(r: 0.365, g: 0.435, b: 0.267)
    static let wingClear  = Wash(r: 0.596, g: 0.612, b: 0.541)

    static let plume      = Wash(r: 0.435, g: 0.376, b: 0.290)
    static let plumePale  = Wash(r: 0.643, g: 0.596, b: 0.514)
    static let plumeDark  = Wash(r: 0.243, g: 0.208, b: 0.169)
    static let plumeGrey  = Wash(r: 0.435, g: 0.451, b: 0.463)
    static let plumeRust  = Wash(r: 0.529, g: 0.376, b: 0.243)
    static let eyeAmber   = Wash(r: 0.812, g: 0.635, b: 0.243)
    static let eyeDark    = Wash(r: 0.129, g: 0.106, b: 0.086)
    static let beak       = Wash(r: 0.263, g: 0.271, b: 0.271)

    static let pelt       = Wash(r: 0.478, g: 0.353, b: 0.235)
    static let peltGrey   = Wash(r: 0.412, g: 0.412, b: 0.396)
    static let peltPale   = Wash(r: 0.635, g: 0.573, b: 0.475)

    static let brass      = Wash(r: 0.639, g: 0.510, b: 0.259)
    static let brassLit   = Wash(r: 0.784, g: 0.659, b: 0.388)
    static let steel      = Wash(r: 0.482, g: 0.498, b: 0.522)
    static let steelLit   = Wash(r: 0.686, g: 0.706, b: 0.729)
    static let glassPale  = Wash(r: 0.741, g: 0.780, b: 0.788)

    static let lampGlow   = Wash(r: 0.949, g: 0.831, b: 0.573)
    static let fireflyLit = Wash(r: 0.812, g: 0.882, b: 0.478)
    static let redInk     = Wash(r: 0.596, g: 0.267, b: 0.204)
    static let blueInk    = Wash(r: 0.220, g: 0.290, b: 0.435)
}

var sheetScale: Double = 1.45

final class Sheet {
    let ctx: CGContext
    let w: Double
    let h: Double
    var light: Double = 2.30

    init(_ wi: Int, _ hi: Int) {
        w = Double(wi); h = Double(hi)
        let pw = Int((Double(wi) * sheetScale).rounded())
        let ph = Int((Double(hi) * sheetScale).rounded())
        ctx = CGContext(data: nil, width: pw, height: ph, bitsPerComponent: 8,
                        bytesPerRow: pw * 4, space: rgbSpace,
                        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
        ctx.scaleBy(x: CGFloat(sheetScale), y: CGFloat(sheetScale))
        ctx.setShouldAntialias(true)
        ctx.interpolationQuality = .high
    }

    func flipTopDown() {
        ctx.translateBy(x: 0, y: CGFloat(h))
        ctx.scaleBy(x: 1, y: -1)
    }

    func floodAll(_ c: Wash) { ctx.setFillColor(cg(c)); ctx.fill(CGRect(x: 0, y: 0, width: w, height: h)) }

    func box(_ x: Double, _ y: Double, _ rw: Double, _ rh: Double, _ c: Wash) {
        ctx.setFillColor(cg(c)); ctx.fill(CGRect(x: x, y: y, width: rw, height: rh))
    }

    func dot(_ x: Double, _ y: Double, _ rad: Double, _ c: Wash) {
        ctx.setFillColor(cg(c))
        ctx.fillEllipse(in: CGRect(x: x - rad, y: y - rad, width: rad * 2, height: rad * 2))
    }

    func ellipse(_ x: Double, _ y: Double, _ rx: Double, _ ry: Double, _ c: Wash) {
        ctx.setFillColor(cg(c))
        ctx.fillEllipse(in: CGRect(x: x - rx, y: y - ry, width: rx * 2, height: ry * 2))
    }

    func hoop(_ x: Double, _ y: Double, _ rad: Double, _ width: Double, _ c: Wash) {
        ctx.setStrokeColor(cg(c)); ctx.setLineWidth(CGFloat(width))
        ctx.strokeEllipse(in: CGRect(x: x - rad, y: y - rad, width: rad * 2, height: rad * 2))
    }

    func shape(_ pts: [CGPoint], _ c: Wash) {
        guard pts.count > 2 else { return }
        ctx.setFillColor(cg(c)); ctx.beginPath(); ctx.move(to: pts[0])
        for p in pts.dropFirst() { ctx.addLine(to: p) }
        ctx.closePath(); ctx.fillPath()
    }

    func bar(_ a: CGPoint, _ b: CGPoint, _ width: Double, _ c: Wash, dash: [CGFloat] = []) {
        ctx.saveGState()
        ctx.setStrokeColor(cg(c)); ctx.setLineWidth(CGFloat(width))
        if !dash.isEmpty { ctx.setLineDash(phase: 0, lengths: dash) }
        ctx.beginPath(); ctx.move(to: a); ctx.addLine(to: b); ctx.strokePath()
        ctx.restoreGState()
    }

    func inside(_ path: CGPath, _ body: () -> Void) {
        guard !path.isEmpty else { return }
        ctx.saveGState(); ctx.beginPath(); ctx.addPath(path); ctx.clip(); body(); ctx.restoreGState()
    }

    func insideBoth(_ a: CGPath, _ b: CGPath, _ body: () -> Void) {
        guard !a.isEmpty, !b.isEmpty else { return }
        ctx.saveGState()
        ctx.beginPath(); ctx.addPath(a); ctx.clip()
        ctx.beginPath(); ctx.addPath(b); ctx.clip()
        body()
        ctx.restoreGState()
    }

    func insideBox(_ r: CGRect, _ body: () -> Void) {
        ctx.saveGState(); ctx.clip(to: r); body(); ctx.restoreGState()
    }

    func emit(_ dir: String, _ name: String, quality: Double = 0.86) {
        guard let img = ctx.makeImage() else { return }
        let url = URL(fileURLWithPath: dir).appendingPathComponent("\(name).jpg")
        guard let dest = CGImageDestinationCreateWithURL(
            url as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else { return }
        CGImageDestinationAddImage(dest, img, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
        CGImageDestinationFinalize(dest)
    }

    func emitPNG(_ dir: String, _ name: String) {
        guard let img = ctx.makeImage() else { return }
        let url = URL(fileURLWithPath: dir).appendingPathComponent("\(name).png")
        guard let dest = CGImageDestinationCreateWithURL(
            url as CFURL, UTType.png.identifier as CFString, 1, nil) else { return }
        CGImageDestinationAddImage(dest, img, nil)
        CGImageDestinationFinalize(dest)
    }
}

func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: CGFloat(x), y: CGFloat(y)) }

func pathOf(_ pts: [CGPoint], close: Bool = true) -> CGPath {
    let p = CGMutablePath()
    guard let first = pts.first else { return p }
    p.move(to: first)
    for q in pts.dropFirst() { p.addLine(to: q) }
    if close { p.closeSubpath() }
    return p
}

func resample(_ pts: [CGPoint], count: Int) -> [CGPoint] {
    guard pts.count > 1, count > 1 else { return pts }
    var lengths: [Double] = [0]
    var total = 0.0
    for i in 1..<pts.count {
        let dx = Double(pts[i].x - pts[i - 1].x), dy = Double(pts[i].y - pts[i - 1].y)
        total += (dx * dx + dy * dy).squareRoot()
        lengths.append(total)
    }
    guard total > 0 else { return pts }
    var out: [CGPoint] = []
    var seg = 1
    for k in 0..<count {
        let target = total * Double(k) / Double(count - 1)
        while seg < lengths.count - 1 && lengths[seg] < target { seg += 1 }
        let l0 = lengths[seg - 1], l1 = lengths[seg]
        let t = l1 > l0 ? (target - l0) / (l1 - l0) : 0
        let a = pts[seg - 1], b = pts[seg]
        out.append(CGPoint(x: a.x + (b.x - a.x) * CGFloat(t), y: a.y + (b.y - a.y) * CGFloat(t)))
    }
    return out
}

func layPaper(_ p: Sheet, seed: UInt64, tone: Wash = Ink.leaf, laid: Bool = true) {
    var rng = Spark(seed)
    p.floodAll(tone)

    for _ in 0..<20 {
        let x = rng.d() * p.w, y = rng.d() * p.h
        let rr = rng.r(p.w * 0.05, p.w * 0.18)
        let warm = rng.odds(0.55)
        if let g = CGGradient(colorsSpace: rgbSpace,
                              colors: [cg(warm ? tone.up(0.045).al(0.22) : tone.down(0.036).al(0.17)),
                                       cg(tone.al(0))] as CFArray, locations: [0, 1]) {
            p.ctx.drawRadialGradient(g, startCenter: CGPoint(x: x, y: y), startRadius: 0,
                                     endCenter: CGPoint(x: x, y: y), endRadius: rr, options: [])
        }
    }

    if laid {
        var y = 0.0
        while y < p.h {
            p.box(0, y, p.w, 1.0 / sheetScale, tone.down(0.058).al(0.30))
            y += rng.r(4.2, 5.8)
        }
        var x = rng.r(0, 90)
        while x < p.w {
            p.box(x, 0, 1.4 / sheetScale, p.h, tone.up(0.11).al(0.25))
            x += rng.r(74, 94)
        }
    }

    for _ in 0..<Int(p.w * p.h * sheetScale * sheetScale / 4000) {
        let fx = rng.d() * p.w, fy = rng.d() * p.h
        let a = rng.r(0, 6.283), len = rng.r(3, 13)
        p.ctx.setStrokeColor(cg(tone.down(rng.r(0.05, 0.18)).al(rng.r(0.14, 0.40))))
        p.ctx.setLineWidth(rng.r(0.6, 1.3))
        p.ctx.beginPath()
        p.ctx.move(to: CGPoint(x: fx, y: fy))
        p.ctx.addLine(to: CGPoint(x: fx + cos(a) * len, y: fy + sin(a) * len))
        p.ctx.strokePath()
    }

    for _ in 0..<rng.i(1, 3) {
        let sx = rng.d() * p.w, sy = rng.d() * p.h
        let rr = rng.r(p.w * 0.05, p.w * 0.14)
        var band: [CGPoint] = []
        var a = 0.0
        while a < 6.283 {
            band.append(CGPoint(x: sx + cos(a) * rr * rng.r(0.82, 1.18),
                                y: sy + sin(a) * rr * rng.r(0.82, 1.18)))
            a += 0.35
        }
        p.shape(band, Wash(r: 0.478, g: 0.427, b: 0.322, a: 0.050))
    }

    if let g = CGGradient(colorsSpace: rgbSpace,
                          colors: [cg(tone.down(0.17).al(0)), cg(tone.down(0.17).al(0.52))] as CFArray,
                          locations: [0.58, 1]) {
        p.ctx.drawRadialGradient(g, startCenter: CGPoint(x: p.w / 2, y: p.h / 2), startRadius: 0,
                                 endCenter: CGPoint(x: p.w / 2, y: p.h / 2),
                                 endRadius: max(p.w, p.h) * 0.74, options: [.drawsAfterEndLocation])
    }
}

func pool(_ p: Sheet, _ region: [CGPoint], _ colour: Wash,
          strength: Double = 0.40, bleed: Double = 6, seed: UInt64) {
    guard region.count > 2 else { return }
    var rng = Spark(seed)
    var edge: [CGPoint] = []
    for q in resample(region + [region[0]], count: max(24, region.count * 3)) {
        edge.append(CGPoint(x: q.x + CGFloat(rng.pm() * bleed), y: q.y + CGFloat(rng.pm() * bleed)))
    }
    let path = pathOf(edge)
    p.ctx.setFillColor(cg(colour.al(strength)))
    p.ctx.beginPath(); p.ctx.addPath(path); p.ctx.fillPath()
    p.ctx.setStrokeColor(cg(colour.down(0.20).al(strength * 0.54)))
    p.ctx.setLineWidth(CGFloat(bleed * 1.6))
    p.ctx.setLineJoin(.round)
    p.ctx.beginPath(); p.ctx.addPath(path); p.ctx.strokePath()

    p.inside(path) {
        let boxRect = path.boundingBox
        let unit = Double(min(boxRect.width, boxRect.height))
        let count = Int(Double(boxRect.width * boxRect.height) / (unit * unit * 0.5)) + 18
        for _ in 0..<min(170, count) {
            let x = Double(boxRect.minX) + rng.d() * Double(boxRect.width)
            let y = Double(boxRect.minY) + rng.d() * Double(boxRect.height)
            let rx = rng.r(unit * 0.020, unit * 0.085)
            let ry = rx * rng.r(0.35, 0.85)
            p.ellipse(x, y, rx, ry, rng.odds(0.62)
                      ? colour.down(0.16).al(strength * 0.14)
                      : colour.up(0.26).al(strength * 0.10))
        }
    }
}

func poolBand(_ p: Sheet, from y0: Double, to y1: Double, _ colour: Wash,
              strength: Double, seed: UInt64) {
    var rng = Spark(seed)
    let over = p.w * 0.09
    var top: [CGPoint] = []
    var x = -over
    while x <= p.w + over {
        top.append(CGPoint(x: x, y: y1 + CGFloat(rng.pm() * (abs(y1 - y0) * 0.10 + 4))))
        x += p.w / 22
    }
    var region: [CGPoint] = [CGPoint(x: CGFloat(-over), y: CGFloat(y0))]
    region.append(contentsOf: top)
    region.append(CGPoint(x: CGFloat(p.w + over), y: CGFloat(y0)))
    pool(p, region, colour, strength: strength, bleed: max(3, abs(y1 - y0) * 0.05), seed: seed &+ 5)
}

func pen(_ p: Sheet, _ pts: [CGPoint], weight: Double, colour: Wash = Ink.jet,
         wobble: Double = 1.0, taper: Bool = true, seed: UInt64 = 7) {
    guard pts.count > 1, weight > 0 else { return }
    var rng = Spark(seed)
    let n = max(10, min(90, Int(weight * 14)))
    let spine = resample(pts, count: n)
    var left: [CGPoint] = []
    var right: [CGPoint] = []
    for i in 0..<spine.count {
        let t = Double(i) / Double(spine.count - 1)
        let a = spine[max(0, i - 1)], b = spine[min(spine.count - 1, i + 1)]
        var tx = Double(b.x - a.x), ty = Double(b.y - a.y)
        let len = (tx * tx + ty * ty).squareRoot()
        if len > 0 { tx /= len; ty /= len } else { tx = 1; ty = 0 }
        let nx = -ty, ny = tx
        let swell = taper ? pow(sin(.pi * t), 0.42) : 1.0
        let hw = max(0.32, weight * 0.5 * (0.55 + 0.45 * swell)) * rng.r(0.88, 1.12)
        let off = rng.pm() * wobble
        let cx = Double(spine[i].x) + nx * off
        let cy = Double(spine[i].y) + ny * off
        left.append(CGPoint(x: cx + nx * hw, y: cy + ny * hw))
        right.append(CGPoint(x: cx - nx * hw, y: cy - ny * hw))
    }
    p.shape(left + right.reversed(), colour)
}

func penBroken(_ p: Sheet, _ pts: [CGPoint], weight: Double, colour: Wash = Ink.jet,
               pieces: Int = 3, gap: Double = 0.10, wobble: Double = 0.9, seed: UInt64 = 11) {
    var rng = Spark(seed)
    let spine = resample(pts, count: 60)
    var t = 0.0
    var k = 0
    while t < 1.0 {
        let run = rng.r(0.7, 1.3) / Double(max(1, pieces))
        let end = min(1.0, t + run)
        let i0 = Int(t * 59), i1 = Int(end * 59)
        if i1 > i0 + 1 {
            pen(p, Array(spine[i0...i1]), weight: weight * rng.r(0.82, 1.12),
                colour: colour, wobble: wobble, taper: true, seed: seed &+ UInt64(k) &+ 1)
        }
        t = end + rng.r(gap * 0.4, gap * 1.4)
        k += 1
    }
}

func penEdge(_ p: Sheet, _ pts: [CGPoint], weight: Double, colour: Wash = Ink.jet,
             seed: UInt64 = 13) {
    guard pts.count > 2 else { return }
    let closed = pts + [pts[0]]
    for i in 0..<(closed.count - 1) {
        let a = closed[i], b = closed[i + 1]
        let ang = atan2(Double(b.y - a.y), Double(b.x - a.x))
        let facing = cos(ang + .pi / 2 - p.light)
        let wt = weight * (0.60 + 0.66 * max(0, -facing))
        pen(p, [a, b], weight: wt, colour: colour, wobble: weight * 0.28,
            taper: false, seed: seed &+ UInt64(i * 17 + 3))
    }
}

func rule(_ p: Sheet, _ path: CGPath, angle: Double, spacing: Double,
          weight: Double = 1.1, colour: Wash = Ink.jetSoft,
          coverage: Double = 0.88, bound: CGPath? = nil, seed: UInt64 = 17) {
    guard !path.isEmpty else { return }
    var rng = Spark(seed)
    let area = path.boundingBox.insetBy(dx: -6, dy: -6)
    guard area.width > 1, area.height > 1 else { return }
    let dx = cos(angle), dy = sin(angle)
    let span = Double(area.width + area.height) * 1.2
    let body: () -> Void = {
        var t = -span / 2
        while t < span / 2 {
            if rng.d() <= coverage {
                let cx = Double(area.midX) - dy * t
                let cy = Double(area.midY) + dx * t
                let pieces = rng.i(2, 4)
                var u = -0.5 + rng.r(0, 0.10)
                for k in 0..<pieces {
                    let run = rng.r(0.08, 0.20)
                    let a = CGPoint(x: cx + dx * span * u, y: cy + dy * span * u)
                    let b = CGPoint(x: cx + dx * span * (u + run), y: cy + dy * span * (u + run))
                    pen(p, [a, b], weight: weight * rng.r(0.7, 1.25),
                        colour: colour.al(rng.r(0.55, 0.95)), wobble: 0.85, taper: true,
                        seed: seed &+ bits(Int(t) &* 31 &+ k &+ 101))
                    u += run + rng.r(0.03, 0.13)
                }
            }
            t += spacing * rng.r(0.86, 1.18)
        }
    }
    if let b = bound { p.insideBoth(path, b, body) } else { p.inside(path, body) }
}

func crossHatch(_ p: Sheet, _ path: CGPath, depth: Int, spacing: Double,
                colour: Wash = Ink.jetSoft, bound: CGPath? = nil, seed: UInt64 = 23) {
    let base = p.light + .pi / 2
    let heft = min(3.4, max(1.4, spacing * 0.22))
    rule(p, path, angle: base, spacing: spacing, weight: heft, colour: colour,
         coverage: 0.92, bound: bound, seed: seed)
    if depth >= 2 {
        rule(p, path, angle: base + 1.0, spacing: spacing * 1.15, weight: heft * 0.88,
             colour: colour, coverage: 0.78, bound: bound, seed: seed &+ 71)
    }
    if depth >= 3 {
        rule(p, path, angle: base - 0.9, spacing: spacing * 1.35, weight: heft * 0.76,
             colour: colour, coverage: 0.62, bound: bound, seed: seed &+ 131)
    }
}

func formShade(_ p: Sheet, _ pts: [CGPoint], inset: Double, depth: Int, spacing: Double,
               colour: Wash = Ink.jetSoft, seed: UInt64 = 53) {
    guard pts.count > 3 else { return }
    var cx = 0.0, cy = 0.0
    for q in pts { cx += Double(q.x); cy += Double(q.y) }
    cx /= Double(pts.count); cy /= Double(pts.count)
    let lx = cos(p.light), ly = sin(p.light)
    var outer: [CGPoint] = []
    var inner: [CGPoint] = []
    for q in pts {
        var dx = Double(q.x) - cx, dy = Double(q.y) - cy
        let len = (dx * dx + dy * dy).squareRoot()
        guard len > 0 else { continue }
        dx /= len; dy /= len
        let facing = dx * lx + dy * ly
        guard facing < 0.12 else { continue }
        let pull = inset * min(1.0, -facing + 0.12) * 1.4
        outer.append(q)
        inner.append(CGPoint(x: q.x - CGFloat(dx * pull), y: q.y - CGFloat(dy * pull)))
    }
    guard outer.count > 2 else { return }
    crossHatch(p, pathOf(outer + inner.reversed()), depth: depth, spacing: spacing,
               colour: colour, bound: pathOf(pts), seed: seed)
}

func stipple(_ p: Sheet, _ path: CGPath, density: Double, sizeMin: Double, sizeMax: Double,
             colour: Wash = Ink.jetSoft, seed: UInt64 = 29) {
    guard !path.isEmpty else { return }
    var rng = Spark(seed)
    let area = path.boundingBox
    let count = Int(Double(area.width * area.height) * density)
    p.inside(path) {
        for _ in 0..<max(0, min(26000, count)) {
            let x = Double(area.minX) + rng.d() * Double(area.width)
            let y = Double(area.minY) + rng.d() * Double(area.height)
            p.dot(x, y, rng.r(sizeMin, sizeMax), colour.al(rng.r(0.28, 0.85)))
        }
    }
}

func bristle(_ p: Sheet, _ path: CGPath, count: Int, length: Double, weight: Double,
             spread: Double, colour: Wash = Ink.jet, seed: UInt64 = 31) {
    guard !path.isEmpty else { return }
    var rng = Spark(seed)
    let area = path.boundingBox
    p.inside(path) {
        for k in 0..<count {
            let x = Double(area.minX) + rng.d() * Double(area.width)
            let y = Double(area.minY) + rng.d() * Double(area.height)
            let a = rng.r(-spread, spread) - .pi / 2
            let len = length * rng.r(0.6, 1.4)
            let mid = CGPoint(x: x + cos(a + 0.4) * len * 0.5, y: y - sin(a) * len * 0.5)
            pen(p, [CGPoint(x: x, y: y), mid,
                    CGPoint(x: x + cos(a) * len * 0.4, y: y - sin(a) * len)],
                weight: weight * rng.r(0.7, 1.3), colour: colour, wobble: 0.5,
                taper: true, seed: seed &+ UInt64(k))
        }
    }
}

func ringPts(cx: Double, cy: Double, rx: Double, ry: Double, steps: Int) -> [CGPoint] {
    var out: [CGPoint] = []
    for i in 0..<steps {
        let a = Double(i) / Double(steps) * 6.283185
        out.append(CGPoint(x: cx + cos(a) * rx, y: cy + sin(a) * ry))
    }
    return out
}

func lump(cx: Double, cy: Double, rx: Double, ry: Double, rough: Double,
          steps: Int = 28, seed: UInt64 = 41) -> [CGPoint] {
    var rng = Spark(seed)
    var out: [CGPoint] = []
    for i in 0..<steps {
        let a = Double(i) / Double(steps) * 6.283185
        let k = 1.0 + rng.pm() * rough
        out.append(CGPoint(x: cx + cos(a) * rx * k, y: cy + sin(a) * ry * k))
    }
    return out
}

enum Just { case left, centre, right }

func letter(_ p: Sheet, _ text: String, at x: Double, _ y: Double, size: Double,
            colour: Wash = Ink.jet, face: String = "Georgia", align: Just = .centre,
            tracking: Double = 0, rotate: Double = 0) {
    guard !text.isEmpty else { return }
    let font = CTFontCreateWithName(face as CFString, CGFloat(size), nil)
    var attrs: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key(kCTFontAttributeName as String): font,
        NSAttributedString.Key(kCTForegroundColorAttributeName as String): cg(colour)
    ]
    if tracking != 0 {
        attrs[NSAttributedString.Key(kCTKernAttributeName as String)] = CGFloat(tracking)
    }
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attrs))
    let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
    var dx = 0.0
    switch align {
    case .left: dx = 0
    case .centre: dx = -Double(bounds.width) / 2
    case .right: dx = -Double(bounds.width)
    }
    p.ctx.saveGState()
    p.ctx.translateBy(x: CGFloat(x), y: CGFloat(y))
    if rotate != 0 { p.ctx.rotate(by: CGFloat(rotate)) }
    p.ctx.scaleBy(x: 1, y: -1)
    p.ctx.textPosition = CGPoint(x: CGFloat(dx), y: 0)
    CTLineDraw(line, p.ctx)
    p.ctx.restoreGState()
}

func letterWidth(_ text: String, size: Double, face: String = "Georgia") -> Double {
    let font = CTFontCreateWithName(face as CFString, CGFloat(size), nil)
    let line = CTLineCreateWithAttributedString(
        NSAttributedString(string: text, attributes: [
            NSAttributedString.Key(kCTFontAttributeName as String): font]))
    return Double(CTLineGetBoundsWithOptions(line, .useOpticalBounds).width)
}

func wrapText(_ text: String, width: Double, size: Double, face: String = "Georgia") -> [String] {
    var lines: [String] = []
    var current = ""
    for word in text.split(separator: " ") {
        let trial = current.isEmpty ? String(word) : current + " " + String(word)
        if letterWidth(trial, size: size, face: face) > width && !current.isEmpty {
            lines.append(current); current = String(word)
        } else {
            current = trial
        }
    }
    if !current.isEmpty { lines.append(current) }
    return lines
}

func borderRule(_ p: Sheet, inset: Double, seed: UInt64, colour: Wash = Ink.jet) {
    var rng = Spark(seed)
    func frame(_ i: Double, _ wgt: Double, _ shade: Wash) {
        let c: [CGPoint] = [pt(i, i), pt(p.w - i, i), pt(p.w - i, p.h - i), pt(i, p.h - i)]
        for k in 0..<4 {
            pen(p, [c[k], c[(k + 1) % 4]], weight: wgt, colour: shade,
                wobble: 0.7, taper: false, seed: seed &+ UInt64(k * 7 + 1))
        }
    }
    frame(inset, 2.6, colour)
    frame(inset + rng.r(8, 12), 1.2, colour.al(0.55))
}
