import WidgetKit
import SwiftUI

/// Les couleurs du widget. Valeurs reprises de Theme/Nocturne.swift : le widget
/// est une cible séparée et ne compile pas le thème de l'app.
private enum Teintes {
    static let fond = Color(red: 0x16 / 255, green: 0x18 / 255, blue: 0x26 / 255)
    static let texte = Color(red: 0xE9 / 255, green: 0xE9 / 255, blue: 0xED / 255)
    static let accent = Color(red: 0x91 / 255, green: 0x84 / 255, blue: 0xD9 / 255)
    static let accent300 = Color(red: 0xD2 / 255, green: 0xCE / 255, blue: 0xFD / 255)
    static let neutre400 = Color(red: 0xB2 / 255, green: 0xB6 / 255, blue: 0xCA / 255)
    static let neutre800 = Color(red: 0x3F / 255, green: 0x42 / 255, blue: 0x4D / 255)
}

struct EntreePratique: TimelineEntry {
    let date: Date
    let resume: ResumePratique
}

struct FournisseurPratique: TimelineProvider {
    func placeholder(in context: Context) -> EntreePratique {
        EntreePratique(date: .now, resume: ResumePratique(minutesAujourdhui: 25,
                                                          objectifQuotidienMinutes: 60,
                                                          serie: 4, heuresTotales: 12,
                                                          ecritLe: .now))
    }

    func getSnapshot(in context: Context, completion: @escaping (EntreePratique) -> Void) {
        completion(EntreePratique(date: .now, resume: resumeCourant()))
    }

    /// L'app rafraîchit le widget quand les données changent ; cette frise
    /// sert surtout à passer minuit proprement (les minutes du jour repartent
    /// de zéro) et à ne pas rester figé si l'app n'est pas ouverte.
    func getTimeline(in context: Context, completion: @escaping (Timeline<EntreePratique>) -> Void) {
        let maintenant = Date.now
        let prochaine = Calendar.current.nextDate(after: maintenant,
                                                  matching: DateComponents(minute: 0),
                                                  matchingPolicy: .nextTime) ?? maintenant.addingTimeInterval(3600)
        let entree = EntreePratique(date: maintenant, resume: resumeCourant(maintenant))
        completion(Timeline(entries: [entree], policy: .after(prochaine)))
    }

    private func resumeCourant(_ maintenant: Date = .now) -> ResumePratique {
        (PartageResume.lire() ?? .vide).actualise(maintenant: maintenant)
    }
}

// MARK: Écran verrouillé — l'anneau du jour

struct AnneauAccessoire: View {
    let resume: ResumePratique

    var body: some View {
        Gauge(value: resume.fractionObjectif) {
            Image(systemName: "pianokeys")
        } currentValueLabel: {
            Text("\(resume.minutesAujourdhui)")
                .monospacedDigit()
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .accessibilityLabel("Pratique du jour")
        .accessibilityValue("\(resume.minutesAujourdhui) minutes sur \(resume.objectifQuotidienMinutes)")
    }
}

struct LigneAccessoire: View {
    let resume: ResumePratique

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "pianokeys").font(.system(size: 12))
                Text("Ostinato").font(.system(size: 13, weight: .medium))
            }
            Text("\(resume.minutesAujourdhui) / \(resume.objectifQuotidienMinutes) min aujourd'hui")
                .font(.system(size: 13))
                .monospacedDigit()
            Text(resume.serie > 0
                 ? "Série de \(resume.serie) jour\(resume.serie > 1 ? "s" : "")"
                 : "La série commence aujourd'hui")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: Écran d'accueil — la petite tuile

struct TuilePratique: View {
    let resume: ResumePratique

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("AUJOURD'HUI")
                    .font(.system(size: 9, weight: .medium))
                    .tracking(1.2)
                    .foregroundStyle(Teintes.neutre400)
                Spacer()
                if resume.serie > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill").font(.system(size: 9))
                        Text("\(resume.serie)").font(.system(size: 10, weight: .medium))
                            .monospacedDigit()
                    }
                    .foregroundStyle(Teintes.accent300)
                }
            }

            Spacer(minLength: 0)

            ZStack {
                Circle()
                    .stroke(Teintes.neutre800, lineWidth: 7)
                Circle()
                    .trim(from: 0, to: max(resume.fractionObjectif, 0.001))
                    .stroke(Teintes.accent, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(resume.minutesAujourdhui)")
                        .font(.system(size: 22, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(Teintes.texte)
                    Text("sur \(resume.objectifQuotidienMinutes)")
                        .font(.system(size: 9))
                        .foregroundStyle(Teintes.neutre400)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 78)

            Spacer(minLength: 0)

            Text(String(format: "%.1f %%", resume.pourcentageRoute)
                    .replacingOccurrences(of: ".", with: ",")
                 + " de la route")
                .font(.system(size: 10))
                .monospacedDigit()
                .foregroundStyle(Teintes.neutre400)
        }
    }
}

// MARK: Le widget

struct WidgetPratique: Widget {
    let kind = "OstinatoPratique"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FournisseurPratique()) { entree in
            VuePratique(resume: entree.resume)
        }
        .configurationDisplayName("Pratique du jour")
        .description("Tes minutes du jour, ta série et la route des 10 000 heures.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .systemSmall])
    }
}

struct VuePratique: View {
    @Environment(\.widgetFamily) private var famille
    let resume: ResumePratique

    var body: some View {
        switch famille {
        case .accessoryCircular:
            AnneauAccessoire(resume: resume)
                .containerBackground(.clear, for: .widget)
        case .accessoryRectangular:
            LigneAccessoire(resume: resume)
                .containerBackground(.clear, for: .widget)
        default:
            TuilePratique(resume: resume)
                .containerBackground(Teintes.fond, for: .widget)
        }
    }
}

@main
struct OstinatoWidgetBundle: WidgetBundle {
    var body: some Widget {
        WidgetPratique()
    }
}
