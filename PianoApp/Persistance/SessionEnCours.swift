import Foundation
import SwiftData

/// L'état persisté d'une session non terminée, pour la retrouver si l'app est fermée.
/// Au plus une ligne : créée au démarrage du timer, mise à jour à chaque pause et
/// passage en arrière-plan, supprimée quand la session se termine ou est remise à zéro.
@Model
final class SessionEnCours {
    var debut: Date
    /// Secondes écoulées au moment de la dernière sauvegarde.
    var secondesAccumulees: Int
    /// Le timer tournait-il au moment de la dernière sauvegarde ?
    var enCours: Bool
    var sauvegardeLe: Date

    init(debut: Date = .now, secondesAccumulees: Int = 0,
         enCours: Bool = true, sauvegardeLe: Date = .now) {
        self.debut = debut
        self.secondesAccumulees = secondesAccumulees
        self.enCours = enCours
        self.sauvegardeLe = sauvegardeLe
    }
}
