import SwiftUI
import CoreAudioKit

/// La fiche système d'appairage Bluetooth MIDI (recherche et connexion
/// des claviers à portée). Tout est géré par iOS, y compris la permission.
struct ConnexionBluetoothMIDI: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        UINavigationController(rootViewController: CABTMIDICentralViewController())
    }

    func updateUIViewController(_ controleur: UINavigationController, context: Context) {}
}
