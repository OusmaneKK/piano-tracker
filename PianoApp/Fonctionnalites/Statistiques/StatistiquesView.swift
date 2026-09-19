import SwiftUI
import SwiftData

/// Les statistiques : tuiles, barres des 7 derniers jours, prévision.
struct StatistiquesView: View {
    let profil: Profil

    @Query(sort: \SessionPratique.date) private var sessions: [SessionPratique]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Ton temps")
                    .font(.system(size: 22, weight: .medium))
                tuiles
                carteSemaine
                cartePrevision
                SectionLectureNotes()
                SectionHistorique(profil: profil)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
    }

    // MARK: Données dérivées

    private struct JourBarre: Identifiable {
        let id: Int
        let libelle: String
        let minutes: Int
        let estAujourdhui: Bool
    }

    private var heuresTotales: Double {
        Double(sessions.reduce(0) { $0 + $1.dureeSecondes }) / 3600
    }

    /// Les 7 derniers jours (aujourd'hui en dernier), minutes par jour.
    private var barres: [JourBarre] {
        let calendrier = Calendar.current
        let aujourdHui = calendrier.startOfDay(for: .now)
        return (0..<7).reversed().map { decalage in
            let jour = calendrier.date(byAdding: .day, value: -decalage, to: aujourdHui) ?? aujourdHui
            let minutes = sessions
                .filter { calendrier.isDate($0.date, inSameDayAs: jour) }
                .reduce(0) { $0 + $1.dureeSecondes } / 60
            let libelle = jour.formatted(
                Date.FormatStyle(locale: Locale(identifier: "fr_FR")).weekday(.narrow))
            return JourBarre(id: decalage, libelle: libelle.uppercased(),
                             minutes: minutes, estAujourdhui: decalage == 0)
        }
    }

    private var minutesSemaine: Int { barres.reduce(0) { $0 + $1.minutes } }

    private var serie: Int {
        Progression.serie(joursDePratique: sessions.map(\.date))
    }

    /// Rythme réel des dernières semaines (calcul dans le domaine).
    private var heuresParSemaine: Double {
        Progression.rythmeHebdomadaire(
            sessions: sessions.map { (date: $0.date, secondes: $0.dureeSecondes) })
    }

    // MARK: Sections

    private var tuiles: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible())],
                  spacing: 10) {
            tuile(valeur: FormatTemps.heuresUneDecimale(Double(minutesSemaine) / 60),
                  legende: "cette semaine")
            tuile(valeur: "\(minutesSemaine / 7) min", legende: "moyenne quotidienne")
            tuile(valeur: "\(serie)", legende: "jours de série", accent: true)
            tuile(valeur: FormatTemps.heuresEntieres(heuresTotales), legende: "heures au total")
        }
    }

    private func tuile(valeur: String, legende: String, accent: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(valeur)
                .font(.system(size: 24, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(accent ? Nocturne.accent300 : Nocturne.texte)
            Text(legende)
                .font(.system(size: 11.5))
                .foregroundStyle(Nocturne.neutre400)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .carteNocturne()
    }

    private var carteSemaine: some View {
        let maximum = max(barres.map(\.minutes).max() ?? 0, profil.objectifQuotidienMinutes, 1)
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Cette semaine").font(.system(size: 13, weight: .medium))
                Spacer()
                Text("minutes / jour")
                    .font(.system(size: 11))
                    .foregroundStyle(Nocturne.neutre400)
            }
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(barres) { barre in
                    VStack(spacing: 6) {
                        Spacer(minLength: 0)
                        Text("\(barre.minutes)")
                            .font(.system(size: 10))
                            .monospacedDigit()
                            .foregroundStyle(Nocturne.neutre400)
                        UnevenRoundedRectangle(topLeadingRadius: 5, bottomLeadingRadius: 2,
                                               bottomTrailingRadius: 2, topTrailingRadius: 5)
                            .fill(barre.estAujourdhui
                                  ? AnyShapeStyle(LinearGradient(
                                        colors: [Nocturne.accent, Nocturne.accent700],
                                        startPoint: .top, endPoint: .bottom))
                                  : AnyShapeStyle(Nocturne.neutre700))
                            .frame(maxWidth: 26)
                            .frame(height: CGFloat(barre.minutes) / CGFloat(maximum) * 78 + 6)
                            .shadow(color: barre.estAujourdhui ? Nocturne.lueur : .clear, radius: 4)
                        Text(barre.libelle)
                            .font(.system(size: 10))
                            .foregroundStyle(barre.estAujourdhui ? Nocturne.accent300 : Nocturne.neutre500)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 118, alignment: .bottom)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .carteNocturne()
    }

    private var cartePrevision: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("À ce rythme").font(.system(size: 13, weight: .medium))
            Text(previsionTexte)
                .font(.system(size: 12.5))
                .foregroundStyle(Nocturne.neutre300)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .carteNocturne()
    }

    private var previsionTexte: String {
        // À défaut de rythme réel (moins d'une session), on prévoit sur l'objectif quotidien.
        let rythme = heuresParSemaine > 0
            ? heuresParSemaine
            : Double(profil.objectifQuotidienMinutes) / 60 * 7
        guard rythme > 0,
              let prochain = Progression.prochainJalon(heuresTotales: heuresTotales),
              let annees = Progression.anneesRestantes(heuresTotales: heuresTotales,
                                                       heuresCible: prochain.heures,
                                                       heuresParSemaine: rythme),
              let anneesMaitrise = Progression.anneesRestantes(heuresTotales: heuresTotales,
                                                               heuresCible: Progression.objectifHeures,
                                                               heuresParSemaine: rythme)
        else {
            return "La route est parcourue — 10 000 heures de pratique délibérée."
        }
        let source = heuresParSemaine > 0 ? "En pratiquant" : "À ton objectif, soit"
        let versJalon: String
        if annees < 1 {
            let mois = max(1, Int((annees * 12).rounded()))
            versJalon = "environ \(mois) mois"
        } else {
            versJalon = "environ \(formatAnnees(annees)) ans"
        }
        return "\(source) \(FormatTemps.heuresUneDecimale(rythme)) par semaine, tu atteindras « \(prochain.titre) » (\(FormatTemps.heuresEntieres(prochain.heures)) h) dans \(versJalon), et la maîtrise (10 000 h) dans \(formatAnnees(anneesMaitrise)) ans. La route est longue — c'est le principe."
    }

    private func formatAnnees(_ annees: Double) -> String {
        String(format: "%.1f", annees).replacingOccurrences(of: ".", with: ",")
    }
}
