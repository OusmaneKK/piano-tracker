import SwiftUI

/// La police du design, mise à l'échelle par le réglage de taille de texte
/// d'iOS. `Font.system(size:)` ignore Dynamic Type ; `@ScaledMetric` applique
/// le même facteur à toutes les tailles, ce qui préserve les rapports de
/// Nocturne au lieu de les écraser sur des styles sémantiques.
private struct PoliceNocturne: ViewModifier {
    @ScaledMetric(relativeTo: .body) private var echelle: CGFloat = 1
    let taille: CGFloat
    let poids: Font.Weight

    func body(content: Content) -> some View {
        content.font(.system(size: taille * echelle, weight: poids))
    }
}

extension View {
    /// Police du design suivant Dynamic Type (remplace `.font(.system(size:))`).
    func police(_ taille: CGFloat, _ poids: Font.Weight = .regular) -> some View {
        modifier(PoliceNocturne(taille: taille, poids: poids))
    }
}

/// Bouton principal Nocturne : pilule au contour accent, jamais d'aplat.
struct BoutonPilule: View {
    let titre: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(titre)
                .police(15, .medium)
                .foregroundStyle(Nocturne.accent200)
                .frame(maxWidth: .infinity, minHeight: 48)
                .overlay(
                    Capsule().strokeBorder(Nocturne.accent, lineWidth: 1.5)
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Petit libellé en capitales espacées (les « kickers » du design).
struct Kicker: View {
    let texte: String

    var body: some View {
        Text(texte.uppercased())
            .police(11, .regular)
            .kerning(1.3)
            .foregroundStyle(Nocturne.neutre400)
    }
}

/// Une option à cocher : pastille ronde, titre, sous-titre.
/// Sert au choix de l'objectif quotidien (onboarding et réglages).
struct LigneOption: View {
    let titre: String
    let sousTitre: String
    let choisi: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Circle()
                    .strokeBorder(choisi ? Nocturne.accent : Nocturne.neutre500, lineWidth: 2)
                    .background(Circle().fill(choisi ? Nocturne.accent : .clear).padding(4))
                    .frame(width: 18, height: 18)
                VStack(alignment: .leading, spacing: 1) {
                    Text(titre)
                        .police(15, .medium)
                        .monospacedDigit()
                        .foregroundStyle(choisi ? Nocturne.accent200 : Nocturne.texte)
                    Text(sousTitre)
                        .police(11.5)
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
}

/// Anneau de progression avec lueur accent (objectif du jour, timer de session).
struct AnneauProgression: View {
    let progression: Double // 0...1
    let diametre: CGFloat
    let epaisseur: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Nocturne.neutre800, lineWidth: epaisseur)
            Circle()
                .trim(from: 0, to: max(min(progression, 1), 0.0001))
                .stroke(Nocturne.accent,
                        style: StrokeStyle(lineWidth: epaisseur, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: Nocturne.lueur, radius: 5)
                .animation(.easeInOut(duration: 0.6), value: progression)
        }
        .frame(width: diametre, height: diametre)
    }
}

/// Carte surface + bord neutre, rayon 14 (le `--radius-lg` du design system).
struct CarteNocturne: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Nocturne.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Nocturne.neutre700, lineWidth: 1)
            )
    }
}

extension View {
    func carteNocturne() -> some View { modifier(CarteNocturne()) }
}

/// Barre de progression fine avec dégradé accent et lueur.
struct BarreProgression: View {
    let fraction: Double // 0...1
    var fondClair = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(fondClair ? Nocturne.texte.opacity(0.14) : Nocturne.neutre800)
                Capsule()
                    .fill(LinearGradient(colors: [Nocturne.accent700, Nocturne.accent],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(geo.size.width * min(max(fraction, 0.012), 1), 6))
                    .shadow(color: Nocturne.lueur, radius: 4)
            }
        }
        .frame(height: 6)
    }
}
