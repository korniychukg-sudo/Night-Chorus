import Foundation

enum Clock {
    static var hour: Int { Calendar.current.component(.hour, from: Date()) }
    static var month: Int { Calendar.current.component(.month, from: Date()) - 1 }
    static var dayOfYear: Int {
        Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 180
    }
    static var hourFraction: Double {
        let c = Calendar.current.dateComponents([.hour, .minute], from: Date())
        return Double(c.hour ?? 0) + Double(c.minute ?? 0) / 60
    }

    static var seasonIndex: Int {
        switch month {
        case 2, 3, 4: return 0
        case 5, 6, 7: return 1
        case 8, 9, 10: return 2
        default: return 3
        }
    }
    static let seasonNames = ["Spring", "Summer", "Autumn", "Winter"]

    static func phase(_ hour: Double) -> Int {
        switch hour {
        case 4..<6: return 0
        case 6..<10: return 1
        case 10..<16: return 2
        case 16..<19: return 3
        case 19..<21: return 4
        case 21..<24: return 5
        case 0..<1: return 5
        default: return 6
        }
    }
    static var phaseIndex: Int { phase(hourFraction) }
    static let phaseNames = ["Grey dawn", "Morning", "Full day", "Late afternoon",
                            "Dusk", "Full dark", "The small hours"]
    static let phaseHours: [Double] = [5.0, 8.0, 13.0, 17.5, 20.0, 22.5, 2.5]

    static var dateLine: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE d MMMM"
        f.locale = Locale(identifier: "en_US")
        return f.string(from: Date())
    }

    static var moonPhase: Double {
        let synodic = 29.530588853
        let known = 1735689600.0
        let diff = Date().timeIntervalSince1970 - known
        var p = (diff / 86400).truncatingRemainder(dividingBy: synodic) / synodic
        if p < 0 { p += 1 }
        return p
    }

    static var moonIndex: Int {
        Int((moonPhase * 8).rounded()) % 8
    }

    static let moonNames = ["New moon", "Waxing crescent", "First quarter", "Waxing gibbous",
                            "Full moon", "Waning gibbous", "Last quarter", "Waning crescent"]

    static var moonLit: Double {
        (1 - cos(moonPhase * 2 * Double.pi)) / 2
    }
}

enum Weather {
    static func expected(month: Int, hour: Int) -> Double {
        let seasonal = [2.0, 3.0, 8.0, 13.0, 18.0, 23.0, 25.0, 24.0, 20.0, 14.0, 8.0, 3.0]
        let base = seasonal[max(0, min(11, month))]
        let swing = cos((Double(hour) - 15.0) / 24.0 * 2 * Double.pi) * 5.0
        return max(0, min(38, base + swing - 1))
    }

    static func fahrenheit(_ c: Double) -> Double { c * 9 / 5 + 32 }
    static func celsius(_ f: Double) -> Double { (f - 32) * 5 / 9 }

    static func words(_ c: Double) -> String {
        switch c {
        case ..<4: return "cold enough that nothing with six legs is moving"
        case 4..<10: return "cold, and every insect voice is slowed right down"
        case 10..<16: return "cool, and the crickets are running slow and clear"
        case 16..<22: return "mild, the temperature most of this was measured at"
        case 22..<27: return "warm, and everything ectothermic has speeded up"
        default: return "hot, and the trills are running too fast to count"
        }
    }
}

struct Spin {
    var s: UInt64
    init(_ seed: UInt64) { s = seed == 0 ? 0x2545F4914F6CDD1D : seed }
    mutating func next() -> UInt64 { s ^= s << 13; s ^= s >> 7; s ^= s << 17; return s }
    mutating func unit() -> Double { Double(next() % 1_000_000) / 1_000_000.0 }
    mutating func span(_ a: Double, _ b: Double) -> Double { a + unit() * (b - a) }
    mutating func step(_ a: Int, _ b: Int) -> Int { a + Int(next() % UInt64(max(1, b - a + 1))) }
    mutating func odds(_ p: Double) -> Bool { unit() < p }
    mutating func pick<T>(_ items: [T]) -> T { items[step(0, items.count - 1)] }
}

func seedOf(_ text: String) -> UInt64 {
    var h: UInt64 = 14695981039346656037
    for b in text.utf8 { h = (h ^ UInt64(b)) &* 1099511628211 }
    return h
}
