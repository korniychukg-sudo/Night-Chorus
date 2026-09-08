import SwiftUI

struct DolbearSheet: View {
    @EnvironmentObject var field: Field
    var onClose: () -> Void

    @State private var taps = 0
    @State private var elapsed: Double = 0
    @State private var running = false
    @State private var finished = false
    @State private var playing = false
    private let ticker = Timer.publish(every: 1.0 / 20.0, on: .main, in: .common).autoconnect()

    private let cricket = Registry.find("snowytree")
    private let windowSeconds = 13.0

    private var readingF: Double { Double(taps) + 40 }
    private var readingC: Double { Weather.celsius(readingF) }
    private var dolbearF: Double {
        let perMinute = Double(taps) * 60 / windowSeconds
        return 50 + (perMinute - 40) / 4
    }
    private var expectedChirps: Int {
        Int((cricket.cycleRate(field.temperature) * windowSeconds).rounded())
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetBar(title: "The cricket thermometer",
                     subtitle: "Snowy tree cricket, Oecanthus fultoni",
                     onClose: { stop(); onClose() })
            ScrollView {
                Column {
                    tracePanel
                    tapPanel
                    if finished { resultPanel }
                    explainPanel
                    PressBtn(title: "Close", tone: Nite.inkSoft, filled: false) { stop(); onClose() }
                }
                .padding(.horizontal, Nite.gutter)
                .padding(.bottom, 26)
            }
        }
        .background(Nite.paper.ignoresSafeArea())
        .onReceive(ticker) { _ in
            if running {
                elapsed += 1.0 / 20.0
                if elapsed >= windowSeconds { finish() }
            }
        }
        .onDisappear { stop() }
    }

    private var tracePanel: some View {
        PaperCard(padding: 0) {
            VStack(spacing: 0) {
                VoiceTrace(voice: cricket, temperature: field.temperature,
                           progress: 1, tone: Nite.groupHue(cricket.group))
                    .frame(height: 122)
                    .clipped()
                HStack(spacing: 10) {
                    Button(action: { toggleSound() }) {
                        HStack(spacing: 6) {
                            PlayMark(size: 13, color: Nite.card, playing: playing)
                            Text(playing ? "Stop the cricket" : "Start the cricket")
                                .font(Nite.title(12.5))
                                .foregroundColor(Nite.card)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 5).fill(Nite.indigo))
                    }
                    .buttonStyle(.plain)
                    Text(String(format: "It is chirping at the app temperature of %.0f degrees.",
                                field.temperature))
                        .font(Nite.text(11.5))
                        .foregroundColor(Nite.inkFaint)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(12)
            }
        }
    }

    private var tapPanel: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 11) {
                RuleLine(text: "Count for thirteen seconds",
                         trailing: String(format: "%.1f s", max(0, windowSeconds - elapsed)))
                MeterBar(label: "Window", value: min(1, elapsed / windowSeconds), tone: Nite.indigo)
                Button(action: { tap() }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(running ? Nite.indigo : Nite.indigo.opacity(0.86))
                        VStack(spacing: 4) {
                            Text("\(taps)")
                                .font(Nite.title(38))
                                .foregroundColor(Nite.card)
                            Text(running ? "Tap on every chirp" : (finished ? "Tap to start again" : "Tap on the first chirp to start"))
                                .font(Nite.text(12.5))
                                .foregroundColor(Nite.card.opacity(0.85))
                        }
                    }
                    .frame(height: 132)
                }
                .buttonStyle(.plain)
                if running || finished {
                    Button(action: { reset() }) {
                        Text("Reset the count")
                            .font(Nite.title(12))
                            .foregroundColor(Nite.inkSoft)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var resultPanel: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 10) {
                RuleLine(text: "Your reading")
                Text(String(format: "%d chirps in thirteen seconds, plus forty, is %.0f degrees Fahrenheit.",
                            taps, readingF))
                    .font(Nite.title(15))
                    .foregroundColor(Nite.ink)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    StatChip(value: String(format: "%.0f F", readingF), label: "field rule")
                    StatChip(value: String(format: "%.0f C", readingC), label: "in celsius")
                    StatChip(value: String(format: "%.0f F", dolbearF), label: "Dolbear 1897")
                }
                Text(String(format: "The cricket was actually running at %.0f degrees celsius, which is %.0f Fahrenheit, and it should have given you about %d chirps.",
                            field.temperature, Weather.fahrenheit(field.temperature), expectedChirps))
                    .font(Nite.text(12.5))
                    .foregroundColor(Nite.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                PressBtn(title: String(format: "Set the app to %.0f degrees", readingC),
                         tone: Nite.ember) {
                    field.temperature = max(0, min(36, readingC))
                }
            }
        }
    }

    private var explainPanel: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 10) {
                RuleLine(text: "Why it works")
                Text("The wing muscle that drives the file is a chemical engine, and its rate rises almost linearly with temperature across the range the animal is willing to sing in. Amos Dolbear noticed the relation and published it in 1897; the thirteen second rule is the field simplification of his equation.")
                    .font(Nite.text(13))
                    .foregroundColor(Nite.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                Text("It is specific to this one cricket. Field crickets are usually quoted with a fifteen second count, and every katydid has a slope of its own. In this app each cold-blooded species carries its own measured percentage change per degree, which is on its register page.")
                    .font(Nite.text(13))
                    .foregroundColor(Nite.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Warm-blooded animals do not do this at all. An owl at four degrees hoots at exactly the rhythm it uses at twenty-four, which is a useful thing to know when you are trying to decide whether what you are hearing is an insect.")
                    .font(Nite.aside(12.5))
                    .foregroundColor(Nite.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func tap() {
        Knock.crisp()
        if finished { reset(); return }
        if !running { running = true; elapsed = 0; taps = 1; return }
        taps += 1
    }

    private func finish() {
        running = false
        finished = true
        Knock.firm()
    }

    private func reset() {
        running = false
        finished = false
        taps = 0
        elapsed = 0
    }

    private func toggleSound() {
        Knock.light()
        if playing {
            playing = false
            ChorusEngine.shared.silence()
            ChorusEngine.shared.stop()
        } else {
            playing = true
            ChorusEngine.shared.stage([StagedVoice(id: cricket.id, pan: 0, distance: 0.08,
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
        ChorusEngine.shared.silence()
        ChorusEngine.shared.stop()
    }
}

struct CalendarSheet: View {
    @EnvironmentObject var field: Field
    var onClose: () -> Void
    @State private var month = Clock.month
    @State private var hour = 21

    private var list: [Voice] {
        Registry.callingAnywhere(month: month, hour: hour).sorted { a, b in
            if a.group != b.group { return a.group < b.group }
            return a.name < b.name
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetBar(title: "Who calls when",
                     subtitle: "Pick a month and an hour and the register answers",
                     onClose: onClose)
            ScrollView {
                Column {
                    PaperCard {
                        VStack(alignment: .leading, spacing: 11) {
                            RuleLine(text: "Month", trailing: Cal.names[month])
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 5) {
                                    ForEach(0..<12, id: \.self) { m in
                                        Button(action: { Knock.light(); month = m }) {
                                            Text(Cal.names[m].prefix(3))
                                                .font(Nite.title(11.5))
                                                .foregroundColor(month == m ? Nite.card : Nite.inkSoft)
                                                .frame(width: 42, height: 30)
                                                .background(RoundedRectangle(cornerRadius: 5)
                                                    .fill(month == m ? Nite.ink : Nite.ink.opacity(0.06)))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                            RuleLine(text: "Hour", trailing: String(format: "%02d:00", hour))
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 5) {
                                    ForEach(0..<24, id: \.self) { h in
                                        Button(action: { Knock.light(); hour = h }) {
                                            Text(String(format: "%02d", h))
                                                .font(Nite.title(11))
                                                .foregroundColor(hour == h ? Nite.card : Nite.inkSoft)
                                                .frame(width: 34, height: 30)
                                                .background(RoundedRectangle(cornerRadius: 5)
                                                    .fill(hour == h ? Nite.indigo : Nite.ink.opacity(0.06)))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                    PaperCard {
                        VStack(alignment: .leading, spacing: 9) {
                            RuleLine(text: "Calling", trailing: "\(list.count)")
                            if list.isEmpty {
                                Text("Nothing at all. That is a real answer for a winter afternoon, and it is why the middle of the day in January is the quietest the year gets.")
                                    .font(Nite.text(13))
                                    .foregroundColor(Nite.inkSoft)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            ForEach(list) { v in
                                NavigationLink(destination: VoicePage(voice: v).environmentObject(field)) {
                                    HStack(spacing: 8) {
                                        Circle().fill(Nite.groupHue(v.group)).frame(width: 7, height: 7)
                                        Text(v.name)
                                            .font(Nite.text(13))
                                            .foregroundColor(Nite.ink)
                                            .lineLimit(1)
                                        Spacer(minLength: 6)
                                        Text(v.groupName)
                                            .font(Nite.aside(10.5))
                                            .foregroundColor(Nite.inkFaint)
                                            .lineLimit(1)
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    PaperCard {
                        VStack(alignment: .leading, spacing: 8) {
                            RuleLine(text: "The year at a glance")
                            YearGrid(hour: hour)
                            Text("Each column is a month, each row a group, and the shading is how many of that group are on the list at \(String(format: "%02d:00", hour)).")
                                .font(Nite.aside(11.5))
                                .foregroundColor(Nite.inkFaint)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    PressBtn(title: "Close", tone: Nite.inkSoft, filled: false) { onClose() }
                }
                .padding(.horizontal, Nite.gutter)
                .padding(.bottom, 26)
            }
        }
        .background(Nite.paper.ignoresSafeArea())
    }
}

struct YearGrid: View {
    var hour: Int

    var body: some View {
        VStack(spacing: 3) {
            HStack(spacing: 2) {
                Text("").frame(width: 74, alignment: .leading)
                ForEach(0..<12, id: \.self) { m in
                    Text(Cal.short[m])
                        .font(Nite.text(8))
                        .foregroundColor(Nite.inkFaint)
                        .frame(maxWidth: .infinity)
                }
            }
            ForEach(0..<Registry.groupNames.count, id: \.self) { g in
                HStack(spacing: 2) {
                    Text(Registry.groupNames[g])
                        .font(Nite.text(9))
                        .foregroundColor(Nite.inkSoft)
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                        .frame(width: 74, alignment: .leading)
                    ForEach(0..<12, id: \.self) { m in
                        let n = Registry.all.filter {
                            $0.group == g && Cal.has($0.months, month: m) && Cal.hasHour($0.hours, hour)
                        }.count
                        Rectangle()
                            .fill(n == 0 ? Nite.ink.opacity(0.05)
                                  : Nite.groupHue(g).opacity(0.25 + min(0.7, Double(n) / 8.0)))
                            .frame(height: 13)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
}

struct ComparePicker: View {
    @EnvironmentObject var field: Field
    var onClose: () -> Void
    @State private var first: Voice? = nil
    @State private var second: Voice? = nil

    private let suggestions: [(String, String, String)] = [
        ("graytree", "copestree", "Identical frogs. The only field difference is pulse rate, and it is a factor of two."),
        ("screech", "squeakygate", "A screech-owl's whinny against a dry hinge. This one catches everybody once."),
        ("amtoad", "fourspot", "A long pure trill from a toad against a long pure trill from a tree cricket, an octave apart."),
        ("truekatydid", "robustconehead", "A slow harsh rasp against a solid unbroken buzz, both from the same field."),
        ("redfox", "barnowl", "Two screams. One is a mammal and one is a bird, and neither sounds like either."),
        ("fieldcricket", "snowytree", "Two chirping crickets, one on the ground and one in a hedge, with different constants."),
        ("bullfrog", "bittern", "The two deepest voices in the register, from the same marsh."),
        ("leopardfrog", "pickerelfrog", "Two snores. One ends in chuckles and one does not.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            SheetBar(title: "Compare two voices",
                     subtitle: "Play them one after the other and watch both traces",
                     onClose: onClose)
            ScrollView {
                Column {
                    PaperCard {
                        VStack(alignment: .leading, spacing: 10) {
                            RuleLine(text: "Classic pairs")
                            ForEach(Array(suggestions.enumerated()), id: \.offset) { _, pair in
                                Button(action: {
                                    Knock.light()
                                    first = Registry.find(pair.0)
                                    second = Registry.find(pair.1)
                                }) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(Registry.find(pair.0).name) against \(Registry.find(pair.1).name)")
                                            .font(Nite.title(13))
                                            .foregroundColor(Nite.ink)
                                            .fixedSize(horizontal: false, vertical: true)
                                        Text(pair.2)
                                            .font(Nite.text(11.5))
                                            .foregroundColor(Nite.inkFaint)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 4)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    PressBtn(title: "Close", tone: Nite.inkSoft, filled: false) { onClose() }
                }
                .padding(.horizontal, Nite.gutter)
                .padding(.bottom, 26)
            }
        }
        .background(Nite.paper.ignoresSafeArea())
        .sheet(item: $first) { a in
            if let b = second {
                ComparePair(a: a, b: b, onClose: { first = nil }).environmentObject(field)
            }
        }
    }
}

struct ComparePair: View {
    @EnvironmentObject var field: Field
    let a: Voice
    let b: Voice
    var onClose: () -> Void

    @State private var side = 0
    @State private var playing = false
    @State private var progress: Double = 1
    private let ticker = Timer.publish(every: 1.0 / 20.0, on: .main, in: .common).autoconnect()

    private var current: Voice { side == 0 ? a : b }

    var body: some View {
        VStack(spacing: 0) {
            SheetBar(title: "\(a.name) and \(b.name)",
                     subtitle: "Same temperature, same distance, one after the other",
                     onClose: { stop(); onClose() })
            ScrollView {
                Column {
                    PaperCard {
                        SegRow(titles: [a.name, b.name], index: $side)
                    }
                    PaperCard(padding: 0) {
                        VStack(spacing: 0) {
                            VoiceTrace(voice: current, temperature: field.temperature,
                                       progress: playing ? progress : 1,
                                       tone: Nite.groupHue(current.group))
                                .frame(height: 150)
                                .clipped()
                            HStack(spacing: 10) {
                                Button(action: { toggle() }) {
                                    HStack(spacing: 6) {
                                        PlayMark(size: 13, color: Nite.card, playing: playing)
                                        Text(playing ? "Stop" : "Play \(current.name)")
                                            .font(Nite.title(12.5))
                                            .foregroundColor(Nite.card)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(RoundedRectangle(cornerRadius: 5).fill(Nite.indigo))
                                }
                                .buttonStyle(.plain)
                                Spacer(minLength: 0)
                            }
                            .padding(12)
                        }
                    }
                    PaperCard {
                        VStack(alignment: .leading, spacing: 9) {
                            RuleLine(text: "Where they differ")
                            differenceRows
                        }
                    }
                    PaperCard {
                        VStack(alignment: .leading, spacing: 8) {
                            RuleLine(text: current.name)
                            Text(current.tell)
                                .font(Nite.text(13.5))
                                .foregroundColor(Nite.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(current.note)
                                .font(Nite.text(12.5))
                                .foregroundColor(Nite.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    PressBtn(title: "Close", tone: Nite.inkSoft, filled: false) { stop(); onClose() }
                }
                .padding(.horizontal, Nite.gutter)
                .padding(.bottom, 26)
            }
        }
        .background(Nite.paper.ignoresSafeArea())
        .onReceive(ticker) { _ in
            if playing {
                progress += (1.0 / 20.0) / max(0.6, Trace.cycle(current, field.temperature) * 1.25)
                if progress > 1 { progress = 0 }
            }
        }
        .onDisappear { stop() }
    }

    private var differenceRows: some View {
        VStack(alignment: .leading, spacing: 6) {
            compareRow("Pulse rate",
                       String(format: "%.1f a second", a.rate(field.temperature)),
                       String(format: "%.1f a second", b.rate(field.temperature)))
            compareRow("Carrier", a.carrierText, b.carrierText)
            compareRow("Pattern", a.shapeName, b.shapeName)
            compareRow("Quality", a.timbreName, b.timbreName)
            compareRow("Calls from", Perch.short[a.perch], Perch.short[b.perch])
            compareRow("Season", Cal.monthSpan(a.months), Cal.monthSpan(b.months))
        }
    }

    private func compareRow(_ key: String, _ left: String, _ right: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(key.uppercased())
                .font(Nite.text(9))
                .tracking(0.9)
                .foregroundColor(Nite.inkFaint)
            HStack(alignment: .top, spacing: 8) {
                Text(left)
                    .font(Nite.text(12))
                    .foregroundColor(left == right ? Nite.inkFaint : Nite.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                Rectangle().fill(Nite.ink.opacity(0.12)).frame(width: 0.8, height: 14)
                Text(right)
                    .font(Nite.text(12))
                    .foregroundColor(left == right ? Nite.inkFaint : Nite.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func toggle() {
        Knock.light()
        if playing { stop(); return }
        playing = true
        progress = 0
        ChorusEngine.shared.stage([StagedVoice(id: current.id, pan: 0, distance: 0.06,
                                               scenePos: 0, scenePosY: 0, offset: 0,
                                               gainScale: 1.0)],
                                  temperature: field.temperature)
        ChorusEngine.shared.setWindow(low: 60, high: 17000)
        ChorusEngine.shared.setGain(0, 1.1)
        if field.soundOn { ChorusEngine.shared.start() }
    }

    private func stop() {
        playing = false
        progress = 1
        ChorusEngine.shared.silence()
        ChorusEngine.shared.stop()
    }
}
