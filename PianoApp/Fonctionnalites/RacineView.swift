import SwiftUI
import SwiftData

/// Les cinq onglets de l'app.
enum Onglet: CaseIterable {
    case aujourdhui, session, atelier, parcours, stats

    var libelle: String {
        switch self {
        case .aujourdhui: "Aujourd'hui"
        case .session: "Session"
        case .atelier: "Atelier"
        case .parcours: "Parcours"
        case .stats: "Stats"
        }
    }

    var icone: String {
        switch self {
        case .aujourdhui: "house"
        case .session: "timer"
        case .atelier: "circle.hexagongrid"
        case .parcours: "point.topleft.down.curvedto.point.bottomright.up"
        case .stats: "chart.bar"
        }
    }

    var iconeActive: String {
        switch self {
        case .aujourdhui: "house.fill"
        case .session: "timer"
        case .atelier: "circle.hexagongrid.fill"
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
                            SessionView(vm: sessionVM,
                                        objectifMinutes: profil.objectifQuotidienMinutes) {
                                onglet = .aujourdhui
                            }
                        case .atelier:
                            AtelierView()
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
                OnboardingView { objectifMinutes, heureCreneauMinutes in
                    terminerOnboarding(objectifMinutes: objectifMinutes,
                                       heureCreneauMinutes: heureCreneauMinutes)
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
                            .police(21)
                        Text(o.libelle)
                            .police(10)
                    }
                    .foregroundStyle(actif ? Nocturne.accent300 : Nocturne.neutre500)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(o.libelle)
                .accessibilityAddTraits(actif ? [.isButton, .isSelected] : .isButton)
            }
        }
        // La barre d'onglets garde une hauteur fixe : on borne la mise à
        // l'échelle de ses libellés pour qu'ils ne débordent pas.
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
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

    private func terminerOnboarding(objectifMinutes: Int, heureCreneauMinutes: Int) {
        if let profil {
            profil.objectifQuotidienMinutes = objectifMinutes
            profil.heureCreneauMinutes = heureCreneauMinutes
            profil.onboardingTermine = true
        } else {
            contexte.insert(Profil(objectifQuotidienMinutes: objectifMinutes,
                                   onboardingTermine: true,
                                   heureCreneauMinutes: heureCreneauMinutes))
        }
    }
}
