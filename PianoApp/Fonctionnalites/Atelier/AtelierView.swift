import SwiftUI

/// L'Atelier : le cercle des quintes en miroir de ce qu'on joue.
/// Touche des notes sur le clavier du bas (ou, plus tard, sur le vrai piano) et
/// le cercle montre où l'accord se situe — un accord appartient à plusieurs
/// tonalités voisines, et c'est toute la leçon.
struct AtelierView: View {
    @State private var touchesTenues: Set<Touche> = []
    @State private var tonaliteConsultee = CercleDesQuintes.majeures[0]
    @State private var ficheAffichee: Tonalite?

    /// L'accord formé par les touches posées, s'il en forme un.
    private var accord: Accord? {
        CercleDesQuintes.accord(pour: touchesTenues)
    }

    private var places: [CercleDesQuintes.Place] {
        accord.map(CercleDesQuintes.placesDe) ?? []
    }

    var body: some View {
        VStack(spacing: 0) {
            entete
            Spacer(minLength: 0)
            CercleView(places: places, selection: tonaliteConsultee) { tonalite in
                tonaliteConsultee = tonalite
                ficheAffichee = tonalite
            }
            Spacer(minLength: 0)
            // La lecture se place juste au-dessus du clavier : on lit le
            // résultat à côté de ses doigts, pas à l'autre bout de l'écran.
            lecture
                .padding(.bottom, 12)
            ClavierPiano(eclairages: eclairages, hauteur: 118) { touche in
                if touchesTenues.contains(touche) {
                    touchesTenues.remove(touche)
                } else {
                    touchesTenues.insert(touche)
                }
            }
            aide
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .sheet(item: $ficheAffichee) { tonalite in
            FicheTonaliteView(tonalite: tonalite)
        }
    }

    // MARK: Sections

    private var entete: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 1) {
                Kicker(texte: "Atelier")
                Text("Le cercle des quintes")
                    .police(20, .medium)
            }
            Spacer()
            if !touchesTenues.isEmpty {
                Button("Effacer") { touchesTenues = [] }
                    .police(12.5)
                    .foregroundStyle(Nocturne.accent300)
            }
        }
    }

    /// Ce que le cercle raconte : l'accord et ses places, ou la tonalité
    /// consultée tant qu'on n'a rien joué.
    private var lecture: some View {
        Group {
            if let accord {
                carteLecture(titre: accord.libelle, detail: rolesTexte)
            } else if touchesTenues.count >= 2 {
                carteLecture(titre: "\(touchesTenues.count) notes",
                             detail: "Pose une triade — trois notes qui s'empilent en tierces — pour que le cercle la situe.")
            } else {
                carteLecture(titre: tonaliteConsultee.libelle,
                             detail: "Extérieur : les majeures · intérieur : leurs relatives mineures. Touche une tonalité pour sa fiche.")
            }
        }
    }

    private func carteLecture(titre: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(titre)
                .police(14, .medium)
                .foregroundStyle(accord != nil ? Nocturne.accent200 : Nocturne.texte)
            Text(detail)
                .police(11.5)
                .foregroundStyle(Nocturne.neutre300)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(accord != nil ? Nocturne.accent900.opacity(0.45) : Nocturne.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(accord != nil ? Nocturne.accent700 : Nocturne.neutre700,
                          lineWidth: 1))
    }

    /// « I de Do · IV de Sol · V de Fa » — le même accord sert plusieurs tonalités.
    private var rolesTexte: String {
        let majeures = places.filter { $0.tonalite.mode == .majeur }
        guard !majeures.isEmpty else { return "" }
        let roles = majeures
            .sorted { ($0.degre.rang, $0.tonalite.libelle) < ($1.degre.rang, $1.tonalite.libelle) }
            .map { "\($0.degre.chiffrage) de \($0.tonalite.tonique.libelle)" }
        return roles.joined(separator: " · ")
            + " — le même accord sert ces tonalités voisines."
    }

    private var aide: some View {
        Text(touchesTenues.isEmpty
             ? "Touche trois notes pour former un accord"
             : "Touche à nouveau une note pour la retirer")
            .police(11)
            .foregroundStyle(Nocturne.neutre500)
            .frame(maxWidth: .infinity)
            .padding(.top, 9)
            .padding(.bottom, 4)
    }

    /// Les doigts posés, et la gamme consultée en fond quand rien n'est joué.
    private var eclairages: [Touche: EclairageTouche] {
        var resultat: [Touche: EclairageTouche] = [:]
        if touchesTenues.isEmpty {
            let gamme = tonaliteConsultee.touches
            for touche in Touche.octave {
                resultat[touche] = gamme.contains(touche) ? .membre : .eteinte
            }
        } else {
            for touche in touchesTenues { resultat[touche] = .tenue }
        }
        return resultat
    }
}

extension Touche {
    /// Les douze touches d'une octave, blanches et noires.
    static var octave: [Touche] {
        NomNote.allCases.map { Touche.blanche($0) }
        + [NomNote.do, .re, .fa, .sol, .la].map { Touche.noire(entre: $0) }
    }
}
