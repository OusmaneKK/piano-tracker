import Foundation

/// Le comptage automatique : à partir des notes entendues sur le clavier,
/// décider quand la session s'arrête d'elle-même. Aucun import SwiftUI.
enum SuiviMIDI {
    /// Silence au-delà duquel la session se met en pause. Deux minutes laissent
    /// le temps de tourner une page ou de chercher un doigté, sans gonfler le
    /// compteur quand on a quitté le piano.
    static let silenceAvantPause: TimeInterval = 120

    /// La session doit-elle se mettre en pause, faute de notes depuis assez longtemps ?
    static func doitMettreEnPause(derniereNote: Date?, maintenant: Date = .now) -> Bool {
        guard let derniereNote else { return false }
        return maintenant.timeIntervalSince(derniereNote) >= silenceAvantPause
    }

    /// La date à laquelle arrêter le décompte : la dernière note entendue,
    /// pour que le silence qui a suivi ne soit pas compté comme de la pratique.
    static func dateDePause(derniereNote: Date?, maintenant: Date = .now) -> Date {
        derniereNote ?? maintenant
    }
}
