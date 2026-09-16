import Foundation
import Observation
import SwiftData

/// État du timer de session. Porté par la racine pour survivre aux changements d'onglet.
/// Le temps écoulé s'ancre sur des dates, pas sur des ticks : il reste juste quand
/// l'écran se verrouille ou que l'app passe en arrière-plan, la minuterie ne servant
/// qu'à rafraîchir l'affichage. L'état est persisté (`SessionEnCours`) pour retrouver
/// une session interrompue par une fermeture de l'app.
@Observable
final class SessionViewModel {
    private(set) var enCours = false
    private(set) var secondesEcoulees = 0

    /// Cible visuelle de l'anneau (une session « pleine » de 25 minutes).
    let cibleSecondes = 25 * 60

    /// Début du segment de pratique en cours, `nil` en pause.
    @ObservationIgnored private var ancre: Date?
    /// Secondes cumulées des segments terminés (avant la dernière pause).
    @ObservationIgnored private var secondesAccumulees = 0
    @ObservationIgnored private var minuterie: Timer?
    @ObservationIgnored private var contexte: ModelContext?
    @ObservationIgnored private var etatPersiste: SessionEnCours?

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
        arreterMinuterie()
        enCours = false
        ancre = nil
        secondesAccumulees = 0
        secondesEcoulees = 0
        supprimerEtatPersiste()
    }

    /// Termine la session et renvoie la durée à enregistrer,
    /// ou `nil` si elle est trop courte pour compter (< 60 s).
    func terminer() -> Int? {
        actualiser()
        let duree = secondesEcoulees
        reinitialiser()
        return duree >= 60 ? duree : nil
    }

    // MARK: Cycle de vie (appelé par la racine)

    /// Recale l'affichage sur les dates, au retour au premier plan.
    func rafraichir() {
        actualiser()
    }

    /// Sauvegarde l'état courant, au passage en arrière-plan.
    func sauvegarder() {
        sauvegarderEtat()
    }

    /// Branche la persistance et restaure une éventuelle session interrompue.
    /// La session retrouvée revient **en pause**, pour laisser l'utilisateur
    /// vérifier le temps avant de continuer ou de terminer.
    func configurer(contexte: ModelContext) {
        guard self.contexte == nil else { return }
        self.contexte = contexte
        guard let etat = try? contexte.fetch(FetchDescriptor<SessionEnCours>()).first else { return }
        etatPersiste = etat

        var secondes = etat.secondesAccumulees
        if etat.enCours {
            // L'app a été fermée timer en marche : on crédite le temps couru depuis.
            secondes += max(Int(Date.now.timeIntervalSince(etat.sauvegardeLe)), 0)
        }
        guard secondes > 0 else {
            supprimerEtatPersiste()
            return
        }
        secondesAccumulees = secondes
        secondesEcoulees = secondes
        sauvegarderEtat()
    }

    // MARK: Timer

    private func demarrer() {
        enCours = true
        ancre = .now
        minuterie = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.actualiser()
        }
        sauvegarderEtat()
    }

    private func mettreEnPause() {
        actualiser()
        secondesAccumulees = secondesEcoulees
        ancre = nil
        enCours = false
        arreterMinuterie()
        sauvegarderEtat()
    }

    private func actualiser() {
        let segment = ancre.map { max(Int(Date.now.timeIntervalSince($0)), 0) } ?? 0
        secondesEcoulees = secondesAccumulees + segment
    }

    private func arreterMinuterie() {
        minuterie?.invalidate()
        minuterie = nil
    }

    // MARK: Persistance de l'état

    private func sauvegarderEtat() {
        guard let contexte else { return }
        actualiser()
        guard enCours || secondesEcoulees > 0 else { return }
        if let etatPersiste {
            etatPersiste.secondesAccumulees = secondesEcoulees
            etatPersiste.enCours = enCours
            etatPersiste.sauvegardeLe = .now
        } else {
            let etat = SessionEnCours(secondesAccumulees: secondesEcoulees, enCours: enCours)
            contexte.insert(etat)
            etatPersiste = etat
        }
    }

    private func supprimerEtatPersiste() {
        if let etatPersiste, let contexte {
            contexte.delete(etatPersiste)
        }
        etatPersiste = nil
    }

    deinit { minuterie?.invalidate() }
}
