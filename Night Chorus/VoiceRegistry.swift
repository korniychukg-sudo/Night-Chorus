import Foundation

enum Cal {
    static let jan = 1, feb = 2, mar = 4, apr = 8, may = 16, jun = 32
    static let jul = 64, aug = 128, sep = 256, oct = 512, nov = 1024, dec = 2048
    static let allYear = 4095
    static let earlySpring = mar | apr
    static let spring = mar | apr | may
    static let lateSpring = apr | may | jun
    static let summer = jun | jul | aug
    static let midSummer = jul | aug
    static let lateSummer = jul | aug | sep
    static let autumn = aug | sep | oct
    static let lateAutumn = sep | oct | nov
    static let winter = dec | jan | feb
    static let coldMonths = dec | jan | feb | mar

    static let names = ["January", "February", "March", "April", "May", "June",
                        "July", "August", "September", "October", "November", "December"]
    static let short = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"]

    static func hours(_ from: Int, _ to: Int) -> Int {
        var mask = 0
        var h = from
        while true {
            mask |= 1 << (h % 24)
            if h % 24 == to % 24 { break }
            h += 1
            if h > from + 24 { break }
        }
        return mask
    }

    static func has(_ mask: Int, month: Int) -> Bool { mask & (1 << month) != 0 }
    static func hasHour(_ mask: Int, _ hour: Int) -> Bool { mask & (1 << (hour % 24)) != 0 }

    static func monthSpan(_ mask: Int) -> String {
        var runs: [(Int, Int)] = []
        var start = -1
        for m in 0..<12 {
            let on = has(mask, month: m)
            if on && start < 0 { start = m }
            if !on && start >= 0 { runs.append((start, m - 1)); start = -1 }
        }
        if start >= 0 { runs.append((start, 11)) }
        if runs.count == 2 && runs[0].0 == 0 && runs[1].1 == 11 {
            runs = [(runs[1].0, runs[0].1)]
        }
        if runs.isEmpty { return "never" }
        if mask == allYear { return "all year" }
        return runs.map { a, b in
            a == b ? Cal.names[a] : "\(Cal.names[a]) to \(Cal.names[b])"
        }.joined(separator: ", ")
    }

    static func hourSpan(_ mask: Int) -> String {
        var start = -1
        var end = -1
        for h in 0..<24 where hasHour(mask, h) {
            if start < 0 { start = h }
        }
        if mask & 1 != 0 && mask & (1 << 23) != 0 {
            var h = 0
            while hasHour(mask, h) && h < 24 { h += 1 }
            end = h - 1
            var g = 23
            while hasHour(mask, g) && g >= 0 { g -= 1 }
            start = g + 1
        } else {
            for h in stride(from: 23, through: 0, by: -1) where hasHour(mask, h) {
                if end < 0 { end = h }
            }
        }
        if start < 0 || end < 0 { return "any hour" }
        return String(format: "%02d:00 to %02d:00", start, (end + 1) % 24)
    }
}

enum Ground {
    static let names = ["Pond Edge", "Wet Meadow", "Hardwood Forest", "Suburban Garden",
                        "Desert Wash", "Cattail Marsh", "Pine Barren", "River Bottom"]
    static let keys = ["pond", "meadow", "hardwood", "garden", "wash", "marsh", "barren", "bottom"]
    static let pond = 1, meadow = 2, hardwood = 4, garden = 8
    static let wash = 16, marsh = 32, barren = 64, bottom = 128
    static let anywhere = 255
    static let wetPlaces = pond | meadow | marsh | bottom
    static let dryPlaces = hardwood | garden | wash | barren

    static let blurbs = [
        "Still water with a soft margin of mud and sedge. The loudest single place in the spring night, and the one where a single species can drown out every other voice for weeks.",
        "Wet grass on a slow slope, no standing water most of the year. The meadow katydids and ground crickets own it after midsummer, and the whole surface of it seems to buzz.",
        "Closed canopy, deep leaf litter, and very little coming from the ground. This is where you listen upward: treefrogs, true katydids, and owls that need old trunks with holes in them.",
        "Mown grass, a hedge, a fence and a light left on. A thin cast, but it is where most people do their listening, and where the things that are not animals are loudest.",
        "Dry sand and gravel that runs water twice a year. Almost silent until it rains, and then it is the fastest chorus there is, over in a week.",
        "Standing water in dense cattail. The reeds carry low sound extremely well, which is why the deepest voices of the night live here and can be heard a mile off.",
        "Sandy soil under scrub pine and scrub oak. Warm and dry and open, a specialist habitat with a cast you will not hear anywhere else nearby.",
        "The flat ground beside a moving river, flooded most springs. Moving water gives you a permanent broadband hiss to listen through, and it hides the quiet voices."
    ]
}

enum Perch {
    static let ground = 0, lowVeg = 1, tree = 2, water = 3, air = 4, burrow = 5
    static let names = ["from the ground", "from low vegetation", "from a tree",
                        "from the water", "from the air", "from a burrow"]
    static let short = ["Ground", "Low plants", "Tree", "Water", "Air", "Burrow"]
}

enum Timbre {
    static let pure = 0, rasping = 1, liquid = 2, nasal = 3, noisy = 4, whistled = 5
    static let names = ["Pure", "Rasping", "Liquid", "Nasal", "Noisy", "Whistled"]
    static let blurbs = [
        "A single clean band on the spectrogram with almost nothing above or below it.",
        "A broad smear of energy across several kilohertz, made by a file and scraper.",
        "A narrow band that wobbles, with a soft attack and a rounded end.",
        "A narrow band plus strong harmonics stacked evenly above it.",
        "Energy everywhere, no band you can point at, like tearing paper.",
        "A pure band that slides, rising or falling within the note."
    ]
}

enum Shape {
    static let trill = 0, chirps = 1, phrase = 2, churr = 3, singles = 4, clicks = 5
    static let names = ["Continuous trill", "Spaced chirps", "Phrase and pause",
                        "Churr", "Single notes", "Clicks"]
    static let blurbs = [
        "One unbroken run of pulses that can last for minutes with no gap you can hear.",
        "Short groups of pulses repeated at a steady rate, with a clear gap between groups.",
        "A shaped sequence of several different notes, then a long silence, then the same sequence again.",
        "A rough continuous rattle, slower than a trill and with the pulses audible one by one.",
        "One note at a time with seconds of silence around it.",
        "Sharp broadband ticks with no tone to them, often speeding up or slowing down."
    ]
}

struct Voice: Identifiable, Hashable {
    let id: String
    let name: String
    let latin: String
    let group: Int
    let months: Int
    let hours: Int
    let habitats: Int
    let perch: Int
    let wet: Bool
    let carrier: Double
    let band: Double
    let rate20: Double
    let tempSlope: Double
    let pulse: Double
    let burst: Int
    let burstGap: Double
    let phraseGap: Double
    let sweep: Double
    let harm: Int
    let attack: Double
    let level: Double
    let timbre: Int
    let shape: Int
    let note: String
    let tell: String

    static func == (a: Voice, b: Voice) -> Bool { a.id == b.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    var plate: String { "vo_" + id }
    var ectotherm: Bool { tempSlope > 0 }

    func rate(_ celsius: Double) -> Double {
        max(0.05, rate20 * (1 + tempSlope * (celsius - 20)))
    }

    func cycleRate(_ celsius: Double) -> Double {
        let r = rate(celsius)
        guard burst > 0 else { return r }
        let span = Double(burst) / r + burstGap / max(0.2, 1 + tempSlope * (celsius - 20))
        return span > 0 ? 1 / span : r
    }

    func rateBandIndex(_ celsius: Double) -> Int {
        let r = rate(celsius)
        if r < 5 { return 0 }
        if r < 25 { return 1 }
        if r < 60 { return 2 }
        return 3
    }

    var freqBandIndex: Int {
        if carrier < 1000 { return 0 }
        if carrier < 3000 { return 1 }
        if carrier < 6000 { return 2 }
        return 3
    }

    var groupName: String { Registry.groupNames[group] }
    var groupHint: String { Registry.groupHints[group] }
    var perchName: String { Perch.names[perch] }
    var timbreName: String { Timbre.names[timbre] }
    var shapeName: String { Shape.names[shape] }

    var habitatList: [String] {
        (0..<8).filter { habitats & (1 << $0) != 0 }.map { Ground.names[$0] }
    }

    func callsIn(month: Int, hour: Int) -> Bool {
        Cal.has(months, month: month) && Cal.hasHour(hours, hour)
    }

    var carrierText: String {
        carrier >= 1000 ? String(format: "%.1f kHz", carrier / 1000) : String(format: "%.0f Hz", carrier)
    }
}

enum Registry {
    static let groupNames = ["Frogs and Toads", "Crickets", "Katydids", "Cicadas", "Owls",
                             "Nightjars", "Night Birds", "Mammals", "Not an Animal"]
    static let groupHints = ["A frog or a toad", "A cricket", "A katydid", "A cicada",
                             "An owl", "A nightjar", "A night bird", "A mammal",
                             "Something that is not an animal"]
    static let groupBlurbs = [
        "Cold-blooded, calling from water or from the plants over it, and every one of them speeds up as the night warms.",
        "A file on one wing drawn across a scraper on the other. Nearly pure tones, and the most reliable thermometers in the field.",
        "The same file and scraper as a cricket but coarser and faster, so the sound comes out as a broadband rasp instead of a tone.",
        "Not a stridulator at all: a pair of ribbed drums on the abdomen buckling in and out hundreds of times a second.",
        "Air pushed through a syrinx with almost no overtones. Warm-blooded, so the rhythm never changes with the temperature.",
        "Wide-mouthed aerial insect hunters that sing their own names, mostly from the ground or a low branch.",
        "Rails, bitterns, herons, waders and migrating thrushes. Some of the strangest sounds in the night belong here.",
        "Foxes, coyotes, squirrels and bats. Loud, irregular, and easy to mistake for something in distress.",
        "Trains, machinery, plumbing and your own ears. Ruling these out is half the skill."
    ]

    static let all: [Voice] = block1 + block2 + block3 + block4
        + block5 + block6 + block7 + block8

    static let byId: [String: Voice] = {
        var map: [String: Voice] = [:]
        for v in all { map[v.id] = v }
        return map
    }()

    static func find(_ id: String) -> Voice { byId[id] ?? all[0] }

    static func inGroup(_ g: Int) -> [Voice] { all.filter { $0.group == g } }

    static func calling(month: Int, hour: Int, habitat: Int) -> [Voice] {
        all.filter { $0.callsIn(month: month, hour: hour) && $0.habitats & (1 << habitat) != 0 }
    }

    static func callingAnywhere(month: Int, hour: Int) -> [Voice] {
        all.filter { $0.callsIn(month: month, hour: hour) }
    }
}
