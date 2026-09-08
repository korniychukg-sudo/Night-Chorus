import Foundation
import CoreGraphics

struct VoiceArt {
    var key: String
    var name: String
    var latin: String
    var kind: Int
    var variant: Int
    var scene: Int
    var hue: Int
}

let voiceArt: [VoiceArt] = [
    VoiceArt(key: "peeper", name: "Spring Peeper", latin: "Pseudacris crucifer", kind: 2, variant: 0, scene: 0, hue: 0),
    VoiceArt(key: "woodfrog", name: "Wood Frog", latin: "Lithobates sylvaticus", kind: 0, variant: 1, scene: 2, hue: 1),
    VoiceArt(key: "chorusfrog", name: "Upland Chorus Frog", latin: "Pseudacris feriarum", kind: 2, variant: 1, scene: 1, hue: 2),
    VoiceArt(key: "graytree", name: "Gray Treefrog", latin: "Hyla versicolor", kind: 2, variant: 2, scene: 2, hue: 3),
    VoiceArt(key: "copestree", name: "Cope's Gray Treefrog", latin: "Hyla chrysoscelis", kind: 2, variant: 3, scene: 2, hue: 3),
    VoiceArt(key: "greenfrog", name: "Green Frog", latin: "Lithobates clamitans", kind: 0, variant: 2, scene: 0, hue: 0),
    VoiceArt(key: "bullfrog", name: "American Bullfrog", latin: "Lithobates catesbeianus", kind: 0, variant: 3, scene: 0, hue: 0),
    VoiceArt(key: "leopardfrog", name: "Northern Leopard Frog", latin: "Lithobates pipiens", kind: 0, variant: 4, scene: 1, hue: 2),
    VoiceArt(key: "pickerelfrog", name: "Pickerel Frog", latin: "Lithobates palustris", kind: 0, variant: 5, scene: 7, hue: 1),
    VoiceArt(key: "amtoad", name: "American Toad", latin: "Anaxyrus americanus", kind: 1, variant: 0, scene: 3, hue: 4),
    VoiceArt(key: "fowlertoad", name: "Fowler's Toad", latin: "Anaxyrus fowleri", kind: 1, variant: 1, scene: 6, hue: 4),
    VoiceArt(key: "spadefoot", name: "Eastern Spadefoot", latin: "Scaphiopus holbrookii", kind: 1, variant: 2, scene: 4, hue: 5),
    VoiceArt(key: "cricketfrog", name: "Northern Cricket Frog", latin: "Acris crepitans", kind: 0, variant: 6, scene: 0, hue: 2),
    VoiceArt(key: "narrowmouth", name: "Eastern Narrow-mouthed Toad", latin: "Gastrophryne carolinensis", kind: 1, variant: 3, scene: 1, hue: 5),
    VoiceArt(key: "carpenterfrog", name: "Carpenter Frog", latin: "Lithobates virgatipes", kind: 0, variant: 7, scene: 5, hue: 1),
    VoiceArt(key: "fieldcricket", name: "Fall Field Cricket", latin: "Gryllus pennsylvanicus", kind: 3, variant: 0, scene: 1, hue: 6),
    VoiceArt(key: "snowytree", name: "Snowy Tree Cricket", latin: "Oecanthus fultoni", kind: 3, variant: 1, scene: 3, hue: 7),
    VoiceArt(key: "fourspot", name: "Four-spotted Tree Cricket", latin: "Oecanthus quadripunctatus", kind: 3, variant: 2, scene: 1, hue: 7),
    VoiceArt(key: "narrowwing", name: "Narrow-winged Tree Cricket", latin: "Oecanthus niveus", kind: 3, variant: 3, scene: 2, hue: 7),
    VoiceArt(key: "allardground", name: "Allard's Ground Cricket", latin: "Allonemobius allardi", kind: 3, variant: 4, scene: 1, hue: 6),
    VoiceArt(key: "carolinaground", name: "Carolina Ground Cricket", latin: "Eunemobius carolinus", kind: 3, variant: 5, scene: 2, hue: 6),
    VoiceArt(key: "molecricket", name: "Northern Mole Cricket", latin: "Neocurtilla hexadactyla", kind: 3, variant: 6, scene: 0, hue: 4),
    VoiceArt(key: "springfield", name: "Spring Field Cricket", latin: "Gryllus veletis", kind: 3, variant: 7, scene: 1, hue: 6),
    VoiceArt(key: "truekatydid", name: "Common True Katydid", latin: "Pterophylla camellifolia", kind: 4, variant: 0, scene: 2, hue: 2),
    VoiceArt(key: "anglewing", name: "Greater Anglewing", latin: "Microcentrum rhombifolium", kind: 4, variant: 1, scene: 3, hue: 2),
    VoiceArt(key: "oblongwing", name: "Oblong-winged Katydid", latin: "Amblycorypha oblongifolia", kind: 4, variant: 2, scene: 1, hue: 2),
    VoiceArt(key: "roundconehead", name: "Round-tipped Conehead", latin: "Neoconocephalus retusus", kind: 5, variant: 0, scene: 1, hue: 2),
    VoiceArt(key: "swordconehead", name: "Sword-bearing Conehead", latin: "Neoconocephalus ensiger", kind: 5, variant: 1, scene: 1, hue: 2),
    VoiceArt(key: "robustconehead", name: "Robust Conehead", latin: "Neoconocephalus robustus", kind: 5, variant: 2, scene: 5, hue: 2),
    VoiceArt(key: "meadowkatydid", name: "Black-legged Meadow Katydid", latin: "Orchelimum nigripes", kind: 4, variant: 3, scene: 5, hue: 2),
    VoiceArt(key: "scissorgrinder", name: "Scissor-grinder Cicada", latin: "Neotibicen pruinosus", kind: 6, variant: 0, scene: 2, hue: 3),
    VoiceArt(key: "dogday", name: "Dog-day Cicada", latin: "Neotibicen canicularis", kind: 6, variant: 1, scene: 3, hue: 3),
    VoiceArt(key: "periodical", name: "Periodical Cicada", latin: "Magicicada septendecim", kind: 6, variant: 2, scene: 2, hue: 8),
    VoiceArt(key: "greathorned", name: "Great Horned Owl", latin: "Bubo virginianus", kind: 7, variant: 0, scene: 2, hue: 4),
    VoiceArt(key: "barred", name: "Barred Owl", latin: "Strix varia", kind: 7, variant: 1, scene: 7, hue: 4),
    VoiceArt(key: "screech", name: "Eastern Screech-Owl", latin: "Megascops asio", kind: 7, variant: 2, scene: 3, hue: 4),
    VoiceArt(key: "sawwhet", name: "Northern Saw-whet Owl", latin: "Aegolius acadicus", kind: 7, variant: 3, scene: 6, hue: 4),
    VoiceArt(key: "barnowl", name: "Barn Owl", latin: "Tyto alba", kind: 7, variant: 4, scene: 1, hue: 9),
    VoiceArt(key: "longeared", name: "Long-eared Owl", latin: "Asio otus", kind: 7, variant: 5, scene: 6, hue: 4),
    VoiceArt(key: "shorteared", name: "Short-eared Owl", latin: "Asio flammeus", kind: 7, variant: 6, scene: 1, hue: 9),
    VoiceArt(key: "whippoorwill", name: "Eastern Whip-poor-will", latin: "Antrostomus vociferus", kind: 8, variant: 0, scene: 2, hue: 4),
    VoiceArt(key: "chuckwills", name: "Chuck-will's-widow", latin: "Antrostomus carolinensis", kind: 8, variant: 1, scene: 6, hue: 4),
    VoiceArt(key: "nighthawk", name: "Common Nighthawk", latin: "Chordeiles minor", kind: 10, variant: 0, scene: 3, hue: 9),
    VoiceArt(key: "poorwill", name: "Common Poorwill", latin: "Phalaenoptilus nuttallii", kind: 8, variant: 2, scene: 4, hue: 5),
    VoiceArt(key: "woodcock", name: "American Woodcock", latin: "Scolopax minor", kind: 9, variant: 0, scene: 1, hue: 4),
    VoiceArt(key: "virginiarail", name: "Virginia Rail", latin: "Rallus limicola", kind: 9, variant: 1, scene: 5, hue: 4),
    VoiceArt(key: "sora", name: "Sora", latin: "Porzana carolina", kind: 9, variant: 2, scene: 5, hue: 2),
    VoiceArt(key: "bittern", name: "American Bittern", latin: "Botaurus lentiginosus", kind: 9, variant: 3, scene: 5, hue: 4),
    VoiceArt(key: "nightheron", name: "Black-crowned Night-Heron", latin: "Nycticorax nycticorax", kind: 9, variant: 4, scene: 0, hue: 9),
    VoiceArt(key: "loon", name: "Common Loon", latin: "Gavia immer", kind: 14, variant: 0, scene: 0, hue: 9),
    VoiceArt(key: "swainsons", name: "Swainson's Thrush", latin: "Catharus ustulatus", kind: 10, variant: 1, scene: 2, hue: 4),
    VoiceArt(key: "killdeer", name: "Killdeer", latin: "Charadrius vociferus", kind: 10, variant: 2, scene: 3, hue: 9),
    VoiceArt(key: "redfox", name: "Red Fox", latin: "Vulpes vulpes", kind: 11, variant: 0, scene: 3, hue: 8),
    VoiceArt(key: "grayfox", name: "Gray Fox", latin: "Urocyon cinereoargenteus", kind: 11, variant: 1, scene: 2, hue: 9),
    VoiceArt(key: "coyote", name: "Coyote", latin: "Canis latrans", kind: 11, variant: 2, scene: 4, hue: 4),
    VoiceArt(key: "flyingsquirrel", name: "Southern Flying Squirrel", latin: "Glaucomys volans", kind: 12, variant: 0, scene: 2, hue: 5),
    VoiceArt(key: "bigbrownbat", name: "Big Brown Bat", latin: "Eptesicus fuscus", kind: 12, variant: 1, scene: 3, hue: 5),
    VoiceArt(key: "raccoon", name: "Raccoon", latin: "Procyon lotor", kind: 11, variant: 3, scene: 3, hue: 9),
    VoiceArt(key: "freighttrain", name: "Distant Freight Train", latin: "Not an animal", kind: 13, variant: 0, scene: 1, hue: 9),
    VoiceArt(key: "generator", name: "Portable Generator", latin: "Not an animal", kind: 13, variant: 1, scene: 3, hue: 9),
    VoiceArt(key: "sprinkler", name: "Lawn Sprinkler", latin: "Not an animal", kind: 13, variant: 2, scene: 3, hue: 9),
    VoiceArt(key: "squeakygate", name: "Squeaky Gate Hinge", latin: "Not an animal", kind: 13, variant: 3, scene: 3, hue: 9),
    VoiceArt(key: "tinnitus", name: "Tinnitus", latin: "Not an animal", kind: 13, variant: 4, scene: 3, hue: 9)
]

func hueWash(_ i: Int) -> Wash {
    let table: [Wash] = [
        Ink.frogGreen, Ink.frogTan, Ink.frogOlive, Ink.frogGrey, Ink.toadBrown,
        Ink.sand, Ink.chitin, Ink.wingGreen, Ink.plumeRust, Ink.plumeGrey
    ]
    return table[i % table.count]
}

let plateW = 1240.0
let plateH = 1600.0

func nightPaper(_ p: Sheet, seed: UInt64) {
    layPaper(p, seed: seed, tone: Ink.leafBlue)
    p.flipTopDown()
    p.light = 3.90
}

func skyBand(_ p: Sheet, horizon: Double, seed: UInt64) {
    var rng = Spark(seed)
    poolBand(p, from: -20, to: horizon * 0.42, Ink.midnight, strength: 0.72, seed: seed &+ 1)
    poolBand(p, from: horizon * 0.36, to: horizon, Ink.indigo, strength: 0.44, seed: seed &+ 2)
    for _ in 0..<260 {
        let x = rng.d() * p.w
        let y = rng.r(30, horizon * 0.92)
        p.dot(x, y, rng.r(0.8, 2.4), Ink.starWhite.al(rng.r(0.14, 0.72)))
    }
    for _ in 0..<7 {
        let x = rng.d() * p.w
        let y = rng.r(50, horizon * 0.6)
        p.dot(x, y, rng.r(3.0, 5.0), Ink.starWhite.al(0.72))
        for k in 0..<4 {
            let a = Double(k) * 1.5708 + 0.3
            pen(p, [pt(x, y), pt(x + cos(a) * rng.r(10, 22), y + sin(a) * rng.r(10, 22))],
                weight: 1.6, colour: Ink.starWhite.al(0.42), wobble: 0.2, taper: true,
                seed: seed &+ UInt64(k))
        }
    }
}

func farRidge(_ p: Sheet, base: Double, amp: Double, kind: Int, seed: UInt64) {
    var rng = Spark(seed)
    var top: [CGPoint] = []
    var x = -30.0
    let step = p.w / 60
    while x <= p.w + 30 {
        let t = x / p.w
        var y = base - amp * (0.32 + 0.68 * abs(sin(t * 8.1 + 0.7)))
        switch kind {
        case 0:
            y = base - amp * (0.20 + 0.55 * abs(sin(t * 5.2)))
        case 1:
            y -= rng.r(0, amp * 0.9)
        case 2:
            y = base - amp * (0.55 + 0.45 * abs(sin(t * 3.1)))
            if rng.odds(0.20) { y -= amp * rng.r(0.4, 1.1) }
        default:
            y -= rng.r(0, amp * 0.4)
        }
        top.append(pt(x, y))
        x += step
    }
    var region = top
    region.append(pt(p.w + 30, base + amp * 2))
    region.append(pt(-30, base + amp * 2))
    pool(p, region, Ink.nightDeep, strength: 0.80, bleed: 5, seed: seed &+ 3)
    penBroken(p, top, weight: 2.4, colour: Ink.jet.al(0.6), pieces: 5, gap: 0.06,
              wobble: 1.4, seed: seed &+ 5)
}

func waterPlane(_ p: Sheet, top: Double, bottom: Double, seed: UInt64) {
    var rng = Spark(seed)
    poolBand(p, from: top, to: bottom, Ink.water, strength: 0.56, seed: seed &+ 1)
    for _ in 0..<70 {
        let y = rng.r(top + 6, bottom)
        let x0 = rng.d() * p.w
        let len = rng.r(p.w * 0.03, p.w * 0.20)
        pen(p, [pt(x0, y), pt(x0 + len, y + rng.r(-2, 2))],
            weight: rng.r(1.2, 3.0), colour: Ink.moonCool.al(rng.r(0.10, 0.34)),
            wobble: 0.6, taper: true, seed: rng.next())
    }
    let glint = rng.r(p.w * 0.3, p.w * 0.7)
    for k in 0..<16 {
        let y = top + Double(k) * (bottom - top) / 16
        let wide = 18.0 + Double(k) * 5
        pen(p, [pt(glint - wide, y), pt(glint + wide, y)], weight: rng.r(2.4, 5.4),
            colour: Ink.moonlit.al(rng.r(0.14, 0.42)), wobble: 1.2, taper: true, seed: rng.next())
    }
}

func stemsAt(_ p: Sheet, count: Int, baseY: Double, height: Double, tone: Wash,
             seed: UInt64, heads: Bool) {
    var rng = Spark(seed)
    for k in 0..<count {
        let x = rng.d() * p.w
        let len = height * rng.r(0.55, 1.35)
        let lean = rng.r(-0.22, 0.22)
        let top = pt(x + lean * len, baseY - len)
        pen(p, [pt(x, baseY), pt(x + lean * len * 0.45, baseY - len * 0.55), top],
            weight: rng.r(2.4, 5.0), colour: tone, wobble: 0.8, taper: true,
            seed: seed &+ UInt64(k))
        if heads && rng.odds(0.55) {
            let hl = len * rng.r(0.14, 0.24)
            let head = ringPts(cx: Double(top.x), cy: Double(top.y) - hl * 0.4,
                               rx: hl * 0.26, ry: hl * 0.55, steps: 18)
            p.shape(head, tone.down(0.10))
            penEdge(p, head, weight: 1.6, colour: Ink.jet.al(0.5), seed: seed &+ UInt64(k * 7))
        }
    }
}

func trunkAt(_ p: Sheet, x: Double, width: Double, top: Double, bottom: Double,
             tone: Wash, seed: UInt64) {
    var rng = Spark(seed)
    var left: [CGPoint] = []
    var right: [CGPoint] = []
    var y = top
    while y <= bottom {
        let wob = rng.r(-width * 0.10, width * 0.10)
        left.append(pt(x - width / 2 + wob, y))
        right.append(pt(x + width / 2 + wob * 0.6, y))
        y += (bottom - top) / 14
    }
    let form = left + right.reversed()
    pool(p, form, tone, strength: 0.66, bleed: 5, seed: seed &+ 1)
    formShade(p, form, inset: width * 0.42, depth: 3, spacing: 5.0,
              colour: Ink.jet.al(0.55), seed: seed &+ 3)
    for _ in 0..<Int(width * 0.7) {
        let yy = rng.r(top, bottom)
        let xx = x + rng.r(-width * 0.42, width * 0.42)
        pen(p, [pt(xx, yy), pt(xx + rng.r(-6, 6), yy + rng.r(30, 110))],
            weight: rng.r(1.0, 3.0), colour: Ink.jet.al(rng.r(0.16, 0.45)),
            wobble: 0.7, taper: true, seed: rng.next())
    }
    penEdge(p, form, weight: 3.0, colour: Ink.jet.al(0.8), seed: seed &+ 9)
}

func branchAt(_ p: Sheet, from a: CGPoint, to b: CGPoint, thick: Double,
              tone: Wash, seed: UInt64) {
    var rng = Spark(seed)
    let spine = resample([a, pt((Double(a.x) + Double(b.x)) / 2,
                                (Double(a.y) + Double(b.y)) / 2 - thick * 1.4), b], count: 40)
    var up: [CGPoint] = []
    var dn: [CGPoint] = []
    for (i, q) in spine.enumerated() {
        let t = Double(i) / Double(spine.count - 1)
        let w = thick * (1.0 - t * 0.45) * rng.r(0.88, 1.12)
        up.append(pt(Double(q.x), Double(q.y) - w))
        dn.append(pt(Double(q.x), Double(q.y) + w))
    }
    let form = up + dn.reversed()
    pool(p, form, tone, strength: 0.70, bleed: 4, seed: seed &+ 1)
    formShade(p, form, inset: thick * 1.1, depth: 2, spacing: 4.4,
              colour: Ink.jet.al(0.5), seed: seed &+ 5)
    penEdge(p, form, weight: 2.6, colour: Ink.jet.al(0.82), seed: seed &+ 7)
    for k in 0..<4 {
        let t = 0.2 + Double(k) * 0.2
        let i = Int(t * Double(spine.count - 1))
        let q = spine[i]
        pen(p, [q, pt(Double(q.x) + rng.r(-90, 90), Double(q.y) - rng.r(50, 150))],
            weight: thick * 0.34, colour: tone.down(0.25), wobble: 1.0, taper: true,
            seed: seed &+ UInt64(k * 13))
    }
}

func plateCaption(_ p: Sheet, name: String, latin: String) {
    let y = p.h - 168
    p.box(p.w * 0.12, y, p.w * 0.76, 1.8, Ink.moonCool.al(0.50))
    letter(p, name, at: p.w / 2, y + 54, size: 46, colour: Ink.moonlit.al(0.92),
           align: .centre)
    letter(p, latin, at: p.w / 2, y + 104, size: 28, colour: Ink.moonCool.al(0.76),
           face: "Georgia-Italic", align: .centre)
}

func frondAt(_ p: Sheet, root: CGPoint, reach: Double, lean: Double,
             tone: Wash, seed: UInt64) {
    var rng = Spark(seed)
    var spine: [CGPoint] = []
    for k in 0...9 {
        let t = Double(k) / 9.0
        spine.append(pt(Double(root.x) + lean * reach * t * t + rng.pm() * 10,
                        Double(root.y) - reach * t))
    }
    var blade: [CGPoint] = []
    for (i, q) in spine.enumerated() {
        let t = Double(i) / Double(spine.count - 1)
        blade.append(pt(Double(q.x) - reach * 0.13 * sin(t * 3.0 + 0.4), Double(q.y)))
    }
    for (i, q) in spine.enumerated().reversed() {
        let t = Double(i) / Double(spine.count - 1)
        blade.append(pt(Double(q.x) + reach * 0.13 * sin(t * 3.0 + 0.4), Double(q.y)))
    }
    pool(p, blade, tone, strength: 0.62, bleed: 6, seed: seed &+ 1)
    crossHatch(p, pathOf(blade), depth: 2, spacing: 17, colour: Ink.jet.al(0.52),
               seed: seed &+ 3)
    p.inside(pathOf(blade)) {
        pen(p, spine, weight: 7.0, colour: Ink.jet.al(0.86), wobble: 1.0,
            taper: true, seed: seed &+ 5)
        for k in 1..<9 {
            let t = Double(k) / 9.0
            let q = spine[k]
            let span = reach * 0.15 * sin(t * 3.0 + 0.4)
            for side in 0..<2 {
                let dir = side == 0 ? -1.0 : 1.0
                pen(p, [q, pt(Double(q.x) + dir * span, Double(q.y) + reach * 0.055)],
                    weight: 3.4, colour: Ink.jet.al(0.62), wobble: 0.8, taper: true,
                    seed: rng.next())
            }
        }
    }
    for run in rimRuns(blade, light: p.light, threshold: 0.34) {
        penBroken(p, run, weight: 4.0, colour: Ink.moonlit.al(0.34), pieces: 2,
                  gap: 0.14, wobble: 1.0, seed: seed &+ 9)
    }
    penEdge(p, blade, weight: 6.0, colour: Ink.jet.al(0.94), seed: seed &+ 11)
}

func nearFrame(_ p: Sheet, seed: UInt64) {
    var rng = Spark(seed)
    for side in 0..<2 {
        let leftSide = side == 0
        let count = 1
        for k in 0..<count {
            let rootX = leftSide ? rng.r(-70, p.w * 0.16) : rng.r(p.w * 0.84, p.w + 70)
            frondAt(p, root: pt(rootX, p.h + 70),
                    reach: rng.r(p.h * 0.30, p.h * 0.46),
                    lean: rng.r(0.10, 0.42) * (leftSide ? 1 : -1),
                    tone: Ink.nightDeep.up(0.06),
                    seed: seed &+ UInt64(side * 17 + k * 5 + 1))
        }
    }
    for k in 0..<8 {
        let x = rng.r(-40, p.w + 40)
        let len = rng.r(p.h * 0.08, p.h * 0.20)
        pen(p, [pt(x, p.h + 40), pt(x + rng.pm() * 40, p.h - len * 0.5),
                pt(x + rng.pm() * 110, p.h - len)],
            weight: rng.r(4.0, 10.0), colour: Ink.jet.al(rng.r(0.66, 0.92)),
            wobble: 2.0, taper: true, seed: seed &+ UInt64(k))
    }
}

func contourWrap(_ outline: [CGPoint], _ t: Double) -> [CGPoint] {
    var cx = 0.0, cy = 0.0
    for q in outline { cx += Double(q.x); cy += Double(q.y) }
    cx /= Double(outline.count); cy /= Double(outline.count)
    return outline.map { pt(cx + (Double($0.x) - cx) * t, cy + (Double($0.y) - cy) * t) }
}

func modelBody(_ p: Sheet, _ outline: [CGPoint], tone: Wash, depth: Int,
               spacing: Double, seed: UInt64, edge: Double = 3.2) {
    guard outline.count > 2 else { return }
    let form = pathOf(outline)
    let box = form.boundingBox
    let unit = max(24.0, Double(min(box.width, box.height)))
    pool(p, outline, tone.up(0.12), strength: 0.62, bleed: max(4, unit * 0.035), seed: seed &+ 1)
    crossHatch(p, form, depth: max(2, depth), spacing: max(12, unit * 0.075),
               colour: tone.down(0.62), seed: seed &+ 3)
    formShade(p, outline, inset: unit * 0.46, depth: max(2, depth),
              spacing: max(11, unit * 0.062), colour: Ink.jet.al(0.70), seed: seed &+ 5)
    var rng = Spark(seed &+ 11)
    p.inside(form) {
        for k in 0..<9 {
            let t = 0.20 + Double(k) * 0.088
            let ring = contourWrap(outline, t)
            penBroken(p, ring + [ring[0]], weight: max(1.8, unit * 0.016),
                      colour: tone.down(rng.r(0.24, 0.58)).al(rng.r(0.34, 0.62)),
                      pieces: rng.i(3, 5), gap: rng.r(0.10, 0.26), wobble: unit * 0.010,
                      seed: rng.next())
        }
        for _ in 0..<Int(unit * 0.26) {
            let x = Double(box.minX) + rng.d() * Double(box.width)
            let y = Double(box.minY) + rng.d() * Double(box.height)
            let len = unit * rng.r(0.06, 0.20)
            let a = p.light + .pi / 2 + rng.pm() * 0.5
            pen(p, [pt(x, y), pt(x + cos(a) * len, y + sin(a) * len)],
                weight: max(1.6, unit * rng.r(0.010, 0.024)),
                colour: (rng.odds(0.66) ? tone.down(rng.r(0.28, 0.66))
                         : Ink.moonCool).al(rng.r(0.24, 0.56)),
                wobble: unit * 0.006, taper: true, seed: rng.next())
        }
    }
    for run in rimRuns(outline, light: p.light, threshold: 0.24) {
        penBroken(p, run, weight: max(3.0, unit * 0.030),
                  colour: Ink.moonlit.al(0.52), pieces: 2, gap: 0.08,
                  wobble: unit * 0.006, seed: seed &+ 21)
    }
    penEdge(p, outline, weight: max(edge, unit * 0.028), colour: Ink.jet.al(0.92),
            seed: seed &+ 31)
}

func eyeAt(_ p: Sheet, _ x: Double, _ y: Double, _ r: Double, iris: Wash, seed: UInt64) {
    let ball = ringPts(cx: x, cy: y, rx: r, ry: r * 0.92, steps: 30)
    pool(p, ball, iris, strength: 0.62, bleed: max(2, r * 0.06), seed: seed &+ 1)
    var rng = Spark(seed &+ 3)
    p.inside(pathOf(ball)) {
        for k in 0..<26 {
            let a = Double(k) / 26.0 * 6.283185
            pen(p, [pt(x + cos(a) * r * 0.30, y + sin(a) * r * 0.30),
                    pt(x + cos(a) * r * 1.02, y + sin(a) * r * 0.96)],
                weight: max(1.4, r * 0.075), colour: iris.down(rng.r(0.30, 0.66)).al(0.66),
                wobble: r * 0.02, taper: true, seed: rng.next())
        }
    }
    formShade(p, ball, inset: r * 0.66, depth: 2, spacing: max(3.0, r * 0.20),
              colour: Ink.jet.al(0.66), seed: seed &+ 5)
    let pupil = ringPts(cx: x, cy: y, rx: r * 0.42, ry: r * 0.50, steps: 24)
    p.shape(pupil, Ink.eyeDark)
    penEdge(p, pupil, weight: max(1.6, r * 0.09), colour: Ink.jet, seed: seed &+ 7)
    p.dot(x - r * 0.34, y - r * 0.34, r * 0.17, Ink.starWhite.al(0.94))
    penEdge(p, ball, weight: max(2.2, r * 0.16), colour: Ink.jet, seed: seed &+ 9)
    let lid = [pt(x - r * 1.10, y - r * 0.30), pt(x - r * 0.24, y - r * 1.14),
               pt(x + r * 0.72, y - r * 0.92), pt(x + r * 1.12, y - r * 0.20)]
    pen(p, lid, weight: max(2.4, r * 0.19), colour: Ink.jet.al(0.88),
        wobble: r * 0.02, taper: true, seed: seed &+ 11)
    for k in 0..<4 {
        let t = 0.16 + Double(k) * 0.22
        let brow = lid.map { pt(Double($0.x), Double($0.y) - r * (0.24 + t * 0.5)) }
        penBroken(p, brow, weight: max(1.6, r * 0.10),
                  colour: Ink.jet.al(0.44), pieces: 2, gap: 0.16, wobble: r * 0.03,
                  seed: seed &+ UInt64(13 + k))
    }
}

func legLine(_ p: Sheet, _ pts: [CGPoint], weight: Double, tone: Wash, seed: UInt64) {
    guard pts.count > 1 else { return }
    let spine = resample(pts, count: 30)
    var left: [CGPoint] = []
    var right: [CGPoint] = []
    for i in 0..<spine.count {
        let t = Double(i) / Double(spine.count - 1)
        let a = spine[max(0, i - 1)], b = spine[min(spine.count - 1, i + 1)]
        var tx = Double(b.x) - Double(a.x), ty = Double(b.y) - Double(a.y)
        let len = max(0.0001, (tx * tx + ty * ty).squareRoot())
        tx /= len; ty /= len
        let hw = weight * 0.5 * (1.0 - t * 0.42)
        left.append(pt(Double(spine[i].x) - ty * hw, Double(spine[i].y) + tx * hw))
        right.append(pt(Double(spine[i].x) + ty * hw, Double(spine[i].y) - tx * hw))
    }
    let form = left + right.reversed()
    pool(p, form, tone, strength: 0.40, bleed: max(2, weight * 0.12), seed: seed &+ 1)
    crossHatch(p, pathOf(form), depth: 2, spacing: max(7, weight * 0.42),
               colour: tone.down(0.56), seed: seed &+ 3)
    formShade(p, form, inset: weight * 0.60, depth: 2, spacing: max(5, weight * 0.28),
              colour: Ink.jet.al(0.66), seed: seed &+ 5)
    for run in rimRuns(form, light: p.light, threshold: 0.30) {
        penBroken(p, run, weight: max(2.0, weight * 0.16), colour: Ink.moonlit.al(0.44),
                  pieces: 2, gap: 0.10, wobble: 0.6, seed: seed &+ 7)
    }
    penEdge(p, form, weight: max(2.4, weight * 0.16), colour: Ink.jet.al(0.90),
            seed: seed &+ 9)
}

func toesAt(_ p: Sheet, _ at: CGPoint, spread: Double, length: Double, count: Int,
            tone: Wash, pads: Bool, seed: UInt64) {
    var rng = Spark(seed)
    for k in 0..<count {
        let a = -0.9 + Double(k) / Double(max(1, count - 1)) * 1.8 + rng.r(-0.08, 0.08)
        let len = length * rng.r(0.7, 1.2)
        let tip = pt(Double(at.x) + sin(a) * len, Double(at.y) + cos(a) * len * 0.55)
        legLine(p, [at, pt(Double(at.x) + sin(a) * len * 0.5,
                           Double(at.y) + cos(a) * len * 0.34), tip],
                weight: spread * 0.34, tone: tone, seed: seed &+ UInt64(k))
        if pads {
            p.shape(ringPts(cx: Double(tip.x), cy: Double(tip.y),
                            rx: spread * 0.30, ry: spread * 0.26, steps: 14), tone.up(0.14))
            penEdge(p, ringPts(cx: Double(tip.x), cy: Double(tip.y),
                               rx: spread * 0.30, ry: spread * 0.26, steps: 14),
                    weight: 1.4, colour: Ink.jet.al(0.7), seed: seed &+ UInt64(k * 3))
        }
    }
}

func vocalSac(_ p: Sheet, at c: CGPoint, radius: Double, tone: Wash, seed: UInt64) {
    let sac = lump(cx: Double(c.x), cy: Double(c.y), rx: radius, ry: radius * 0.88,
                   rough: 0.05, steps: 30, seed: seed)
    modelBody(p, sac, tone: tone.up(0.10), depth: 2, spacing: max(2.0, radius * 0.10),
              seed: seed &+ 7, edge: 2.4)
    var rng = Spark(seed &+ 41)
    for _ in 0..<16 {
        let a = rng.r(0, 6.283)
        let d = rng.r(radius * 0.2, radius * 0.82)
        pen(p, [pt(Double(c.x) + cos(a) * d, Double(c.y) + sin(a) * d),
                pt(Double(c.x) + cos(a) * (d + radius * 0.22),
                   Double(c.y) + sin(a) * (d + radius * 0.22))],
            weight: rng.r(1.0, 2.2), colour: Ink.jet.al(rng.r(0.16, 0.34)),
            wobble: 0.4, taper: true, seed: rng.next())
    }
}

func frogPlate(_ p: Sheet, _ art: VoiceArt, seed: UInt64) {
    let tone = hueWash(art.hue)
    let cx = 600.0
    let cy = 900.0
    let long = art.variant == 4 || art.variant == 5 ? 1.16 : 1.0
    let fat = art.variant == 3 ? 1.22 : (art.variant == 6 ? 0.66 : 1.0)
    var outline: [CGPoint] = []
    let steps = 44
    for i in 0...steps {
        let t = Double(i) / Double(steps)
        let a = -Double.pi * 0.98 + t * Double.pi * 1.02
        let rx = 320.0 * long * fat
        let ry = 190.0 * fat
        outline.append(pt(cx + cos(a) * rx, cy + sin(a) * ry * (a < -1.2 ? 1.35 : 1.0)))
    }
    outline.append(pt(cx + 300 * long * fat, cy + 150 * fat))
    outline.append(pt(cx - 250 * long * fat, cy + 160 * fat))
    modelBody(p, outline, tone: tone, depth: 3, spacing: 5.2, seed: seed &+ 3)

    let headX = cx - 190 * long * fat
    let headY = cy - 96 * fat
    let head = lump(cx: headX, cy: headY, rx: 168 * fat, ry: 124 * fat,
                    rough: 0.05, steps: 34, seed: seed &+ 9)
    modelBody(p, head, tone: tone.up(0.06), depth: 3, spacing: 4.4, seed: seed &+ 11)

    if art.variant != 6 {
        vocalSac(p, at: pt(headX - 20, headY + 132 * fat), radius: 96 * fat,
                 tone: tone.up(0.14), seed: seed &+ 21)
    }

    eyeAt(p, headX - 62 * fat, headY - 62 * fat, 44 * fat,
          iris: Wash(r: 0.808, g: 0.663, b: 0.239), seed: seed &+ 31)
    eyeAt(p, headX + 84 * fat, headY - 74 * fat, 34 * fat,
          iris: Wash(r: 0.588, g: 0.478, b: 0.196), seed: seed &+ 33)
    pen(p, [pt(headX - 148 * fat, headY + 34 * fat), pt(headX - 40 * fat, headY + 62 * fat),
            pt(headX + 96 * fat, headY + 40 * fat)],
        weight: 5.0, colour: Ink.jet.al(0.78), wobble: 0.8, taper: true, seed: seed &+ 41)
    p.shape(ringPts(cx: headX + 116 * fat, cy: headY - 6 * fat, rx: 32 * fat,
                    ry: 30 * fat, steps: 20), tone.down(0.30))
    penEdge(p, ringPts(cx: headX + 116 * fat, cy: headY - 6 * fat, rx: 32 * fat,
                       ry: 30 * fat, steps: 20), weight: 2.2,
            colour: Ink.jet.al(0.7), seed: seed &+ 43)

    legLine(p, [pt(cx + 220 * long * fat, cy + 40),
                pt(cx + 320 * long * fat, cy + 190),
                pt(cx + 200 * long * fat, cy + 250),
                pt(cx + 300 * long * fat, cy + 320)],
            weight: 34 * fat, tone: tone, seed: seed &+ 51)
    toesAt(p, pt(cx + 300 * long * fat, cy + 320), spread: 40 * fat, length: 110 * fat,
           count: 5, tone: tone, pads: false, seed: seed &+ 53)
    legLine(p, [pt(cx - 120 * fat, cy + 120), pt(cx - 150 * fat, cy + 250),
                pt(cx - 110 * fat, cy + 320)],
            weight: 24 * fat, tone: tone, seed: seed &+ 55)
    toesAt(p, pt(cx - 110 * fat, cy + 320), spread: 30 * fat, length: 80 * fat,
           count: 4, tone: tone, pads: false, seed: seed &+ 57)

    var rng = Spark(seed &+ 71)
    let form = pathOf(outline)
    p.inside(form) {
        switch art.variant {
        case 1:
            pool(p, lump(cx: headX + 120, cy: headY + 4, rx: 90, ry: 62, rough: 0.20,
                         steps: 22, seed: seed &+ 81), Ink.jet, strength: 0.44,
                 bleed: 5, seed: seed &+ 83)
        case 4, 5:
            for _ in 0..<Int(art.variant == 4 ? 22 : 30) {
                let x = rng.r(cx - 280, cx + 300)
                let y = rng.r(cy - 180, cy + 140)
                let blot = lump(cx: x, cy: y, rx: rng.r(26, 52),
                                ry: rng.r(20, 38), rough: 0.22, steps: 20, seed: rng.next())
                pool(p, blot, Ink.jet, strength: 0.36, bleed: 3, seed: rng.next())
                penEdge(p, blot, weight: 2.0, colour: Ink.moonCool.al(0.30), seed: rng.next())
            }
        case 7:
            for k in 0..<4 {
                let y = cy - 120 + Double(k) * 76
                penBroken(p, [pt(cx - 300, y), pt(cx + 60, y + 20), pt(cx + 320, y + 6)],
                          weight: 9.0, colour: Ink.moonCool.al(0.34), pieces: 3, gap: 0.10,
                          wobble: 2.0, seed: seed &+ UInt64(k * 17))
            }
        case 2, 3:
            for _ in 0..<180 {
                let x = rng.r(cx - 320, cx + 340)
                let y = rng.r(cy - 200, cy + 160)
                p.dot(x, y, rng.r(2.0, 5.4), Ink.jet.al(rng.r(0.10, 0.30)))
            }
        default:
            for _ in 0..<120 {
                let x = rng.r(cx - 320, cx + 340)
                let y = rng.r(cy - 200, cy + 160)
                pen(p, [pt(x, y), pt(x + rng.r(-30, 30), y + rng.r(-14, 14))],
                    weight: rng.r(1.4, 3.2), colour: Ink.jet.al(rng.r(0.10, 0.28)),
                    wobble: 0.5, taper: true, seed: rng.next())
            }
        }
        penBroken(p, [pt(cx - 250, cy - 150), pt(cx, cy - 168), pt(cx + 300, cy - 120)],
                  weight: 7.0, colour: Ink.moonCool.al(0.30), pieces: 3, gap: 0.08,
                  wobble: 2.0, seed: seed &+ 91)
    }
}

func toadPlate(_ p: Sheet, _ art: VoiceArt, seed: UInt64) {
    let tone = hueWash(art.hue)
    let cx = 610.0
    let cy = 920.0
    let squat = art.variant == 2 ? 1.14 : 1.0
    let outline = lump(cx: cx, cy: cy, rx: 330 * squat, ry: 216 * squat,
                       rough: 0.045, steps: 46, seed: seed &+ 3)
    modelBody(p, outline, tone: tone, depth: 3, spacing: 5.6, seed: seed &+ 5)
    let headX = cx - 216 * squat
    let headY = cy - 78 * squat
    let head = lump(cx: headX, cy: headY, rx: 170 * squat, ry: 132 * squat,
                    rough: 0.05, steps: 32, seed: seed &+ 9)
    modelBody(p, head, tone: tone.up(0.05), depth: 3, spacing: 4.6, seed: seed &+ 11)
    vocalSac(p, at: pt(headX - 24, headY + 148 * squat), radius: 118 * squat,
             tone: tone.up(0.20), seed: seed &+ 21)
    eyeAt(p, headX - 56 * squat, headY - 66 * squat, 46 * squat,
          iris: Wash(r: 0.839, g: 0.686, b: 0.243), seed: seed &+ 31)
    eyeAt(p, headX + 90 * squat, headY - 76 * squat, 34 * squat,
          iris: Wash(r: 0.596, g: 0.494, b: 0.204), seed: seed &+ 33)
    pen(p, [pt(headX - 152 * squat, headY + 40), pt(headX - 30, headY + 66),
            pt(headX + 104 * squat, headY + 42)],
        weight: 5.6, colour: Ink.jet.al(0.80), wobble: 0.8, taper: true, seed: seed &+ 41)

    let gland = lump(cx: headX + 96, cy: headY - 6, rx: 88 * squat, ry: 42 * squat,
                     rough: 0.10, steps: 22, seed: seed &+ 45)
    pool(p, gland, tone.down(0.26), strength: 0.50, bleed: 4, seed: seed &+ 47)
    penEdge(p, gland, weight: 2.4, colour: Ink.jet.al(0.68), seed: seed &+ 49)

    legLine(p, [pt(cx + 244 * squat, cy + 60), pt(cx + 336 * squat, cy + 200),
                pt(cx + 214 * squat, cy + 258), pt(cx + 308 * squat, cy + 330)],
            weight: 40 * squat, tone: tone, seed: seed &+ 51)
    toesAt(p, pt(cx + 308 * squat, cy + 330), spread: 44, length: 118, count: 5,
           tone: tone, pads: false, seed: seed &+ 53)
    legLine(p, [pt(cx - 130, cy + 140), pt(cx - 168, cy + 262), pt(cx - 120, cy + 328)],
            weight: 28 * squat, tone: tone, seed: seed &+ 55)
    toesAt(p, pt(cx - 120, cy + 328), spread: 32, length: 86, count: 4,
           tone: tone, pads: false, seed: seed &+ 57)

    var rng = Spark(seed &+ 61)
    p.inside(pathOf(outline)) {
        for _ in 0..<Int(art.variant == 3 ? 90 : 210) {
            let x = rng.r(cx - 330, cx + 340)
            let y = rng.r(cy - 220, cy + 190)
            let r = rng.r(7, 21)
            let wart = ringPts(cx: x, cy: y, rx: r, ry: r * 0.86, steps: 12)
            p.shape(wart, tone.down(rng.r(0.10, 0.28)).al(0.7))
            pen(p, [pt(x - r * 0.6, y - r * 0.6), pt(x + r * 0.3, y - r * 0.9)],
                weight: 1.6, colour: Ink.moonCool.al(0.34), wobble: 0.3, taper: true,
                seed: rng.next())
            penEdge(p, wart, weight: 1.4, colour: Ink.jet.al(0.42), seed: rng.next())
        }
    }
}

func treeFrogPlate(_ p: Sheet, _ art: VoiceArt, seed: UInt64) {
    let tone = hueWash(art.hue)
    let stemX = 620.0
    trunkAt(p, x: stemX + 130, width: 118, top: 220, bottom: p.h - 150,
            tone: Ink.barkPale, seed: seed &+ 3)
    let cx = 560.0
    let cy = 880.0
    let small = art.variant == 0 || art.variant == 1 ? 0.66 : 1.0
    let outline = lump(cx: cx, cy: cy, rx: 250 * small, ry: 168 * small,
                       rough: 0.05, steps: 40, seed: seed &+ 5)
    modelBody(p, outline, tone: tone, depth: 3, spacing: 4.8 * small, seed: seed &+ 7)
    let headX = cx - 150 * small
    let headY = cy - 68 * small
    let head = lump(cx: headX, cy: headY, rx: 138 * small, ry: 108 * small,
                    rough: 0.05, steps: 30, seed: seed &+ 9)
    modelBody(p, head, tone: tone.up(0.06), depth: 3, spacing: 4.2 * small, seed: seed &+ 11)
    vocalSac(p, at: pt(headX - 14, headY + 128 * small), radius: 104 * small,
             tone: tone.up(0.16), seed: seed &+ 21)
    eyeAt(p, headX - 50 * small, headY - 54 * small, 42 * small,
          iris: Wash(r: 0.855, g: 0.678, b: 0.259), seed: seed &+ 31)
    eyeAt(p, headX + 76 * small, headY - 62 * small, 31 * small,
          iris: Wash(r: 0.588, g: 0.463, b: 0.184), seed: seed &+ 33)
    pen(p, [pt(headX - 124 * small, headY + 34 * small), pt(headX - 20, headY + 56 * small),
            pt(headX + 88 * small, headY + 34 * small)],
        weight: 4.4, colour: Ink.jet.al(0.78), wobble: 0.7, taper: true, seed: seed &+ 41)

    for (k, anchor) in [pt(cx + 150 * small, cy - 96 * small),
                        pt(cx + 190 * small, cy + 70 * small),
                        pt(cx - 130 * small, cy + 96 * small)].enumerated() {
        legLine(p, [pt(cx, cy), anchor,
                    pt(Double(anchor.x) + 96 * small, Double(anchor.y) + 30 * small)],
                weight: 26 * small, tone: tone, seed: seed &+ UInt64(51 + k * 4))
        toesAt(p, pt(Double(anchor.x) + 96 * small, Double(anchor.y) + 30 * small),
               spread: 34 * small, length: 74 * small, count: 4, tone: tone.up(0.10),
               pads: true, seed: seed &+ UInt64(53 + k * 4))
    }

    var rng = Spark(seed &+ 61)
    p.inside(pathOf(outline)) {
        if art.variant == 0 {
            penBroken(p, [pt(cx - 220, cy - 120), pt(cx + 30, cy + 20), pt(cx + 220, cy + 130)],
                      weight: 16, colour: Ink.jet.al(0.44), pieces: 2, gap: 0.05,
                      wobble: 2.0, seed: seed &+ 63)
            penBroken(p, [pt(cx + 220, cy - 120), pt(cx + 20, cy + 20), pt(cx - 210, cy + 130)],
                      weight: 16, colour: Ink.jet.al(0.44), pieces: 2, gap: 0.05,
                      wobble: 2.0, seed: seed &+ 65)
        } else if art.variant == 1 {
            for k in 0..<3 {
                penBroken(p, [pt(cx - 240, cy - 90 + Double(k) * 74),
                              pt(cx + 240, cy - 60 + Double(k) * 74)],
                          weight: 12, colour: Ink.jet.al(0.40), pieces: 3, gap: 0.10,
                          wobble: 2.2, seed: seed &+ UInt64(67 + k))
            }
        } else {
            for _ in 0..<40 {
                let x = rng.r(cx - 250, cx + 250)
                let y = rng.r(cy - 170, cy + 150)
                let blot = lump(cx: x, cy: y, rx: rng.r(24, 62), ry: rng.r(18, 44),
                                rough: 0.30, steps: 18, seed: rng.next())
                pool(p, blot, Ink.jet, strength: art.variant == 3 ? 0.36 : 0.24,
                     bleed: 4, seed: rng.next())
            }
        }
    }
}
