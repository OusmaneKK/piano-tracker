import Foundation
import SwiftData

/// Une session de pratique enregistrée à la fin du timer.
@Model
final class SessionPratique {
    var date: Date
    var dureeSecondes: Int

    init(date: Date = .now, dureeSecondes: Int) {
        self.date = date
        self.dureeSecondes = dureeSecondes
    }

    var dureeMinutes: Int { dureeSecondes / 60 }
}
