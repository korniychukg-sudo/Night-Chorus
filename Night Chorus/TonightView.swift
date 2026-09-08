import SwiftUI

struct TonightView: View {
    @EnvironmentObject var field: Field
    @State private var drift: Double = 0
    @State private var openField = false
    @State private var openMoon = false
    @State private var openDolbear = false
    @State private var hourNow = Clock.hourFraction
    private let ticker = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    private var card: Card { Plan.card(field.today) }

    var body: some View {
        ScrollView {
            Column {
                heroCard
                cardOfTheNight
                thermometerCard
                standingCard
                callingNowCard
                moonCard
                logCard
            }
            .padding(.horizontal, Nite.gutter)
            .padding(.bottom, 26)
        }
        .background(Nite.paper.ignoresSafeArea())
        .navigationBarHidden(true)
        .onReceive(ticker) { _ in
            drift += 1.0
            hourNow = Clock.hourFraction
        }
        .fullScreenCover(isPresented: $openField) {
            ListenView(startHabitat: card.habitat).environmentObject(field)
        }
        .sheet(isPresented: $openMoon) { MoonSheet(onClose: { openMoon = false }) }
        .sheet(isPresented: $openDolbear) {
            DolbearSheet(onClose: { openDolbear = false }).environmentObject(field)
        }
    }

    private var heroCard: some View {
        PaperCard(padding: 0) {
            VStack(spacing: 0) {
                ZStack {
                    PlateBox(name: Plates.scene(Clock.seasonIndex, Clock.phaseIndex),
                             height: Nite.wide ? 260 : 196, corner: 0)
                    SkyOverlay(hour: hourNow, moonPhase: Clock.moonPhase,
                               season: Clock.seasonIndex, drift: drift)
                        .frame(height: Nite.wide ? 260 : 196)
                        .clipped()
                }
                .frame(height: Nite.wide ? 260 : 196)
                .clipped()
                VStack(alignment: .leading, spacing: 4) {
                    Text(hourWords)
                        .font(Nite.title(16))
                        .foregroundColor(Nite.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(Clock.dateLine). \(Clock.phaseNames[Clock.phaseIndex]) in \(Clock.seasonNames[Clock.seasonIndex].lowercased()), \(Clock.moonNames[Clock.moonIndex].lowercased()).")
                        .font(Nite.text(12))
                        .foregroundColor(Nite.inkFaint)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(13)
            }
        }
        .rising(0)
    }

    private var hourWords: String {
        switch Clock.phaseIndex {
        case 0: return "The last owl and the first thrush overlap for about ten minutes"
        case 1: return "The night shift has gone quiet and handed over"
        case 2: return "Only the cicadas and the odd cricket are working"
        case 3: return "The light is going and the first insects are tuning up"
        case 4: return "Dusk, and the chorus is filling in from the water outward"
        case 5: return "Full dark, and everything that is going to call is calling"
        default: return "The small hours, when the chorus thins to a handful of voices"
        }
    }

    private var cardOfTheNight: some View {
        let log = field.tonight
        let done = card.targets.filter { log?.named.contains($0) ?? false }
        return PaperCard {
            VStack(alignment: .leading, spacing: 11) {
                HStack {
                    RuleLine(text: "Tonight's listening card")
                    if !done.isEmpty {
                        Stamp(text: "\(done.count) of \(card.targets.count)",
                              tone: done.count == card.targets.count ? Nite.good : Nite.brass)
                    }
                }
                Text(card.opening)
                    .font(Nite.aside(14.5))
                    .foregroundColor(Nite.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    StatChip(value: card.habitatName, label: "where")
                    StatChip(value: card.hourText, label: "when")
                }
                VStack(spacing: 7) {
                    ForEach(card.targets, id: \.self) { id in
                        targetRow(Registry.find(id), got: done.contains(id))
                    }
                }
                if Plan.extraRequired(field.rankIndex) {
                    NoteBanner(text: "As \(field.rank.0): " + Plan.extraTasks[card.extra],
                               tone: Nite.dusk)
                }
                PressBtn(title: done.count == card.targets.count
                         ? "Go back out anyway" : "Take the dish out",
                         tone: done.count == card.targets.count ? Nite.inkSoft : Nite.indigo,
                         filled: done.count != card.targets.count) {
                    openField = true
                }
            }
        }
        .rising(1)
    }

    private func targetRow(_ v: Voice, got: Bool) -> some View {
        HStack(spacing: 9) {
            ZStack {
                Circle().fill(got ? Nite.good.opacity(0.16) : Nite.ink.opacity(0.06))
                    .frame(width: 26, height: 26)
                if got {
                    TickMark(size: 14, color: Nite.good)
                } else {
                    Circle().fill(Nite.groupHue(v.group)).frame(width: 8, height: 8)
                }
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(got ? v.name : v.groupHint)
                    .font(Nite.title(13.5))
                    .foregroundColor(Nite.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(got ? v.latin : v.tell)
                    .font(got ? Nite.aside(11.5) : Nite.text(11.5))
                    .foregroundColor(Nite.inkFaint)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private var thermometerCard: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 10) {
                RuleLine(text: "Temperature", trailing: String(format: "%.0f F",
                                                              Weather.fahrenheit(field.temperature)))
                HStack(alignment: .top, spacing: 14) {
                    Thermometer(celsius: field.temperature)
                        .frame(width: 62, height: 128)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(format: "%.0f degrees, %@",
                                    field.temperature, Weather.words(field.temperature)))
                            .font(Nite.text(13))
                            .foregroundColor(Nite.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                        DragSlider(value: field.temperature, range: 0...36, tone: Nite.ember) {
                            field.temperature = $0
                        }
                        Text("Every cold-blooded voice in the app speeds up and slows down with this. Warm-blooded ones do not move at all.")
                            .font(Nite.aside(11.5))
                            .foregroundColor(Nite.inkFaint)
                            .fixedSize(horizontal: false, vertical: true)
                        Button(action: { Knock.light(); openDolbear = true }) {
                            Text("Read it off a cricket instead")
                                .font(Nite.title(12))
                                .foregroundColor(Nite.indigo)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .rising(2)
    }

    private var standingCard: some View {
        let (name, note, marks, ceiling) = field.rank
        let progress = ceiling > marks ? Double(marks) / Double(max(1, ceiling)) : 1
        return PaperCard {
            VStack(alignment: .leading, spacing: 10) {
                RuleLine(text: "Standing", trailing: "\(marks) marks")
                Text(name).font(Nite.title(19)).foregroundColor(Nite.ink)
                Text(note)
                    .font(Nite.aside(13))
                    .foregroundColor(Nite.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                MeterBar(label: ceiling > marks ? "Toward \(nextRankName)" : "Top of the list",
                         value: progress, tone: Nite.indigo)
                HStack(spacing: 8) {
                    StatChip(value: "\(field.liveStreak)", label: "night streak")
                    StatChip(value: "\(field.namedCount)", label: "named")
                    StatChip(value: "\(field.ledger.cabinet.count)", label: "cylinders")
                }
                Text("Rank does not lock anything. The register, the cabinet and the field are open from the first night; a higher rank only adds another line to the card.")
                    .font(Nite.aside(11.5))
                    .foregroundColor(Nite.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .rising(3)
    }

    private var nextRankName: String {
        let i = field.rankIndex
        return i + 1 < Field.ranks.count ? Field.ranks[i + 1].1 : Field.ranks[i].1
    }

    private var callingNowCard: some View {
        let hour = Clock.hour
        let list = Registry.callingAnywhere(month: Clock.month, hour: hour)
            .sorted { $0.level > $1.level }
        return PaperCard {
            VStack(alignment: .leading, spacing: 9) {
                RuleLine(text: "Should be calling now", trailing: "\(list.count)")
                if list.isEmpty {
                    Text("Nothing on the list for this month at this hour. That happens in the middle of a winter afternoon, and it is a real answer.")
                        .font(Nite.text(12.5))
                        .foregroundColor(Nite.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    ForEach(list.prefix(7)) { v in
                        NavigationLink(destination: VoicePage(voice: v).environmentObject(field)) {
                            HStack(spacing: 8) {
                                Circle().fill(Nite.groupHue(v.group)).frame(width: 7, height: 7)
                                Text(v.name)
                                    .font(Nite.text(13))
                                    .foregroundColor(Nite.ink)
                                    .lineLimit(1)
                                Spacer(minLength: 6)
                                Text(v.groupName)
                                    .font(Nite.aside(11))
                                    .foregroundColor(Nite.inkFaint)
                                    .lineLimit(1)
                                NextChev(size: 11, color: Nite.inkFaint)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    if list.count > 7 {
                        Text("and \(list.count - 7) more in the register.")
                            .font(Nite.aside(11.5))
                            .foregroundColor(Nite.inkFaint)
                    }
                }
            }
        }
        .rising(4)
    }

    private var moonCard: some View {
        PaperCard(padding: 0) {
            VStack(spacing: 0) {
                PlateBox(name: Plates.moon(Clock.moonIndex), height: 132, corner: 0)
                VStack(alignment: .leading, spacing: 5) {
                    Text(Clock.moonNames[Clock.moonIndex])
                        .font(Nite.title(15))
                        .foregroundColor(Nite.ink)
                    Text(String(format: "%.0f per cent lit. ", Clock.moonLit * 100) + moonNote)
                        .font(Nite.text(12))
                        .foregroundColor(Nite.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                    Button(action: { Knock.light(); openMoon = true }) {
                        Text("Why the moon matters")
                            .font(Nite.title(12))
                            .foregroundColor(Nite.indigo)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(13)
            }
        }
        .rising(5)
    }

    private var moonNote: String {
        Clock.moonLit > 0.6
        ? "Nightjars call hardest on bright nights, and small mammals go quiet under a full moon."
        : "A dark night favours anything that does not want to be seen, and quietens the whip-poor-will."
    }

    private var logCard: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 9) {
                RuleLine(text: "Nights logged", trailing: "\(field.ledger.nights.count)")
                if field.ledger.nights.isEmpty {
                    Text("Nothing logged yet. A night counts once you have put a name to something.")
                        .font(Nite.text(12.5))
                        .foregroundColor(Nite.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    ForEach(field.ledger.nights.prefix(5)) { night in
                        HStack(alignment: .top, spacing: 8) {
                            Text(night.day == field.today ? "Tonight" : "\(field.today - night.day) nights ago")
                                .font(Nite.title(12))
                                .foregroundColor(Nite.inkSoft)
                                .frame(width: 96, alignment: .leading)
                            Text(night.named.map { Registry.find($0).name }.joined(separator: ", "))
                                .font(Nite.text(12))
                                .foregroundColor(Nite.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                    }
                    HStack(spacing: 8) {
                        StatChip(value: "\(field.ledger.bestStreak)", label: "best streak")
                        StatChip(value: "\(field.readVoiceCount)", label: "entries read")
                    }
                }
            }
        }
        .rising(6)
    }
}

struct MoonSheet: View {
    var onClose: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            SheetBar(title: "The moon and the chorus",
                     subtitle: Clock.moonNames[Clock.moonIndex],
                     onClose: onClose)
            ScrollView {
                Column {
                    PlateBox(name: Plates.moon(Clock.moonIndex), height: 200)
                    PaperCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("The phase drawn above is the real one for tonight, worked out from the date against a known new moon and the 29.53 day synodic month.")
                                .font(Nite.text(13.5))
                                .foregroundColor(Nite.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                            RuleLine(text: "Who cares about it")
                            Text("Whip-poor-wills and their relatives hunt moths by sight and call far more on bright nights. Their breeding is timed so that the hungriest chicks coincide with a waxing moon.")
                                .font(Nite.text(13))
                                .foregroundColor(Nite.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("Mice and voles move less under a full moon because owls can see them, so the owls themselves often hunt harder on dark nights. Frogs and insects mostly ignore the moon and answer to temperature and rain instead.")
                                .font(Nite.text(13))
                                .foregroundColor(Nite.inkSoft)
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
