import SwiftUI
import SwiftData

/// Le timer de pratique : grand anneau, lecture/pause, remise à zéro, terminer.
struct SessionView: View {
    @Bindable var vm: SessionViewModel
    /// L'objectif du jour, rappelé sous le titre.
    let objectifMinutes: Int
    /// Appelé quand la session est terminée (retour à l'accueil).
    var terminer: () -> Void

    @Environment(\.modelContext) private var contexte
    @Environment(GestionnaireMIDI.self) private var midi
    @State private var confirmerRemiseAZero = false

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Kicker(texte: "Session de pratique")
                Text("Objectif du jour : \(objectifMinutes) min")
                    .font(.system(size: 16, weight: .medium))
                    .monospacedDigit()
            }
            .padding(.top, 16)

            VStack(spacing: 10) {
                ZStack {
                    AnneauProgression(progression: vm.fractionAnneau,
                                      diametre: 230, epaisseur: 8)
                    VStack(spacing: 2) {
                        Text(vm.affichage)
                            .font(.system(size: 44, weight: .medium))
                            .monospacedDigit()
                        Text(vm.sousTexte)
                            .font(.system(size: 12))
                            .foregroundStyle(Nocturne.neutre400)
                    }
                }
                Text("Chaque minute s'ajoute à ta route des 10 000 heures")
                    .font(.system(size: 12))
                    .foregroundStyle(Nocturne.neutre400)
            }
            .padding(.top, 10)

            HStack(spacing: 22) {
                boutonSecondaire(icone: "arrow.counterclockwise") {
                    if vm.secondesEcoulees > 0 {
                        confirmerRemiseAZero = true
                    }
                }
                Button {
                    vm.basculer()
                } label: {
                    ZStack {
                        Circle().fill(Nocturne.accent900)
                        Circle().strokeBorder(Nocturne.accent, lineWidth: 1.5)
                        Image(systemName: vm.enCours ? "pause.fill" : "play.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Nocturne.accent200)
                    }
                    .frame(width: 74, height: 74)
                    .shadow(color: Nocturne.lueur.opacity(0.78), radius: 9)
                    .contentShape(Circle())
                }
                .buttonStyle(.plain)
                boutonSecondaire(icone: "checkmark") {
                    if let duree = vm.terminer() {
                        contexte.insert(SessionPratique(dureeSecondes: duree))
                    }
                    terminer()
                }
            }

            if midi.estConnecte {
                carteComptageAutomatique
            } else {
                pastille(icone: "pianokeys", texte: "Aucun clavier connecté")
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .confirmationDialog("Remettre le timer à zéro ?",
                            isPresented: $confirmerRemiseAZero,
                            titleVisibility: .visible) {
            Button("Effacer \(vm.affichage) de pratique", role: .destructive) {
                vm.reinitialiser()
            }
            Button("Continuer la session", role: .cancel) {}
        } message: {
            Text("Le temps écoulé ne sera pas enregistré.")
        }
    }

    /// Le clavier est branché : il peut piloter la session tout seul.
    private var carteComptageAutomatique: some View {
        HStack(spacing: 12) {
            Image(systemName: "pianokeys")
                .font(.system(size: 19))
                .foregroundStyle(vm.suiviMIDIArme ? Nocturne.accent300 : Nocturne.neutre400)
            VStack(alignment: .leading, spacing: 1) {
                Text("Comptage automatique")
                    .font(.system(size: 14, weight: .medium))
                Text(vm.suiviMIDIArme
                     ? "Joue — je démarre, et le silence met en pause"
                     : "Laisse ton clavier lancer la session")
                    .font(.system(size: 11.5))
                    .foregroundStyle(vm.suiviMIDIArme ? Nocturne.accent300 : Nocturne.neutre400)
            }
            Spacer(minLength: 0)
            Toggle("Comptage automatique", isOn: $vm.suiviMIDIArme)
                .labelsHidden()
                .tint(Nocturne.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .carteNocturne()
    }

    private func boutonSecondaire(icone: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle().strokeBorder(Nocturne.neutre600, lineWidth: 1)
                Image(systemName: icone)
                    .font(.system(size: 20))
                    .foregroundStyle(Nocturne.neutre300)
            }
            .frame(width: 52, height: 52)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private func pastille(icone: String, texte: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icone).font(.system(size: 12))
            Text(texte).font(.system(size: 12))
        }
        .foregroundStyle(Nocturne.neutre300)
        .padding(.horizontal, 13)
        .padding(.vertical, 7)
        .overlay(Capsule().strokeBorder(Nocturne.neutre700, lineWidth: 1))
    }
}
