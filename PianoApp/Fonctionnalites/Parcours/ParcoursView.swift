import SwiftUI
import SwiftData

/// La route des 10 000 heures : total investi, rythme, frise des jalons.
struct ParcoursView: View {
    @Query(sort: \SessionPratique.date) private var sessions: [SessionPratique]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                entete
                heros
                frise
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
    }

    // MARK: Données dérivées

    private var heuresTotales: Double {
        Double(sessions.reduce(0) { $0 + $1.dureeSecondes }) / 3600
    }

    /// Rythme réel : heures des 28 derniers jours ramenées à la semaine.
    private var heuresParSemaine: Double {
        let seuil = Calendar.current.date(byAdding: .day, value: -28, to: .now) ?? .now
        let secondes = sessions.filter { $0.date >= seuil }.reduce(0) { $0 + $1.dureeSecondes }
        return Double(secondes) / 3600 / 4
    }

    // MARK: Sections

    private var entete: some View {
        VStack(alignment: .leading, spacing: 3) {
            Kicker(texte: "Le parcours")
            Text("10 000 heures vers la maîtrise")
                .font(.system(size: 22, weight: .medium))
            Text("L'expertise n'est pas un talent — c'est du temps délibéré, accumulé. Chaque session te fait avancer sur cette route.")
                .font(.system(size: 12.5))
                .foregroundStyle(Nocturne.neutre300)
                .lineSpacing(3)
                .padding(.top, 3)
        }
    }

    private var heros: some View {
        let pct = Progression.pourcentage(heuresTotales: heuresTotales)
        return VStack(spacing: 0) {
            Text(FormatTemps.heuresEntieres(heuresTotales))
                .font(.system(size: 46, weight: .medium))
                .monospacedDigit()
            Text("heures investies · \(String(format: "%.1f", pct).replacingOccurrences(of: ".", with: ",")) % du chemin")
                .font(.system(size: 12))
                .foregroundStyle(Nocturne.accent200)
                .padding(.top, 2)
            BarreProgression(fraction: pct / 100, fondClair: true)
                .padding(.top, 14)
            Text(rythmeTexte)
                .font(.system(size: 11))
                .foregroundStyle(Nocturne.accent200.opacity(0.85))
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
        .background(
            ZStack {
                LinearGradient(colors: [Nocturne.section, Nocturne.sectionLueur],
                               startPoint: .top, endPoint: .bottom)
                RadialGradient(colors: [Nocturne.accent.opacity(0.28), .clear],
                               center: .top, startRadius: 0, endRadius: 220)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var rythmeTexte: String {
        let prochain = Progression.prochainJalon(heuresTotales: heuresTotales)
        let cible = prochain.map { "prochain jalon à \(FormatTemps.heuresEntieres($0.heures)) h" }
            ?? "la route est parcourue"
        guard heuresParSemaine > 0 else {
            return "Lance ta première session pour établir ton rythme — \(cible)"
        }
        return "≈ \(FormatTemps.heuresUneDecimale(heuresParSemaine)) / semaine — \(cible)"
    }

    private var frise: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(Jalon.tous.enumerated()), id: \.element.id) { index, jalon in
                ligneJalon(jalon, dernier: index == Jalon.tous.count - 1)
            }
        }
    }

    private func ligneJalon(_ jalon: Jalon, dernier: Bool) -> some View {
        let atteint = heuresTotales >= jalon.heures
        return HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                Circle()
                    .fill(atteint ? Nocturne.accent : Nocturne.neutre800)
                    .overlay(Circle().strokeBorder(
                        atteint ? Nocturne.accent : Nocturne.neutre600, lineWidth: 2))
                    .frame(width: 12, height: 12)
                    .shadow(color: atteint ? Nocturne.lueur.opacity(0.9) : .clear, radius: 4)
                    .padding(.top, 3)
                if !dernier {
                    LinearGradient(colors: [atteint ? Nocturne.accent700 : Nocturne.neutre700, .clear],
                                   startPoint: .top, endPoint: .bottom)
                        .frame(width: 1.5)
                        .frame(minHeight: 34)
                }
            }
            .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(jalon.titre)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(atteint ? Nocturne.accent300 : Nocturne.texte)
                    Text("\(FormatTemps.heuresEntieres(jalon.heures)) h")
                        .font(.system(size: 11.5))
                        .monospacedDigit()
                        .foregroundStyle(Nocturne.neutre400)
                }
                Text(jalon.detail)
                    .font(.system(size: 12))
                    .foregroundStyle(Nocturne.neutre400)
                    .lineSpacing(2)
            }
            .padding(.bottom, 18)
            Spacer(minLength: 0)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
