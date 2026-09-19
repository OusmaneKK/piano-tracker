import Foundation
import SwiftData

/// Une série de quiz terminée. Les séries abandonnées ne sont pas enregistrées :
/// un score partiel ne dirait rien de la progression.
@Model
final class SerieQuiz {
    var date: Date
    /// La clé lue, sous forme de texte (les enums ne sont pas persistés tels quels).
    var cleLibelle: String
    var avecAlterations: Bool
    var score: Int
    var total: Int
    /// Le palier joué. Optionnel : les séries d'avant la route de lecture
    /// n'en portent pas (migration légère).
    var palierNumero: Int?
    /// Temps moyen par note, en secondes. Optionnel pour la même raison.
    var tempsMoyenSecondes: Double?

    @Relationship(deleteRule: .cascade, inverse: \ReponseQuiz.serie)
    var reponses: [ReponseQuiz] = []

    init(date: Date = .now, cleLibelle: String, avecAlterations: Bool,
         score: Int, total: Int, palierNumero: Int? = nil,
         tempsMoyenSecondes: Double? = nil) {
        self.date = date
        self.cleLibelle = cleLibelle
        self.avecAlterations = avecAlterations
        self.score = score
        self.total = total
        self.palierNumero = palierNumero
        self.tempsMoyenSecondes = tempsMoyenSecondes
    }

    /// Réussite de la série, de 0 à 1.
    var taux: Double {
        total > 0 ? Double(score) / Double(total) : 0
    }

    /// Série sans faute et assez rapide.
    var estMaitrise: Bool {
        RouteLecture.estMaitrise(score: score, total: total,
                                 tempsMoyen: tempsMoyenSecondes)
    }
}

/// Une réponse à une question : la note affichée et si elle a été trouvée.
@Model
final class ReponseQuiz {
    /// Le nom complet avec son altération, ex. « La♭ ».
    var note: String
    /// La position sur la portée, pour reparler du lieu (« 2ᵉ interligne »).
    var position: Int
    var juste: Bool
    /// Temps de réponse en secondes. Optionnel : avant le chrono, il n'existait pas.
    var secondes: Double?
    var serie: SerieQuiz?

    init(note: String, position: Int, juste: Bool, secondes: Double? = nil) {
        self.note = note
        self.position = position
        self.juste = juste
        self.secondes = secondes
    }
}
