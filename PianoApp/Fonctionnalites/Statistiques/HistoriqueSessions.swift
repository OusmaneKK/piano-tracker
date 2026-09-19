import SwiftUI
import SwiftData

/// L'historique des sessions dans Stats : liste des dernières sessions,
/// suppression avec confirmation, ajout manuel d'une session oubliée.
struct SectionHistorique: View {
    let profil: Profil

    @Environment(\.modelContext) private var contexte
    @Query(sort: \SessionPratique.date, order: .reverse) private var sessions: [SessionPratique]
    @State private var montrerSaisie = false
    @State private var sessionASupprimer: SessionPratique?

    /// Nombre de sessions affichées (les plus récentes).
    private let limite = 10

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Sessions récentes").police(13, .medium)
                Spacer()
                Button {
                    montrerSaisie = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "plus").police(11, .medium)
                        Text("Ajouter").police(12)
                    }
                    .foregroundStyle(Nocturne.accent300)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .overlay(Capsule().strokeBorder(Nocturne.accent700, lineWidth: 1))
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            if sessions.isEmpty {
                Text("Aucune session pour l'instant — la première s'enregistre à la fin du timer, ou ajoute-la ici à la main.")
                    .police(12.5)
                    .foregroundStyle(Nocturne.neutre400)
                    .lineSpacing(3)
                    .padding(.vertical, 6)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(sessions.prefix(limite).enumerated()), id: \.element.persistentModelID) { indice, session in
                        if indice > 0 {
                            Rectangle().fill(Nocturne.neutre800).frame(height: 1)
                        }
                        ligne(session)
                    }
                }
                if sessions.count > limite {
                    Text("… et \(sessions.count - limite) autres, toutes comptées dans la route.")
                        .police(11)
                        .foregroundStyle(Nocturne.neutre500)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .carteNocturne()
        .sheet(isPresented: $montrerSaisie) {
            SaisieSessionView(dureeParDefaut: profil.objectifQuotidienMinutes)
        }
        .confirmationDialog("Supprimer cette session ?",
                            isPresented: .init(get: { sessionASupprimer != nil },
                                               set: { if !$0 { sessionASupprimer = nil } }),
                            titleVisibility: .visible,
                            presenting: sessionASupprimer) { session in
            Button("Supprimer \(session.dureeMinutes) min de pratique", role: .destructive) {
                contexte.delete(session)
                sessionASupprimer = nil
            }
            Button("Garder", role: .cancel) { sessionASupprimer = nil }
        } message: { _ in
            Text("Ces minutes seront retirées de la route des 10 000 heures.")
        }
    }

    private func ligne(_ session: SessionPratique) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text(jourTexte(session.date))
                    .police(13, .medium)
                Text(heureTexte(session.date))
                    .police(11)
                    .foregroundStyle(Nocturne.neutre500)
            }
            Spacer()
            Text("\(session.dureeMinutes) min")
                .police(13)
                .monospacedDigit()
                .foregroundStyle(Nocturne.accent300)
            Button {
                sessionASupprimer = session
            } label: {
                Image(systemName: "trash")
                    .police(13)
                    .foregroundStyle(Nocturne.neutre500)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Supprimer la session de \(session.dureeMinutes) minutes du \(jourTexte(session.date))")
        }
        .padding(.vertical, 8)
    }

    private func jourTexte(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Aujourd'hui" }
        if Calendar.current.isDateInYesterday(date) { return "Hier" }
        return date.formatted(
            Date.FormatStyle(locale: Locale(identifier: "fr_FR"))
                .weekday(.abbreviated).day().month(.abbreviated)
        )
    }

    private func heureTexte(_ date: Date) -> String {
        date.formatted(
            Date.FormatStyle(locale: Locale(identifier: "fr_FR")).hour().minute()
        )
    }
}

/// Saisie manuelle d'une session oubliée : un jour (pas dans le futur) et une durée.
struct SaisieSessionView: View {
    let dureeParDefaut: Int

    @Environment(\.dismiss) private var fermer
    @Environment(\.modelContext) private var contexte
    @State private var jour: Date = .now
    @State private var dureeMinutes: Int

    init(dureeParDefaut: Int) {
        self.dureeParDefaut = dureeParDefaut
        _dureeMinutes = State(initialValue: min(max(dureeParDefaut, 5), 180))
    }

    var body: some View {
        ZStack {
            Nocturne.fond.ignoresSafeArea()
            VStack(spacing: 0) {
                Kicker(texte: "Session oubliée")
                    .padding(.top, 26)
                Text("Ajouter une session")
                    .police(20, .medium)
                    .padding(.top, 6)

                DatePicker("Jour", selection: $jour, in: ...Date.now,
                           displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .tint(Nocturne.accent)
                    .police(14)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .carteNocturne()
                    .padding(.top, 22)

                HStack {
                    Text("Durée").police(14)
                    Spacer()
                    Picker("Durée", selection: $dureeMinutes) {
                        ForEach(Array(stride(from: 5, through: 180, by: 5)), id: \.self) { minutes in
                            Text("\(minutes) min").tag(minutes)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 120, height: 90)
                    .clipped()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .carteNocturne()
                .padding(.top, 10)

                Spacer()
                BoutonPilule(titre: "Ajouter \(dureeMinutes) minutes") {
                    contexte.insert(SessionPratique(date: dateEnregistrement,
                                                    dureeSecondes: dureeMinutes * 60))
                    fermer()
                }
                Button("Annuler") { fermer() }
                    .police(13)
                    .foregroundStyle(Nocturne.neutre400)
                    .padding(.top, 14)
                    .padding(.bottom, 10)
            }
            .padding(.horizontal, 26)
            .padding(.bottom, 14)
        }
        .foregroundStyle(Nocturne.texte)
        .presentationDetents([.medium, .large])
        .presentationBackground(Nocturne.fond)
    }

    /// Aujourd'hui : l'heure réelle ; un jour passé : midi, pour rester dans la bonne journée.
    private var dateEnregistrement: Date {
        if Calendar.current.isDateInToday(jour) { return .now }
        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: jour) ?? jour
    }
}
