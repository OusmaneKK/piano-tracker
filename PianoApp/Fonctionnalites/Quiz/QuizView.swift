import SwiftUI
import SwiftData

/// L'écran du quiz de notes (design « mini-clavier ») : réglages de la série,
/// portée en grand, bandeau pédagogique, réponse en touchant la touche du piano.
struct QuizView: View {
    @Environment(\.dismiss) private var fermer
    @State private var cle: Cle = .sol
    @State private var avecAlterations = false
    @State private var vm: QuizViewModel?
    @Environment(GestionnaireMIDI.self) private var midi
    @Environment(\.modelContext) private var contexte
    @Query(sort: \SerieQuiz.date, order: .reverse) private var series: [SerieQuiz]
    @State private var montrerBluetooth = false

    var body: some View {
        ZStack {
            Nocturne.fond.ignoresSafeArea()
            if let vm {
                if vm.phase == .termine {
                    fin(vm)
                } else {
                    question(vm)
                }
            } else {
                reglages
            }
        }
        .foregroundStyle(Nocturne.texte)
        .task { midi.demarrer() }
        .onDisappear { midi.desabonner("quiz") }
        // La série n'est enregistrée qu'une fois terminée : un score partiel
        // ne dirait rien de la progression.
        .onChange(of: vm?.phase) { _, nouvelle in
            if nouvelle == .termine { enregistrerSerie() }
        }
        .sheet(isPresented: $montrerBluetooth) {
            ConnexionBluetoothMIDI()
                .ignoresSafeArea()
        }
    }

    /// Enregistre la série terminée et chacune de ses réponses.
    private func enregistrerSerie() {
        guard let vm, !vm.reponses.isEmpty else { return }
        let serie = SerieQuiz(cleLibelle: vm.cle.libelle,
                              avecAlterations: vm.avecAlterations,
                              score: vm.score,
                              total: QuizNotes.questionsParSerie)
        contexte.insert(serie)
        for reponse in vm.reponses {
            let ligne = ReponseQuiz(note: reponse.note.nomComplet,
                                    position: reponse.note.position,
                                    juste: reponse.juste)
            ligne.serie = serie
            contexte.insert(ligne)
        }
    }

    /// Lance une série et branche le clavier MIDI dessus : note jouée = touche.
    private func commencerSerie() {
        let nouveau = QuizViewModel(cle: cle, avecAlterations: avecAlterations)
        vm = nouveau
        midi.abonner("quiz") { [weak nouveau] noteMIDI in
            nouveau?.repondre(Touche.depuisNoteMIDI(noteMIDI))
        }
    }

    // MARK: Réglages de la série

    private var reglages: some View {
        VStack(spacing: 0) {
            HStack {
                boutonFermer
                Spacer()
            }
            Kicker(texte: "Quiz de notes")
                .padding(.top, 26)
            Text("Ta série de \(QuizNotes.questionsParSerie)")
                .font(.system(size: 22, weight: .medium))
                .padding(.top, 6)

            VStack(spacing: 10) {
                ForEach(Cle.allCases, id: \.self) { option in
                    ligneCle(option)
                }
            }
            .padding(.top, 26)

            Toggle(isOn: $avecAlterations) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Altérations ♯ ♭")
                        .font(.system(size: 15, weight: .medium))
                    Text("Les touches noires entrent en jeu")
                        .font(.system(size: 11.5))
                        .foregroundStyle(Nocturne.neutre400)
                }
            }
            .tint(Nocturne.accent)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .carteNocturne()
            .padding(.top, 10)

            HStack(spacing: 14) {
                Image(systemName: "pianokeys")
                    .font(.system(size: 19))
                    .foregroundStyle(midi.estConnecte ? Nocturne.accent300 : Nocturne.neutre400)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Clavier MIDI")
                        .font(.system(size: 15, weight: .medium))
                    Text(midi.estConnecte
                         ? "Connecté — joue les notes pour répondre"
                         : "Réponds en jouant les vraies touches")
                        .font(.system(size: 11.5))
                        .foregroundStyle(midi.estConnecte ? Nocturne.accent300 : Nocturne.neutre400)
                }
                Spacer()
                if !midi.estConnecte {
                    Button("Bluetooth…") { montrerBluetooth = true }
                        .font(.system(size: 12.5))
                        .foregroundStyle(Nocturne.accent300)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .overlay(Capsule().strokeBorder(Nocturne.accent700, lineWidth: 1))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .carteNocturne()
            .padding(.top, 10)

            Spacer()
            BoutonPilule(titre: "Commencer la série") { commencerSerie() }
        }
        .padding(.horizontal, 26)
        .padding(.top, 14)
        .padding(.bottom, 26)
    }

    private func ligneCle(_ option: Cle) -> some View {
        let choisie = cle == option
        return Button {
            cle = option
        } label: {
            HStack(spacing: 14) {
                Text(option == .sol ? "\u{1D11E}" : "\u{1D122}")
                    .font(.system(size: option == .sol ? 34 : 26))
                    .frame(width: 34)
                VStack(alignment: .leading, spacing: 1) {
                    Text(option.libelle)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(choisie ? Nocturne.accent200 : Nocturne.texte)
                    Text(option == .sol ? "Main droite · Do4 à Fa5" : "Main gauche · Sol2 à Do4")
                        .font(.system(size: 11.5))
                        .foregroundStyle(Nocturne.neutre400)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(choisie ? Nocturne.accent900 : Nocturne.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(choisie ? Nocturne.accent : Nocturne.neutre700, lineWidth: 1.5))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Question

    private func question(_ vm: QuizViewModel) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                boutonFermer
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
                if midi.estConnecte {
                    Image(systemName: "pianokeys")
                        .font(.system(size: 12))
                        .foregroundStyle(Nocturne.accent300)
                }
            }
            Kicker(texte: "Quiz de notes · \(vm.cle.libelle)")
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
                PorteeView(note: vm.note, enSurbrillance: reponseJuste(vm) == true)
            }
            .frame(maxHeight: .infinity)
            .padding(.top, 18)

            bandeau(vm)
                .frame(height: 64)
                .padding(.vertical, 6)

            ClavierReponse(correcte: toucheCorrecte(vm), fausse: toucheFausse(vm),
                           active: vm.phase == .question) { touche in
                vm.repondre(touche)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 26)
    }

    private var boutonFermer: some View {
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
    }

    private func bandeau(_ vm: QuizViewModel) -> some View {
        Group {
            switch vm.phase {
            case .repondu(_, let juste) where juste:
                ligneBandeau(icone: "checkmark.circle.fill", teinte: Nocturne.accent300,
                             texte: "Juste ! C'était \(vm.note.nomComplet) — \(vm.note.libellePosition).",
                             fond: Nocturne.accent900, bord: Nocturne.accent700)
            case .repondu:
                ligneBandeau(icone: "arrow.counterclockwise.circle.fill", teinte: Nocturne.neutre300,
                             texte: "Pas encore — c'était \(vm.note.nomComplet), \(vm.note.libellePosition).",
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

    private func reponseJuste(_ vm: QuizViewModel) -> Bool? {
        if case .repondu(_, let juste) = vm.phase { return juste }
        return nil
    }

    private func toucheCorrecte(_ vm: QuizViewModel) -> Touche? {
        vm.estRepondu ? vm.note.toucheAttendue : nil
    }

    private func toucheFausse(_ vm: QuizViewModel) -> Touche? {
        if case .repondu(let choix, let juste) = vm.phase, !juste { return choix }
        return nil
    }

    // MARK: Fin de série

    private func fin(_ vm: QuizViewModel) -> some View {
        VStack(spacing: 0) {
            Spacer()
            Kicker(texte: "Série terminée · \(vm.cle.libelle)\(vm.avecAlterations ? " · ♯♭" : "")")
            Text("\(vm.score) / \(QuizNotes.questionsParSerie)")
                .font(.system(size: 64, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(Nocturne.accent200)
                .shadow(color: Nocturne.lueur, radius: 15)
                .padding(.top, 14)
            Text(messageFin(vm))
                .font(.system(size: 13.5))
                .foregroundStyle(Nocturne.neutre300)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: 290)
                .padding(.top, 16)
            if let comparaison = comparaisonTexte(vm) {
                Text(comparaison)
                    .font(.system(size: 12.5))
                    .monospacedDigit()
                    .foregroundStyle(Nocturne.accent300)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
            }
            Spacer()
            BoutonPilule(titre: "Rejouer une série") { vm.rejouer() }
            Button("Changer les réglages") { self.vm = nil }
                .font(.system(size: 13))
                .foregroundStyle(Nocturne.neutre400)
                .padding(.top, 14)
            Button("Terminer") { fermer() }
                .font(.system(size: 13))
                .foregroundStyle(Nocturne.neutre400)
                .padding(.top, 10)
        }
        .padding(.horizontal, 26)
        .padding(.bottom, 26)
    }

    /// Situe la série dans l'historique : record battu, ou meilleur score connu.
    private func comparaisonTexte(_ vm: QuizViewModel) -> String? {
        // La série qui vient de finir est déjà enregistrée : on compare aux autres.
        let precedentes = series.dropFirst().map(\.score)
        guard let meilleur = precedentes.max() else { return nil }
        if vm.score > meilleur { return "Nouveau record — le précédent était \(meilleur) / \(QuizNotes.questionsParSerie)." }
        if vm.score == meilleur { return "Tu égales ton meilleur score." }
        return "Ton meilleur : \(meilleur) / \(QuizNotes.questionsParSerie) · \(precedentes.count + 1) séries jouées."
    }

    private func messageFin(_ vm: QuizViewModel) -> String {
        switch vm.score {
        case QuizNotes.questionsParSerie:
            return "Sans faute. \(vm.cle.libelle) commence à se lire comme du texte."
        case 7...:
            return "Solide. Encore quelques séries et la lecture deviendra automatique."
        case 4...:
            return "Ça vient. La lecture se gagne comme les heures — en répétant."
        default:
            return "Tous les grands lecteurs ont commencé ici. Rejoue une série."
        }
    }
}

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
/// noires, toutes actives. Le même geste servira au clavier MIDI.
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
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(estCorrecte ? Nocturne.accent900 : Nocturne.neutre800)
                        .padding(.bottom, 10)
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!active)
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
    }
}
