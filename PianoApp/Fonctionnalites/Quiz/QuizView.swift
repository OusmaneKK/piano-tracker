import SwiftUI

/// L'écran du quiz de notes (design « mini-clavier ») : portée en grand,
/// bandeau pédagogique, réponse en touchant la touche du piano.
struct QuizView: View {
    @Environment(\.dismiss) private var fermer
    @State private var vm = QuizViewModel()

    var body: some View {
        ZStack {
            Nocturne.fond.ignoresSafeArea()
            if vm.phase == .termine {
                fin
            } else {
                questionEnCours
            }
        }
        .foregroundStyle(Nocturne.texte)
    }

    // MARK: Question

    private var questionEnCours: some View {
        VStack(spacing: 0) {
            entete
            Kicker(texte: "Quiz de notes · Clé de sol")
                .padding(.top, 24)
            Text("Quelle est cette note ?")
                .font(.system(size: 19, weight: .medium))
                .padding(.top, 4)

            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LinearGradient(colors: [Nocturne.neutre800, Nocturne.fond],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Nocturne.neutre700, lineWidth: 1)
                PorteeView(note: vm.note, enSurbrillance: reponseJuste == true)
            }
            .frame(maxHeight: .infinity)
            .padding(.top, 18)

            bandeau
                .frame(height: 64)
                .padding(.vertical, 6)

            ClavierReponse(correcte: nomCorrect, fausse: nomFaux,
                           active: vm.phase == .question) { nom in
                vm.repondre(nom)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 26)
    }

    private var entete: some View {
        HStack(spacing: 14) {
            Button {
                fermer()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14))
                    .foregroundStyle(Nocturne.neutre300)
                    .frame(width: 34, height: 34)
                    .overlay(Circle().strokeBorder(Nocturne.neutre700, lineWidth: 1))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Nocturne.neutre800)
                    Capsule()
                        .fill(Nocturne.accent)
                        .frame(width: geo.size.width * Double(vm.numero) / Double(QuizNotes.questionsParSerie))
                        .shadow(color: Nocturne.lueur, radius: 4)
                }
            }
            .frame(height: 5)
            Text("\(vm.numero) / \(QuizNotes.questionsParSerie)")
                .font(.system(size: 12))
                .monospacedDigit()
                .foregroundStyle(Nocturne.neutre400)
        }
    }

    private var bandeau: some View {
        Group {
            switch vm.phase {
            case .repondu(_, let juste) where juste:
                ligneBandeau(icone: "checkmark.circle.fill", teinte: Nocturne.accent300,
                             texte: "Juste ! C'était \(vm.note.nom.rawValue) — \(vm.note.libellePosition).",
                             fond: Nocturne.accent900, bord: Nocturne.accent700)
            case .repondu:
                ligneBandeau(icone: "arrow.counterclockwise.circle.fill", teinte: Nocturne.neutre300,
                             texte: "Pas encore — c'était \(vm.note.nom.rawValue), \(vm.note.libellePosition).",
                             fond: Nocturne.surface, bord: Nocturne.neutre700)
            default:
                Color.clear
            }
        }
    }

    private func ligneBandeau(icone: String, teinte: Color, texte: String,
                              fond: Color, bord: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icone)
                .font(.system(size: 19))
                .foregroundStyle(teinte)
            Text(texte)
                .font(.system(size: 13.5))
                .foregroundStyle(teinte)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .frame(maxHeight: .infinity)
        .background(fond)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(bord, lineWidth: 1))
    }

    private var reponseJuste: Bool? {
        if case .repondu(_, let juste) = vm.phase { return juste }
        return nil
    }

    private var nomCorrect: NomNote? {
        vm.estRepondu ? vm.note.nom : nil
    }

    private var nomFaux: NomNote? {
        if case .repondu(let choix, let juste) = vm.phase, !juste { return choix }
        return nil
    }

    // MARK: Fin de série

    private var fin: some View {
        VStack(spacing: 0) {
            Spacer()
            Kicker(texte: "Série terminée")
            Text("\(vm.score) / \(QuizNotes.questionsParSerie)")
                .font(.system(size: 64, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(Nocturne.accent200)
                .shadow(color: Nocturne.lueur, radius: 15)
                .padding(.top, 14)
            Text(messageFin)
                .font(.system(size: 13.5))
                .foregroundStyle(Nocturne.neutre300)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: 290)
                .padding(.top, 16)
            Spacer()
            BoutonPilule(titre: "Rejouer une série") { vm.rejouer() }
            Button("Terminer") { fermer() }
                .font(.system(size: 13))
                .foregroundStyle(Nocturne.neutre400)
                .padding(.top, 14)
        }
        .padding(.horizontal, 26)
        .padding(.bottom, 26)
    }

    private var messageFin: String {
        switch vm.score {
        case QuizNotes.questionsParSerie:
            return "Sans faute. La clé de sol commence à se lire comme du texte."
        case 7...:
            return "Solide. Encore quelques séries et la lecture deviendra automatique."
        case 4...:
            return "Ça vient. La lecture se gagne comme les heures — en répétant."
        default:
            return "Tous les grands lecteurs ont commencé ici. Rejoue une série."
        }
    }
}

/// La portée en clé de sol : cinq lignes, la clé, une note avec sa hampe.
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
            Text("\u{1D11E}")
                .font(.system(size: 100))
                .foregroundStyle(Nocturne.neutre200)
                .offset(x: -largeur / 2 + 32, y: -2)
            if note.ligneSupplementaire {
                Rectangle()
                    .fill(Nocturne.neutre400)
                    .frame(width: 44, height: 2)
                    .offset(x: xNote, y: y(position: -2))
            }
            groupeNote
        }
        .frame(width: largeur, height: 200)
        .animation(.easeOut(duration: 0.15), value: enSurbrillance)
    }

    private var xNote: CGFloat { 34 }

    private func y(position: Int) -> CGFloat {
        CGFloat(4 - position) * interligne / 2
    }

    private var groupeNote: some View {
        let teinte = enSurbrillance ? Nocturne.accent300 : Nocturne.texte
        return ZStack {
            Ellipse()
                .fill(teinte)
                .frame(width: 26, height: 19)
                .rotationEffect(.degrees(-18))
                .shadow(color: enSurbrillance ? Nocturne.lueur : .clear, radius: 8)
            Rectangle()
                .fill(teinte)
                .frame(width: 2.5, height: 58)
                .offset(x: note.hampeVersLeBas ? -11.5 : 11.5,
                        y: note.hampeVersLeBas ? 29 : -29)
        }
        .offset(x: xNote, y: y(position: note.position))
    }
}

/// Une octave de piano pour répondre : sept touches blanches actives,
/// cinq touches noires décoratives (aucune altération au quiz v1 —
/// elles s'activeront avec les dièses/bémols, puis le clavier MIDI).
struct ClavierReponse: View {
    let correcte: NomNote?
    let fausse: NomNote?
    let active: Bool
    var choisir: (NomNote) -> Void

    /// Index des touches blanches suivies d'une touche noire (Do, Ré, Fa, Sol, La).
    private static let positionsNoires = [0, 1, 3, 4, 5]

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
                ForEach(Self.positionsNoires, id: \.self) { indice in
                    UnevenRoundedRectangle(topLeadingRadius: 2, bottomLeadingRadius: 5,
                                           bottomTrailingRadius: 5, topTrailingRadius: 2)
                        .fill(Nocturne.neutre900)
                        .overlay(UnevenRoundedRectangle(topLeadingRadius: 2, bottomLeadingRadius: 5,
                                                        bottomTrailingRadius: 5, topTrailingRadius: 2)
                            .strokeBorder(Nocturne.neutre700, lineWidth: 1))
                        .frame(width: largeurTouche * 0.58, height: 78)
                        .offset(x: (largeurTouche + espace) * CGFloat(indice + 1)
                                    - espace / 2 - largeurTouche * 0.29)
                        .allowsHitTesting(false)
                }
            }
        }
        .frame(height: 132)
    }

    private func toucheBlanche(_ nom: NomNote) -> some View {
        let estCorrecte = nom == correcte
        let estFausse = nom == fausse
        let fond: Color = estCorrecte ? Nocturne.accent300
            : estFausse ? Nocturne.neutre600 : Nocturne.neutre200
        return Button {
            choisir(nom)
        } label: {
            UnevenRoundedRectangle(topLeadingRadius: 4, bottomLeadingRadius: 8,
                                   bottomTrailingRadius: 8, topTrailingRadius: 4)
                .fill(fond)
                .shadow(color: estCorrecte ? Nocturne.lueur : .clear, radius: 11)
                .overlay(alignment: .bottom) {
                    Text(nom.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(estCorrecte ? Nocturne.accent900 : Nocturne.neutre800)
                        .padding(.bottom, 10)
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!active)
    }
}
