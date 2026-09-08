import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var field: Field
    @State private var query = ""
    @State private var groupFilter = 0
    @State private var seasonOnly = false

    private var filtered: [Voice] {
        var list = Registry.all
        if groupFilter > 0 { list = list.filter { $0.group == groupFilter - 1 } }
        if seasonOnly { list = list.filter { Cal.has($0.months, month: Clock.month) } }
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty {
            list = list.filter {
                $0.name.lowercased().contains(q) || $0.latin.lowercased().contains(q)
                || $0.groupName.lowercased().contains(q) || $0.tell.lowercased().contains(q)
            }
        }
        return list
    }

    private var grouped: [(Int, [Voice])] {
        var buckets: [Int: [Voice]] = [:]
        for v in filtered { buckets[v.group, default: []].append(v) }
        return buckets.keys.sorted().map { ($0, buckets[$0] ?? []) }
    }

    var body: some View {
        ScrollView {
            Column {
                searchCard
                ForEach(grouped, id: \.0) { group, voices in
                    groupCard(group, voices)
                }
                if filtered.isEmpty {
                    PaperCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nothing matches that.")
                                .font(Nite.title(15))
                                .foregroundColor(Nite.ink)
                            Text("Try a group name, a Latin name, or a word from the description such as trill, snore, whinny or buzz.")
                                .font(Nite.text(13))
                                .foregroundColor(Nite.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                            PressBtn(title: "Clear the filters", tone: Nite.indigo, filled: false) {
                                query = ""; groupFilter = 0; seasonOnly = false
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Nite.gutter)
            .padding(.bottom, 26)
        }
        .background(Nite.paper.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    private var searchCard: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 10) {
                RuleLine(text: "The register", trailing: "\(filtered.count) of \(Registry.all.count)")
                HStack(spacing: 8) {
                    LensMark(size: 15, color: Nite.inkFaint)
                    TextField("Search by name, group or sound", text: $query)
                        .font(Nite.text(14))
                        .foregroundColor(Nite.ink)
                        .disableAutocorrection(true)
                    if !query.isEmpty {
                        Button(action: { Knock.light(); query = "" }) {
                            CrossMark(size: 13, color: Nite.inkFaint)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(9)
                .background(RoundedRectangle(cornerRadius: 5).fill(Nite.ink.opacity(0.05)))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        chip("All", 0)
                        ForEach(0..<Registry.groupNames.count, id: \.self) { i in
                            chip(Registry.groupNames[i], i + 1)
                        }
                    }
                    .padding(.vertical, 2)
                }
                Toggle(isOn: $seasonOnly) {
                    Text("Only what calls in \(Cal.names[Clock.month])")
                        .font(Nite.text(13))
                        .foregroundColor(Nite.inkSoft)
                }
                .tint(Nite.indigo)
            }
        }
        .rising(0)
    }

    private func chip(_ title: String, _ value: Int) -> some View {
        Button(action: { Knock.light(); groupFilter = value }) {
            Text(title)
                .font(Nite.title(11.5))
                .foregroundColor(groupFilter == value ? Nite.card : Nite.inkSoft)
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background(RoundedRectangle(cornerRadius: 5)
                    .fill(groupFilter == value ? Nite.ink : Nite.ink.opacity(0.06)))
        }
        .buttonStyle(.plain)
    }

    private func groupCard(_ group: Int, _ voices: [Voice]) -> some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 9) {
                RuleLine(text: Registry.groupNames[group], trailing: "\(voices.count)")
                Text(Registry.groupBlurbs[group])
                    .font(Nite.aside(12))
                    .foregroundColor(Nite.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(voices) { v in
                    NavigationLink(destination: VoicePage(voice: v).environmentObject(field)) {
                        HStack(spacing: 9) {
                            Circle().fill(Nite.groupHue(v.group)).frame(width: 8, height: 8)
                            VStack(alignment: .leading, spacing: 1) {
                                HStack(spacing: 6) {
                                    Text(v.name)
                                        .font(Nite.title(13.5))
                                        .foregroundColor(Nite.ink)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                    if field.hasNamed(v.id) {
                                        TickMark(size: 11, color: Nite.good)
                                    }
                                }
                                Text(v.latin)
                                    .font(Nite.aside(11))
                                    .foregroundColor(Nite.inkFaint)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 4)
                            Text(v.carrierText)
                                .font(Nite.text(11))
                                .foregroundColor(Nite.inkFaint)
                            NextChev(size: 12, color: Nite.inkFaint)
                        }
                        .padding(.vertical, 3)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .rising(1)
    }
}

struct VoicePage: View {
    @EnvironmentObject var field: Field
    let voice: Voice
    @Environment(\.presentationMode) private var presentation
    @State private var playing = false
    @State private var progress: Double = 1
    @State private var compare: Voice? = nil
    private let ticker = Timer.publish(every: 1.0 / 20.0, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            Column {
                PaperCard(padding: 0) {
                    VStack(spacing: 0) {
                        PlateBox(name: voice.plate, height: Nite.wide ? 320 : 236, corner: 0)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(voice.name)
                                    .font(Nite.title(20))
                                    .foregroundColor(Nite.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 6)
                                if field.hasNamed(voice.id) {
                                    Stamp(text: "Named", tone: Nite.good)
                                }
                            }
                            Text(voice.latin)
                                .font(Nite.aside(13))
                                .foregroundColor(Nite.inkFaint)
                            Text(voice.groupName)
                                .font(Nite.text(12))
                                .foregroundColor(Nite.groupHue(voice.group))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(13)
                    }
                }
                tracePanel
                structurePanel
                whenPanel
                notesPanel
                confusablePanel
                PressBtn(title: "Back", tone: Nite.inkSoft, filled: false) {
                    presentation.wrappedValue.dismiss()
                }
            }
            .padding(.horizontal, Nite.gutter)
            .padding(.bottom, 26)
        }
        .background(Nite.paper.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { field.markRead(0, voice.id) }
        .onDisappear { stop() }
        .onReceive(ticker) { _ in
            if playing {
                progress += (1.0 / 20.0) / max(0.6, Trace.cycle(voice, field.temperature) * 1.25)
                if progress > 1 { progress = 0 }
            }
        }
        .sheet(item: $compare) { other in
            ComparePair(a: voice, b: other, onClose: { compare = nil }).environmentObject(field)
        }
    }

    private var tracePanel: some View {
        PaperCard(padding: 0) {
            VStack(spacing: 0) {
                VoiceTrace(voice: voice, temperature: field.temperature,
                           progress: progress, tone: Nite.groupHue(voice.group))
                    .frame(height: Nite.wide ? 200 : 150)
                    .clipped()
                HStack(spacing: 10) {
                    Button(action: { toggle() }) {
                        HStack(spacing: 7) {
                            PlayMark(size: 14, color: Nite.card, playing: playing)
                            Text(playing ? "Stop" : "Play")
                                .font(Nite.title(13))
                                .foregroundColor(Nite.card)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 5).fill(Nite.indigo))
                    }
                    .buttonStyle(.plain)
                    Text(Trace.description(voice, field.temperature))
                        .font(Nite.text(11.5))
                        .foregroundColor(Nite.inkFaint)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(12)
            }
        }
    }

    private var structurePanel: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 9) {
                RuleLine(text: "Structure")
                KeyValue(key: "Carrier", value: voice.carrierText)
                KeyValue(key: "Pulse rate at \(Int(field.temperature)) C",
                         value: String(format: "%.1f a second", voice.rate(field.temperature)))
                KeyValue(key: "Pattern", value: voice.shapeName)
                KeyValue(key: "Quality", value: voice.timbreName)
                KeyValue(key: "Bandwidth",
                         value: voice.band < 0.15 ? "narrow, almost a pure tone"
                         : (voice.band < 0.5 ? "moderate" : "broad, a rasp or a hiss"))
                if voice.ectotherm {
                    KeyValue(key: "Temperature response",
                             value: String(format: "%.1f%% faster per degree C", voice.tempSlope * 100))
                    MeterBar(label: "At 10 C against 30 C",
                             value: voice.rate(10) / max(0.01, voice.rate(30)),
                             tone: Nite.ember,
                             caption: String(format: "%.1f a second at ten degrees, %.1f at thirty.",
                                             voice.rate(10), voice.rate(30)))
                } else {
                    KeyValue(key: "Temperature response", value: "none, it is warm-blooded")
                }
                Text(Timbre.blurbs[voice.timbre])
                    .font(Nite.aside(12))
                    .foregroundColor(Nite.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
                Text(Shape.blurbs[voice.shape])
                    .font(Nite.aside(12))
                    .foregroundColor(Nite.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var whenPanel: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 9) {
                RuleLine(text: "When and where")
                KeyValue(key: "Months", value: Cal.monthSpan(voice.months))
                KeyValue(key: "Hours", value: Cal.hourSpan(voice.hours))
                KeyValue(key: "Calls from", value: voice.perchName)
                KeyValue(key: "Ground", value: voice.wet ? "wet ground or water" : "dry ground")
                MonthStrip(months: voice.months)
                HourStrip(hours: voice.hours)
                Text(voice.habitatList.joined(separator: ", "))
                    .font(Nite.text(12.5))
                    .foregroundColor(Nite.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var notesPanel: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 9) {
                RuleLine(text: "The giveaway")
                Text(voice.tell)
                    .font(Nite.text(14))
                    .foregroundColor(Nite.ink)
                    .fixedSize(horizontal: false, vertical: true)
                RuleLine(text: "What it is doing")
                Text(voice.note)
                    .font(Nite.text(13))
                    .foregroundColor(Nite.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var confusablePanel: some View {
        let others = Registry.all
            .filter { $0.id != voice.id }
            .map { ($0, similarity($0)) }
            .sorted { $0.1 > $1.1 }
            .prefix(3)
            .map { $0.0 }
        return PaperCard {
            VStack(alignment: .leading, spacing: 9) {
                RuleLine(text: "Easy to confuse with")
                ForEach(others) { other in
                    Button(action: { Knock.light(); compare = other }) {
                        HStack(spacing: 8) {
                            Circle().fill(Nite.groupHue(other.group)).frame(width: 7, height: 7)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(other.name)
                                    .font(Nite.text(13))
                                    .foregroundColor(Nite.ink)
                                    .lineLimit(1)
                                Text(other.tell)
                                    .font(Nite.aside(11))
                                    .foregroundColor(Nite.inkFaint)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 4)
                            Text("Compare")
                                .font(Nite.title(11))
                                .foregroundColor(Nite.indigo)
                        }
                        .padding(.vertical, 3)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func similarity(_ other: Voice) -> Double {
        var score = 0.0
        if other.freqBandIndex == voice.freqBandIndex { score += 3 }
        if other.shape == voice.shape { score += 2.5 }
        if other.timbre == voice.timbre { score += 2 }
        if other.group == voice.group { score += 1.5 }
        if other.habitats & voice.habitats != 0 { score += 1 }
        if other.months & voice.months != 0 { score += 1 }
        let ratio = min(other.rate20, voice.rate20) / max(0.01, max(other.rate20, voice.rate20))
        score += ratio * 2
        return score
    }

    private func toggle() {
        Knock.light()
        if playing {
            stop()
        } else {
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
    }

    private func stop() {
        playing = false
        progress = 1
        ChorusEngine.shared.silence()
        ChorusEngine.shared.stop()
    }
}

struct MonthStrip: View {
    var months: Int
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<12, id: \.self) { m in
                VStack(spacing: 2) {
                    Rectangle()
                        .fill(Cal.has(months, month: m) ? Nite.moss : Nite.ink.opacity(0.08))
                        .frame(height: 14)
                    Text(Cal.short[m])
                        .font(Nite.text(8))
                        .foregroundColor(m == Clock.month ? Nite.ink : Nite.inkFaint)
                }
            }
        }
    }
}

struct HourStrip: View {
    var hours: Int
    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<24, id: \.self) { h in
                VStack(spacing: 2) {
                    Rectangle()
                        .fill(Cal.hasHour(hours, h) ? Nite.indigo : Nite.ink.opacity(0.08))
                        .frame(height: 12)
                    if h % 6 == 0 {
                        Text("\(h)")
                            .font(Nite.text(7.5))
                            .foregroundColor(Nite.inkFaint)
                    } else {
                        Text(" ").font(Nite.text(7.5))
                    }
                }
            }
        }
    }
}
