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
    @Environment(\.modelContext) private var contexte
    @Environment(\.scenePhase) private var scenePhase
    @State private var onglet: Onglet = .aujourdhui
    @State private var sessionVM = SessionViewModel()

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
        .task { sessionVM.configurer(contexte: contexte) }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active: sessionVM.rafraichir()
            case .background: sessionVM.sauvegarder()
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
