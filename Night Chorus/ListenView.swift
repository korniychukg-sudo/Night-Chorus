import SwiftUI

struct ListenView: View {
    @EnvironmentObject var field: Field
    @Environment(\.presentationMode) private var presentation
    var startHabitat: Int? = nil

    @State private var habitat = 0
    @State private var hour = Clock.hour
    @State private var aim: Double = 0
    @State private var narrow: Double = 0.45
    @State private var windowLow: Double = 120
    @State private var windowHigh: Double = 15000
    @State private var placed: [Placed] = []
    @State private var gains: [Double] = []
    @State private var envelopes: [Double] = []
    @State private var clock: Double = 0
    @State private var holding: Double = 0
    @State private var lockedIndex: Int? = nil
    @State private var revealed: Set<Int> = []
    @State private var showLock = false
    @State private var showTools = false
    @State private var isolation: Double = 0
    @State private var soundOn = true
    private let ticker = Timer.publish(every: 1.0 / 16.0, on: .main, in: .common).autoconnect()

    private var card: Card { Plan.card(field.today) }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                header
                scenePane(height: max(180, geo.size.height * 0.34))
                spectrogramPane
                controlPane
                Spacer(minLength: 0)
            }
            .background(Nite.paper.ignoresSafeArea())
        }
        .navigationBarHidden(true)
        .onAppear { begin() }
        .onDisappear { ChorusEngine.shared.silence(); ChorusEngine.shared.stop() }
        .onReceive(ticker) { _ in step() }
        .sheet(isPresented: $showLock, onDismiss: { unlock() }) {
            if let i = lockedIndex, i < placed.count {
                IsolateSheet(voice: Registry.find(placed[i].voiceId),
                             pool: candidatePool,
                             isolation: isolation,
                             habitat: habitat,
                             targets: card.targets,
                             onClose: { showLock = false })
                    .environmentObject(field)
            } else {
                VStack {
                    SheetBar(title: "Nothing locked", onClose: { showLock = false })
                    Spacer()
                    PressBtn(title: "Close", tone: Nite.inkSoft, filled: false) { showLock = false }
                        .padding(Nite.gutter)
                }
                .background(Nite.paper.ignoresSafeArea())
            }
        }
        .sheet(isPresented: $showTools) {
            FieldTools(habitat: $habitat, hour: $hour, soundOn: $soundOn,
                       temperature: Binding(get: { field.temperature },
                                            set: { field.temperature = $0 }),
                       onClose: { showTools = false; restage() })
        }
    }

    private var candidatePool: [Voice] {
        placed.map { Registry.find($0.voiceId) }
    }

    private var header: some View {
        HStack(spacing: 10) {
            if presentation.wrappedValue.isPresented {
                Button(action: { Knock.light(); presentation.wrappedValue.dismiss() }) {
                    CrossMark(size: 15, color: Nite.inkSoft)
                        .padding(8)
                        .background(Circle().fill(Nite.ink.opacity(0.07)))
                }
                .buttonStyle(.plain)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(Ground.names[habitat])
                    .font(Nite.title(16))
                    .foregroundColor(Nite.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(String(format: "%02d:00, %.0f degrees, %d calling", hour,
                            field.temperature, placed.count))
                    .font(Nite.text(11.5))
                    .foregroundColor(Nite.inkFaint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 4)
            Button(action: { Knock.light(); showTools = true }) {
                Text("Set up")
                    .font(Nite.title(12))
                    .foregroundColor(Nite.indigo)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .overlay(RoundedRectangle(cornerRadius: 5)
                        .stroke(Nite.indigo.opacity(0.5), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Nite.gutter)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    private func scenePane(height: CGFloat) -> some View {
        ZStack(alignment: .top) {
            FieldScene(habitat: habitat, hour: Double(hour), placed: placed,
                       gains: gains, envelopes: envelopes, aim: aim,
                       dishWidth: 1 - narrow, locked: lockedIndex, drift: clock,
                       revealed: revealed)
            .frame(height: height)
            .clipped()
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        let w = max(1, UIScreen.main.bounds.width)
                        aim = max(-1, min(1, Double(g.location.x / w) * 2 - 1))
                        let v = Double(g.translation.height / max(1, height))
                        narrow = max(0.05, min(0.95, narrow - v * 0.06))
                    }
            )
            HStack {
                Text("Drag to aim. Pull up to narrow the dish.")
                    .font(Nite.aside(10.5))
                    .foregroundColor(Color.white.opacity(0.72))
                Spacer()
                Text(String(format: "beam %.0f", (1 - narrow) * 100) + " wide")
                    .font(Nite.text(10.5))
                    .foregroundColor(Color.white.opacity(0.72))
            }
            .padding(.horizontal, 12)
            .padding(.top, 7)
        }
        .frame(height: height)
    }

    private var spectrogramPane: some View {
        GeometryReader { geo in
            let h = geo.size.height
            ZStack(alignment: .topLeading) {
                Spectrogram(placed: placed, gains: gains, temperature: field.temperature,
                            windowLow: windowLow, windowHigh: windowHigh, clock: clock,
                            span: 4.0, soloIndex: lockedIndex)
                bandHandles(h: h)
                Text("Frequency window")
                    .font(Nite.aside(10))
                    .foregroundColor(Color.white.opacity(0.55))
                    .padding(.leading, 10)
                    .padding(.top, 4)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        let f = freqAt(Double(g.location.y), Double(h))
                        let span = windowHigh / max(1, windowLow)
                        let lowTarget = f / sqrt(span)
                        setWindow(low: lowTarget, high: lowTarget * span)
                    }
            )
        }
        .frame(height: Nite.wide ? 190 : 150)
        .cornerRadius(6)
        .padding(.horizontal, Nite.gutter)
        .padding(.bottom, 8)
    }

    private func bandHandles(h: Double) -> some View {
        let yHigh = yFor(windowHigh, h)
        let yLow = yFor(windowLow, h)
        return ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(Nite.moon.opacity(0.85))
                .frame(height: 2)
                .offset(y: CGFloat(yHigh))
            Rectangle()
                .fill(Nite.moon.opacity(0.85))
                .frame(height: 2)
                .offset(y: CGFloat(yLow))
            HStack {
                Spacer()
                Text(label(windowHigh))
                    .font(Nite.text(9.5))
                    .foregroundColor(Nite.moon)
                    .padding(.trailing, 8)
            }
            .offset(y: CGFloat(yHigh) - 12)
            HStack {
                Spacer()
                Text(label(windowLow))
                    .font(Nite.text(9.5))
                    .foregroundColor(Nite.moon)
                    .padding(.trailing, 8)
            }
            .offset(y: CGFloat(yLow) + 3)
        }
        .allowsHitTesting(false)
    }

    private func label(_ f: Double) -> String {
        f >= 1000 ? String(format: "%.1f kHz", f / 1000) : String(format: "%.0f Hz", f)
    }

    private func yFor(_ f: Double, _ h: Double) -> Double {
        let lo = log(90.0), hi = log(17000.0)
        return h * (1 - (log(max(90, min(17000, f))) - lo) / (hi - lo))
    }

    private func freqAt(_ y: Double, _ h: Double) -> Double {
        let lo = log(90.0), hi = log(17000.0)
        let v = 1 - max(0, min(1, y / max(1, h)))
        return exp(lo + v * (hi - lo))
    }

    private func setWindow(low: Double, high: Double) {
        var l = max(90, min(15000, low))
        var hgh = max(l * 1.10, min(17000, high))
        if hgh > 17000 { hgh = 17000; l = min(l, hgh / 1.10) }
        windowLow = l
        windowHigh = hgh
        ChorusEngine.shared.setWindow(low: l, high: hgh)
    }

    private var controlPane: some View {
        VStack(spacing: 9) {
            HStack(spacing: 10) {
                Text("Window width")
                    .font(Nite.text(12))
                    .foregroundColor(Nite.inkSoft)
                DragSlider(value: log(windowHigh / windowLow), range: 0.1...5.2, tone: Nite.cool) { v in
                    let centre = sqrt(windowLow * windowHigh)
                    let span = exp(v)
                    setWindow(low: centre / sqrt(span), high: centre * sqrt(span))
                }
            }
            HStack(spacing: 10) {
                loudestPanel
                holdButton
            }
        }
        .padding(.horizontal, Nite.gutter)
        .padding(.bottom, 12)
    }

    private var loudest: Int? {
        var best: Int? = nil
        var bestScore = 0.02
        for i in 0..<placed.count {
            let g = i < gains.count ? gains[i] : 0
            let v = Registry.find(placed[i].voiceId)
            let s = g * v.level
            if s > bestScore { bestScore = s; best = i }
        }
        return best
    }

    private var loudestPanel: some View {
        let i = loudest
        let v = i != nil ? Registry.find(placed[i!].voiceId) : nil
        return VStack(alignment: .leading, spacing: 3) {
            Text(v == nil ? "Nothing in the beam" : "One voice is out in front")
                .font(Nite.title(13))
                .foregroundColor(Nite.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(v == nil
                 ? "Swing the dish across the scene until something comes forward."
                 : String(format: "Isolation %.0f per cent. Hold to lock it.", isolation * 100))
                .font(Nite.text(11.5))
                .foregroundColor(Nite.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var holdButton: some View {
        ZStack {
            Circle()
                .fill(loudest == nil ? Nite.ink.opacity(0.08) : Nite.indigo.opacity(0.14))
                .frame(width: 66, height: 66)
            Circle()
                .trim(from: 0, to: CGFloat(min(1, holding)))
                .stroke(Nite.indigo, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(-90))
            VStack(spacing: 1) {
                DishMark(size: 20, color: loudest == nil ? Nite.inkFaint : Nite.indigo)
                Text("Hold")
                    .font(Nite.title(9.5))
                    .foregroundColor(loudest == nil ? Nite.inkFaint : Nite.indigo)
            }
        }
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if holding == 0 { holding = 0.01 } }
                .onEnded { _ in if holding < 1 { holding = 0 } }
        )
    }

    private func begin() {
        habitat = startHabitat ?? field.habitat
        soundOn = field.soundOn
        if !Cal.hasHour(Cal.hours(17, 6), hour) { hour = max(19, min(23, Clock.hour)) }
        restage()
        if soundOn { ChorusEngine.shared.start() }
    }

    private func restage() {
        field.habitat = habitat
        field.soundOn = soundOn
        lockedIndex = nil
        revealed = []
        holding = 0
        placed = Plan.stage(habitat: habitat, month: Clock.month, hour: hour, day: field.today)
        gains = Array(repeating: 0.5, count: placed.count)
        envelopes = Array(repeating: 0, count: placed.count)
        ChorusEngine.shared.stage(Plan.staged(placed), temperature: field.temperature)
        ChorusEngine.shared.setWindow(low: windowLow, high: windowHigh)
        if soundOn { ChorusEngine.shared.start() } else { ChorusEngine.shared.stop() }
    }

    private func step() {
        clock += 1.0 / 16.0
        var newGains: [Double] = []
        let spread = max(0.10, 0.95 - narrow * 0.80)
        var total = 0.0
        var top = 0.0
        for item in placed {
            let v = Registry.find(item.voiceId)
            let delta = abs(item.x - aim)
            let directional = pow(max(0, 1 - delta / spread), 1.5)
            let inBand = v.carrier >= windowLow && v.carrier <= windowHigh
            let octavesOut = inBand ? 0 : abs(log2(v.carrier / (v.carrier < windowLow ? windowLow : windowHigh)))
            let bandFactor = inBand ? 1.0 : max(0.05, pow(0.45, octavesOut))
            let depthFactor = 1.0 - item.depth * 0.35
            let g = (0.07 + 0.93 * directional) * (0.40 + 0.60 * bandFactor) * depthFactor
            newGains.append(g)
            let weight = g * v.level * bandFactor
            total += weight
            top = max(top, weight)
        }
        if lockedIndex == nil {
            gains = newGains
            isolation = total > 0.0001 ? min(1, top / total) : 0
            for (i, g) in newGains.enumerated() { ChorusEngine.shared.setGain(i, g) }
        }
        if soundOn {
            var env: [Double] = []
            for i in 0..<placed.count { env.append(ChorusEngine.shared.envelope(i)) }
            envelopes = env
        } else {
            envelopes = placed.map { Trace.envelope(Registry.find($0.voiceId), field.temperature,
                                                    at: clock + $0.offset) }
        }
        if holding > 0 && holding < 1 {
            holding = min(1, holding + (1.0 / 16.0) / 1.1)
            if holding >= 1 { lockOn() }
        }
    }

    private func lockOn() {
        guard let i = loudest else { holding = 0; return }
        Knock.firm()
        lockedIndex = i
        revealed.insert(i)
        for j in 0..<placed.count { ChorusEngine.shared.setGain(j, j == i ? 1.25 : 0.06) }
        showLock = true
    }

    private func unlock() {
        holding = 0
        lockedIndex = nil
        ChorusEngine.shared.stage(Plan.staged(placed), temperature: field.temperature)
    }
}

struct FieldTools: View {
    @Binding var habitat: Int
    @Binding var hour: Int
    @Binding var soundOn: Bool
    @Binding var temperature: Double
    var onClose: () -> Void

    private let hours = [17, 18, 19, 20, 21, 22, 23, 0, 1, 2, 3, 4, 5]

    var body: some View {
        VStack(spacing: 0) {
            SheetBar(title: "Set up the listening post",
                     subtitle: "Where you are standing and when",
                     onClose: onClose)
            ScrollView {
                Column {
                    PaperCard {
                        VStack(alignment: .leading, spacing: 10) {
                            RuleLine(text: "Habitat")
                            ForEach(0..<8, id: \.self) { i in
                                Button(action: { Knock.light(); habitat = i }) {
                                    HStack(spacing: 9) {
                                        Circle()
                                            .strokeBorder(habitat == i ? Nite.indigo : Nite.ink.opacity(0.3),
                                                          lineWidth: habitat == i ? 5 : 1.4)
                                            .frame(width: 15, height: 15)
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(Ground.names[i])
                                                .font(Nite.title(13.5))
                                                .foregroundColor(Nite.ink)
                                            Text(Ground.blurbs[i])
                                                .font(Nite.text(11.5))
                                                .foregroundColor(Nite.inkFaint)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                        Spacer(minLength: 0)
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    PaperCard {
                        VStack(alignment: .leading, spacing: 10) {
                            RuleLine(text: "Hour", trailing: String(format: "%02d:00", hour))
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(hours, id: \.self) { h in
                                        Button(action: { Knock.light(); hour = h }) {
                                            Text(String(format: "%02d", h))
                                                .font(Nite.title(12))
                                                .foregroundColor(hour == h ? Nite.card : Nite.inkSoft)
                                                .frame(width: 38, height: 32)
                                                .background(RoundedRectangle(cornerRadius: 5)
                                                    .fill(hour == h ? Nite.ink : Nite.ink.opacity(0.06)))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                            Text("The cast changes with the hour. Nothing is hidden from you: this is the same clock the Tonight scene runs on, set by hand so you can listen in daylight.")
                                .font(Nite.aside(11.5))
                                .foregroundColor(Nite.inkFaint)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    PaperCard {
                        VStack(alignment: .leading, spacing: 10) {
                            RuleLine(text: "Temperature",
                                     trailing: String(format: "%.0f C", temperature))
                            DragSlider(value: temperature, range: 0...36, tone: Nite.ember) {
                                temperature = $0
                            }
                            Toggle(isOn: $soundOn) {
                                Text("Sound")
                                    .font(Nite.title(13.5))
                                    .foregroundColor(Nite.ink)
                            }
                            .tint(Nite.indigo)
                            Text("With the sound off everything still works: the spectrogram, the dish and the key all run off the same model that drives the audio.")
                                .font(Nite.aside(11.5))
                                .foregroundColor(Nite.inkFaint)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    PressBtn(title: "Back to the field", tone: Nite.indigo) { onClose() }
                }
                .padding(.horizontal, Nite.gutter)
                .padding(.bottom, 26)
            }
        }
        .background(Nite.paper.ignoresSafeArea())
    }
}
