import SwiftUI

struct Lesson: Identifiable {
    let id: Int
    let title: String
    let standfirst: String
    let paragraphs: [String]
}

enum Primer {
    static let lessons: [Lesson] = [
        Lesson(id: 0, title: "How to read a spectrogram",
               standfirst: "Time runs left to right, frequency runs bottom to top, and the darker the mark the louder the sound.",
               paragraphs: [
                "A spectrogram is not a picture of a sound wave. It is a stack of short slices of the sound, each one broken into frequency bands, printed side by side. A voice that sits on one pitch draws a horizontal line. A voice that slides draws a diagonal. A voice with no pitch at all draws a vertical smear.",
                "The comb effect matters more than anything else here. A trill is a train of separate pulses, and at this scale each pulse draws its own narrow vertical mark. Count those marks along one second and you have the pulse rate, which is the single most useful number in the whole business.",
                "Stacked horizontal bands at exact multiples of the lowest one are harmonics. Owls, bitterns and bullfrogs all show them, because a vibrating membrane rarely produces a clean sine. A cricket, which rubs a file at one rate, very nearly does.",
                "The frequency axis in this app is logarithmic, which is why the gap between one and two kilohertz looks the same as the gap between four and eight. That matches how hearing works, and it stops the low voices being squashed into the bottom two millimetres."
               ]),
        Lesson(id: 1, title: "Pulse rate is the first question",
               standfirst: "Before you ask what it is, ask how fast it is going.",
               paragraphs: [
                "Every stridulating insect makes sound the same way: a hardened file on one wing is drawn across a scraper on the other, and each tooth of the file makes one pulse. The pulse rate is therefore the rate at which the wing is being closed multiplied by the number of teeth engaged, and it is astonishingly consistent within a species at a given temperature.",
                "Under five pulses a second and you can count them out loud. Five to twenty-five and you can tap along. Twenty-five to sixty and you can just hear the individual pulses as a rattle. Above sixty they fuse into a tone and you have to read the rate off a spectrogram instead of off your ear.",
                "This is why the gray treefrog and Cope's gray treefrog can be separated in the field at all. The two are identical to look at and hybridise where they meet, but one trills at about twenty pulses a second on a mild night and the other at about forty. Nothing else about them helps.",
                "Do not confuse pulse rate with call rate. A field cricket chirps two or three times a second, but each chirp contains four pulses at twenty-six a second. Both numbers are useful, and the key in this app asks for the pulse rate."
               ]),
        Lesson(id: 2, title: "Carrier frequency, and the voices you lose",
               standfirst: "Half the night chorus sits above the range most adults can still hear.",
               paragraphs: [
                "The carrier is the frequency the animal is actually radiating: for a spring peeper about 2.9 kilohertz, for a bullfrog about 200 hertz, for a round-tipped conehead about 12.5 kilohertz. The whole cast of a summer field is laid out across that range, and each species has staked out a slice of it.",
                "That is not an accident. Acoustic niche partitioning is real and measurable: species that call in the same place at the same time push apart in frequency, in pulse rate, or in the timing of their bursts, because a male whose signal is masked does not breed.",
                "Human hearing at the top end falls away steadily with age. A twenty-year-old typically hears to about eighteen kilohertz; by fifty many people have lost everything above twelve. That takes out the coneheads, most of the tree crickets, the flying squirrel and every bat, and it happens so gradually that people do not notice their summer nights getting quieter.",
                "The practical consequence for identification is that you must not treat silence as evidence. If you cannot hear anything above eight kilohertz, look at the spectrogram instead of listening, and take the reading as real."
               ]),
        Lesson(id: 3, title: "Dolbear's law",
               standfirst: "Count the chirps of a snowy tree cricket in thirteen seconds, add forty, and you have the temperature in Fahrenheit.",
               paragraphs: [
                "Amos Dolbear published the relation in 1897 in The American Naturalist under the title The Cricket as a Thermometer. His own equation was for the number of chirps in a minute: the temperature in Fahrenheit equals fifty plus the count minus forty, all over four.",
                "The field version drops the arithmetic. Count for thirteen seconds instead of sixty, add forty, and you land within a degree or two of the full equation across the range the cricket actually sings in. It works because the reaction rates in the muscle driving the wing scale almost linearly with temperature over that band.",
                "It only works properly for the snowy tree cricket, Oecanthus fultoni, which is the species Dolbear was listening to. Other crickets have their own constants; field crickets are commonly quoted with a fifteen second count, and katydids and coneheads all have slopes of their own. In this app every cold-blooded voice carries its own measured slope, given as a percentage change per degree.",
                "The limits are worth knowing. Below about four degrees the cricket stops singing rather than slowing down further, and above about thirty the relation bends. And it is one animal you are timing, not the average of a hedge, so pick a single close chirper and stay with it."
               ]),
        Lesson(id: 4, title: "What a parabolic dish actually does",
               standfirst: "It buys you gain and direction, but only above a frequency set by its diameter.",
               paragraphs: [
                "A parabola collects everything arriving parallel to its axis and concentrates it at one point. Put a microphone, or an ear, at that point and you get real gain over the same sound arriving at open air, plus a narrow beam that rejects everything off to the side.",
                "The catch is wavelength. A dish only behaves like a mirror for sound whose wavelength is small compared with the dish. Sound travels at about 343 metres a second, so a two kilohertz call has a wavelength of about seventeen centimetres and a sixty centimetre dish handles it comfortably. A bullfrog at two hundred hertz has a wavelength of over a metre and a half and simply flows around the dish as if it were not there.",
                "This is why aiming the dish in this app pulls the crickets and katydids sharply forward and barely touches the bullfrog or the bittern. That is not a shortcut in the model. It is the same physics you meet the first time you take a real dish out to a pond.",
                "The second control here does what a real recordist does with a filter afterwards. Closing the window to a band around one voice throws away everything above and below it, and against a wall of high katydid noise that is often the only way to get at a low voice underneath."
               ]),
        Lesson(id: 5, title: "Why a cylinder looks like its sound",
               standfirst: "The first recordings were cut vertically into wax, and the groove is a direct picture of the pressure.",
               paragraphs: [
                "On a phonograph cylinder the stylus cuts up and down into the surface rather than side to side, which is called hill and dale. The depth of the cut at any point is the air pressure at that instant, so the groove is not a code for the sound; it is a scale drawing of it.",
                "That is why the cylinders in the cabinet here all look different. A snowy tree cricket cuts a shallow even ripple with a clean gap between chirps. A bullfrog cuts three deep slow troughs. A robust conehead cuts a solid band with no gaps in it at all, and you can see at a glance why it is so hard to hear anything else near one.",
                "Wax gives you one more true detail: how long you hold the cut matters. Lift the stylus early and you have half a call, which is often not enough to identify anything. Both the depth and the length of the groove in this cabinet come from how well you isolated the voice and how long you held on.",
                "Real cylinders were also the first recordings anyone made of wild animals. The earliest surviving bird recordings, made on wax in the last years of the nineteenth century, sound very much like what a badly isolated cut looks like here."
               ])
    ]
}

struct PrimerView: View {
    @EnvironmentObject var field: Field
    @State private var openDolbear = false
    @State private var openCalendar = false
    @State private var openCompare = false

    var body: some View {
        ScrollView {
            Column {
                headerCard
                toolsCard
                lessonsCard
                habitatsCard
            }
            .padding(.horizontal, Nite.gutter)
            .padding(.bottom, 26)
        }
        .background(Nite.paper.ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $openDolbear) {
            DolbearSheet(onClose: { openDolbear = false }).environmentObject(field)
        }
        .sheet(isPresented: $openCalendar) {
            CalendarSheet(onClose: { openCalendar = false }).environmentObject(field)
        }
        .sheet(isPresented: $openCompare) {
            ComparePicker(onClose: { openCompare = false }).environmentObject(field)
        }
    }

    private var headerCard: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 8) {
                RuleLine(text: "The primer", trailing: "\(Primer.lessons.count) pages")
                Text("Everything the field screen assumes you know, written out. None of it is locked and none of it depends on your rank.")
                    .font(Nite.text(13))
                    .foregroundColor(Nite.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .rising(0)
    }

    private var toolsCard: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 10) {
                RuleLine(text: "Tools")
                toolRow("The cricket thermometer",
                        "Tap along with a snowy tree cricket for thirteen seconds and read the temperature off your own count.") {
                    openDolbear = true
                }
                toolRow("Who calls when",
                        "A month by month and hour by hour chart of the whole register.") {
                    openCalendar = true
                }
                toolRow("Compare two voices",
                        "Put a confusable pair side by side and play them one after the other.") {
                    openCompare = true
                }
            }
        }
        .rising(1)
    }

    private func toolRow(_ title: String, _ note: String, _ action: @escaping () -> Void) -> some View {
        Button(action: { Knock.light(); action() }) {
            HStack(alignment: .top, spacing: 9) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Nite.title(13.5))
                        .foregroundColor(Nite.ink)
                    Text(note)
                        .font(Nite.text(11.5))
                        .foregroundColor(Nite.inkFaint)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                NextChev(size: 13, color: Nite.inkFaint)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var lessonsCard: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 10) {
                RuleLine(text: "Pages")
                ForEach(Primer.lessons) { lesson in
                    NavigationLink(destination: LessonPage(lesson: lesson).environmentObject(field)) {
                        HStack(alignment: .top, spacing: 9) {
                            Text("\(lesson.id + 1)")
                                .font(Nite.title(13))
                                .foregroundColor(Nite.inkFaint)
                                .frame(width: 18, alignment: .leading)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(lesson.title)
                                    .font(Nite.title(13.5))
                                    .foregroundColor(Nite.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(lesson.standfirst)
                                    .font(Nite.aside(11.5))
                                    .foregroundColor(Nite.inkFaint)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 4)
                            NextChev(size: 12, color: Nite.inkFaint)
                        }
                        .padding(.vertical, 3)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .rising(2)
    }

    private var habitatsCard: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 10) {
                RuleLine(text: "Habitats", trailing: "8")
                ForEach(0..<8, id: \.self) { i in
                    NavigationLink(destination: HabitatPage(index: i).environmentObject(field)) {
                        HStack(alignment: .top, spacing: 9) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(Ground.names[i])
                                    .font(Nite.title(13.5))
                                    .foregroundColor(Nite.ink)
                                Text("\(Registry.all.filter { $0.habitats & (1 << i) != 0 }.count) voices on the list")
                                    .font(Nite.text(11.5))
                                    .foregroundColor(Nite.inkFaint)
                            }
                            Spacer(minLength: 4)
                            NextChev(size: 12, color: Nite.inkFaint)
                        }
                        .padding(.vertical, 3)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .rising(3)
    }
}

struct LessonPage: View {
    @EnvironmentObject var field: Field
    let lesson: Lesson
    @Environment(\.presentationMode) private var presentation

    var body: some View {
        ScrollView {
            Column {
                PaperCard(padding: 0) {
                    VStack(spacing: 0) {
                        PlateBox(name: Plates.primer(lesson.id), height: Nite.wide ? 280 : 200, corner: 0)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(lesson.title)
                                .font(Nite.title(20))
                                .foregroundColor(Nite.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(lesson.standfirst)
                                .font(Nite.aside(14))
                                .foregroundColor(Nite.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(13)
                    }
                }
                PaperCard {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(lesson.paragraphs.enumerated()), id: \.offset) { _, text in
                            Text(text)
                                .font(Nite.text(14))
                                .foregroundColor(Nite.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                PressBtn(title: "Back to the primer", tone: Nite.inkSoft, filled: false) {
                    presentation.wrappedValue.dismiss()
                }
            }
            .padding(.horizontal, Nite.gutter)
            .padding(.bottom, 26)
        }
        .background(Nite.paper.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { field.markRead(1, "lesson-\(lesson.id)") }
    }
}

struct HabitatPage: View {
    @EnvironmentObject var field: Field
    let index: Int
    @Environment(\.presentationMode) private var presentation

    private var voices: [Voice] {
        Registry.all.filter { $0.habitats & (1 << index) != 0 }
    }

    var body: some View {
        ScrollView {
            Column {
                PaperCard(padding: 0) {
                    VStack(spacing: 0) {
                        PlateBox(name: Plates.habitat(index), height: Nite.wide ? 280 : 200, corner: 0)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(Ground.names[index])
                                .font(Nite.title(20))
                                .foregroundColor(Nite.ink)
                            Text(Ground.blurbs[index])
                                .font(Nite.text(13.5))
                                .foregroundColor(Nite.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(13)
                    }
                }
                PaperCard {
                    VStack(alignment: .leading, spacing: 9) {
                        RuleLine(text: "The cast", trailing: "\(voices.count)")
                        ForEach(voices) { v in
                            NavigationLink(destination: VoicePage(voice: v).environmentObject(field)) {
                                HStack(spacing: 8) {
                                    Circle().fill(Nite.groupHue(v.group)).frame(width: 7, height: 7)
                                    Text(v.name)
                                        .font(Nite.text(13))
                                        .foregroundColor(Nite.ink)
                                        .lineLimit(1)
                                    Spacer(minLength: 6)
                                    Text(Cal.monthSpan(v.months))
                                        .font(Nite.aside(10.5))
                                        .foregroundColor(Nite.inkFaint)
                                        .lineLimit(1)
                                    NextChev(size: 11, color: Nite.inkFaint)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                PressBtn(title: "Back", tone: Nite.inkSoft, filled: false) {
                    presentation.wrappedValue.dismiss()
                }
            }
            .padding(.horizontal, Nite.gutter)
            .padding(.bottom, 26)
        }
        .background(Nite.paper.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { field.markRead(1, "habitat-\(index)") }
    }
}
