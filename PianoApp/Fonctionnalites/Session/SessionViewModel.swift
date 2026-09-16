import Foundation
import Observation

/// État du timer de session. Porté par la racine pour survivre aux changements d'onglet.
@Observable
final class SessionViewModel {
    private(set) var enCours = false
    private(set) var secondesEcoulees = 0

    /// Cible visuelle de l'anneau (une session « pleine » de 25 minutes).
    let cibleSecondes = 25 * 60

    @ObservationIgnored private var minuterie: Timer?

    var affichage: String { FormatTemps.minutesSecondes(secondesEcoulees) }

    var sousTexte: String {
        if enCours { return "tes heures s'enregistrent" }
        return secondesEcoulees > 0 ? "en pause" : "prêt quand tu l'es"
    }

    /// Fraction de l'anneau (bornée à 1 au-delà de la cible).
    var fractionAnneau: Double {
        min(Double(secondesEcoulees) / Double(cibleSecondes), 1)
    }

    func basculer() {
        enCours ? mettreEnPause() : demarrer()
    }

    func reinitialiser() {
        mettreEnPause()
        secondesEcoulees = 0
    }

    /// Termine la session et renvoie la durée à enregistrer,
    /// ou `nil` si elle est trop courte pour compter (< 60 s).
    func terminer() -> Int? {
        let duree = secondesEcoulees
        reinitialiser()
        return duree >= 60 ? duree : nil
    }

    private func demarrer() {
        enCours = true
        minuterie = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.secondesEcoulees += 1
        }
    }

    private func mettreEnPause() {
        enCours = false
        minuterie?.invalidate()
        minuterie = nil
    }

    deinit { minuterie?.invalidate() }
}
