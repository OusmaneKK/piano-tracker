import SwiftUI
import SwiftData

@main
struct PianoApp: App {
    var body: some Scene {
        WindowGroup {
            RacineView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [SessionPratique.self, Profil.self])
    }
}
