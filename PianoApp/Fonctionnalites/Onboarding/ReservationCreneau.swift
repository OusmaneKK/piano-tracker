import SwiftUI
import EventKitUI

/// Fiche système de création d'événement, pré-remplie avec le créneau quotidien.
/// Sur iOS 17+, cette fiche ne demande aucune permission d'accès au calendrier :
/// l'utilisateur valide, modifie ou annule dans l'interface d'Apple.
/// On n'écrit rien nous-mêmes — pas de lecture d'agenda, pas de replanification.
struct EditeurCreneauAgenda: UIViewControllerRepresentable {
    /// L'heure quotidienne choisie (seuls l'heure et les minutes comptent).
    let heure: Date
    let dureeMinutes: Int
    /// Appelé à la fermeture de la fiche ; `true` si l'événement a été enregistré.
    var terminer: (Bool) -> Void

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let magasin = EKEventStore()
        let evenement = EKEvent(eventStore: magasin)
        evenement.title = "Piano — session quotidienne"
        evenement.notes = "Réservé depuis Ostinato. Même heure, même geste, chaque jour."
        evenement.startDate = Self.prochaineOccurrence(de: heure)
        evenement.endDate = evenement.startDate.addingTimeInterval(Double(max(dureeMinutes, 15)) * 60)
        evenement.addRecurrenceRule(EKRecurrenceRule(recurrenceWith: .daily, interval: 1, end: nil))

        let controleur = EKEventEditViewController()
        controleur.eventStore = magasin
        controleur.event = evenement
        controleur.editViewDelegate = context.coordinator
        return controleur
    }

    func updateUIViewController(_ controleur: EKEventEditViewController, context: Context) {}

    func makeCoordinator() -> Coordinateur { Coordinateur(terminer: terminer) }

    /// La prochaine occurrence de l'heure choisie : aujourd'hui si elle est à venir, sinon demain.
    static func prochaineOccurrence(de heure: Date,
                                    apres reference: Date = .now,
                                    calendrier: Calendar = .current) -> Date {
        let composantes = calendrier.dateComponents([.hour, .minute], from: heure)
        return calendrier.nextDate(after: reference, matching: composantes,
                                   matchingPolicy: .nextTime) ?? reference
    }

    final class Coordinateur: NSObject, EKEventEditViewDelegate {
        let terminer: (Bool) -> Void

        init(terminer: @escaping (Bool) -> Void) {
            self.terminer = terminer
        }

        func eventEditViewController(_ controleur: EKEventEditViewController,
                                     didCompleteWith action: EKEventEditViewAction) {
            terminer(action == .saved)
        }
    }
}
