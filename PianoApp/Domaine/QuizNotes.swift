import Foundation

/// Le quiz de lecture : les notes lisibles en clé de sol (Do4 à Fa5),
/// leur position sur la portée et le tirage des questions. Aucun import SwiftUI.

/// Les sept noms de notes naturelles.
enum NomNote: String, CaseIterable {
    case `do` = "Do", re = "Ré", mi = "Mi", fa = "Fa", sol = "Sol", la = "La", si = "Si"
}

/// Une note posée sur la portée en clé de sol.
struct NotePortee: Equatable {
    let nom: NomNote
    let octave: Int

    /// Position diatonique par rapport à Mi4 (ligne du bas = 0) ;
    /// chaque pas monte d'un demi-interligne.
    var position: Int {
        let indice = NomNote.allCases.firstIndex(of: nom) ?? 0
        return indice + (octave - 4) * 7 - 2
    }

    /// Do4 demande une petite ligne supplémentaire sous la portée.
    var ligneSupplementaire: Bool { position <= -2 }

    /// Au-dessus de la ligne du milieu (Si4), la hampe pointe vers le bas.
    var hampeVersLeBas: Bool { position > 4 }

    /// Libellé pédagogique de la position : « 2ᵉ interligne », « 3ᵉ ligne »…
    var libellePosition: String {
        switch position {
        case ..<(-1): return "sur la petite ligne sous la portée"
        case -1: return "suspendu sous la portée"
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
    /// Le périmètre v1 : les notes naturelles de Do4 à Fa5.
    static let notes: [NotePortee] =
        NomNote.allCases.map { NotePortee(nom: $0, octave: 4) }
        + [NotePortee(nom: .do, octave: 5), NotePortee(nom: .re, octave: 5),
           NotePortee(nom: .mi, octave: 5), NotePortee(nom: .fa, octave: 5)]

    static let questionsParSerie = 10

    /// Tire une note au hasard, dont le nom diffère de la précédente
    /// (deux « Do » de suite, même d'octaves différents, feraient douter du tirage).
    static func tirer(differenteDe precedente: NotePortee?,
                      avec generateur: inout some RandomNumberGenerator) -> NotePortee {
        var note = notes.randomElement(using: &generateur) ?? notes[0]
        while note.nom == precedente?.nom {
            note = notes.randomElement(using: &generateur) ?? notes[0]
        }
        return note
    }

    static func tirer(differenteDe precedente: NotePortee?) -> NotePortee {
        var generateur = SystemRandomNumberGenerator()
        return tirer(differenteDe: precedente, avec: &generateur)
    }
}
