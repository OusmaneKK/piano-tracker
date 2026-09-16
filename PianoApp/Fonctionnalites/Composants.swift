import SwiftUI

/// Bouton principal Nocturne : pilule au contour accent, jamais d'aplat.
struct BoutonPilule: View {
    let titre: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(titre)
                .font(.system(size: 15, weight: .medium))
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
            .font(.system(size: 11, weight: .regular))
            .kerning(1.3)
            .foregroundStyle(Nocturne.neutre400)
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
