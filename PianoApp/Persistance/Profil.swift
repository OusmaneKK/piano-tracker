import Foundation
import SwiftData

/// Le profil unique de l'utilisateur : objectif quotidien et état de l'onboarding.
@Model
final class Profil {
    var objectifQuotidienMinutes: Int
    var onboardingTermine: Bool
    var creeLe: Date
    /// Heure du créneau quotidien, en minutes depuis minuit. Optionnel : les
    /// profils créés avant cette version n'en portent pas (migration légère).
    var heureCreneauMinutes: Int?

    init(objectifQuotidienMinutes: Int = 60, onboardingTermine: Bool = false,
         creeLe: Date = .now, heureCreneauMinutes: Int? = nil) {
        self.objectifQuotidienMinutes = objectifQuotidienMinutes
        self.onboardingTermine = onboardingTermine
        self.creeLe = creeLe
        self.heureCreneauMinutes = heureCreneauMinutes
    }

    /// L'heure du créneau, ramenée à aujourd'hui (19 h tant qu'elle n'a pas été choisie).
    var heureCreneau: Date {
        get {
            let minutes = heureCreneauMinutes ?? 19 * 60
            return Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60,
                                         second: 0, of: .now) ?? .now
        }
        set {
            let composantes = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            heureCreneauMinutes = (composantes.hour ?? 19) * 60 + (composantes.minute ?? 0)
        }
    }
}
