import SwiftUI
import SwiftData

/// L'écran d'accueil : objectif du jour, série, route des 10 000 heures, suggestions.
struct AujourdhuiView: View {
    let profil: Profil
    var allerPratiquer: () -> Void

    @Query(sort: \SessionPratique.date) private var sessions: [SessionPratique]
    @State private var montrerQuiz = false
    @State private var montrerReglages = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                entete
                carteObjectifDuJour
                carteRoute
                suggestions
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
        .fullScreenCover(isPresented: $montrerQuiz) {
            QuizView()
        }
        .sheet(isPresented: $montrerReglages) {
            ReglagesView(profil: profil)
        }
    }

    // MARK: Données dérivées

    private var minutesAujourdhui: Int {
        let calendrier = Calendar.current
        return sessions
            .filter { calendrier.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.dureeSecondes } / 60
    }

    private var heuresTotales: Double {
        Double(sessions.reduce(0) { $0 + $1.dureeSecondes }) / 3600
    }

    private var serie: Int {
        Progression.serie(joursDePratique: sessions.map(\.date))
    }

    private var salutation: String {
        Calendar.current.component(.hour, from: .now) < 18 ? "Bonjour" : "Bonsoir"
    }

    private var dateDuJour: String {
        Date.now.formatted(
            Date.FormatStyle(locale: Locale(identifier: "fr_FR"))
                .weekday(.wide).day().month(.wide)
        )
    }

    // MARK: Sections

    private var entete: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Kicker(texte: dateDuJour)
                Text(salutation)
                    .police(22, .medium)
            }
            Spacer()
            Button {
                montrerReglages = true
            } label: {
                ZStack {
                    Circle().fill(Nocturne.accent800)
                    Image(systemName: "gearshape")
                        .police(16, .medium)
                        .foregroundStyle(Nocturne.accent200)
                }
                .frame(width: 38, height: 38)
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Réglages")
        }
    }

    private var carteObjectifDuJour: some View {
        let objectif = max(profil.objectifQuotidienMinutes, 1)
        let restant = max(objectif - minutesAujourdhui, 0)
        return HStack(spacing: 20) {
            ZStack {
                AnneauProgression(progression: Double(minutesAujourdhui) / Double(objectif),
                                  diametre: 104, epaisseur: 7)
                    .accessibilityHidden(true)
                VStack(spacing: 0) {
                    Text("\(minutesAujourdhui)")
                        .police(22, .medium)
                        .monospacedDigit()
                    Text("sur \(objectif) min")
                        .police(10)
                        .foregroundStyle(Nocturne.neutre400)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Objectif du jour")
            .accessibilityValue("\(minutesAujourdhui) minutes pratiquées sur \(objectif)")
            VStack(alignment: .leading, spacing: 0) {
                Text("Pratique du jour")
                    .police(15, .medium)
                Text(restant > 0
                     ? "Encore \(restant) minutes pour atteindre l'objectif du jour. La régularité bat l'intensité."
                     : "Objectif atteint — chaque minute de plus compte double.")
                    .police(12.5)
                    .foregroundStyle(Nocturne.neutre300)
                    .lineSpacing(2)
                    .padding(.top, 4)
                if serie > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill").police(14)
                        Text("Série de \(serie) jour\(serie > 1 ? "s" : "")")
                    }
                    .police(12.5)
                    .foregroundStyle(Nocturne.accent300)
                    .padding(.top, 10)
                }
                HStack(spacing: 6) {
                    Image(systemName: "timer").police(13)
                    Text("Enregistré à la fin de chaque session")
                }
                .police(11.5)
                .foregroundStyle(Nocturne.neutre400)
                .padding(.top, 6)
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .background(
            LinearGradient(colors: [Nocturne.neutre800, Nocturne.surface],
                           startPoint: .top, endPoint: .bottom)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Nocturne.neutre700, lineWidth: 1)
        )
    }

    private var carteRoute: some View {
        let pct = Progression.pourcentage(heuresTotales: heuresTotales)
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Kicker(texte: "La route des 10 000 heures")
                Spacer()
                Text(pourcentageTexte(pct))
                    .police(11)
                    .monospacedDigit()
                    .foregroundStyle(Nocturne.accent300)
            }
            BarreProgression(fraction: pct / 100)
                .padding(.top, 10)
            HStack {
                Text("\(FormatTemps.heuresEntieres(heuresTotales)) heures au compteur")
                Spacer()
                Text("10 000")
            }
            .police(11.5)
            .monospacedDigit()
            .foregroundStyle(Nocturne.neutre400)
            .padding(.top, 8)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .carteNocturne()
    }

    private var suggestions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("S'exercer")
                .police(13, .medium)
                .foregroundStyle(Nocturne.neutre300)
            ligneSuggestion(icone: "timer", fondIcone: Nocturne.accent900,
                            teinteIcone: Nocturne.accent300,
                            titre: "Lancer une session",
                            sousTitre: minutesAujourdhui > 0
                                ? "Reprendre là où tu t'es arrêté aujourd'hui"
                                : "Le timer compte chaque minute jouée")
            ligneSuggestion(icone: "music.note", fondIcone: Nocturne.accent900,
                            teinteIcone: Nocturne.accent300,
                            titre: "Quiz de notes",
                            sousTitre: "Ta route de lecture · \(RouteLecture.paliers.count) paliers") {
                montrerQuiz = true
            }
        }
    }

    private func ligneSuggestion(icone: String, fondIcone: Color, teinteIcone: Color,
                                 titre: String, sousTitre: String,
                                 action: (() -> Void)? = nil) -> some View {
        Button(action: action ?? allerPratiquer) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous).fill(fondIcone)
                    Image(systemName: icone)
                        .police(20)
                        .foregroundStyle(teinteIcone)
                }
                .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(titre).police(14, .medium)
                    Text(sousTitre)
                        .police(12)
                        .foregroundStyle(Nocturne.neutre400)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .police(13)
                    .foregroundStyle(Nocturne.neutre500)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .carteNocturne()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func pourcentageTexte(_ pct: Double) -> String {
        String(format: "%.1f", pct).replacingOccurrences(of: ".", with: ",") + " %"
    }
}
