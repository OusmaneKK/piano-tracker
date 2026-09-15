import Foundation
import SwiftData

/// Le profil unique de l'utilisateur : objectif quotidien et état de l'onboarding.
@Model
final class Profil {
    var objectifQuotidienMinutes: Int
    var onboardingTermine: Bool
    var creeLe: Date

    init(objectifQuotidienMinutes: Int = 60, onboardingTermine: Bool = false, creeLe: Date = .now) {
        self.objectifQuotidienMinutes = objectifQuotidienMinutes
        self.onboardingTermine = onboardingTermine
        self.creeLe = creeLe
    }
}
