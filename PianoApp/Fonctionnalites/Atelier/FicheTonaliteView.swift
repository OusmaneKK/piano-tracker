import SwiftUI

/// La fiche d'une tonalité : son armure, sa gamme sur le clavier, ses sept
/// degrés et ses voisines sur le cercle.
struct FicheTonaliteView: View {
    let tonalite: Tonalite

    @Environment(\.dismiss) private var fermer
    @State private var mode: ModeTonal

    init(tonalite: Tonalite) {
        self.tonalite = tonalite
        _mode = State(initialValue: tonalite.mode)
    }

    /// La tonalité réellement affichée, selon le sélecteur majeur/mineur.
    private var affichee: Tonalite {
        mode == tonalite.mode ? tonalite : tonalite.relative
    }

    var body: some View {
        ZStack {
            Nocturne.fond.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    entete
                    selecteur
                    carteGamme
                    titreSection("Les accords de la tonalité")
                        .padding(.top, 18)
                    grilleDegres
                    Text("Les trois piliers sont en accent : avec I, IV et V tu accompagnes déjà une grande part du répertoire.")
                        .police(11.5)
                        .foregroundStyle(Nocturne.neutre400)
                        .lineSpacing(2)
                        .padding(.top, 8)
                    titreSection("Les tonalités voisines")
                        .padding(.top, 20)
                    voisines
                    Text("Elles partagent presque toutes leurs notes avec \(affichee.libelle) : c'est pour ça qu'on passe de l'une à l'autre sans que l'oreille tique.")
                        .police(11.5)
                        .foregroundStyle(Nocturne.neutre400)
                        .lineSpacing(2)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .foregroundStyle(Nocturne.texte)
    }

    // MARK: Sections

    private var entete: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Kicker(texte: affichee.armureTexte)
                Text(affichee.libelle)
                    .police(21, .medium)
            }
            Spacer()
            Button {
                fermer()
            } label: {
                Image(systemName: "xmark")
                    .police(14)
                    .foregroundStyle(Nocturne.neutre300)
                    .frame(width: 34, height: 34)
                    .overlay(Circle().strokeBorder(Nocturne.neutre700, lineWidth: 1))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Fermer la fiche")
        }
        .padding(.top, 20)
    }

    private var selecteur: some View {
        HStack(spacing: 4) {
            boutonMode(.majeur)
            boutonMode(.mineur)
        }
        .padding(3)
        .background(Nocturne.neutre900)
        .clipShape(Capsule())
        .padding(.top, 16)
    }

    private func boutonMode(_ candidat: ModeTonal) -> some View {
        let tonaliteDuMode = candidat == tonalite.mode ? tonalite : tonalite.relative
        let actif = mode == candidat
        return Button {
            mode = candidat
        } label: {
            Text(tonaliteDuMode.libelle)
                .police(12.5)
                .foregroundStyle(actif ? Nocturne.accent200 : Nocturne.neutre400)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(actif ? Nocturne.accent900 : .clear)
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(actif ? Nocturne.accent700 : .clear,
                                                lineWidth: 1))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var carteGamme: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("La gamme — " + affichee.gamme.map(\.libelle).joined(separator: " "))
                .police(11.5)
                .foregroundStyle(Nocturne.neutre400)
                .fixedSize(horizontal: false, vertical: true)
            ClavierPiano(eclairages: eclairagesGamme, active: false, hauteur: 104)
                .padding(.top, 10)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Gamme de \(affichee.libelle) : "
                                    + affichee.gamme.map(\.libelle).joined(separator: ", "))
            Text(noteHorsGamme)
                .police(10.5)
                .foregroundStyle(Nocturne.neutre500)
                .lineSpacing(2)
                .padding(.top, 8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .carteNocturne()
        .padding(.top, 14)
    }

    private var eclairagesGamme: [Touche: EclairageTouche] {
        let gamme = affichee.touches
        let tonique = affichee.tonique.touche
        return Dictionary(uniqueKeysWithValues: Touche.octave.map { touche in
            if touche == tonique { return (touche, EclairageTouche.attendue) }
            return (touche, gamme.contains(touche) ? .membre : .eteinte)
        })
    }

    /// Une phrase qui pointe ce que cette tonalité a de particulier.
    private var noteHorsGamme: String {
        guard let premiere = affichee.armure.first else {
            return "Aucune altération : que des touches blanches. C'est la tonalité de départ."
        }
        return "La tonique est en accent. \(premiere.libelle) est allumée à la place du \(premiere.nom.rawValue) naturel — c'est ce qui distingue cette tonalité."
    }

    private var grilleDegres: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 7), count: 4),
                  spacing: 7) {
            ForEach(affichee.degres) { degre in
                let pilier = degre.fonction != nil
                VStack(spacing: 2) {
                    Text(degre.chiffrage)
                        .police(10.5)
                        .foregroundStyle(pilier ? Nocturne.accent300 : Nocturne.neutre400)
                    Text(degre.accord.libelle)
                        .police(13, .medium)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(pilier ? Nocturne.accent900.opacity(0.55) : Nocturne.fond)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(pilier ? Nocturne.accent700 : Nocturne.neutre700,
                                  lineWidth: 1))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Degré \(degre.chiffrage), \(degre.accord.libelle)"
                                    + (degre.fonction.map { ", \($0)" } ?? ""))
            }
        }
        .padding(.top, 10)
    }

    private var voisines: some View {
        HStack(spacing: 8) {
            ForEach(CercleDesQuintes.voisines(de: affichee), id: \.id) { voisine in
                VStack(spacing: 2) {
                    Text(voisine.libelle)
                        .police(12.5, .medium)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text(ecartTexte(voisine))
                        .police(10)
                        .foregroundStyle(Nocturne.neutre400)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .carteNocturne()
            }
        }
        .padding(.top, 10)
    }

    /// Combien de notes séparent deux tonalités voisines.
    private func ecartTexte(_ voisine: Tonalite) -> String {
        let communes = voisine.touches.intersection(affichee.touches).count
        return communes == 7 ? "mêmes notes" : "\(communes) notes en commun"
    }

    private func titreSection(_ texte: String) -> some View {
        Text(texte)
            .police(12, .medium)
            .foregroundStyle(Nocturne.neutre300)
    }
}
