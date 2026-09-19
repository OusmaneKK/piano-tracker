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
