import Foundation

/// Ce que l'historique du quiz raconte : taux de réussite, progression,
/// et les notes qui résistent encore. Aucun import SwiftUI ni SwiftData.
enum StatistiquesQuiz {

    /// Une note et son bilan, pour l'écran de statistiques.
    struct BilanNote: Equatable {
        let note: String
        let ratees: Int
        let tentatives: Int

        /// Part d'erreurs, de 0 à 1.
        var tauxErreur: Double {
            tentatives > 0 ? Double(ratees) / Double(tentatives) : 0
        }
    }

    /// Taux de réussite global, de 0 à 1 ; `nil` sans aucune réponse.
    static func tauxDeReussite(reponses: [(note: String, juste: Bool)]) -> Double? {
        guard !reponses.isEmpty else { return nil }
        let justes = reponses.filter(\.juste).count
        return Double(justes) / Double(reponses.count)
    }

    /// Les notes qui résistent le plus, la pire d'abord.
    ///
    /// Une note doit avoir été vue au moins `minimumTentatives` fois pour
    /// apparaître : sinon un seul raté sur une seule apparition la hisserait
    /// en tête et le conseil serait faux. À taux d'erreur égal, la note la
    /// plus souvent ratée passe devant ; puis l'ordre alphabétique, pour que
    /// l'affichage ne change pas d'une fois sur l'autre.
    static func notesQuiResistent(reponses: [(note: String, juste: Bool)],
                                  minimumTentatives: Int = 3,
                                  limite: Int = 3) -> [BilanNote] {
        var tentatives: [String: Int] = [:]
        var ratees: [String: Int] = [:]
        for reponse in reponses {
            tentatives[reponse.note, default: 0] += 1
            if !reponse.juste { ratees[reponse.note, default: 0] += 1 }
        }

        return tentatives
            .compactMap { note, nb -> BilanNote? in
                let manquees = ratees[note] ?? 0
                guard nb >= minimumTentatives, manquees > 0 else { return nil }
                return BilanNote(note: note, ratees: manquees, tentatives: nb)
            }
            .sorted { gauche, droite in
                if gauche.tauxErreur != droite.tauxErreur {
                    return gauche.tauxErreur > droite.tauxErreur
                }
                if gauche.ratees != droite.ratees { return gauche.ratees > droite.ratees }
                return gauche.note < droite.note
            }
            .prefix(limite)
            .map { $0 }
    }

    /// Progression entre les `taille` dernières séries et les `taille`
    /// précédentes, en points de pourcentage. `nil` tant qu'il n'y a pas
    /// assez de séries pour que la comparaison veuille dire quelque chose.
    ///
    /// `taux` est attendu de la plus récente à la plus ancienne.
    static func progression(taux: [Double], taille: Int = 3) -> Double? {
        guard taux.count >= taille * 2 else { return nil }
        let recentes = taux.prefix(taille)
        let precedentes = taux.dropFirst(taille).prefix(taille)
        let moyenneRecente = recentes.reduce(0, +) / Double(taille)
        let moyennePrecedente = precedentes.reduce(0, +) / Double(taille)
        return (moyenneRecente - moyennePrecedente) * 100
    }
}
