import Foundation
import WidgetKit

/// Le pont app → widget : construire le résumé depuis les sessions, le déposer
/// dans le trousseau partagé et demander au widget de se rafraîchir.
extension ResumePratique {
    static func depuis(sessions: [SessionPratique], profil: Profil?,
                       maintenant: Date = .now, calendrier: Calendar = .current) -> ResumePratique {
        let minutes = sessions
            .filter { calendrier.isDate($0.date, inSameDayAs: maintenant) }
            .reduce(0) { $0 + $1.dureeSecondes } / 60
        let heures = Double(sessions.reduce(0) { $0 + $1.dureeSecondes }) / 3600
        return ResumePratique(
            minutesAujourdhui: minutes,
            objectifQuotidienMinutes: profil?.objectifQuotidienMinutes ?? 60,
            serie: Progression.serie(joursDePratique: sessions.map(\.date),
                                     aujourdHui: maintenant, calendrier: calendrier),
            heuresTotales: heures,
            ecritLe: maintenant
        )
    }

    /// Dépose le résumé pour le widget et lui demande de se redessiner.
    static func publier(sessions: [SessionPratique], profil: Profil?) {
        PartageResume.ecrire(depuis(sessions: sessions, profil: profil))
        WidgetCenter.shared.reloadAllTimelines()
    }
}
