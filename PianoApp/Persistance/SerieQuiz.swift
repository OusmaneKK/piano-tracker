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

    @Relationship(deleteRule: .cascade, inverse: \ReponseQuiz.serie)
    var reponses: [ReponseQuiz] = []

    init(date: Date = .now, cleLibelle: String, avecAlterations: Bool,
         score: Int, total: Int) {
        self.date = date
        self.cleLibelle = cleLibelle
        self.avecAlterations = avecAlterations
        self.score = score
        self.total = total
    }

    /// Réussite de la série, de 0 à 1.
    var taux: Double {
        total > 0 ? Double(score) / Double(total) : 0
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
    var serie: SerieQuiz?

    init(note: String, position: Int, juste: Bool) {
        self.note = note
        self.position = position
        self.juste = juste
    }
}
