import Foundation

/// Un palier de la route de lecture : un sous-ensemble de notes à apprendre
/// avant d'ouvrir le suivant.
struct Palier: Identifiable, Equatable {
    let numero: Int
    let nom: String
    let sousTitre: String
    let cles: [Cle]
    /// Positions autorisées sur la portée (0 = ligne du bas).
    let positions: Set<Int>
    let avecAlterations: Bool

    var id: Int { numero }
}

/// La route de lecture : les paliers, leur ouverture, leur maîtrise.
/// Aucun import SwiftUI ni SwiftData.
enum RouteLecture {
    /// Score qui ouvre le palier suivant. Une seule fois suffit : bloquer la
    /// progression décourage, ce n'est pas le rôle d'un palier.
    static let scorePourOuvrir = 9

    /// Un palier est « maîtrisé » à 10/10 **et** sous ce temps moyen par note.
    /// C'est là que la vitesse de lecture compte — pas dans la progression.
    static let secondesPourMaitrise: Double = 3

    private static let lignes: Set<Int> = [0, 2, 4, 6, 8]
    private static let interlignes: Set<Int> = [1, 3, 5, 7]
    /// Clé de sol : de Do4 (petite ligne dessous) à Fa5.
    private static let touteLaCleDeSol = Set(-2...8)
    /// Clé de fa : de Sol2 à Do4 (petite ligne au-dessus).
    private static let touteLaCleDeFa = Set(0...10)

    static let paliers: [Palier] = [
        Palier(numero: 1, nom: "Les cinq lignes",
               sousTitre: "Mi, Sol, Si, Ré, Fa — les notes posées sur les lignes",
               cles: [.sol], positions: lignes, avecAlterations: false),
        Palier(numero: 2, nom: "Les interlignes",
               sousTitre: "Fa, La, Do, Mi — les notes entre les lignes",
               cles: [.sol], positions: interlignes, avecAlterations: false),
        Palier(numero: 3, nom: "Toute la clé de sol",
               sousTitre: "Les deux mêlées, et le Do central sous la portée",
               cles: [.sol], positions: touteLaCleDeSol, avecAlterations: false),
        Palier(numero: 4, nom: "Les lignes de la clé de fa",
               sousTitre: "La main gauche commence — Sol, Si, Ré, Fa, La",
               cles: [.fa], positions: lignes, avecAlterations: false),
        Palier(numero: 5, nom: "Toute la clé de fa",
               sousTitre: "Lignes, interlignes, et le Do central au-dessus",
               cles: [.fa], positions: touteLaCleDeFa, avecAlterations: false),
        Palier(numero: 6, nom: "Les altérations",
               sousTitre: "Dièses et bémols — les touches noires entrent en jeu",
               cles: [.sol, .fa], positions: touteLaCleDeSol.union(touteLaCleDeFa),
               avecAlterations: true),
        Palier(numero: 7, nom: "Les deux mains",
               sousTitre: "Les deux clés mêlées, comme sur une vraie partition",
               cles: [.sol, .fa], positions: touteLaCleDeSol.union(touteLaCleDeFa),
               avecAlterations: true),
    ]

    static func palier(numero: Int) -> Palier? {
        paliers.first { $0.numero == numero }
    }

    /// Les notes que ce palier peut tirer.
    static func notes(du palier: Palier) -> [NotePortee] {
        palier.cles
            .flatMap { QuizNotes.notes(cle: $0) }
            .filter { palier.positions.contains($0.position) }
    }

    /// Le palier est-il ouvert ? Le premier l'est toujours ; les suivants
    /// demandent `scorePourOuvrir` sur le palier précédent.
    /// `meilleursScores` associe un numéro de palier à son meilleur score.
    static func estOuvert(_ palier: Palier, meilleursScores: [Int: Int]) -> Bool {
        guard palier.numero > 1 else { return true }
        return (meilleursScores[palier.numero - 1] ?? 0) >= scorePourOuvrir
    }

    /// Le palier à travailler : le premier ouvert qui n'est pas encore acquis,
    /// ou le dernier palier quand toute la route est parcourue.
    static func palierEnCours(meilleursScores: [Int: Int]) -> Palier {
        paliers.first {
            estOuvert($0, meilleursScores: meilleursScores)
                && (meilleursScores[$0.numero] ?? 0) < scorePourOuvrir
        } ?? paliers[paliers.count - 1]
    }

    /// Le palier suivant, s'il existe.
    static func suivant(_ palier: Palier) -> Palier? {
        self.palier(numero: palier.numero + 1)
    }

    /// Une série sans faute et assez rapide vaut la maîtrise du palier.
    static func estMaitrise(score: Int, total: Int, tempsMoyen: Double?) -> Bool {
        guard total > 0, score == total, let tempsMoyen else { return false }
        return tempsMoyen <= secondesPourMaitrise
    }

    /// Cette série vient-elle d'ouvrir le palier suivant ?
    /// (Le score est atteint pour la première fois.)
    static func ouvreLeSuivant(palier: Palier, score: Int,
                               meilleurScorePrecedent: Int) -> Bool {
        suivant(palier) != nil
            && score >= scorePourOuvrir
            && meilleurScorePrecedent < scorePourOuvrir
    }
}
