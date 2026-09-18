import Foundation
import Observation

/// Le déroulé d'une série de quiz : question, réponse, avance automatique, fin.
@Observable
final class QuizViewModel {
    enum Phase: Equatable {
        case question
        case repondu(choix: NomNote, juste: Bool)
        case termine
    }

    private(set) var note: NotePortee
    private(set) var numero = 1
    private(set) var score = 0
    private(set) var phase: Phase = .question

    init() {
        note = QuizNotes.tirer(differenteDe: nil)
    }

    var estRepondu: Bool {
        if case .repondu = phase { return true }
        return false
    }

    func repondre(_ choix: NomNote) {
        guard phase == .question else { return }
        let juste = choix == note.nom
        if juste { score += 1 }
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
        note = QuizNotes.tirer(differenteDe: note)
        phase = .question
    }

    private func avancer() {
        guard estRepondu else { return }
        guard numero < QuizNotes.questionsParSerie else {
            phase = .termine
            return
        }
        numero += 1
        note = QuizNotes.tirer(differenteDe: note)
        phase = .question
    }
}
