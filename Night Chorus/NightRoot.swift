import SwiftUI

struct NightRoot: View {
    @EnvironmentObject var field: Field
    @State private var tab = 0
    @State private var lastTab = 0

    var body: some View {
        ZStack {
            Nite.paper.ignoresSafeArea()
            VStack(spacing: 0) {
                Group {
                    switch tab {
                    case 0:
                        NavigationView { TonightView().environmentObject(field) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 1:
                        NavigationView { ListenView().environmentObject(field) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 2:
                        NavigationView { CabinetView().environmentObject(field) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 3:
                        NavigationView { RegisterView().environmentObject(field) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    default:
                        NavigationView { PrimerView().environmentObject(field) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    }
                }
                .id(tab)
                .transition(.asymmetric(
                    insertion: .move(edge: tab > lastTab ? .trailing : .leading).combined(with: .opacity),
                    removal: .opacity))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                tabBar
            }
        }
        .navigationBarHidden(true)
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(0, "Tonight")
            tabButton(1, "Listen")
            tabButton(2, "Cabinet")
            tabButton(3, "Register")
            tabButton(4, "Primer")
        }
        .padding(.top, 6)
        .padding(.bottom, 2)
        .background(
            Nite.card
                .overlay(Rectangle().fill(Nite.ink.opacity(0.10)).frame(height: 0.7), alignment: .top)
                .edgesIgnoringSafeArea(.bottom)
        )
    }

    private func tabButton(_ index: Int, _ label: String) -> some View {
        let active = tab == index
        let tone = active ? Nite.ink : Nite.inkFaint
        return Button(action: {
            Knock.light()
            lastTab = tab
            withAnimation(.easeInOut(duration: 0.22)) { tab = index }
        }) {
            VStack(spacing: 3) {
                Group {
                    switch index {
                    case 0: MoonMark(size: 21, color: tone)
                    case 1: DishMark(size: 21, color: tone)
                    case 2: CabinetMark(size: 21, color: tone)
                    case 3: FeatherMark(size: 21, color: tone)
                    default: GridMark(size: 21, color: tone)
                    }
                }
                Text(label)
                    .font(Nite.text(9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundColor(tone)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct FirstNight: View {
    var onDone: () -> Void
    @State private var page = 0

    private let pages: [(String, String)] = [
        ("The night is full of animals calling",
         "Almost nobody can name one of them. Every voice in this app is built from the ground up out of a pulse rate, a carrier frequency and a rhythm, because that is genuinely all most of these calls are. Nothing is recorded and nothing is downloaded."),
        ("Aim the dish and cut the band",
         "Drag across the scene and a parabolic dish swings with your finger, bringing one corner of the pond forward and pushing the rest back. Then drag a band across the spectrogram to throw away everything above and below the voice you want."),
        ("Read it, do not look it up",
         "Once a voice is alone you work it out from its structure. How many pulses a second. Where the energy sits. Whether it trills, chirps or churrs. A key is there if you need it, and using less of it counts for more."),
        ("Then cut a cylinder",
         "Press and hold and a wax cylinder turns while a stylus cuts a groove taken from that animal's own waveform, so every cylinder in the cabinet looks like the sound it holds. Hold through a whole call and you get a complete one.")
    ]

    var body: some View {
        ZStack {
            Nite.paper.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    if page > 0 {
                        Button(action: { Knock.light(); withAnimation { page -= 1 } }) {
                            HStack(spacing: 4) {
                                BackChev(size: 15, color: Nite.inkSoft)
                                Text("Back").font(Nite.text(14)).foregroundColor(Nite.inkSoft)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                    Button(action: { Knock.light(); onDone() }) {
                        Text("Skip").font(Nite.text(14)).foregroundColor(Nite.inkFaint)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, Nite.gutter)
                .padding(.top, 12)
                Spacer(minLength: 0)
                Column {
                    PaperCard(padding: 9) {
                        PlateBox(name: Plates.intro(page), height: Nite.wide ? 300 : 216)
                    }
                    VStack(alignment: .leading, spacing: 9) {
                        Text(pages[page].0)
                            .font(Nite.title(Nite.narrow ? 20 : 23))
                            .foregroundColor(Nite.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(pages[page].1)
                            .font(Nite.text(14.5))
                            .foregroundColor(Nite.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, Nite.gutter)
                .id(page)
                .transition(.opacity)
                Spacer(minLength: 0)
                HStack(spacing: 6) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Circle().fill(i == page ? Nite.ink : Nite.ink.opacity(0.20))
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.bottom, 12)
                PressBtn(title: page == pages.count - 1 ? "Go out into the dark" : "Next",
                         tone: Nite.indigo) {
                    if page == pages.count - 1 { onDone() } else { withAnimation { page += 1 } }
                }
                .padding(.horizontal, Nite.gutter)
                .padding(.bottom, 20)
            }
        }
    }
}
