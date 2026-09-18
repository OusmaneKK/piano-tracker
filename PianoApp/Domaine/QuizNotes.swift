import Foundation

/// Le quiz de lecture : notes en clé de sol et clé de fa, altérations,
/// position sur la portée et tirage des questions. Aucun import SwiftUI.

/// Les sept noms de notes naturelles.
enum NomNote: String, CaseIterable {
    case `do` = "Do", re = "Ré", mi = "Mi", fa = "Fa", sol = "Sol", la = "La", si = "Si"

    /// Le nom précédent dans l'ordre diatonique (Do → Si).
    var precedente: NomNote {
        let indice = Self.allCases.firstIndex(of: self) ?? 0
        return Self.allCases[(indice + 6) % 7]
    }
}

/// Les deux clés lues par le quiz.
enum Cle: CaseIterable {
    case sol, fa

    var libelle: String {
        switch self {
        case .sol: "Clé de sol"
        case .fa: "Clé de fa"
        }
    }
}

/// L'altération portée par la note.
enum Alteration: String {
    case naturelle = ""
    case diese = "♯"
    case bemol = "♭"
}

/// Une touche de l'octave du clavier de réponse.
enum Touche: Equatable, Hashable {
    case blanche(NomNote)
    /// La touche noire à droite de la touche blanche donnée (Do♯/Ré♭ = noire(entre: .do)).
    case noire(entre: NomNote)
}

/// Une note posée sur une portée.
struct NotePortee: Equatable {
    let nom: NomNote
    let octave: Int
    let cle: Cle
    let alteration: Alteration

    init(nom: NomNote, octave: Int, cle: Cle = .sol, alteration: Alteration = .naturelle) {
        self.nom = nom
        self.octave = octave
        self.cle = cle
        self.alteration = alteration
    }

    private var indiceDiatonique: Int {
        (NomNote.allCases.firstIndex(of: nom) ?? 0) + octave * 7
    }

    /// Position diatonique par rapport à la ligne du bas de la portée
    /// (Mi4 en clé de sol, Sol2 en clé de fa) ; chaque pas monte d'un demi-interligne.
    var position: Int {
        let base = cle == .sol ? 2 + 4 * 7 : 4 + 2 * 7
        return indiceDiatonique - base
    }

    /// Petite ligne supplémentaire sous la portée (Do4 en clé de sol).
    var ligneSupplementaireBas: Bool { position <= -2 }

    /// Petite ligne supplémentaire au-dessus (Do4 en clé de fa).
    var ligneSupplementaireHaut: Bool { position >= 10 }

    /// Au-dessus de la ligne du milieu, la hampe pointe vers le bas.
    var hampeVersLeBas: Bool { position > 4 }

    /// « Sol♯ », « La♭ », « Mi »…
    var nomComplet: String { nom.rawValue + alteration.rawValue }

    /// La touche du clavier qui répond juste à cette note.
    var toucheAttendue: Touche {
        switch alteration {
        case .naturelle: .blanche(nom)
        case .diese: .noire(entre: nom)
        case .bemol: .noire(entre: nom.precedente)
        }
    }

    /// Libellé pédagogique de la position : « 2ᵉ interligne », « 3ᵉ ligne »…
    var libellePosition: String {
        switch position {
        case ..<(-1): return "sur la petite ligne sous la portée"
        case -1: return "suspendu sous la portée"
        case 10...: return "sur la petite ligne au-dessus de la portée"
        case 9: return "posé au-dessus de la portée"
        case let p where p.isMultiple(of: 2):
            let numero = p / 2 + 1
            return numero == 1 ? "1ʳᵉ ligne" : "\(numero)ᵉ ligne"
        case let p:
            let numero = (p + 1) / 2
            return numero == 1 ? "1ᵉʳ interligne" : "\(numero)ᵉ interligne"
        }
    }
}

enum QuizNotes {
    /// Les noms pouvant porter un dièse (la touche noire à leur droite existe).
    static let nomsDiese: Set<NomNote> = [.do, .re, .fa, .sol, .la]
    /// Les noms pouvant porter un bémol (la touche noire à leur gauche existe).
    static let nomsBemol: Set<NomNote> = [.re, .mi, .sol, .la, .si]

    static let questionsParSerie = 10

    /// Les notes naturelles lisibles : Do4–Fa5 en clé de sol (le Do central
    /// sous la portée), Sol2–Do4 en clé de fa (le Do central au-dessus).
    static func notes(cle: Cle) -> [NotePortee] {
        switch cle {
        case .sol:
            NomNote.allCases.map { NotePortee(nom: $0, octave: 4) }
            + [NotePortee(nom: .do, octave: 5), NotePortee(nom: .re, octave: 5),
               NotePortee(nom: .mi, octave: 5), NotePortee(nom: .fa, octave: 5)]
        case .fa:
            [NotePortee(nom: .sol, octave: 2, cle: .fa), NotePortee(nom: .la, octave: 2, cle: .fa),
             NotePortee(nom: .si, octave: 2, cle: .fa)]
            + NomNote.allCases.map { NotePortee(nom: $0, octave: 3, cle: .fa) }
            + [NotePortee(nom: .do, octave: 4, cle: .fa)]
        }
    }

    /// Tire une note au hasard : environ une sur trois porte une altération
    /// quand elles sont activées, et deux questions de suite ne partagent
    /// jamais le même nom complet.
    static func tirer(cle: Cle, avecAlterations: Bool,
                      differenteDe precedente: NotePortee?,
                      avec generateur: inout some RandomNumberGenerator) -> NotePortee {
        let naturelles = notes(cle: cle)
        while true {
            guard let base = naturelles.randomElement(using: &generateur) else {
                return NotePortee(nom: .do, octave: 4, cle: cle)
            }
            var note = base
            if avecAlterations, Int.random(in: 0..<3, using: &generateur) == 0 {
                if Bool.random(using: &generateur), nomsDiese.contains(base.nom) {
                    note = NotePortee(nom: base.nom, octave: base.octave, cle: cle, alteration: .diese)
                } else if nomsBemol.contains(base.nom) {
                    note = NotePortee(nom: base.nom, octave: base.octave, cle: cle, alteration: .bemol)
                }
            }
            if note.nomComplet != precedente?.nomComplet { return note }
        }
    }

    static func tirer(cle: Cle, avecAlterations: Bool,
                      differenteDe precedente: NotePortee?) -> NotePortee {
        var generateur = SystemRandomNumberGenerator()
        return tirer(cle: cle, avecAlterations: avecAlterations,
                     differenteDe: precedente, avec: &generateur)
    }
}
