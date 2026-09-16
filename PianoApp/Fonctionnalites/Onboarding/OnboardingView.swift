import SwiftUI

/// Onboarding en trois étapes : le principe, l'objectif quotidien, le clavier.
struct OnboardingView: View {
    /// Appelé à la fin avec l'objectif quotidien choisi (en minutes).
    var terminer: (Int) -> Void

    @State private var etape = 1
    @State private var objectifMinutes = 60

    private static let options: [(minutes: Int, sousTitre: String)] = [
        (30, "Une habitude régulière"),
        (45, "Le bon tempo pour débuter"),
        (60, "Des progrès sérieux et durables"),
        (90, "Ambitieux — gare à la fatigue"),
    ]

    var body: some View {
        Group {
            switch etape {
            case 1: principe
            case 2: objectif
            default: clavier
            }
        }
        .padding(.horizontal, 26)
        .padding(.bottom, 24)
    }

    // MARK: Étape 1 — le principe

    private var principe: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 70)
            Kicker(texte: "Le principe de la pratique")
            Text("10 000")
                .font(.system(size: 64, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(Nocturne.accent200)
                .shadow(color: Nocturne.lueur, radius: 15)
                .padding(.top, 18)
            Text("heures vers la maîtrise")
                .font(.system(size: 15))
                .foregroundStyle(Nocturne.neutre300)
            Text("Il n'y a pas de raccourci. La recherche sur l'expertise pointe une seule chose : la pratique délibérée, accumulée. Cette app existe pour t'aider à mettre les heures — et à faire compter chaque minute.")
                .font(.system(size: 13.5))
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
                .font(.system(size: 22, weight: .medium))
            Text("La régularité compte plus que les coups d'éclat. Choisis un objectif que tu peux tenir.")
                .font(.system(size: 13))
                .foregroundStyle(Nocturne.neutre300)
                .lineSpacing(3)
                .padding(.top, 6)

            VStack(spacing: 10) {
                ForEach(Self.options, id: \.minutes) { option in
                    ligneOption(option.minutes, option.sousTitre)
                }
            }
            .padding(.top, 22)

            VStack(alignment: .leading, spacing: 6) {
                Kicker(texte: "À ce rythme")
                Text(prevision)
                    .font(.system(size: 12.5))
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

    private func ligneOption(_ minutes: Int, _ sousTitre: String) -> some View {
        let choisi = objectifMinutes == minutes
        return Button {
            objectifMinutes = minutes
        } label: {
            HStack(spacing: 14) {
                Circle()
                    .strokeBorder(choisi ? Nocturne.accent : Nocturne.neutre500, lineWidth: 2)
                    .background(Circle().fill(choisi ? Nocturne.accent : .clear).padding(4))
                    .frame(width: 18, height: 18)
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(minutes) minutes")
                        .font(.system(size: 15, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(choisi ? Nocturne.accent200 : Nocturne.texte)
                    Text(sousTitre)
                        .font(.system(size: 11.5))
                        .foregroundStyle(Nocturne.neutre400)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(choisi ? Nocturne.accent900 : Nocturne.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(choisi ? Nocturne.accent : Nocturne.neutre700, lineWidth: 1.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var prevision: String {
        let heuresParSemaine = Double(objectifMinutes) / 60 * 7
        let mois = Progression.moisPourAtteindre(heuresCible: 100, minutesParJour: objectifMinutes) ?? 0
        let annees = Progression.anneesRestantes(heuresTotales: 0, heuresCible: 1_000,
                                                 heuresParSemaine: heuresParSemaine) ?? 0
        let anneesTexte = String(format: "%.1f", annees).replacingOccurrences(of: ".", with: ",")
        return "\(objectifMinutes) minutes par jour atteignent Novice (100 h) en environ \(mois) mois et Intermédiaire (1 000 h) en \(anneesTexte) ans. La route est longue — c'est le principe."
    }

    // MARK: Étape 3 — le clavier

    private var clavier: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 70)
            ZStack {
                Circle()
                    .fill(Nocturne.accent900)
                    .overlay(Circle().strokeBorder(Nocturne.accent700, lineWidth: 1.5))
                    .shadow(color: Nocturne.lueur.opacity(0.66), radius: 13)
                Image(systemName: "pianokeys")
                    .font(.system(size: 40))
                    .foregroundStyle(Nocturne.accent200)
            }
            .frame(width: 96, height: 96)
            Text("Connecte ton clavier")
                .font(.system(size: 22, weight: .medium))
                .padding(.top, 22)
            Text("Bientôt : branché en MIDI ou Bluetooth, chaque minute jouée sera comptée automatiquement. En attendant, le timer de session s'en charge — sans rien oublier.")
                .font(.system(size: 13.5))
                .foregroundStyle(Nocturne.neutre300)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: 290)
                .padding(.top, 10)
            Spacer()
            pointsDePage(actif: 3)
                .padding(.bottom, 22)
            BoutonPilule(titre: "Commencer à pratiquer") { terminer(objectifMinutes) }
        }
    }

    // MARK: Points de pagination

    private func pointsDePage(actif: Int) -> some View {
        HStack(spacing: 6) {
            ForEach(1...3, id: \.self) { i in
                Capsule()
                    .fill(i == actif ? Nocturne.accent : Nocturne.neutre600)
                    .frame(width: i == actif ? 18 : 5, height: 5)
            }
        }
    }
}
