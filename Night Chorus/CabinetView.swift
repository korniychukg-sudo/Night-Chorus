import SwiftUI

struct CabinetView: View {
    @EnvironmentObject var field: Field
    @State private var spin: Double = 0
    @State private var chosen: Cylinder? = nil
    private let ticker = Timer.publish(every: 1.0 / 20.0, on: .main, in: .common).autoconnect()

    private var columns: Int { Nite.wide ? 6 : (Nite.narrow ? 3 : 4) }
    private var slots: Int {
        let filled = field.ledger.cabinet.count
        let rows = max(4, (filled + columns) / columns + 1)
        return columns * min(20, rows)
    }

    private var ordered: [Cylinder] {
        field.ledger.cabinet.sorted { a, b in
            let ga = Registry.find(a.voiceId).group
            let gb = Registry.find(b.voiceId).group
            if ga != gb { return ga < gb }
            return Registry.find(a.voiceId).name < Registry.find(b.voiceId).name
        }
    }

    private var byslot: [Int: Cylinder] {
        var map: [Int: Cylinder] = [:]
        for (i, c) in ordered.enumerated() { map[i] = c }
        return map
    }

    var body: some View {
        ScrollView {
            Column {
                headerCard
                cabinetCard
                if field.ledger.cabinet.isEmpty { emptyCard } else { bestCard }
            }
            .padding(.horizontal, Nite.gutter)
            .padding(.bottom, 26)
        }
        .background(Nite.paper.ignoresSafeArea())
        .navigationBarHidden(true)
        .onReceive(ticker) { _ in spin += 0.006 }
        .sheet(item: $chosen) { c in
            CylinderSheet(cylinder: c, onClose: { chosen = nil }).environmentObject(field)
        }
    }

    private var headerCard: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 8) {
                RuleLine(text: "The cabinet",
                         trailing: "\(field.ledger.cabinet.count) of \(Registry.all.count)")
                Text("Every voice you name can be cut onto a wax cylinder. The groove is drawn from that animal's own waveform, so the cylinders are all different and each one looks like what it holds.")
                    .font(Nite.text(13))
                    .foregroundColor(Nite.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    StatChip(value: "\(archiveCount)", label: "archive")
                    StatChip(value: "\(field.namedCount)", label: "named ever")
                    StatChip(value: String(format: "%.0f%%", averageQuality * 100), label: "average cut")
                }
            }
        }
        .rising(0)
    }

    private var archiveCount: Int { field.ledger.cabinet.filter { $0.quality >= 0.88 }.count }
    private var averageQuality: Double {
        let all = field.ledger.cabinet.map { $0.quality }
        return all.isEmpty ? 0 : all.reduce(0, +) / Double(all.count)
    }

    private var cabinetCard: some View {
        let rows = max(4, slots / columns)
        return PaperCard(padding: 8) {
            CabinetWall(columns: columns, rows: rows, filled: byslot,
                        temperature: field.temperature, spin: spin) { slot in
                if let c = byslot[slot] { Knock.light(); chosen = c }
            }
            .frame(height: CGFloat(rows) * (Nite.wide ? 118 : 96))
            .cornerRadius(4)
        }
        .rising(1)
    }

    private var emptyCard: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 9) {
                RuleLine(text: "Nothing shelved yet")
                Text("Go out to the field, aim the dish until one voice comes forward, hold to lock it, name it, and then press and hold on the blank to cut the groove.")
                    .font(Nite.text(13))
                    .foregroundColor(Nite.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                Text("The pigeonholes stay in the cabinet whether they are full or not, so the gaps are the list of what is left to find.")
                    .font(Nite.aside(12))
                    .foregroundColor(Nite.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .rising(2)
    }

    private var bestCard: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 9) {
                RuleLine(text: "Cleanest cuts")
                ForEach(field.ledger.cabinet.sorted { $0.quality > $1.quality }.prefix(5)) { c in
                    Button(action: { Knock.light(); chosen = c }) {
                        HStack(spacing: 8) {
                            Circle().fill(Nite.groupHue(Registry.find(c.voiceId).group))
                                .frame(width: 7, height: 7)
                            Text(Registry.find(c.voiceId).name)
                                .font(Nite.text(13))
                                .foregroundColor(Nite.ink)
                                .lineLimit(1)
                            Spacer(minLength: 6)
                            Stamp(text: c.grade, tone: c.gradeTone)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .rising(2)
    }
}

struct CylinderSheet: View {
    @EnvironmentObject var field: Field
    let cylinder: Cylinder
    var onClose: () -> Void

    @State private var spin: Double = 0
    @State private var playing = false
    @State private var progress: Double = 0
    private let ticker = Timer.publish(every: 1.0 / 20.0, on: .main, in: .common).autoconnect()

    private var voice: Voice { Registry.find(cylinder.voiceId) }

    var body: some View {
        VStack(spacing: 0) {
            SheetBar(title: voice.name, subtitle: voice.latin, onClose: { stop(); onClose() })
            ScrollView {
                Column {
                    PaperCard {
                        HStack(alignment: .top, spacing: 14) {
                            WaxCylinder(voiceId: cylinder.voiceId, quality: cylinder.quality,
                                        seed: cylinder.seed, spin: spin,
                                        temperature: field.temperature, cutting: 1)
                                .frame(width: 104, height: 142)
                            VStack(alignment: .leading, spacing: 8) {
                                Stamp(text: cylinder.grade, tone: cylinder.gradeTone)
                                KeyValue(key: "Cut on night", value: "\(cylinder.day + 1)")
                                KeyValue(key: "Isolation",
                                         value: String(format: "%.0f%%", cylinder.isolation * 100))
                                KeyValue(key: "Key steps used", value: "\(cylinder.keySteps)")
                                KeyValue(key: "Groove length",
                                         value: String(format: "%.0f%%", cylinder.length * 100))
                                Button(action: { toggle() }) {
                                    HStack(spacing: 7) {
                                        PlayMark(size: 15, color: Nite.card, playing: playing)
                                        Text(playing ? "Stop" : "Play it back")
                                            .font(Nite.title(13))
                                            .foregroundColor(Nite.card)
                                    }
                                    .padding(.horizontal, 13)
                                    .padding(.vertical, 8)
                                    .background(RoundedRectangle(cornerRadius: 5).fill(Nite.indigo))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    PaperCard(padding: 0) {
                        VoiceTrace(voice: voice, temperature: field.temperature,
                                   progress: playing ? progress : 1,
                                   tone: Nite.groupHue(voice.group))
                            .frame(height: 140)
                            .clipped()
                            .cornerRadius(8)
                    }
                    PaperCard {
                        VStack(alignment: .leading, spacing: 9) {
                            RuleLine(text: "What is on it")
                            Text(Trace.description(voice, field.temperature))
                                .font(Nite.text(13))
                                .foregroundColor(Nite.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(voice.tell)
                                .font(Nite.aside(13))
                                .foregroundColor(Nite.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    NavigationLink(destination: VoicePage(voice: voice).environmentObject(field)) {
                        Text("Open the register entry")
                            .font(Nite.title(13))
                            .foregroundColor(Nite.indigo)
                    }
                    .buttonStyle(.plain)
                    PressBtn(title: "Close", tone: Nite.inkSoft, filled: false) { stop(); onClose() }
                }
                .padding(.horizontal, Nite.gutter)
                .padding(.bottom, 26)
            }
        }
        .background(Nite.paper.ignoresSafeArea())
        .onReceive(ticker) { _ in
            spin += 0.012
            if playing {
                progress += (1.0 / 20.0) / max(0.6, Trace.cycle(voice, field.temperature) * 1.25)
                if progress > 1 { progress = 0 }
            }
        }
        .onDisappear { stop() }
    }

    private func toggle() {
        Knock.light()
        if playing { stop() } else { start() }
    }

    private func start() {
        playing = true
        progress = 0
        ChorusEngine.shared.stage([StagedVoice(id: voice.id, pan: 0, distance: 0.06,
                                               scenePos: 0, scenePosY: 0, offset: 0,
                                               gainScale: 1.0)],
                                  temperature: field.temperature)
        ChorusEngine.shared.setWindow(low: 60, high: 17000)
        ChorusEngine.shared.setGain(0, 1.1)
        if field.soundOn { ChorusEngine.shared.start() }
    }

    private func stop() {
        playing = false
        ChorusEngine.shared.silence()
        ChorusEngine.shared.stop()
    }
}
