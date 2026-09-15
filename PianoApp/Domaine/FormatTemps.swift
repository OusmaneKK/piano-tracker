import Foundation

/// Formatage du temps pour l'affichage. Aucun import SwiftUI.
enum FormatTemps {
    /// « 04:32 » à partir d'un nombre de secondes (les valeurs négatives donnent « 00:00 »).
    static func minutesSecondes(_ secondes: Int) -> String {
        let s = max(secondes, 0)
        return String(format: "%02d:%02d", s / 60, s % 60)
    }

    /// Heures entières localisées en français, ex. 10 000.
    static func heuresEntieres(_ heures: Double) -> String {
        let formateur = NumberFormatter()
        formateur.numberStyle = .decimal
        formateur.maximumFractionDigits = 0
        formateur.locale = Locale(identifier: "fr_FR")
        return formateur.string(from: NSNumber(value: max(heures, 0))) ?? "0"
    }

    /// Heures avec une décimale, ex. « 6,2 h ».
    static func heuresUneDecimale(_ heures: Double) -> String {
        let formateur = NumberFormatter()
        formateur.numberStyle = .decimal
        formateur.minimumFractionDigits = 0
        formateur.maximumFractionDigits = 1
        formateur.locale = Locale(identifier: "fr_FR")
        let texte = formateur.string(from: NSNumber(value: max(heures, 0))) ?? "0"
        return texte + " h"
    }
}
