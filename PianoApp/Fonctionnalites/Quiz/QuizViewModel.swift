import Foundation
import Observation

/// Le déroulé d'une série de quiz : question, réponse, avance automatique, fin.
@Observable
final class QuizViewModel {
    enum Phase: Equatable {
        case question
        case repondu(choix: Touche, juste: Bool)
        case termine
    }

    let cle: Cle
    let avecAlterations: Bool

    private(set) var note: NotePortee
    private(set) var numero = 1
    private(set) var score = 0
    private(set) var phase: Phase = .question
    /// Les réponses de la série en cours, enregistrées une fois la série finie.
    private(set) var reponses: [(note: NotePortee, juste: Bool)] = []

    init(cle: Cle, avecAlterations: Bool) {
        self.cle = cle
        self.avecAlterations = avecAlterations
        note = QuizNotes.tirer(cle: cle, avecAlterations: avecAlterations, differenteDe: nil)
    }

    var estRepondu: Bool {
        if case .repondu = phase { return true }
        return false
    }

    func repondre(_ choix: Touche) {
        guard phase == .question else { return }
        let juste = choix == note.toucheAttendue
        if juste { score += 1 }
        reponses.append((note: note, juste: juste))
        phase = .repondu(choix: choix, juste: juste)
        // La lecture du bandeau demande un peu plus de temps après une erreur.
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(juste ? 1.1 : 1.8))
            self?.avancer()
        }
    }

    func rejouer() {
        score = 0
        numero = 1
        reponses = []
        note = QuizNotes.tirer(cle: cle, avecAlterations: avecAlterations, differenteDe: note)
        phase = .question
    }

    private func avancer() {
        guard estRepondu else { return }
        guard numero < QuizNotes.questionsParSerie else {
            phase = .termine
            return
        }
        numero += 1
        note = QuizNotes.tirer(cle: cle, avecAlterations: avecAlterations, differenteDe: note)
        phase = .question
    }
}
