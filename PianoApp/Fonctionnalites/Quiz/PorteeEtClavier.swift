import SwiftUI

/// La portée : cinq lignes, la clé, une note avec sa hampe et son altération.
struct PorteeView: View {
    let note: NotePortee
    let enSurbrillance: Bool

    private let interligne: CGFloat = 20
    private let largeur: CGFloat = 250

    var body: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { indice in
                Rectangle()
                    .fill(Nocturne.neutre400)
                    .frame(width: largeur, height: 2)
                    .offset(y: CGFloat(indice - 2) * interligne)
            }
            if note.cle == .sol {
                Text("\u{1D11E}")
                    .font(.system(size: 100))
                    .foregroundStyle(Nocturne.neutre200)
                    .offset(x: -largeur / 2 + 32, y: -2)
            } else {
                Text("\u{1D122}")
                    .font(.system(size: 74))
                    .foregroundStyle(Nocturne.neutre200)
                    .offset(x: -largeur / 2 + 30, y: -11)
            }
            if note.ligneSupplementaireBas {
                Rectangle()
                    .fill(Nocturne.neutre400)
                    .frame(width: 44, height: 2)
                    .offset(x: xNote, y: y(position: -2))
            }
            if note.ligneSupplementaireHaut {
                Rectangle()
                    .fill(Nocturne.neutre400)
                    .frame(width: 44, height: 2)
                    .offset(x: xNote, y: y(position: 10))
            }
            if note.alteration != .naturelle {
                Text(note.alteration.rawValue)
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(teinteNote)
                    .offset(x: xNote - 27, y: y(position: note.position))
            }
            groupeNote
        }
        .frame(width: largeur, height: 240)
        .animation(.easeOut(duration: 0.15), value: enSurbrillance)
    }

    private var xNote: CGFloat { 34 }

    private var teinteNote: Color {
        enSurbrillance ? Nocturne.accent300 : Nocturne.texte
    }

    private func y(position: Int) -> CGFloat {
        CGFloat(4 - position) * interligne / 2
    }

    private var groupeNote: some View {
        ZStack {
            Ellipse()
                .fill(teinteNote)
                .frame(width: 26, height: 19)
                .rotationEffect(.degrees(-18))
                .shadow(color: enSurbrillance ? Nocturne.lueur : .clear, radius: 8)
            Rectangle()
                .fill(teinteNote)
                .frame(width: 2.5, height: 58)
                .offset(x: note.hampeVersLeBas ? -11.5 : 11.5,
                        y: note.hampeVersLeBas ? 29 : -29)
        }
        .offset(x: xNote, y: y(position: note.position))
    }
}

/// Une octave de piano pour répondre : sept touches blanches et cinq touches
/// noires, toutes actives. Le même geste sert au clavier MIDI.
struct ClavierReponse: View {
    let correcte: Touche?
    let fausse: Touche?
    let active: Bool
    var choisir: (Touche) -> Void

    /// Les touches blanches suivies d'une touche noire, avec leur index visuel.
    private static let noires: [(indice: Int, gauche: NomNote)] =
        [(0, .do), (1, .re), (3, .fa), (4, .sol), (5, .la)]

    var body: some View {
        GeometryReader { geo in
            let espace: CGFloat = 3
            let largeurTouche = (geo.size.width - espace * 6) / 7
            ZStack(alignment: .topLeading) {
                HStack(spacing: espace) {
                    ForEach(NomNote.allCases, id: \.self) { nom in
                        toucheBlanche(nom)
                    }
                }
                ForEach(Self.noires, id: \.indice) { noire in
                    toucheNoire(noire.gauche)
                        .frame(width: largeurTouche * 0.62, height: 80)
                        .offset(x: (largeurTouche + espace) * CGFloat(noire.indice + 1)
                                    - espace / 2 - largeurTouche * 0.31)
                }
            }
        }
        .frame(height: 132)
    }

    private func toucheBlanche(_ nom: NomNote) -> some View {
        let touche = Touche.blanche(nom)
        let estCorrecte = touche == correcte
        let estFausse = touche == fausse
        let fond: Color = estCorrecte ? Nocturne.accent300
            : estFausse ? Nocturne.neutre600 : Nocturne.neutre200
        return Button {
            choisir(touche)
        } label: {
            UnevenRoundedRectangle(topLeadingRadius: 4, bottomLeadingRadius: 8,
                                   bottomTrailingRadius: 8, topTrailingRadius: 4)
                .fill(fond)
                .shadow(color: estCorrecte ? Nocturne.lueur : .clear, radius: 11)
                .overlay(alignment: .bottom) {
                    Text(nom.rawValue)
                        .police(13, .medium)
                        .foregroundStyle(estCorrecte ? Nocturne.accent900 : Nocturne.neutre800)
                        .padding(.bottom, 10)
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!active)
        .accessibilityLabel(nom.rawValue)
        .accessibilityHint("Répondre \(nom.rawValue)")
    }

    private func toucheNoire(_ gauche: NomNote) -> some View {
        let touche = Touche.noire(entre: gauche)
        let estCorrecte = touche == correcte
        let estFausse = touche == fausse
        let forme = UnevenRoundedRectangle(topLeadingRadius: 2, bottomLeadingRadius: 5,
                                           bottomTrailingRadius: 5, topTrailingRadius: 2)
        return Button {
            choisir(touche)
        } label: {
            forme
                .fill(estCorrecte ? Nocturne.accent400 : estFausse ? Nocturne.neutre600 : Nocturne.neutre900)
                .shadow(color: estCorrecte ? Nocturne.lueur : .clear, radius: 11)
                .overlay(forme.strokeBorder(estCorrecte ? Nocturne.accent : Nocturne.neutre700,
                                            lineWidth: 1))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!active)
        .accessibilityLabel("\(gauche.rawValue) dièse")
        .accessibilityHint("Touche noire, aussi \(gauche.suivante.rawValue) bémol")
    }
}
