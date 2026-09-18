import SwiftUI
import SwiftData

/// Les quatre onglets de l'app.
enum Onglet: CaseIterable {
    case aujourdhui, session, parcours, stats

    var libelle: String {
        switch self {
        case .aujourdhui: "Aujourd'hui"
        case .session: "Session"
        case .parcours: "Parcours"
        case .stats: "Stats"
        }
    }

    var icone: String {
        switch self {
        case .aujourdhui: "house"
        case .session: "timer"
        case .parcours: "point.topleft.down.curvedto.point.bottomright.up"
        case .stats: "chart.bar"
        }
    }

    var iconeActive: String {
        switch self {
        case .aujourdhui: "house.fill"
        case .session: "timer"
        case .parcours: "point.topleft.down.curvedto.point.bottomright.up"
        case .stats: "chart.bar.fill"
        }
    }
}

/// Racine : aiguille vers l'onboarding tant que le profil n'existe pas,
/// puis porte la barre d'onglets custom et l'état du timer de session
/// (pour qu'il survive aux changements d'onglet).
struct RacineView: View {
    @Query private var profils: [Profil]
    @Query private var sessions: [SessionPratique]
    @Environment(\.modelContext) private var contexte
    @Environment(\.scenePhase) private var scenePhase
    @State private var onglet: Onglet = .aujourdhui
    @State private var sessionVM = SessionViewModel()
    @State private var midi = GestionnaireMIDI()

    private var profil: Profil? { profils.first }

    var body: some View {
        ZStack {
            Nocturne.fond.ignoresSafeArea()
            if let profil, profil.onboardingTermine {
                VStack(spacing: 0) {
                    Group {
                        switch onglet {
                        case .aujourdhui:
                            AujourdhuiView(profil: profil) { onglet = .session }
                        case .session:
                            SessionView(vm: sessionVM) { onglet = .aujourdhui }
                        case .parcours:
                            ParcoursView()
                        case .stats:
                            StatistiquesView(profil: profil)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    barreOnglets
                }
            } else {
                OnboardingView { objectifMinutes in
                    terminerOnboarding(objectifMinutes: objectifMinutes)
                }
            }
        }
        .foregroundStyle(Nocturne.texte)
        .environment(midi)
        .task {
            sessionVM.configurer(contexte: contexte)
            midi.demarrer()
            midi.abonner("session") { _ in sessionVM.noteJouee() }
            publierResume()
        }
        // Le widget suit l'historique : une session enregistrée ou supprimée
        // le met à jour, comme le passage en arrière-plan.
        .onChange(of: sessions.count) { _, _ in publierResume() }
        .onChange(of: profil?.objectifQuotidienMinutes) { _, _ in publierResume() }
        // L'écran ne se met pas en veille pendant qu'une session tourne, ni
        // pendant qu'on attend les premières notes du clavier.
        .onChange(of: sessionVM.enCours) { _, _ in majVeille() }
        .onChange(of: sessionVM.suiviMIDIArme) { _, _ in majVeille() }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active: sessionVM.rafraichir()
            case .background:
                sessionVM.sauvegarder()
                publierResume()
            default: break
            }
        }
    }

    private var barreOnglets: some View {
        HStack(spacing: 0) {
            ForEach(Onglet.allCases, id: \.self) { o in
                let actif = onglet == o
                Button {
                    onglet = o
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: actif ? o.iconeActive : o.icone)
                            .font(.system(size: 21))
                        Text(o.libelle)
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(actif ? Nocturne.accent300 : Nocturne.neutre500)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 6)
        .background(
            Nocturne.fond.opacity(0.92)
                .background(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
        .overlay(alignment: .top) {
            Rectangle().fill(Nocturne.neutre800).frame(height: 1)
        }
    }

    private func publierResume() {
        ResumePratique.publier(sessions: sessions, profil: profil)
    }

    private func majVeille() {
        UIApplication.shared.isIdleTimerDisabled = sessionVM.enCours || sessionVM.suiviMIDIArme
    }

    private func terminerOnboarding(objectifMinutes: Int) {
        if let profil {
            profil.objectifQuotidienMinutes = objectifMinutes
            profil.onboardingTermine = true
        } else {
            contexte.insert(Profil(objectifQuotidienMinutes: objectifMinutes,
                                   onboardingTermine: true))
        }
    }
}
