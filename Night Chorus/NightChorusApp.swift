import SwiftUI

@main
struct NightChorusApp: App {
    @StateObject private var field = Field()

    var body: some Scene {
        WindowGroup {
            Group {
                if field.ledger.seenIntro == true {
                    NightRoot().environmentObject(field)
                } else {
                    FirstNight { field.ledger.seenIntro = true }
                }
            }
            .preferredColorScheme(.light)
        }
    }
}
