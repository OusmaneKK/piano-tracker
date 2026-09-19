import SwiftUI

/// L'Atelier : le cercle des quintes en miroir de ce qu'on joue.
/// Joue un accord sur ton piano — ou pose-le au doigt sur le clavier du bas —
/// et le cercle montre où il se situe : un accord appartient à plusieurs
/// tonalités voisines, et c'est toute la leçon.
struct AtelierView: View {
    @Environment(GestionnaireMIDI.self) private var midi

    /// Les notes posées au doigt sur l'écran, quand aucun clavier ne joue.
    @State private var touchesDoigt: Set<Touche> = []
    @State private var tonaliteConsultee = CercleDesQuintes.majeures[0]
    @State private var ficheAffichee: Tonalite?
    /// Le dernier accord reconnu, gardé après le relâchement : on peut lâcher
    /// les touches et continuer à lire le cercle.
    @State private var accord: Accord?

    /// Ce qui sonne en ce moment : le vrai piano s'il joue, sinon l'écran.
    private var touchesTenues: Set<Touche> {
        midi.touchesTenues.isEmpty ? touchesDoigt : midi.touchesTenues
    }

    private var places: [CercleDesQuintes.Place] {
        accord.map(CercleDesQuintes.placesDe) ?? []
    }

    var body: some View {
        VStack(spacing: 0) {
            entete
            Spacer(minLength: 0)
            // Toucher une tonalité la sélectionne seulement : sa gamme s'allume
            // au clavier. La fiche s'ouvre par la carte de lecture, en dessous.
            CercleView(places: places, selection: tonaliteConsultee) { tonalite in
                tonaliteConsultee = tonalite
            }
            Spacer(minLength: 0)
            // La lecture se place juste au-dessus du clavier : on lit le
            // résultat à côté de ses doigts, pas à l'autre bout de l'écran.
            lecture
                .padding(.bottom, 12)
            ClavierPiano(eclairages: eclairages, hauteur: 118) { touche in
                if touchesDoigt.contains(touche) {
                    touchesDoigt.remove(touche)
                } else {
                    touchesDoigt.insert(touche)
                }
            }
            aide
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .task { midi.demarrer() }
        // Dès que le vrai piano parle, l'écran s'efface : on ne mélange pas
        // des notes posées au doigt avec celles qui sonnent vraiment.
        .onChange(of: midi.touchesTenues) { _, tenues in
            if !tenues.isEmpty { touchesDoigt = [] }
            majAccord()
        }
        .onChange(of: touchesDoigt) { _, _ in majAccord() }
        .sheet(item: $ficheAffichee) { tonalite in
            FicheTonaliteView(tonalite: tonalite)
        }
    }

    /// Retient le dernier accord reconnu. Tant qu'on n'en joue pas un autre,
    /// le cercle garde son arc allumé — sinon relâcher effacerait la réponse.
    private func majAccord() {
        if let nouveau = CercleDesQuintes.accord(pour: touchesTenues) {
            accord = nouveau
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
            if midi.estConnecte {
                Image(systemName: "pianokeys")
                    .police(16)
                    .foregroundStyle(Nocturne.accent300)
                    .accessibilityLabel("Clavier connecté")
                    .padding(.trailing, accord != nil ? 10 : 0)
            }
            if accord != nil || !touchesDoigt.isEmpty {
                Button("Effacer") {
                    touchesDoigt = []
                    accord = nil
                }
                .police(12.5)
                .foregroundStyle(Nocturne.accent300)
            }
        }
    }

    /// La carte porte deux choses : ce que l'accord joué raconte, et l'accès à
    /// la fiche de la tonalité sélectionnée — toujours présent, puisque c'est
    /// désormais le seul chemin vers elle.
    private var lecture: some View {
        VStack(spacing: 0) {
            if let accord {
                ligneLecture(titre: accord.libelle, detail: rolesTexte)
            } else if touchesTenues.count >= 2 {
                ligneLecture(titre: "\(touchesTenues.count) notes",
                             detail: "Pose une triade — trois notes qui s'empilent en tierces — pour que le cercle la situe.")
            } else {
                ligneLecture(titre: "Ta tonalité",
                             detail: midi.estConnecte
                                ? "Joue un accord sur ton piano : le cercle allumera les tonalités qui le contiennent."
                                : "Sa gamme est allumée au clavier. Joue par-dessus : le cercle situera tes accords.")
            }
            Rectangle()
                .fill(accord != nil ? Nocturne.accent700.opacity(0.5) : Nocturne.neutre800)
                .frame(height: 1)
            ligneFiche
        }
        .background(accord != nil ? Nocturne.accent900.opacity(0.45) : Nocturne.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(accord != nil ? Nocturne.accent700 : Nocturne.neutre700,
                          lineWidth: 1))
    }

    private func ligneLecture(titre: String, detail: String) -> some View {
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
    }

    /// « Fa majeur · 1 bémol › » — la tonalité sélectionnée, et sa fiche.
    private var ligneFiche: some View {
        Button {
            ficheAffichee = tonaliteConsultee
        } label: {
            HStack(spacing: 8) {
                Text(tonaliteConsultee.libelle)
                    .police(13, .medium)
                Text("·")
                    .police(12)
                    .foregroundStyle(Nocturne.neutre600)
                Text(tonaliteConsultee.armureTexte)
                    .police(11.5)
                    .foregroundStyle(Nocturne.neutre400)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .police(11)
                    .foregroundStyle(Nocturne.neutre500)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Fiche de \(tonaliteConsultee.libelle), \(tonaliteConsultee.armureTexte)")
        .accessibilityHint("Ouvre l'armure, la gamme et les accords")
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
        Text(midi.estConnecte
             ? "Joue un accord sur ton piano, ou pose-le au doigt"
             : touchesDoigt.isEmpty
                ? "Touche une tonalité pour allumer sa gamme, ou trois notes pour un accord"
                : "Touche à nouveau une note pour la retirer")
            .police(11)
            .foregroundStyle(Nocturne.neutre500)
            .frame(maxWidth: .infinity)
            .padding(.top, 9)
            .padding(.bottom, 4)
    }

    /// Le clavier superpose quatre niveaux, du plus fort au plus faible : ce qui
    /// sonne maintenant, les notes du dernier accord, la gamme de la tonalité
    /// sélectionnée, et le reste. On voit ainsi *où l'on est* et *ce qu'on joue*
    /// en même temps.
    private var eclairages: [Touche: EclairageTouche] {
        let gamme = tonaliteConsultee.touches
        let notesAccord = accord?.touches ?? []
        return Dictionary(uniqueKeysWithValues: Touche.octave.map { touche in
            if touchesTenues.contains(touche) { return (touche, EclairageTouche.tenue) }
            if notesAccord.contains(touche) { return (touche, .attendue) }
            return (touche, gamme.contains(touche) ? .membre : .eteinte)
        })
    }
}

extension Touche {
    /// Les douze touches d'une octave, blanches et noires.
    static var octave: [Touche] {
        NomNote.allCases.map { Touche.blanche($0) }
        + [NomNote.do, .re, .fa, .sol, .la].map { Touche.noire(entre: $0) }
    }
}
