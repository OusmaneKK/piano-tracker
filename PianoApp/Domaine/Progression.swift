import Foundation

/// Calculs purs autour de la route des 10 000 heures. Aucun import SwiftUI.
enum Progression {
    /// Le seuil de maîtrise, en heures de pratique délibérée.
    static let objectifHeures: Double = 10_000

    /// Pourcentage de la route parcourue, borné à [0, 100].
    static func pourcentage(heuresTotales: Double) -> Double {
        guard heuresTotales > 0 else { return 0 }
        return min(heuresTotales / objectifHeures * 100, 100)
    }

    /// Le prochain jalon non atteint, `nil` si la route est terminée.
    static func prochainJalon(heuresTotales: Double) -> Jalon? {
        Jalon.tous.first { $0.heures > heuresTotales }
    }

    /// Série de jours de pratique, avec tolérance d'une journée manquée :
    /// un trou d'un jour entre deux jours pratiqués ne casse pas la série,
    /// et la série reste vivante si la dernière pratique date d'avant-hier.
    /// Seuls les jours effectivement pratiqués comptent.
    static func serie(joursDePratique: [Date],
                      aujourdHui: Date = .now,
                      calendrier: Calendar = .current) -> Int {
        let jours = Set(joursDePratique.map { calendrier.startOfDay(for: $0) })
            .sorted(by: >)
        guard let dernier = jours.first else { return 0 }

        let debut = calendrier.startOfDay(for: aujourdHui)
        let ecartDernier = calendrier.dateComponents([.day], from: dernier, to: debut).day ?? .max
        guard ecartDernier >= 0, ecartDernier <= 2 else { return 0 }

        var compte = 1
        for (recent, precedent) in zip(jours, jours.dropFirst()) {
            let ecart = calendrier.dateComponents([.day], from: precedent, to: recent).day ?? .max
            if ecart <= 2 { compte += 1 } else { break }
        }
        return compte
    }

    /// Années restantes pour atteindre `heuresCible` au rythme hebdomadaire donné.
    /// `nil` si le rythme est nul (aucune prévision possible).
    static func anneesRestantes(heuresTotales: Double,
                                heuresCible: Double,
                                heuresParSemaine: Double) -> Double? {
        guard heuresParSemaine > 0 else { return nil }
        let restantes = max(heuresCible - heuresTotales, 0)
        return restantes / heuresParSemaine / 52
    }

    /// Mois (arrondis, minimum 1) pour atteindre `heuresCible` à raison de
    /// `minutesParJour` chaque jour. `nil` si l'objectif quotidien est nul.
    static func moisPourAtteindre(heuresCible: Double, minutesParJour: Int) -> Int? {
        guard minutesParJour > 0 else { return nil }
        let heuresParMois = Double(minutesParJour) / 60 * 30.4
        return max(1, Int((heuresCible / heuresParMois).rounded()))
    }
}
