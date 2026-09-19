import Foundation

/// L'harmonie tonale : notes écrites, accords, degrés, tonalités.
/// Aucun import SwiftUI ni SwiftData.
///
/// Règle d'or de ce fichier : **le nom sert à l'écriture, la classe de hauteur
/// sert à la comparaison**. Fa majeur porte un Si♭ et jamais un La♯, mais un
/// La♯ joué au clavier valide bien un Si♭ écrit — parce qu'on ne compare
/// jamais deux notes par leur nom.

extension NomNote {
    /// Demi-tons depuis Do dans l'octave : do 0, ré 2, mi 4, fa 5, sol 7, la 9, si 11.
    var demiTons: Int {
        switch self {
        case .do: 0
        case .re: 2
        case .mi: 4
        case .fa: 5
        case .sol: 7
        case .la: 9
        case .si: 11
        }
    }

    /// Position sur la ligne des quintes : Fa −1, Do 0, Sol 1, Ré 2, La 3, Mi 4, Si 5.
    /// C'est ce qui donne l'armure d'une tonalité sans aucune table codée en dur.
    var indiceDeQuinte: Int {
        switch self {
        case .fa: -1
        case .do: 0
        case .sol: 1
        case .re: 2
        case .la: 3
        case .mi: 4
        case .si: 5
        }
    }
}

extension Alteration {
    /// Ce que l'altération ajoute en demi-tons.
    var demiTons: Int {
        switch self {
        case .naturelle: 0
        case .diese: 1
        case .bemol: -1
        }
    }
}

/// Une note écrite : un nom diatonique et son altération.
struct NoteEcrite: Hashable {
    let nom: NomNote
    let alteration: Alteration

    init(_ nom: NomNote, _ alteration: Alteration = .naturelle) {
        self.nom = nom
        self.alteration = alteration
    }

    /// Le demi-ton dans l'octave (0 = Do), indépendant de l'orthographe.
    /// Do♭ vaut 11, Mi♯ vaut 5 — deux noms pour une seule touche.
    var classeDeHauteur: Int {
        (nom.demiTons + alteration.demiTons + 12) % 12
    }

    /// La touche du clavier qui la produit. Passe par la classe de hauteur,
    /// donc Do♭ donne bien la touche blanche Si.
    var touche: Touche {
        Touche.depuisNoteMIDI(UInt8(classeDeHauteur))
    }

    /// « Si♭ », « Fa♯ », « Mi ».
    var libelle: String { nom.rawValue + alteration.rawValue }
}

/// La qualité d'une triade.
enum QualiteAccord: Hashable {
    case majeur, mineur, diminue

    /// Le suffixe du nom d'accord : « Fa », « Ré m », « Mi° ».
    var suffixe: String {
        switch self {
        case .majeur: ""
        case .mineur: " m"
        case .diminue: "°"
        }
    }

    /// La qualité déduite des intervalles, en demi-tons depuis la fondamentale.
    /// Les gammes majeure et mineure naturelle ne produisent que ces trois-là.
    static func depuis(tierce: Int, quinte: Int) -> QualiteAccord {
        switch (tierce, quinte) {
        case (3, 6): .diminue
        case (3, 7): .mineur
        default: .majeur
        }
    }
}

/// Une triade : fondamentale, tierce, quinte, dans l'orthographe de sa gamme.
struct Accord: Hashable {
    let notes: [NoteEcrite]

    var fondamentale: NoteEcrite { notes[0] }

    var qualite: QualiteAccord {
        let tierce = (notes[1].classeDeHauteur - notes[0].classeDeHauteur + 12) % 12
        let quinte = (notes[2].classeDeHauteur - notes[0].classeDeHauteur + 12) % 12
        return .depuis(tierce: tierce, quinte: quinte)
    }

    /// « Si♭ », « Ré m », « Mi° ».
    var libelle: String { fondamentale.libelle + qualite.suffixe }

    /// Ce qu'on compare au clavier. Comme `Touche` ignore l'octave, les
    /// renversements et les doublures passent gratuitement.
    var touches: Set<Touche> { Set(notes.map(\.touche)) }
}

/// Un degré de la gamme et l'accord qui s'y bâtit.
struct Degre: Identifiable, Hashable {
    let rang: Int          // 1…7
    let accord: Accord

    var id: Int { rang }

    private static let romains = ["I", "II", "III", "IV", "V", "VI", "VII"]

    /// « I », « ii », « vii° » — la casse dit la qualité, comme en analyse.
    var chiffrage: String {
        let base = Self.romains[rang - 1]
        switch accord.qualite {
        case .majeur: return base
        case .mineur: return base.lowercased()
        case .diminue: return base.lowercased() + "°"
        }
    }

    /// La fonction tonale, pour les trois piliers seulement.
    var fonction: String? {
        switch rang {
        case 1: "tonique"
        case 4: "sous-dominante"
        case 5: "dominante"
        default: nil
        }
    }
}

/// Majeur, ou mineur **naturel** (voir CLAUDE.md : le mineur harmonique
/// demanderait des doubles dièses que `Alteration` ne sait pas écrire).
enum ModeTonal: Hashable {
    case majeur, mineur
}

/// Une tonalité : une tonique écrite et un mode. Tout le reste en découle.
struct Tonalite: Hashable, Identifiable {
    let tonique: NoteEcrite
    let mode: ModeTonal

    init(_ tonique: NoteEcrite, _ mode: ModeTonal) {
        self.tonique = tonique
        self.mode = mode
    }

    var id: String { libelle }

    /// « Fa majeur », « ré mineur » — minuscule au mineur, convention d'analyse.
    var libelle: String {
        switch mode {
        case .majeur: "\(tonique.libelle) majeur"
        case .mineur: "\(tonique.libelle.lowercased()) mineur"
        }
    }

    /// Nombre d'altérations à la clé, **signé** : +2 = deux dièses, −3 = trois bémols.
    /// La ligne des quintes donne le résultat sans table : chaque dièse vaut
    /// sept quintes vers le haut, chaque bémol sept vers le bas, et une mineure
    /// partage l'armure de sa relative, trois quintes plus bas.
    var nbAlterations: Int {
        tonique.nom.indiceDeQuinte
            + 7 * tonique.alteration.demiTons
            + (mode == .mineur ? -3 : 0)
    }

    /// L'armure dite en toutes lettres : « 1 bémol · Si♭ », « 2 dièses · Fa♯ Do♯ »,
    /// « aucune altération ».
    var armureTexte: String {
        let notes = armure
        guard !notes.isEmpty else { return "aucune altération" }
        let nombre = abs(nbAlterations)
        let nom = nbAlterations > 0 ? "dièse" : "bémol"
        return "\(nombre) \(nom)\(nombre > 1 ? "s" : "") · "
            + notes.map(\.libelle).joined(separator: " ")
    }

    /// L'armure dans l'ordre d'écriture : Fa♯ Do♯ Sol♯… ou Si♭ Mi♭ La♭…
    var armure: [NoteEcrite] {
        guard nbAlterations != 0 else { return [] }
        let ordre = nbAlterations > 0 ? CercleDesQuintes.ordreDesDieses
                                      : CercleDesQuintes.ordreDesBemols
        let alteration: Alteration = nbAlterations > 0 ? .diese : .bemol
        return ordre.prefix(abs(nbAlterations)).map { NoteEcrite($0, alteration) }
    }

    /// Les sept notes de la gamme, tonique d'abord, orthographe correcte :
    /// les sept noms successifs depuis la tonique, chacun altéré si l'armure
    /// le demande. Fa majeur donne Si♭ ; Sol♭ majeur donne Do♭.
    var gamme: [NoteEcrite] {
        let alterees = Dictionary(uniqueKeysWithValues: armure.map { ($0.nom, $0.alteration) })
        var notes: [NoteEcrite] = []
        var nom = tonique.nom
        for _ in 0..<7 {
            notes.append(NoteEcrite(nom, alterees[nom] ?? .naturelle))
            nom = nom.suivante
        }
        return notes
    }

    /// La gamme en touches de clavier — ce qu'on compare au MIDI.
    var touches: Set<Touche> { Set(gamme.map(\.touche)) }

    /// Les sept degrés. La triade du degré `r` empile les degrés r, r+2 et r+4
    /// de la gamme : l'orthographe de la tierce et de la quinte suit donc
    /// automatiquement celle de la gamme.
    var degres: [Degre] {
        let g = gamme
        return (1...7).map { rang in
            Degre(rang: rang,
                  accord: Accord(notes: [g[(rang - 1) % 7],
                                         g[(rang + 1) % 7],
                                         g[(rang + 3) % 7]]))
        }
    }

    /// La relative : même armure, mode opposé.
    var relative: Tonalite {
        switch mode {
        case .majeur: Tonalite(gamme[5], .mineur)   // 6ᵉ degré
        case .mineur: Tonalite(gamme[2], .majeur)   // 3ᵉ degré
        }
    }

    /// La cadence de l'exercice : I – IV – V – I (i – iv – v – i en mineur naturel).
    var cadence: [Degre] {
        let d = degres
        return [d[0], d[3], d[4], d[0]]
    }
}
