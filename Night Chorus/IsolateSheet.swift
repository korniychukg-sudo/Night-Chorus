import SwiftUI

struct IsolateSheet: View {
    @EnvironmentObject var field: Field
    let voice: Voice
    let pool: [Voice]
    let isolation: Double
    let habitat: Int
    let targets: [String]
    var onClose: () -> Void

    @State private var used: [Int: Int] = [:]
    @State private var progress: Double = 0
    @State private var solved = false
    @State private var attempts = 0
    @State private var wrongNote: String? = nil
    @State private var cutting: Double = 0
    @State private var spin: Double = 0
    @State private var holdingCut = false
    @State private var cutDone = false
    @State private var savedQuality: Double = 0
    @State private var seed = Int.random(in: 1...9999)
    private let ticker = Timer.publish(every: 1.0 / 20.0, on: .main, in: .common).autoconnect()

    private var remaining: [Voice] {
        FieldKey.narrow(pool, used: used, temperature: field.temperature)
    }

    private var holdTime: Double {
        max(1.4, min(4.0, Trace.cycle(voice, field.temperature)))
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetBar(title: solved ? voice.name : "One voice, alone",
                     subtitle: solved ? voice.latin : "Locked out of the chorus. Now work out what it is.",
                     onClose: onClose)
            ScrollView {
                Column {
                    tracePanel
                    if solved {
                        answerPanel
                        cylinderPanel
                    } else {
                        keyPanel
                        namePanel
                    }
                    PressBtn(title: solved ? "Back to the field" : "Give up and go back",
                             tone: Nite.inkSoft, filled: false) { onClose() }
                }
                .padding(.horizontal, Nite.gutter)
                .padding(.bottom, 26)
            }
        }
        .background(Nite.paper.ignoresSafeArea())
        .onReceive(ticker) { _ in tick() }
    }

    private func tick() {
        progress += (1.0 / 20.0) / 1.8
        if progress > 1.35 { progress = 0 }
        if holdingCut && !cutDone {
            cutting = min(1, cutting + (1.0 / 20.0) / holdTime)
            spin += 0.02
            if cutting >= 1 { finishCut() }
        }
    }

    private var tracePanel: some View {
        PaperCard(padding: 0) {
            VStack(spacing: 0) {
                VoiceTrace(voice: voice, temperature: field.temperature,
                           progress: min(1, progress), tone: Nite.groupHue(voice.group))
                    .frame(height: Nite.wide ? 200 : 148)
                    .clipped()
                VStack(alignment: .leading, spacing: 4) {
                    Text(solved ? Trace.description(voice, field.temperature)
                         : "The stylus is drawing what the microphone would have seen. Read the picture: how often the marks repeat, how high they sit, and how wide they smear.")
                        .font(Nite.text(12))
                        .foregroundColor(Nite.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 8) {
                        StatChip(value: String(format: "%.0f%%", isolation * 100), label: "isolation")
                        StatChip(value: "\(used.count)", label: "key steps")
                        StatChip(value: "\(remaining.count)", label: "candidates")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
            }
        }
    }

    private var keyPanel: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 10) {
                RuleLine(text: "The key", trailing: "\(6 - used.count) unused")
                Text("Each step measures one thing off the signal and throws out everything that does not match. Using fewer of them cuts a better cylinder.")
                    .font(Nite.aside(12))
                    .foregroundColor(Nite.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(FieldKey.steps) { step in
                    keyRow(step)
                }
            }
        }
    }

    private func keyRow(_ step: KeyStep) -> some View {
        let value = used[step.id]
        return Button(action: {
            guard value == nil else { return }
            Knock.light()
            withAnimation(.easeOut(duration: 0.2)) {
                used[step.id] = step.read(voice, field.temperature)
            }
        }) {
            HStack(alignment: .top, spacing: 9) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(value == nil ? Nite.ink.opacity(0.06) : Nite.indigo.opacity(0.14))
                        .frame(width: 26, height: 26)
                    if value != nil { TickMark(size: 13, color: Nite.indigo) }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(step.title)
                        .font(Nite.title(13))
                        .foregroundColor(Nite.ink)
                    Text(value == nil ? step.question : "It is " + step.phrasing(value!) + ".")
                        .font(value == nil ? Nite.text(11.5) : Nite.aside(12))
                        .foregroundColor(value == nil ? Nite.inkFaint : Nite.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                if value == nil {
                    Text("Use")
                        .font(Nite.title(11))
                        .foregroundColor(Nite.indigo)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var namePanel: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 9) {
                RuleLine(text: "Name it", trailing: "\(remaining.count) left")
                if let note = wrongNote {
                    NoteBanner(text: note, tone: Nite.alarm)
                }
                if remaining.isEmpty {
                    Text("Nothing matches, which cannot happen with a real signal. Close and lock it again.")
                        .font(Nite.text(12.5))
                        .foregroundColor(Nite.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                ForEach(remaining) { candidate in
                    Button(action: { guess(candidate) }) {
                        HStack(spacing: 8) {
                            Circle().fill(Nite.groupHue(candidate.group))
                                .frame(width: 7, height: 7)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(candidate.name)
                                    .font(Nite.text(13.5))
                                    .foregroundColor(Nite.ink)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                Text(candidate.latin)
                                    .font(Nite.aside(11))
                                    .foregroundColor(Nite.inkFaint)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 0)
                            NextChev(size: 12, color: Nite.inkFaint)
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func guess(_ candidate: Voice) {
        if candidate.id == voice.id {
            Knock.hard()
            withAnimation(.easeOut(duration: 0.3)) { solved = true }
            field.named(voice.id)
            field.markTonight(voice.id, habitat: habitat,
                              temperature: field.temperature, targets: targets)
            field.markRead(0, voice.id)
        } else {
            Knock.crisp()
            attempts += 1
            withAnimation(.easeOut(duration: 0.2)) {
                wrongNote = difference(candidate)
            }
        }
    }

    private func difference(_ candidate: Voice) -> String {
        for step in FieldKey.steps {
            let a = step.read(candidate, field.temperature)
            let b = step.read(voice, field.temperature)
            if a != b {
                return "Not the \(candidate.name). That one is \(step.phrasing(a)) and this is \(step.phrasing(b))."
            }
        }
        return "Not the \(candidate.name), though the two are very close on every measure in the key."
    }

    private var answerPanel: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    RuleLine(text: "Named")
                    Stamp(text: attempts == 0 ? "First try" : "\(attempts + 1) tries",
                          tone: attempts == 0 ? Nite.good : Nite.brass)
                }
                Text("The giveaway: " + voice.tell)
                    .font(Nite.text(13.5))
                    .foregroundColor(Nite.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(voice.note)
                    .font(Nite.text(13))
                    .foregroundColor(Nite.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                KeyValue(key: "Structure", value: Trace.description(voice, field.temperature))
                KeyValue(key: "Calling", value: voice.perchName)
                KeyValue(key: "Season", value: Cal.monthSpan(voice.months))
                if voice.ectotherm {
                    KeyValue(key: "Temperature",
                             value: String(format: "%.1f per cent faster per degree",
                                           voice.tempSlope * 100))
                } else {
                    KeyValue(key: "Temperature", value: "warm-blooded, rate does not move")
                }
                NavigationLink(destination: VoicePage(voice: voice).environmentObject(field)) {
                    Text("Open the register entry")
                        .font(Nite.title(12.5))
                        .foregroundColor(Nite.indigo)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var cylinderPanel: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 11) {
                RuleLine(text: "Cut a cylinder",
                         trailing: cutDone ? String(format: "%.0f%%", savedQuality * 100) : nil)
                HStack(alignment: .center, spacing: 14) {
                    WaxCylinder(voiceId: voice.id, quality: savedQuality, seed: seed,
                                spin: spin, temperature: field.temperature,
                                cutting: cutDone ? 1 : cutting)
                        .frame(width: 96, height: 128)
                    VStack(alignment: .leading, spacing: 8) {
                        if cutDone {
                            Text("Cut and shelved. The groove is this animal's own waveform, so no two cylinders in the cabinet look alike.")
                                .font(Nite.text(12.5))
                                .foregroundColor(Nite.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                            Stamp(text: gradeText, tone: gradeTone)
                        } else {
                            Text("Press and hold. The cylinder turns at its own speed and the stylus cuts as it goes. Let go early and you keep a short thin groove.")
                                .font(Nite.text(12.5))
                                .foregroundColor(Nite.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                            MeterBar(label: "Groove cut", value: cutting, tone: Nite.brass)
                        }
                    }
                }
                if !cutDone {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(holdingCut ? Nite.brass : Nite.brass.opacity(0.86))
                        Text(holdingCut ? "Cutting" : "Press and hold to cut")
                            .font(Nite.title(15))
                            .foregroundColor(Nite.card)
                    }
                    .frame(height: 46)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in if !holdingCut { holdingCut = true; Knock.light() } }
                            .onEnded { _ in if !cutDone { holdingCut = false; finishCut() } }
                    )
                }
                if cutDone {
                    Text("Only the best cylinder for each species stays in the cabinet, so a cleaner night replaces this one.")
                        .font(Nite.aside(11.5))
                        .foregroundColor(Nite.inkFaint)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var gradeText: String {
        switch savedQuality {
        case 0.88...: return "Archive"
        case 0.72..<0.88: return "Clean"
        case 0.52..<0.72: return "Usable"
        default: return "Rough"
        }
    }

    private var gradeTone: Color {
        switch savedQuality {
        case 0.88...: return Nite.good
        case 0.72..<0.88: return Nite.moss
        case 0.52..<0.72: return Nite.brass
        default: return Nite.inkFaint
        }
    }

    private func finishCut() {
        guard !cutDone, cutting > 0.02 else { holdingCut = false; return }
        holdingCut = false
        cutDone = true
        Knock.hard()
        let q = FieldKey.quality(isolation: isolation, stepsUsed: used.count,
                                hold: cutting, firstTry: attempts == 0)
        savedQuality = q
        field.cut(Cylinder(voiceId: voice.id, quality: q, day: field.today, seed: seed,
                           keySteps: used.count, isolation: isolation, length: cutting))
    }
}
