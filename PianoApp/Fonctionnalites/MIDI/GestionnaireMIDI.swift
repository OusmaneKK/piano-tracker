import Foundation
import CoreMIDI
import Observation

/// Réception MIDI : écoute toutes les sources connectées (Bluetooth comme USB)
/// et publie chaque note jouée (note-on). Le branchement se refait tout seul
/// quand une source apparaît ou disparaît.
@Observable
final class GestionnaireMIDI {
    private(set) var nbSources = 0
    var estConnecte: Bool { nbSources > 0 }

    /// Les notes actuellement enfoncées (60 = Do central). C'est ce qui permet
    /// de reconnaître un accord **tenu**, sans fenêtre temporelle hasardeuse.
    private(set) var notesTenues: Set<UInt8> = []

    /// Les touches tenues, octave ignorée — prêtes à être comparées au domaine.
    var touchesTenues: Set<Touche> {
        Set(notesTenues.map { Touche.depuisNoteMIDI($0) })
    }

    /// Les abonnés aux notes jouées, par clé (« session », « quiz »…) :
    /// plusieurs écrans peuvent écouter le clavier en même temps.
    /// Ils ne reçoivent que les note-on, comme avant.
    @ObservationIgnored private var abonnes: [String: (UInt8) -> Void] = [:]

    @ObservationIgnored private var client = MIDIClientRef()
    @ObservationIgnored private var port = MIDIPortRef()

    /// Reçoit chaque note jouée (60 = Do central), sur le fil principal.
    /// Un nouvel abonnement remplace le précédent portant la même clé.
    func abonner(_ cle: String, _ action: @escaping (UInt8) -> Void) {
        abonnes[cle] = action
    }

    func desabonner(_ cle: String) {
        abonnes[cle] = nil
    }

    func demarrer() {
        guard client == 0 else {
            rebrancher()
            return
        }
        MIDIClientCreateWithBlock("Ostinato" as CFString, &client) { [weak self] _ in
            DispatchQueue.main.async { self?.rebrancher() }
        }
        MIDIInputPortCreateWithProtocol(client, "Entrée" as CFString, ._1_0, &port) {
            [weak self] listePaquets, _ in
            self?.traiter(listePaquets)
        }
        rebrancher()
    }

    /// Oublie les touches réputées enfoncées. Un note-off perdu — ça arrive en
    /// Bluetooth — laisserait sinon une note fantôme pour toujours, et plus
    /// aucun accord ne se validerait.
    func oublierLesTouchesTenues() {
        notesTenues.removeAll()
    }

    private func rebrancher() {
        let nombre = MIDIGetNumberOfSources()
        for indice in 0..<nombre {
            MIDIPortConnectSource(port, MIDIGetSource(indice), nil)
        }
        nbSources = nombre
        oublierLesTouchesTenues()
    }

    /// Décode les paquets UMP (MIDI 1.0) : les note-on nourrissent les abonnés,
    /// les note-off tiennent `notesTenues` à jour.
    private func traiter(_ liste: UnsafePointer<MIDIEventList>) {
        for paquet in liste.unsafeSequence() {
            let nbMots = Int(paquet.pointee.wordCount)
            withUnsafeBytes(of: paquet.pointee.words) { brut in
                for indice in 0..<min(nbMots, 64) {
                    let mot = brut.load(fromByteOffset: indice * 4, as: UInt32.self)
                    guard mot >> 28 == 0x2 else { continue }   // voix MIDI 1.0
                    let statut = (mot >> 20) & 0xF
                    guard statut == 0x8 || statut == 0x9 else { continue }
                    let note = UInt8((mot >> 8) & 0x7F)
                    let velocite = mot & 0x7F
                    // Un note-on à vélocité nulle vaut un relâchement.
                    let enfoncee = statut == 0x9 && velocite > 0
                    // Un seul saut vers le fil principal par événement : l'ensemble
                    // des touches tenues est à jour **avant** que les abonnés soient
                    // prévenus, sinon un abonné lirait un état d'avant sa propre note.
                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        if enfoncee {
                            notesTenues.insert(note)
                            for prevenir in abonnes.values { prevenir(note) }
                        } else {
                            notesTenues.remove(note)
                        }
                    }
                }
            }
        }
    }
}
