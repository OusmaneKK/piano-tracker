import SwiftUI

/// Le cercle des quintes : douze majeures à l'extérieur, leurs relatives
/// mineures à l'intérieur (en minuscules, la convention d'analyse).
/// Les tonalités allumées sont celles qui contiennent l'accord joué.
struct CercleView: View {
    /// Où se situe l'accord joué — vide au repos.
    let places: [CercleDesQuintes.Place]
    /// La tonalité consultée, mise en avant quand rien n'est joué.
    let selection: Tonalite?
    var choisir: (Tonalite) -> Void

    var body: some View {
        GeometryReader { geo in
            let cote = min(geo.size.width, geo.size.height)
            let centre = CGPoint(x: geo.size.width / 2, y: cote / 2)
            let rayonMajeur = cote / 2 - 23
            let rayonMineur = rayonMajeur - 43

            ZStack {
                Circle()
                    .strokeBorder(Nocturne.neutre800, lineWidth: 1)
                    .frame(width: rayonMajeur * 2, height: rayonMajeur * 2)
                    .position(centre)
                Circle()
                    .strokeBorder(Nocturne.neutre800, lineWidth: 1)
                    .frame(width: rayonMineur * 2, height: rayonMineur * 2)
                    .position(centre)

                ForEach(Array(CercleDesQuintes.majeures.enumerated()), id: \.offset) { indice, majeure in
                    let radians = CercleDesQuintes.angle(index: indice) * .pi / 180
                    pastille(majeure, diametre: 44, police: 13)
                        .position(x: centre.x + rayonMajeur * cos(radians),
                                  y: centre.y + rayonMajeur * sin(radians))
                    pastille(majeure.relative, diametre: 34, police: 11)
                        .position(x: centre.x + rayonMineur * cos(radians),
                                  y: centre.y + rayonMineur * sin(radians))
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: Une pastille

    private func place(de tonalite: Tonalite) -> CercleDesQuintes.Place? {
        places.first { $0.tonalite == tonalite }
    }

    private func pastille(_ tonalite: Tonalite, diametre: CGFloat,
                          police taille: CGFloat) -> some View {
        let place = place(de: tonalite)
        let foyer = place?.estFoyer ?? false
        let contient = place != nil
        // La sélection ne dépend plus de l'accord joué : on doit pouvoir
        // étudier une tonalité **et** jouer par-dessus.
        let choisie = tonalite == selection
        let majeure = tonalite.mode == .majeur

        return Button {
            choisir(tonalite)
        } label: {
            ZStack {
                Circle().fill(fond(foyer: foyer, contient: contient, majeure: majeure))
                Circle().strokeBorder(bord(foyer: foyer, contient: contient),
                                      lineWidth: foyer ? 1.5 : 1)
                Text(libelle(tonalite))
                    .police(taille, majeure ? .medium : .regular)
                    .foregroundStyle(teinte(foyer: foyer, contient: contient,
                                            majeure: majeure))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 3)
            }
            .frame(width: diametre, height: diametre)
            .shadow(color: foyer ? Nocturne.lueur : .clear, radius: 10)
            // L'anneau de sélection se pose **autour** de la pastille : il se
            // superpose à n'importe quel état sans lui disputer son fond.
            .overlay {
                if choisie {
                    Circle()
                        .strokeBorder(Nocturne.accent, lineWidth: 1.5)
                        .padding(-3.5)
                }
            }
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tonalite.libelle)
        .accessibilityValue(etatTexte(place: place, choisie: choisie))
    }

    private func etatTexte(place: CercleDesQuintes.Place?, choisie: Bool) -> String {
        [choisie ? "sélectionnée" : nil,
         place.map { "\($0.degre.chiffrage) de cet accord" }]
            .compactMap { $0 }
            .joined(separator: ", ")
    }

    /// Les mineures s'écrivent en minuscules et sans « m » : la convention
    /// d'analyse, et de quoi tenir dans une pastille de 34 points.
    private func libelle(_ tonalite: Tonalite) -> String {
        tonalite.mode == .majeur
            ? tonalite.tonique.libelle
            : tonalite.tonique.libelle.lowercased()
    }

    // Ces trois fonctions ne décrivent que le rapport à l'accord joué ;
    // la sélection est rendue à part, par l'anneau.

    private func fond(foyer: Bool, contient: Bool, majeure: Bool) -> Color {
        if foyer { return majeure ? Nocturne.accent : Nocturne.accent800 }
        if contient { return majeure ? Nocturne.accent900 : .clear }
        return majeure ? Nocturne.surface : .clear
    }

    private func bord(foyer: Bool, contient: Bool) -> Color {
        if foyer { return Nocturne.accent }
        if contient { return Nocturne.accent700 }
        return Nocturne.neutre800
    }

    private func teinte(foyer: Bool, contient: Bool, majeure: Bool) -> Color {
        if foyer { return majeure ? Nocturne.accent900 : Nocturne.accent100 }
        if contient { return Nocturne.accent200 }
        return majeure ? Nocturne.neutre300 : Nocturne.neutre500
    }
}
