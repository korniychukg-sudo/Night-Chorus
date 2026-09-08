import Foundation
import AVFoundation
import UIKit

let sineBits = 12
let sineCount = 1 << sineBits
let sineMask = sineCount - 1

let sineTable: UnsafeMutablePointer<Float> = {
    let p = UnsafeMutablePointer<Float>.allocate(capacity: sineCount + 1)
    for i in 0...sineCount {
        p[i] = Float(sin(2.0 * Double.pi * Double(i) / Double(sineCount)))
    }
    return p
}()

@inline(__always) func fastSin(_ phase: Float) -> Float {
    let x = phase - floorf(phase)
    let idx = x * Float(sineCount)
    let i0 = Int(idx) & sineMask
    let fr = idx - floorf(idx)
    let a = sineTable[i0]
    let b = sineTable[i0 + 1]
    return a + (b - a) * fr
}

struct Slot {
    var active: Int32 = 0
    var carrier: Float = 1000
    var band: Float = 0
    var rate: Float = 4
    var pulse: Float = 0.1
    var burst: Int32 = 0
    var burstGap: Float = 0
    var phraseGap: Float = 0
    var sweep: Float = 0
    var harm: Int32 = 1
    var attack: Float = 0.2
    var level: Float = 0.8
    var pan: Float = 0
    var distance: Float = 0.3
    var clock: Float = 0
    var phase: Float = 0
    var svfLow: Float = 0
    var svfBand: Float = 0
    var lp: Float = 0
    var gain: Float = 1
    var target: Float = 1
    var env: Float = 0
    var rnd: UInt32 = 22222
}

struct StagedVoice {
    var id: String
    var pan: Double
    var distance: Double
    var scenePos: Double
    var scenePosY: Double
    var offset: Double
    var gainScale: Double
}

final class ChorusEngine {
    static let shared = ChorusEngine()

    static let capacity = 20
    static let scratch = 8192
    private let engine = AVAudioEngine()
    private let reverb = AVAudioUnitReverb()
    private var source: AVAudioSourceNode?
    private let slots: UnsafeMutablePointer<Slot>
    private let envOut: UnsafeMutablePointer<Float>
    private let mixL: UnsafeMutablePointer<Float>
    private let mixR: UnsafeMutablePointer<Float>
    private var sampleRate: Float = 44100
    private var built = false

    private var loLowA: Float = 0
    private var loLowB: Float = 0
    private var hiA: Float = 0
    private var hiB: Float = 0
    private var loLowA2: Float = 0
    private var loLowB2: Float = 0
    private var hiA2: Float = 0
    private var hiB2: Float = 0

    var bandLow: Float = 60
    var bandHigh: Float = 16000
    private(set) var running = false
    private var wasRunning = false

    var ids: [String] = []

    private init() {
        slots = UnsafeMutablePointer<Slot>.allocate(capacity: ChorusEngine.capacity)
        slots.initialize(repeating: Slot(), count: ChorusEngine.capacity)
        envOut = UnsafeMutablePointer<Float>.allocate(capacity: ChorusEngine.capacity)
        envOut.initialize(repeating: 0, count: ChorusEngine.capacity)
        mixL = UnsafeMutablePointer<Float>.allocate(capacity: ChorusEngine.scratch)
        mixL.initialize(repeating: 0, count: ChorusEngine.scratch)
        mixR = UnsafeMutablePointer<Float>.allocate(capacity: ChorusEngine.scratch)
        mixR.initialize(repeating: 0, count: ChorusEngine.scratch)
        _ = sineTable[0]
        NotificationCenter.default.addObserver(
            self, selector: #selector(goingAway),
            name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(comingBack),
            name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    @objc private func goingAway() {
        wasRunning = running
        stop()
    }

    @objc private func comingBack() {
        if wasRunning { start() }
    }

    private func build() {
        guard !built else { return }
        built = true
        let format = engine.outputNode.inputFormat(forBus: 0)
        let rate = format.sampleRate > 0 ? format.sampleRate : 44100
        sampleRate = Float(rate)
        guard let mono = AVAudioFormat(standardFormatWithSampleRate: rate, channels: 2) else { return }
        let node = AVAudioSourceNode(format: mono) { [slots, envOut, mixL, mixR] _, _, frameCount, audioBuffers in
            let abl = UnsafeMutableAudioBufferListPointer(audioBuffers)
            let n = min(Int(frameCount), ChorusEngine.scratch)
            guard abl.count > 0, let outL = abl[0].mData?.assumingMemoryBound(to: Float.self)
            else { return noErr }
            let outR = abl.count > 1
                ? (abl[1].mData?.assumingMemoryBound(to: Float.self) ?? outL) : outL
            let fs = Float(rate)
            let dt = 1 / fs
            for f in 0..<n { mixL[f] = 0; mixR[f] = 0 }

            for i in 0..<ChorusEngine.capacity {
                if slots[i].active == 0 { continue }
                var v = slots[i]
                let period = 1 / max(0.02, v.rate)
                let dur = min(v.pulse, period * 0.94)
                let at = max(0.02, v.attack)
                let burstLen = Float(v.burst) * period
                let cycle = burstLen + max(0.01, v.burstGap) + v.phraseGap
                let panL = 0.75 - v.pan * 0.5
                let panR = 0.75 + v.pan * 0.5
                let alpha = max(0.04, min(0.96, 0.94 - v.distance * 0.72))
                let far = 1 / (1 + v.distance * 2.4)
                let fcCap = fs * 0.22
                for f in 0..<n {
                    v.clock += dt
                    var env: Float = 0
                    var uu: Float = 0
                    if v.burst > 0 {
                        if v.clock >= cycle { v.clock -= cycle * floorf(v.clock / cycle) }
                        if v.clock < burstLen {
                            let tp = v.clock - period * floorf(v.clock / period)
                            if tp < dur { uu = tp / dur; env = 1 }
                        }
                    } else {
                        if v.clock >= period { v.clock -= period * floorf(v.clock / period) }
                        if v.clock < dur { uu = v.clock / dur; env = 1 }
                    }
                    if env > 0 {
                        if uu < at {
                            env = uu / at
                        } else {
                            let d = 1 - (uu - at) / (1 - at)
                            env = d * d * (0.55 + 0.45 * d)
                        }
                    }
                    let freq = v.carrier + v.sweep * uu
                    v.phase += max(1, freq) * dt
                    if v.phase > 1 { v.phase -= floorf(v.phase) }
                    var tone = fastSin(v.phase)
                    if v.harm > 1 { tone += 0.46 * fastSin(v.phase * 2) }
                    if v.harm > 2 { tone += 0.26 * fastSin(v.phase * 3) }
                    if v.harm > 3 { tone += 0.14 * fastSin(v.phase * 4) }
                    tone *= 0.70
                    var noise: Float = 0
                    if v.band > 0.001 {
                        var r = v.rnd
                        r ^= r << 13; r ^= r >> 17; r ^= r << 5
                        v.rnd = r
                        let white = Float(Int32(bitPattern: r)) * 4.6566e-10
                        let ff = 2 * sinf(Float.pi * min(freq, fcCap) / fs)
                        let q: Float = 0.34
                        v.svfLow += ff * v.svfBand
                        let high = white - v.svfLow - q * v.svfBand
                        v.svfBand += ff * high
                        if v.svfBand > 4 { v.svfBand = 4 } else if v.svfBand < -4 { v.svfBand = -4 }
                        if v.svfLow > 4 { v.svfLow = 4 } else if v.svfLow < -4 { v.svfLow = -4 }
                        noise = v.svfBand * 2.0
                    }
                    var s = (tone * (1 - v.band) + noise * v.band) * env * v.level
                    v.lp += alpha * (s - v.lp)
                    v.gain += 0.0009 * (v.target - v.gain)
                    s = v.lp * far * v.gain
                    v.env += 0.004 * (env * v.gain - v.env)
                    mixL[f] += s * panL
                    mixR[f] += s * panR
                }
                slots[i] = v
                envOut[i] = v.env
            }

            let host = ChorusEngine.shared
            let aHigh = 1 - expf(-2 * Float.pi * min(fs * 0.45, host.bandHigh) / fs)
            let aLow = 1 - expf(-2 * Float.pi * max(20, host.bandLow) / fs)
            var s1 = host.loLowA, s2 = host.loLowB, s3 = host.hiA, s4 = host.hiB
            var s5 = host.loLowA2, s6 = host.loLowB2, s7 = host.hiA2, s8 = host.hiB2
            for f in 0..<n {
                s1 += aHigh * (mixL[f] - s1)
                s2 += aHigh * (s1 - s2)
                s3 += aLow * (s2 - s3)
                s4 += aLow * (s3 - s4)
                let l = (s2 - s4) * 0.66
                s5 += aHigh * (mixR[f] - s5)
                s6 += aHigh * (s5 - s6)
                s7 += aLow * (s6 - s7)
                s8 += aLow * (s7 - s8)
                let r = (s6 - s8) * 0.66
                outL[f] = l / (1 + abs(l))
                outR[f] = r / (1 + abs(r))
            }
            host.loLowA = s1; host.loLowB = s2; host.hiA = s3; host.hiB = s4
            host.loLowA2 = s5; host.loLowB2 = s6; host.hiA2 = s7; host.hiB2 = s8
            return noErr
        }
        source = node
        engine.attach(node)
        engine.attach(reverb)
        reverb.loadFactoryPreset(.mediumHall)
        reverb.wetDryMix = 16
        engine.connect(node, to: reverb, format: mono)
        engine.connect(reverb, to: engine.mainMixerNode, format: mono)
        engine.mainMixerNode.outputVolume = 0.92
    }

    func start() {
        build()
        guard !engine.isRunning else { running = true; return }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true, options: [])
        engine.prepare()
        do {
            try engine.start()
            running = true
        } catch {
            running = false
        }
    }

    func stop() {
        guard built else { running = false; return }
        engine.pause()
        running = false
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    func silence() {
        for i in 0..<ChorusEngine.capacity {
            slots[i].active = 0
            slots[i].env = 0
            envOut[i] = 0
        }
        ids = []
    }

    func stage(_ voices: [StagedVoice], temperature: Double) {
        var newIds: [String] = []
        for i in 0..<ChorusEngine.capacity {
            if i < voices.count {
                let sv = voices[i]
                let v = Registry.find(sv.id)
                var slot = slots[i]
                let reuse = i < ids.count && ids[i] == sv.id
                slot.active = 1
                slot.carrier = Float(v.carrier)
                slot.band = Float(v.band)
                slot.rate = Float(v.rate(temperature))
                slot.pulse = Float(v.pulse)
                slot.burst = Int32(v.burst)
                let squeeze = max(0.35, 1 + v.tempSlope * (temperature - 20))
                slot.burstGap = Float(v.burstGap / squeeze)
                slot.phraseGap = Float(v.phraseGap / squeeze)
                slot.sweep = Float(v.sweep)
                slot.harm = Int32(v.harm)
                slot.attack = Float(v.attack)
                slot.level = Float(v.level * sv.gainScale)
                slot.pan = Float(sv.pan)
                slot.distance = Float(sv.distance)
                if !reuse {
                    slot.clock = Float(sv.offset)
                    slot.phase = Float(sv.offset.truncatingRemainder(dividingBy: 1))
                    slot.rnd = UInt32(truncatingIfNeeded: abs(sv.id.hashValue) | 1)
                    slot.gain = 0
                    slot.svfLow = 0
                    slot.svfBand = 0
                    slot.lp = 0
                    slot.env = 0
                }
                slot.target = 1
                slots[i] = slot
                newIds.append(sv.id)
            } else {
                slots[i].active = 0
                slots[i].env = 0
                envOut[i] = 0
            }
        }
        ids = newIds
    }

    func setGain(_ index: Int, _ value: Double) {
        guard index >= 0 && index < ChorusEngine.capacity else { return }
        slots[index].target = Float(max(0, min(1.6, value)))
    }

    func setWindow(low: Double, high: Double) {
        bandLow = Float(max(40, min(low, high - 80)))
        bandHigh = Float(min(18000, max(high, low + 80)))
    }

    func envelope(_ index: Int) -> Double {
        guard index >= 0 && index < ChorusEngine.capacity else { return 0 }
        return Double(envOut[index])
    }

    func levels() -> [Double] {
        (0..<ids.count).map { Double(envOut[$0]) }
    }
}
