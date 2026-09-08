import Foundation

struct Placed: Identifiable, Hashable {
    var id: String { voiceId + "@" + String(index) }
    var index: Int
    var voiceId: String
    var x: Double
    var depth: Double
    var offset: Double

    var pan: Double { max(-0.95, min(0.95, x)) }
    var distance: Double { 0.10 + depth * 0.90 }
}

struct Card {
    var day: Int
    var habitat: Int
    var hourFrom: Int
    var hourTo: Int
    var targets: [String]
    var extra: Int
    var opening: String

    var hourText: String {
        String(format: "%02d:00 to %02d:00", hourFrom, hourTo % 24)
    }
    var habitatName: String { Ground.names[habitat] }
}

enum Plan {
    static let nightHours = [18, 19, 20, 21, 22, 23, 0, 1, 2, 3, 4, 5]

    static let openings = [
        "Three voices to find and name before the night turns over.",
        "The card for tonight. Work them in any order you like.",
        "Tonight's three. Two of them will be easy and one will not.",
        "Go out, aim the dish, and put a name to these three.",
        "A short list. The point is not speed, it is certainty."
    ]

    static func callable(month: Int, habitat: Int, from: Int, to: Int) -> [Voice] {
        var out: [Voice] = []
        for v in Registry.all where v.habitats & (1 << habitat) != 0 {
            guard Cal.has(v.months, month: month) else { continue }
            var h = from
            var ok = false
            for _ in 0..<12 {
                if Cal.hasHour(v.hours, h) { ok = true; break }
                if h % 24 == to % 24 { break }
                h += 1
            }
            if ok { out.append(v) }
        }
        return out
    }

    static func card(_ day: Int) -> Card { card(day, month: Clock.month) }

    static func card(_ day: Int, month: Int) -> Card {
        var rng = Spin(seedOf("night-chorus-card-\(day)"))
        var order = Array(0..<8)
        for i in stride(from: order.count - 1, to: 0, by: -1) {
            let j = rng.step(0, i)
            order.swapAt(i, j)
        }
        let startIndex = rng.step(0, nightHours.count - 4)
        let from = nightHours[startIndex]
        let to = nightHours[min(nightHours.count - 1, startIndex + 3)]

        var bestHabitat = order[0]
        var bestPool = callable(month: month, habitat: bestHabitat, from: from, to: to)
        for h in order {
            let pool = callable(month: month, habitat: h, from: from, to: to)
            if pool.count >= 3 { bestHabitat = h; bestPool = pool; break }
            if pool.count > bestPool.count { bestHabitat = h; bestPool = pool }
        }

        var pool = bestPool
        pool.sort { $0.id < $1.id }
        var targets: [String] = []
        var guardCount = 0
        while targets.count < min(3, pool.count) && guardCount < 200 {
            guardCount += 1
            let pick = pool[rng.step(0, pool.count - 1)]
            if !targets.contains(pick.id) { targets.append(pick.id) }
        }
        let extra = rng.step(0, 3)
        return Card(day: day, habitat: bestHabitat, hourFrom: from, hourTo: to % 24,
                    targets: targets, extra: extra,
                    opening: openings[rng.step(0, openings.count - 1)])
    }

    static let extraTasks = [
        "No key steps on at least one of them.",
        "Read the temperature off a cricket before you finish.",
        "Cut a cylinder for every one you name.",
        "Name one of them with the frequency window closed to two kilohertz or less."
    ]

    static func extraRequired(_ rank: Int) -> Bool { rank >= 2 }

    static func stage(habitat: Int, month: Int, hour: Int, day: Int) -> [Placed] {
        var rng = Spin(seedOf("stage-\(habitat)-\(month)-\(hour)-\(day / 1)"))
        var pool = Registry.all.filter {
            $0.habitats & (1 << habitat) != 0
            && Cal.has($0.months, month: month)
            && Cal.hasHour($0.hours, hour)
        }
        pool.sort { $0.id < $1.id }
        if pool.count > ChorusEngine.capacity {
            var kept: [Voice] = []
            var seenGroups = Set<Int>()
            let promised = card(day, month: month)
            if promised.habitat == habitat {
                for id in promised.targets {
                    guard kept.count < ChorusEngine.capacity else { break }
                    guard let v = pool.first(where: { $0.id == id }) else { continue }
                    guard !kept.contains(where: { $0.id == v.id }) else { continue }
                    kept.append(v); seenGroups.insert(v.group)
                }
            }
            for v in pool where !seenGroups.contains(v.group) {
                guard kept.count < ChorusEngine.capacity else { break }
                kept.append(v); seenGroups.insert(v.group)
            }
            var rest = pool.filter { v in !kept.contains(where: { $0.id == v.id }) }
            while kept.count < ChorusEngine.capacity && !rest.isEmpty {
                let i = rng.step(0, rest.count - 1)
                kept.append(rest.remove(at: i))
            }
            pool = kept
        }
        pool.sort { $0.id < $1.id }
        var out: [Placed] = []
        for (i, v) in pool.enumerated() {
            let x = rng.span(-0.92, 0.92)
            var depth = rng.span(0.05, 0.95)
            if v.perch == Perch.tree { depth = min(depth, 0.7) }
            if v.perch == Perch.air { depth = max(depth, 0.5) }
            let cycle = max(0.4, 1 / max(0.05, v.cycleRate(20)))
            out.append(Placed(index: i, voiceId: v.id, x: x, depth: depth,
                              offset: rng.span(0, cycle)))
        }
        return out
    }

    static func staged(_ placed: [Placed]) -> [StagedVoice] {
        placed.map {
            StagedVoice(id: $0.voiceId, pan: $0.pan, distance: $0.distance,
                        scenePos: $0.x, scenePosY: $0.depth, offset: $0.offset,
                        gainScale: 1.0)
        }
    }
}

struct KeyStep: Identifiable {
    let id: Int
    let title: String
    let question: String
    let options: [String]
    let read: (Voice, Double) -> Int
    let phrasing: (Int) -> String
}

enum FieldKey {
    static let steps: [KeyStep] = [
        KeyStep(id: 0, title: "Pulse rate",
                question: "How many pulses a second?",
                options: ["Under 5", "5 to 25", "25 to 60", "Over 60"],
                read: { v, t in v.rateBandIndex(t) },
                phrasing: { i in ["fewer than five pulses a second",
                                  "between five and twenty-five a second",
                                  "between twenty-five and sixty a second",
                                  "more than sixty a second"][i] }),
        KeyStep(id: 1, title: "Carrier",
                question: "Where does the energy sit?",
                options: ["Below 1 kHz", "1 to 3 kHz", "3 to 6 kHz", "Above 6 kHz"],
                read: { v, _ in v.freqBandIndex },
                phrasing: { i in ["below the one kilohertz line",
                                  "between one and three kilohertz",
                                  "between three and six kilohertz",
                                  "above six kilohertz"][i] }),
        KeyStep(id: 2, title: "Pattern",
                question: "What shape is the call?",
                options: Shape.names,
                read: { v, _ in v.shape },
                phrasing: { i in Shape.names[i].lowercased() }),
        KeyStep(id: 3, title: "Quality",
                question: "What does it sound like?",
                options: Timbre.names,
                read: { v, _ in v.timbre },
                phrasing: { i in Timbre.names[i].lowercased() }),
        KeyStep(id: 4, title: "Perch",
                question: "Where is it calling from?",
                options: Perch.short,
                read: { v, _ in v.perch },
                phrasing: { i in Perch.names[i] }),
        KeyStep(id: 5, title: "Ground",
                question: "Wet ground or dry?",
                options: ["Wet", "Dry"],
                read: { v, _ in v.wet ? 0 : 1 },
                phrasing: { i in i == 0 ? "over wet ground or water" : "over dry ground" })
    ]

    static func narrow(_ pool: [Voice], used: [Int: Int], temperature: Double) -> [Voice] {
        pool.filter { v in
            for (stepId, value) in used {
                if steps[stepId].read(v, temperature) != value { return false }
            }
            return true
        }
    }

    static func quality(isolation: Double, stepsUsed: Int, hold: Double, firstTry: Bool) -> Double {
        let clean = max(0, min(1, isolation))
        let terse = max(0, 1 - Double(stepsUsed) / 6.0)
        let full = max(0, min(1, hold))
        var q = clean * 0.34 + terse * 0.28 + full * 0.38
        if !firstTry { q *= 0.72 }
        return max(0.05, min(1, q))
    }
}
