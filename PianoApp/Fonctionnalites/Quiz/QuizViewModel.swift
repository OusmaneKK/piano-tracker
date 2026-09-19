import Foundation
import Observation

/// Le déroulé d'une série de quiz : question, réponse, avance automatique, fin.
/// Le chrono mesure chaque réponse sans jamais la sanctionner : une bonne
/// réponse lente reste juste, le temps est une mesure à part.
@Observable
final class QuizViewModel {
    enum Phase: Equatable {
        case question
        case repondu(choix: Touche, juste: Bool)
        case termine
    }

    /// Une réponse donnée, avec le temps qu'elle a demandé.
    struct Reponse {
        let note: NotePortee
        let juste: Bool
        let secondes: Double
    }

    let palier: Palier

    private(set) var note: NotePortee
    private(set) var numero = 1
    private(set) var score = 0
    private(set) var phase: Phase = .question
    private(set) var reponses: [Reponse] = []
    /// Bonnes réponses consécutives dans la série en cours.
    private(set) var serieEnCours = 0
    /// Secondes écoulées sur la question affichée (rafraîchi par la vue).
    private(set) var secondesQuestion: Double = 0

    /// Durée au-delà de laquelle la barre de chrono est pleine : repère
    /// visuel, sans conséquence sur le score.
    let secondesRepere: Double = 6

    @ObservationIgnored private var debutQuestion = Date.now

    init(palier: Palier) {
        self.palier = palier
        note = QuizNotes.tirer(palier: palier, differenteDe: nil)
    }

    var estRepondu: Bool {
        if case .repondu = phase { return true }
        return false
    }

    /// Part du repère écoulée, bornée à 1 (pour la barre de chrono).
    var fractionChrono: Double {
        min(secondesQuestion / secondesRepere, 1)
    }

    /// Temps moyen par note sur la série, `nil` sans réponse.
    var tempsMoyen: Double? {
        guard !reponses.isEmpty else { return nil }
        return reponses.reduce(0) { $0 + $1.secondes } / Double(reponses.count)
    }

    /// La meilleure série de bonnes réponses d'affilée.
    var meilleureSerie: Int {
        var meilleure = 0
        var courante = 0
        for reponse in reponses {
            courante = reponse.juste ? courante + 1 : 0
            meilleure = max(meilleure, courante)
        }
        return meilleure
    }

    /// La note qui a demandé le plus de temps, pour la fin de série.
    var noteLaPlusLente: Reponse? {
        reponses.max { $0.secondes < $1.secondes }
    }

    /// Rafraîchit l'affichage du chrono (appelé chaque fraction de seconde).
    func tic() {
        guard phase == .question else { return }
        secondesQuestion = Date.now.timeIntervalSince(debutQuestion)
    }

    func repondre(_ choix: Touche) {
        guard phase == .question else { return }
        let secondes = Date.now.timeIntervalSince(debutQuestion)
        let juste = choix == note.toucheAttendue
        if juste {
            score += 1
            serieEnCours += 1
        } else {
            serieEnCours = 0
        }
        reponses.append(Reponse(note: note, juste: juste, secondes: secondes))
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
        serieEnCours = 0
        note = QuizNotes.tirer(palier: palier, differenteDe: note)
        nouvelleQuestion()
    }

    private func avancer() {
        guard estRepondu else { return }
        guard numero < QuizNotes.questionsParSerie else {
            phase = .termine
            return
        }
        numero += 1
        note = QuizNotes.tirer(palier: palier, differenteDe: note)
        nouvelleQuestion()
    }

    private func nouvelleQuestion() {
        debutQuestion = .now
        secondesQuestion = 0
        phase = .question
    }
}
