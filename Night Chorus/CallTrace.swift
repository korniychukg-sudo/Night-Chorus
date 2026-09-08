import Foundation

enum Trace {
    static func period(_ v: Voice, _ t: Double) -> Double { 1 / max(0.05, v.rate(t)) }

    static func squeeze(_ v: Voice, _ t: Double) -> Double {
        max(0.35, 1 + v.tempSlope * (t - 20))
    }

    static func cycle(_ v: Voice, _ t: Double) -> Double {
        let p = period(v, t)
        guard v.burst > 0 else { return p }
        return Double(v.burst) * p + (v.burstGap + v.phraseGap) / squeeze(v, t)
    }

    static func burstLength(_ v: Voice, _ t: Double) -> Double {
        v.burst > 0 ? Double(v.burst) * period(v, t) : 0
    }

    static func envelope(_ v: Voice, _ t: Double, at time: Double) -> Double {
        let p = period(v, t)
        let dur = min(v.pulse, p * 0.94)
        var local = time
        if v.burst > 0 {
            let cyc = cycle(v, t)
            local = time.truncatingRemainder(dividingBy: cyc)
            if local < 0 { local += cyc }
            let span = Double(v.burst) * p
            if local >= span { return 0 }
        }
        var tp = local.truncatingRemainder(dividingBy: p)
        if tp < 0 { tp += p }
        guard tp < dur else { return 0 }
        let u = tp / dur
        let at = max(0.02, v.attack)
        if u < at { return u / at }
        let d = 1 - (u - at) / (1 - at)
        return d * d * (0.55 + 0.45 * d)
    }

    static func pulseStarts(_ v: Voice, _ t: Double, from: Double, to: Double) -> [Double] {
        let p = period(v, t)
        guard p > 0.0005 else { return [] }
        var out: [Double] = []
        let cyc = cycle(v, t)
        var k = floor(from / p)
        var count = 0
        while count < 600 {
            let start = k * p
            if start > to { break }
            if start >= from - p {
                var ok = true
                if v.burst > 0 {
                    var local = start.truncatingRemainder(dividingBy: cyc)
                    if local < 0 { local += cyc }
                    if local >= Double(v.burst) * p - p * 0.4 { ok = false }
                }
                if ok { out.append(start) }
            }
            k += 1
            count += 1
        }
        return out
    }

    static func waveform(_ v: Voice, _ t: Double, at time: Double) -> Double {
        let env = envelope(v, t, at: time)
        guard env > 0.0001 else { return 0 }
        let freq = v.carrier
        let carrier = sin(2 * Double.pi * freq * time)
        let grain = sin(2 * Double.pi * freq * 1.61803 * time + 1.3)
        return env * (carrier * (1 - v.band) + grain * v.band * 0.9)
    }

    static func grooveDepth(_ v: Voice, _ t: Double, at u: Double, seed: Int) -> Double {
        let cyc = cycle(v, t)
        let time = u * cyc
        let env = envelope(v, t, at: time)
        let wob = sin(u * 61.3 + Double(seed % 97) * 0.31) * 0.10
        return env * (0.82 + wob) + env * env * 0.24
    }

    static func spread(_ v: Voice) -> Double {
        0.045 + v.band * 0.34
    }

    static func description(_ v: Voice, _ t: Double) -> String {
        let r = v.rate(t)
        let c = v.cycleRate(t)
        var parts: [String] = []
        if r >= 40 {
            parts.append(String(format: "about %.0f pulses a second", r))
        } else {
            parts.append(String(format: "%.1f pulses a second", r))
        }
        parts.append("centred on " + v.carrierText)
        if v.burst > 1 {
            parts.append(String(format: "in groups of %d, repeating %.2f times a second",
                                v.burst, c))
        } else if v.burst == 1 {
            parts.append(String(format: "one note every %.1f seconds", 1 / max(0.02, c)))
        } else {
            parts.append("with no break in it")
        }
        return parts.joined(separator: ", ")
    }
}
