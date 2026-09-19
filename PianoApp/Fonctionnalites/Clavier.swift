import SwiftUI

/// Pourquoi une touche est éclairée. Une touche absente du dictionnaire garde
/// son apparence neutre — c'est ce qui permet au quiz de n'en éclairer que deux
/// sans rien changer à son code.
enum EclairageTouche {
    /// Hors du sujet (une note qui n'est pas dans la gamme affichée).
    case eteinte
    /// Membre de la gamme affichée.
    case membre
    /// La note ou l'accord à jouer.
    case attendue
    /// Sous les doigts en ce moment.
    case tenue
    /// La touche choisie à tort.
    case fausse
}

/// Une octave de piano. Sert au quiz (deux touches éclairées) comme à
/// l'Atelier (une gamme, un accord, les doigts posés). Le même geste servira
/// au clavier MIDI.
struct ClavierPiano: View {
    var eclairages: [Touche: EclairageTouche] = [:]
    var active: Bool = true
    var hauteur: CGFloat = 132
    var choisir: ((Touche) -> Void)? = nil

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
                        .frame(width: largeurTouche * 0.62, height: hauteur * 0.61)
                        .offset(x: (largeurTouche + espace) * CGFloat(noire.indice + 1)
                                    - espace / 2 - largeurTouche * 0.31)
                }
            }
        }
        .frame(height: hauteur)
    }

    // MARK: Apparence

    private func fondBlanche(_ eclairage: EclairageTouche?) -> Color {
        switch eclairage {
        case .attendue: Nocturne.accent300
        case .tenue: Nocturne.accent500
        case .fausse: Nocturne.neutre600
        case .eteinte: Nocturne.neutre800
        case .membre, .none: Nocturne.neutre200
        }
    }

    private func fondNoire(_ eclairage: EclairageTouche?) -> Color {
        switch eclairage {
        case .attendue: Nocturne.accent400
        case .tenue: Nocturne.accent500
        case .fausse: Nocturne.neutre600
        case .membre: Nocturne.neutre200
        case .eteinte, .none: Nocturne.neutre900
        }
    }

    private func lueur(_ eclairage: EclairageTouche?) -> Color {
        switch eclairage {
        case .attendue, .tenue: Nocturne.lueur
        default: .clear
        }
    }

    private func teinteTexte(_ eclairage: EclairageTouche?) -> Color {
        switch eclairage {
        case .attendue, .tenue: Nocturne.accent900
        case .eteinte: Nocturne.neutre600
        default: Nocturne.neutre800
        }
    }

    // MARK: Touches

    private func toucheBlanche(_ nom: NomNote) -> some View {
        let touche = Touche.blanche(nom)
        let eclairage = eclairages[touche]
        return Button {
            choisir?(touche)
        } label: {
            UnevenRoundedRectangle(topLeadingRadius: 4, bottomLeadingRadius: 8,
                                   bottomTrailingRadius: 8, topTrailingRadius: 4)
                .fill(fondBlanche(eclairage))
                .shadow(color: lueur(eclairage), radius: 11)
                .overlay(alignment: .bottom) {
                    Text(nom.rawValue)
                        .police(13, .medium)
                        .foregroundStyle(teinteTexte(eclairage))
                        .padding(.bottom, 10)
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!active || choisir == nil)
        .accessibilityLabel(nom.rawValue)
    }

    private func toucheNoire(_ gauche: NomNote) -> some View {
        let touche = Touche.noire(entre: gauche)
        let eclairage = eclairages[touche]
        let forme = UnevenRoundedRectangle(topLeadingRadius: 2, bottomLeadingRadius: 5,
                                           bottomTrailingRadius: 5, topTrailingRadius: 2)
        return Button {
            choisir?(touche)
        } label: {
            forme
                .fill(fondNoire(eclairage))
                .shadow(color: lueur(eclairage), radius: 11)
                .overlay(forme.strokeBorder(
                    eclairage == .attendue ? Nocturne.accent : Nocturne.neutre700,
                    lineWidth: 1))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!active || choisir == nil)
        .accessibilityLabel("\(gauche.rawValue) dièse")
        .accessibilityHint("Aussi \(gauche.suivante.rawValue) bémol")
    }
}

/// Le clavier du quiz : une touche juste, une touche fausse. Enveloppe mince
/// au-dessus de `ClavierPiano`, pour que l'écran du quiz reste inchangé.
struct ClavierReponse: View {
    let correcte: Touche?
    let fausse: Touche?
    let active: Bool
    var choisir: (Touche) -> Void

    var body: some View {
        var eclairages: [Touche: EclairageTouche] = [:]
        if let correcte { eclairages[correcte] = .attendue }
        if let fausse { eclairages[fausse] = .fausse }
        return ClavierPiano(eclairages: eclairages, active: active, choisir: choisir)
    }
}
