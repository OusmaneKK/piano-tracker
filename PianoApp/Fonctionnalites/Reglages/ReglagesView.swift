import SwiftUI
import SwiftData

/// Les réglages : objectif quotidien, créneau de pratique, clavier MIDI.
/// Tout ce qui était figé à l'onboarding se change ici.
struct ReglagesView: View {
    @Bindable var profil: Profil

    @Environment(\.dismiss) private var fermer
    @Environment(GestionnaireMIDI.self) private var midi
    @State private var montrerAgenda = false
    @State private var montrerBluetooth = false

    /// Les objectifs proposés, comme à l'onboarding.
    static let objectifs: [(minutes: Int, sousTitre: String)] = [
        (30, "Une habitude régulière"),
        (45, "Le bon tempo pour débuter"),
        (60, "Des progrès sérieux et durables"),
        (90, "Ambitieux — gare à la fatigue"),
    ]

    var body: some View {
        ZStack {
            Nocturne.fond.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    entete
                    objectifQuotidien
                    creneau
                    clavierMIDI
                    pied
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .foregroundStyle(Nocturne.texte)
        .task { midi.demarrer() }
        .sheet(isPresented: $montrerAgenda) {
            EditeurCreneauAgenda(heure: profil.heureCreneau,
                                 dureeMinutes: profil.objectifQuotidienMinutes) { _ in
                montrerAgenda = false
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $montrerBluetooth) {
            ConnexionBluetoothMIDI()
                .ignoresSafeArea()
        }
    }

    // MARK: Sections

    private var entete: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Kicker(texte: "Ostinato")
                Text("Réglages")
                    .font(.system(size: 22, weight: .medium))
            }
            Spacer()
            Button {
                fermer()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14))
                    .foregroundStyle(Nocturne.neutre300)
                    .frame(width: 34, height: 34)
                    .overlay(Circle().strokeBorder(Nocturne.neutre700, lineWidth: 1))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 18)
    }

    private var objectifQuotidien: some View {
        VStack(alignment: .leading, spacing: 10) {
            titreSection("Objectif quotidien")
            Text("Change-le quand ta vie change — mieux vaut un objectif tenu qu'un objectif ambitieux.")
                .font(.system(size: 12.5))
                .foregroundStyle(Nocturne.neutre400)
                .lineSpacing(2)
                .padding(.bottom, 2)
            ForEach(Self.objectifs, id: \.minutes) { option in
                LigneOption(titre: "\(option.minutes) minutes",
                            sousTitre: option.sousTitre,
                            choisi: profil.objectifQuotidienMinutes == option.minutes) {
                    profil.objectifQuotidienMinutes = option.minutes
                }
            }
        }
        .padding(.top, 26)
    }

    private var creneau: some View {
        VStack(alignment: .leading, spacing: 10) {
            titreSection("Créneau quotidien")
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Heure de pratique")
                        .font(.system(size: 15, weight: .medium))
                    Text("Mémorisée pour tes prochains rendez-vous")
                        .font(.system(size: 11.5))
                        .foregroundStyle(Nocturne.neutre400)
                }
                Spacer()
                DatePicker("Heure de pratique",
                           selection: Binding(get: { profil.heureCreneau },
                                              set: { profil.heureCreneau = $0 }),
                           displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(Nocturne.accent)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .carteNocturne()

            BoutonPilule(titre: "Réserver dans mon agenda") { montrerAgenda = true }
                .padding(.top, 2)
        }
        .padding(.top, 26)
    }

    private var clavierMIDI: some View {
        VStack(alignment: .leading, spacing: 10) {
            titreSection("Clavier MIDI")
            HStack(spacing: 14) {
                Image(systemName: "pianokeys")
                    .font(.system(size: 19))
                    .foregroundStyle(midi.estConnecte ? Nocturne.accent300 : Nocturne.neutre400)
                VStack(alignment: .leading, spacing: 1) {
                    Text(midi.estConnecte ? "Clavier connecté" : "Aucun clavier")
                        .font(.system(size: 15, weight: .medium))
                    Text(midi.estConnecte
                         ? "Il répond au quiz et peut compter tes sessions"
                         : "Appaire ton piano pour jouer tes réponses")
                        .font(.system(size: 11.5))
                        .foregroundStyle(midi.estConnecte ? Nocturne.accent300 : Nocturne.neutre400)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .carteNocturne()

            BoutonPilule(titre: "Appairer en Bluetooth") { montrerBluetooth = true }
                .padding(.top, 2)
        }
        .padding(.top, 26)
    }

    /// La version installée — utile pour savoir quel build tourne sur l'appareil.
    private var pied: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Ostinato \(versionTexte)")
                .font(.system(size: 11.5))
                .monospacedDigit()
                .foregroundStyle(Nocturne.neutre500)
            Text("La route des 10 000 heures se marche un jour à la fois.")
                .font(.system(size: 11.5))
                .foregroundStyle(Nocturne.neutre600)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 34)
    }

    private var versionTexte: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }

    private func titreSection(_ texte: String) -> some View {
        Text(texte)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(Nocturne.neutre300)
    }
}
