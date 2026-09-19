import Foundation

/// Le cercle des quintes : les douze tonalités, leurs voisines, et la lecture
/// d'un accord joué — « où suis-je ? ». Aucun import SwiftUI ni SwiftData.
enum CercleDesQuintes {
    /// L'ordre d'écriture des dièses à la clé.
    static let ordreDesDieses: [NomNote] = [.fa, .do, .sol, .re, .la, .mi, .si]
    /// L'ordre d'écriture des bémols — l'exact inverse.
    static let ordreDesBemols: [NomNote] = [.si, .mi, .la, .re, .sol, .do, .fa]

    /// Les douze majeures, dans l'ordre du cercle depuis Do, en tournant par quintes.
    ///
    /// À six altérations il faut choisir une écriture : on retient **Sol♭
    /// majeur** (et donc mi♭ mineur comme relative), parce que mi♭ mineur se
    /// rencontre vraiment alors que ré♯ mineur presque jamais.
    static let majeures: [Tonalite] = [
        Tonalite(NoteEcrite(.do), .majeur),
        Tonalite(NoteEcrite(.sol), .majeur),
        Tonalite(NoteEcrite(.re), .majeur),
        Tonalite(NoteEcrite(.la), .majeur),
        Tonalite(NoteEcrite(.mi), .majeur),
        Tonalite(NoteEcrite(.si), .majeur),
        Tonalite(NoteEcrite(.sol, .bemol), .majeur),
        Tonalite(NoteEcrite(.re, .bemol), .majeur),
        Tonalite(NoteEcrite(.la, .bemol), .majeur),
        Tonalite(NoteEcrite(.mi, .bemol), .majeur),
        Tonalite(NoteEcrite(.si, .bemol), .majeur),
        Tonalite(NoteEcrite(.fa), .majeur),
    ]

    /// Les vingt-quatre tonalités : les douze majeures et leurs relatives.
    static var toutes: [Tonalite] {
        majeures.flatMap { [$0, $0.relative] }
    }

    /// La position d'une tonalité sur le cercle (0 = Do, en haut).
    /// Une mineure occupe la position de sa relative majeure.
    static func index(de tonalite: Tonalite) -> Int? {
        let majeure = tonalite.mode == .majeur ? tonalite : tonalite.relative
        return majeures.firstIndex { $0.tonique == majeure.tonique }
    }

    /// L'angle d'une position, en degrés : 0 = Do en haut, puis sens horaire.
    static func angle(index: Int) -> Double {
        Double(index) * 30 - 90
    }

    /// Les tonalités voisines : une quinte au-dessus, une quinte en dessous,
    /// et la relative. Ce sont celles qui partagent le plus de notes — d'où la
    /// facilité à passer de l'une à l'autre.
    static func voisines(de tonalite: Tonalite) -> [Tonalite] {
        guard let position = index(de: tonalite) else { return [] }
        let majeure = tonalite.mode == .majeur ? tonalite : tonalite.relative
        return [majeures[(position + 1) % 12],
                majeures[(position + 11) % 12],
                majeure.relative == tonalite ? majeure : tonalite.relative]
    }

    /// Où un accord se situe : une tonalité qui le contient, et le degré qu'il y occupe.
    struct Place: Hashable {
        let tonalite: Tonalite
        let degre: Degre

        /// L'accord est le premier degré : c'est là qu'il est « chez lui ».
        var estFoyer: Bool { degre.rang == 1 }
    }

    /// Toutes les tonalités qui contiennent cet accord, avec son degré dans chacune.
    ///
    /// Un accord n'appartient jamais à une seule tonalité — Do majeur est le I
    /// de Do, le IV de Sol et le V de Fa — et c'est précisément ce que le cercle
    /// sert à montrer.
    static func placesDe(_ accord: Accord) -> [Place] {
        toutes.flatMap { tonalite in
            tonalite.degres
                .filter { $0.accord.touches == accord.touches }
                .map { Place(tonalite: tonalite, degre: $0) }
        }
    }

    /// L'accord formé par ces touches, nommé dans son orthographe la plus
    /// naturelle : celle de la tonalité où il est le premier degré.
    /// `nil` si les touches ne forment pas une triade du système tonal.
    static func accord(pour touches: Set<Touche>) -> Accord? {
        guard touches.count == 3 else { return nil }
        let candidats = toutes.flatMap(\.degres).filter { $0.accord.touches == touches }
        // Le degré I donne la fondamentale juste ; à défaut, n'importe quel
        // degré porte les mêmes touches, seule l'orthographe diffère.
        return (candidats.first { $0.rang == 1 } ?? candidats.first)?.accord
    }
}

/// Les comparaisons entre ce qui est joué et ce qui est attendu.
enum Harmonie {
    /// L'accord est-il joué ? Renversements et doublures d'octave acceptés
    /// (on compare des touches, qui ignorent l'octave), mais **une note en
    /// trop invalide** : sinon poser toute la gamme validerait tout.
    static func correspond(touches: Set<Touche>, a accord: Accord) -> Bool {
        touches == accord.touches
    }

    /// Part des notes jouées qui appartiennent à la gamme. `nil` sans note —
    /// pas 0 %, qui laisserait croire qu'on a tout raté.
    static func tauxDansLaGamme(touches: [Touche], gamme: Set<Touche>) -> Double? {
        guard !touches.isEmpty else { return nil }
        let dedans = touches.filter { gamme.contains($0) }.count
        return Double(dedans) / Double(touches.count)
    }

    /// Les degrés les plus joués, pour le bilan d'improvisation. Les notes hors
    /// gamme sont ignorées. À égalité, l'ordre des degrés départage, pour que
    /// l'affichage ne saute pas d'une consultation à l'autre.
    static func degresLesPlusJoues(touches: [Touche], tonalite: Tonalite,
                                   limite: Int = 3) -> [(degre: Int, occurrences: Int)] {
        let gamme = tonalite.gamme
        var comptes: [Int: Int] = [:]
        for touche in touches {
            if let rang = gamme.firstIndex(where: { $0.touche == touche }) {
                comptes[rang + 1, default: 0] += 1
            }
        }
        return comptes
            .sorted { gauche, droite in
                gauche.value != droite.value ? gauche.value > droite.value
                                             : gauche.key < droite.key
            }
            .prefix(limite)
            .map { (degre: $0.key, occurrences: $0.value) }
    }
}
