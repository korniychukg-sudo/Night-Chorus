import Foundation
import SwiftUI

struct Cylinder: Codable, Hashable, Identifiable {
    var id: String { voiceId }
    var voiceId: String
    var quality: Double
    var day: Int
    var seed: Int
    var keySteps: Int
    var isolation: Double
    var length: Double

    var grade: String {
        switch quality {
        case 0.88...: return "Archive"
        case 0.72..<0.88: return "Clean"
        case 0.52..<0.72: return "Usable"
        default: return "Rough"
        }
    }

    var gradeTone: Color {
        switch quality {
        case 0.88...: return Nite.good
        case 0.72..<0.88: return Nite.moss
        case 0.52..<0.72: return Nite.brass
        default: return Nite.inkFaint
        }
    }
}

struct NightLog: Codable, Hashable, Identifiable {
    var id: Int { day }
    var day: Int
    var named: [String]
    var habitat: Int
    var score: Double
    var temperature: Double
}

struct Ledger: Codable {
    var nights: [NightLog] = []
    var cabinet: [Cylinder] = []
    var streak: Int = 0
    var bestStreak: Int = 0
    var lastDay: Int = -1
    var marks: Int = 0
    var seenIntro: Bool? = nil
    var readVoices: [String]? = nil
    var readPages: [String]? = nil
    var namedEver: [String]? = nil
    var temperature: Double? = nil
    var lastHabitat: Int? = nil
    var soundOn: Bool? = nil
}

final class Field: ObservableObject {
    @Published var ledger: Ledger { didSet { save() } }
    private let key = "night.chorus.ledger.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(Ledger.self, from: data) {
            ledger = decoded
        } else {
            ledger = Ledger()
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(ledger) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static let epoch: Double = 1_767_225_600
    var today: Int { max(0, Int((Date().timeIntervalSince1970 - Field.epoch) / 86_400)) }

    var liveStreak: Int {
        guard ledger.lastDay == today || ledger.lastDay == today - 1 else { return 0 }
        return ledger.streak
    }

    var soundOn: Bool {
        get { ledger.soundOn ?? true }
        set { ledger.soundOn = newValue }
    }

    var temperature: Double {
        get { ledger.temperature ?? Weather.expected(month: Clock.month, hour: Clock.hour) }
        set { ledger.temperature = max(0, min(38, newValue)) }
    }

    var habitat: Int {
        get { ledger.lastHabitat ?? 0 }
        set { ledger.lastHabitat = max(0, min(7, newValue)) }
    }

    var rankIndex: Int {
        let p = ledger.marks
        var index = 0
        for (i, step) in Field.ranks.enumerated() where p >= step.0 { index = i }
        return index
    }

    static let ranks: [(Int, String, String)] = [
        (0, "Listener", "You are outside after dark on purpose, which is more than most people manage."),
        (150, "Field Recorder", "You can put a name to the loud ones and you have started keeping cylinders."),
        (420, "Naturalist", "You know who should be calling tonight before you go out and check."),
        (900, "Bioacoustician", "You read pulse rate and carrier off a spectrogram and separate the confusable pairs."),
        (1700, "Chorus Master", "You can pull one voice out of a full summer wall of sound and name it cold.")
    ]

    var rank: (String, String, Int, Int) {
        let p = ledger.marks
        let i = rankIndex
        let current = Field.ranks[i]
        let next = i + 1 < Field.ranks.count ? Field.ranks[i + 1] : current
        return (current.1, current.2, p, next.0 == current.0 ? current.0 : next.0)
    }

    func award(_ n: Int) { ledger.marks += n }

    func loggedToday() -> Bool { ledger.nights.contains { $0.day == today } }

    func markTonight(_ id: String, habitat: Int, temperature: Double, targets: [String]) {
        let firstToday = !ledger.nights.contains { $0.day == today }
        var log = ledger.nights.first { $0.day == today }
            ?? NightLog(day: today, named: [], habitat: habitat, score: 0, temperature: temperature)
        if !log.named.contains(id) { log.named.append(id) }
        log.habitat = habitat
        log.temperature = temperature
        let hit = targets.filter { log.named.contains($0) }.count
        log.score = targets.isEmpty ? 0 : Double(hit) / Double(targets.count)
        ledger.nights.removeAll { $0.day == today }
        ledger.nights.append(log)
        ledger.nights.sort { $0.day > $1.day }
        if ledger.nights.count > 220 { ledger.nights.removeLast(ledger.nights.count - 220) }
        if firstToday {
            if ledger.lastDay == today - 1 { ledger.streak += 1 } else { ledger.streak = 1 }
            ledger.lastDay = today
            ledger.bestStreak = max(ledger.bestStreak, ledger.streak)
            award(10)
        }
    }

    var tonight: NightLog? { ledger.nights.first { $0.day == today } }

    func named(_ id: String) {
        var seen = ledger.namedEver ?? []
        if !seen.contains(id) { seen.append(id); award(14) } else { award(4) }
        ledger.namedEver = seen
    }

    func hasNamed(_ id: String) -> Bool { (ledger.namedEver ?? []).contains(id) }
    var namedCount: Int { (ledger.namedEver ?? []).count }

    func cut(_ cylinder: Cylinder) {
        if let old = ledger.cabinet.first(where: { $0.voiceId == cylinder.voiceId }) {
            if cylinder.quality > old.quality {
                ledger.cabinet.removeAll { $0.voiceId == cylinder.voiceId }
                ledger.cabinet.append(cylinder)
                award(18)
            } else {
                award(5)
            }
        } else {
            ledger.cabinet.append(cylinder)
            award(30)
        }
    }

    func cylinder(_ id: String) -> Cylinder? { ledger.cabinet.first { $0.voiceId == id } }

    func markRead(_ kind: Int, _ id: String) {
        func bump(_ list: [String]?) -> [String]? {
            var seen = list ?? []
            if !seen.contains(id) { seen.append(id); award(3) }
            return seen
        }
        if kind == 0 { ledger.readVoices = bump(ledger.readVoices) }
        else { ledger.readPages = bump(ledger.readPages) }
    }

    var readVoiceCount: Int { (ledger.readVoices ?? []).count }
    var bestNight: Double { ledger.nights.map { $0.score }.max() ?? 0 }
}
