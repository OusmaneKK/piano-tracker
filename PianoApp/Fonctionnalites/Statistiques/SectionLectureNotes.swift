import SwiftUI
import SwiftData

/// Ce que le quiz a retenu : taux de réussite, progression, et les notes
/// qui résistent encore.
struct SectionLectureNotes: View {
    @Query(sort: \SerieQuiz.date, order: .reverse) private var series: [SerieQuiz]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Lecture de notes").police(13, .medium)
                Spacer()
                if !series.isEmpty {
                    Text("\(series.count) série\(series.count > 1 ? "s" : "")")
                        .police(11)
                        .monospacedDigit()
                        .foregroundStyle(Nocturne.neutre400)
                }
            }

            if series.isEmpty {
                Text("Aucune série jouée — le quiz de notes t'attend depuis l'écran Aujourd'hui.")
                    .police(12.5)
                    .foregroundStyle(Nocturne.neutre400)
                    .lineSpacing(3)
            } else {
                resume
                if !notesQuiResistent.isEmpty {
                    Rectangle().fill(Nocturne.neutre800).frame(height: 1)
                    notesADeblayer
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .carteNocturne()
    }

    // MARK: Données dérivées

    private var reponses: [(note: String, juste: Bool)] {
        series.flatMap { serie in
            serie.reponses.map { (note: $0.note, juste: $0.juste) }
        }
    }

    private var taux: Double? {
        StatistiquesQuiz.tauxDeReussite(reponses: reponses)
    }

    private var progression: Double? {
        StatistiquesQuiz.progression(taux: series.map(\.taux))
    }

    private var notesQuiResistent: [StatistiquesQuiz.BilanNote] {
        StatistiquesQuiz.notesQuiResistent(reponses: reponses)
    }

    // MARK: Sections

    private var resume: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 1) {
                Text(taux.map { "\(Int(($0 * 100).rounded())) %" } ?? "—")
                    .police(24, .medium)
                    .monospacedDigit()
                    .foregroundStyle(Nocturne.accent300)
                Text("de notes trouvées")
                    .police(11.5)
                    .foregroundStyle(Nocturne.neutre400)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("\(series.first?.score ?? 0) / \(series.first?.total ?? QuizNotes.questionsParSerie)")
                    .police(24, .medium)
                    .monospacedDigit()
                Text("dernière série")
                    .police(11.5)
                    .foregroundStyle(Nocturne.neutre400)
            }
            Spacer(minLength: 0)
        }
        .overlay(alignment: .topTrailing) {
            if let progression, abs(progression) >= 1 {
                HStack(spacing: 4) {
                    Image(systemName: progression > 0 ? "arrow.up.right" : "arrow.down.right")
                        .police(10, .medium)
                    Text("\(abs(Int(progression.rounded()))) pts")
                        .police(11)
                        .monospacedDigit()
                }
                .foregroundStyle(progression > 0 ? Nocturne.accent300 : Nocturne.neutre400)
            }
        }
    }

    private var notesADeblayer: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ces notes résistent encore")
                .police(12, .medium)
                .foregroundStyle(Nocturne.neutre300)
            ForEach(notesQuiResistent, id: \.note) { bilan in
                HStack(spacing: 12) {
                    Text(bilan.note)
                        .police(14, .medium)
                        .monospacedDigit()
                        .frame(width: 46, alignment: .leading)
                    BarreProgression(fraction: bilan.tauxErreur)
                    Text("\(bilan.ratees) / \(bilan.tentatives)")
                        .police(11)
                        .monospacedDigit()
                        .foregroundStyle(Nocturne.neutre400)
                        .frame(width: 42, alignment: .trailing)
                }
            }
        }
    }
}
