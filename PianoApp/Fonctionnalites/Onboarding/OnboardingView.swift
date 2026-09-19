import SwiftUI

/// Onboarding en quatre étapes : le principe, l'objectif quotidien, le créneau, le clavier.
struct OnboardingView: View {
    /// Appelé à la fin avec l'objectif quotidien (minutes) et l'heure du
    /// créneau choisie (minutes depuis minuit).
    var terminer: (Int, Int) -> Void

    @State private var etape = 1
    @State private var objectifMinutes = 60
    @State private var heureCreneau = Calendar.current.date(bySettingHour: 19, minute: 0,
                                                            second: 0, of: .now) ?? .now
    @State private var montrerAgenda = false

    private static let options: [(minutes: Int, sousTitre: String)] = [
        (30, "Une habitude régulière"),
        (45, "Le bon tempo pour débuter"),
        (60, "Des progrès sérieux et durables"),
        (90, "Ambitieux — gare à la fatigue"),
    ]

    var body: some View {
        // Aux grandes tailles de texte le contenu dépasse l'écran : il défile
        // alors au lieu d'être tronqué, tout en gardant la mise en page pleine
        // hauteur (les Spacer) quand il tient.
        GeometryReader { geo in
            ScrollView {
                Group {
                    switch etape {
                    case 1: principe
                    case 2: objectif
                    case 3: creneau
                    default: clavier
                    }
                }
                .frame(minHeight: geo.size.height - 24, alignment: .top)
                .padding(.horizontal, 26)
                .padding(.bottom, 24)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    // MARK: Étape 1 — le principe

    private var principe: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 70)
            Kicker(texte: "Le principe de la pratique")
            Text("10 000")
                .police(64, .medium)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundStyle(Nocturne.accent200)
                .shadow(color: Nocturne.lueur, radius: 15)
                .padding(.top, 18)
            Text("heures vers la maîtrise")
                .police(15)
                .foregroundStyle(Nocturne.neutre300)
            Text("Il n'y a pas de raccourci. La recherche sur l'expertise pointe une seule chose : la pratique délibérée, accumulée. Cette app existe pour t'aider à mettre les heures — et à faire compter chaque minute.")
                .police(13.5)
                .foregroundStyle(Nocturne.neutre300)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: 290)
                .padding(.top, 22)
            Spacer()
            pointsDePage(actif: 1)
                .padding(.bottom, 22)
            BoutonPilule(titre: "Je suis prêt") { etape = 2 }
        }
    }

    // MARK: Étape 2 — l'objectif quotidien

    private var objectif: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 60)
            Text("Combien de temps, chaque jour ?")
                .police(22, .medium)
            Text("La régularité compte plus que les coups d'éclat. Choisis un objectif que tu peux tenir.")
                .police(13)
                .foregroundStyle(Nocturne.neutre300)
                .lineSpacing(3)
                .padding(.top, 6)

            VStack(spacing: 10) {
                ForEach(Self.options, id: \.minutes) { option in
                    LigneOption(titre: "\(option.minutes) minutes",
                                sousTitre: option.sousTitre,
                                choisi: objectifMinutes == option.minutes) {
                        objectifMinutes = option.minutes
                    }
                }
            }
            .padding(.top, 22)

            VStack(alignment: .leading, spacing: 6) {
                Kicker(texte: "À ce rythme")
                Text(prevision)
                    .police(12.5)
                    .foregroundStyle(Nocturne.neutre200)
                    .lineSpacing(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .carteNocturne()
            .padding(.top, 18)

            Spacer()
            pointsDePage(actif: 2)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 22)
            BoutonPilule(titre: "Définir mon objectif") { etape = 3 }
        }
    }

    /// L'heure du créneau, en minutes depuis minuit (ce que le profil retient).
    private var minutesDepuisMinuit: Int {
        let composantes = Calendar.current.dateComponents([.hour, .minute], from: heureCreneau)
        return (composantes.hour ?? 19) * 60 + (composantes.minute ?? 0)
    }

    private var prevision: String {
        let heuresParSemaine = Double(objectifMinutes) / 60 * 7
        let mois = Progression.moisPourAtteindre(heuresCible: 100, minutesParJour: objectifMinutes) ?? 0
        let annees = Progression.anneesRestantes(heuresTotales: 0, heuresCible: 1_000,
                                                 heuresParSemaine: heuresParSemaine) ?? 0
        let anneesTexte = String(format: "%.1f", annees).replacingOccurrences(of: ".", with: ",")
        return "\(objectifMinutes) minutes par jour atteignent Novice (100 h) en environ \(mois) mois et Intermédiaire (1 000 h) en \(anneesTexte) ans. La route est longue — c'est le principe."
    }

    // MARK: Étape 3 — le créneau quotidien

    private var creneau: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)
            Text("Réserve ton créneau")
                .police(22, .medium)
            Text("Même heure, même geste, chaque jour. Un créneau réservé dans ton agenda est plus difficile à ignorer qu'une bonne intention.")
                .police(13.5)
                .foregroundStyle(Nocturne.neutre300)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: 290)
                .padding(.top, 8)

            DatePicker("Heure du créneau", selection: $heureCreneau,
                       displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxHeight: 170)
                .padding(.top, 18)

            Text("\(objectifMinutes) minutes · tous les jours")
                .police(12.5)
                .monospacedDigit()
                .foregroundStyle(Nocturne.accent300)
                .padding(.top, 6)

            Spacer()
            pointsDePage(actif: 3)
                .padding(.bottom, 22)
            BoutonPilule(titre: "Réserver dans mon agenda") { montrerAgenda = true }
            Button("Plus tard") { etape = 4 }
                .police(13)
                .foregroundStyle(Nocturne.neutre400)
                .padding(.top, 14)
        }
        .sheet(isPresented: $montrerAgenda) {
            EditeurCreneauAgenda(heure: heureCreneau, dureeMinutes: objectifMinutes) { enregistre in
                montrerAgenda = false
                if enregistre { etape = 4 }
            }
            .ignoresSafeArea()
        }
    }

    // MARK: Étape 4 — le clavier

    private var clavier: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 70)
            ZStack {
                Circle()
                    .fill(Nocturne.accent900)
                    .overlay(Circle().strokeBorder(Nocturne.accent700, lineWidth: 1.5))
                    .shadow(color: Nocturne.lueur.opacity(0.66), radius: 13)
                Image(systemName: "pianokeys")
                    .police(40)
                    .foregroundStyle(Nocturne.accent200)
            }
            .frame(width: 96, height: 96)
            Text("Connecte ton clavier")
                .police(22, .medium)
                .padding(.top, 22)
            Text("Branche-le en Bluetooth MIDI et réponds au quiz de notes en jouant les vraies touches. Le comptage automatique des minutes arrive ensuite — en attendant, le timer de session s'en charge.")
                .police(13.5)
                .foregroundStyle(Nocturne.neutre300)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: 290)
                .padding(.top, 10)
            Spacer()
            pointsDePage(actif: 4)
                .padding(.bottom, 22)
            BoutonPilule(titre: "Commencer à pratiquer") {
                terminer(objectifMinutes, minutesDepuisMinuit)
            }
        }
    }

    // MARK: Points de pagination

    private func pointsDePage(actif: Int) -> some View {
        HStack(spacing: 6) {
            ForEach(1...4, id: \.self) { i in
                Capsule()
                    .fill(i == actif ? Nocturne.accent : Nocturne.neutre600)
                    .frame(width: i == actif ? 18 : 5, height: 5)
            }
        }
    }
}
