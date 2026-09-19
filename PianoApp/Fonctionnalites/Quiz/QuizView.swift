import SwiftUI
import SwiftData

/// Le quiz de lecture : la route des paliers, la question chronométrée,
/// la fin de série.
struct QuizView: View {
    @Environment(\.dismiss) private var fermer
    @Environment(GestionnaireMIDI.self) private var midi
    @Environment(\.modelContext) private var contexte
    @Query(sort: \SerieQuiz.date, order: .reverse) private var series: [SerieQuiz]

    @State private var vm: QuizViewModel?
    @State private var montrerBluetooth = false
    /// Le meilleur score du palier **avant** la série en cours : sert à
    /// n'annoncer l'ouverture du palier suivant qu'une seule fois.
    @State private var meilleurAvant = 0

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
                route
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

    // MARK: Données de la route

    /// Le meilleur score obtenu sur chaque palier.
    private var meilleursScores: [Int: Int] {
        series.reduce(into: [:]) { scores, serie in
            guard let numero = serie.palierNumero else { return }
            scores[numero] = max(scores[numero] ?? 0, serie.score)
        }
    }

    private func estMaitrise(_ palier: Palier) -> Bool {
        series.contains { $0.palierNumero == palier.numero && $0.estMaitrise }
    }

    /// Le meilleur temps moyen sur un palier, s'il a déjà été joué au chrono.
    private func meilleurTemps(_ palier: Palier) -> Double? {
        series
            .filter { $0.palierNumero == palier.numero }
            .compactMap(\.tempsMoyenSecondes)
            .min()
    }

    // MARK: La route de lecture

    private var route: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                boutonFermer
                VStack(alignment: .leading, spacing: 1) {
                    Kicker(texte: "Quiz de notes")
                    Text("Ta route de lecture")
                        .police(20, .medium)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                Text("\(nbPaliersAcquis) paliers sur \(RouteLecture.paliers.count)")
                    .police(12.5)
                    .monospacedDigit()
                    .foregroundStyle(Nocturne.neutre300)
                BarreProgression(fraction: Double(nbPaliersAcquis) / Double(RouteLecture.paliers.count))
            }
            .padding(.top, 16)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(RouteLecture.paliers) { palier in
                        lignePalier(palier)
                    }
                }
                .padding(.vertical, 14)
            }

            if !midi.estConnecte {
                Button {
                    montrerBluetooth = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "pianokeys").police(12)
                        Text("Répondre sur mon clavier").police(12.5)
                    }
                    .foregroundStyle(Nocturne.accent300)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .overlay(Capsule().strokeBorder(Nocturne.accent700, lineWidth: 1))
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.bottom, 12)
            }

            BoutonPilule(titre: "Commencer « \(palierEnCours.nom) »") {
                commencer(palierEnCours)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 26)
    }

    private var palierEnCours: Palier {
        RouteLecture.palierEnCours(meilleursScores: meilleursScores)
    }

    private var nbPaliersAcquis: Int {
        RouteLecture.paliers.filter {
            (meilleursScores[$0.numero] ?? 0) >= RouteLecture.scorePourOuvrir
        }.count
    }

    private func lignePalier(_ palier: Palier) -> some View {
        let ouvert = RouteLecture.estOuvert(palier, meilleursScores: meilleursScores)
        let meilleur = meilleursScores[palier.numero] ?? 0
        let acquis = meilleur >= RouteLecture.scorePourOuvrir
        let maitrise = estMaitrise(palier)
        let enCours = palier.numero == palierEnCours.numero

        return Button {
            if ouvert { commencer(palier) }
        } label: {
            HStack(alignment: .top, spacing: 13) {
                pastille(numero: palier.numero, acquis: acquis,
                         maitrise: maitrise, enCours: enCours, ouvert: ouvert)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(palier.nom)
                            .police(14.5, .medium)
                        Spacer(minLength: 8)
                        if meilleur > 0 {
                            Text("\(meilleur) / \(QuizNotes.questionsParSerie)")
                                .police(11.5)
                                .monospacedDigit()
                                .foregroundStyle(acquis ? Nocturne.accent300 : Nocturne.neutre400)
                        }
                    }
                    Text(palier.sousTitre)
                        .police(11.5)
                        .foregroundStyle(Nocturne.neutre400)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                    if let temps = meilleurTemps(palier) {
                        Text(maitrise
                             ? "Maîtrisé · \(tempsTexte(temps)) par note"
                             : "Meilleur temps : \(tempsTexte(temps)) par note")
                            .police(10.5)
                            .monospacedDigit()
                            .foregroundStyle(maitrise ? Nocturne.accent300 : Nocturne.neutre500)
                            .padding(.top, 2)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(enCours ? Nocturne.accent900.opacity(0.55) : Nocturne.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(enCours ? Nocturne.accent : Nocturne.neutre700,
                                  lineWidth: enCours ? 1.5 : 1)
            )
            .opacity(ouvert ? 1 : 0.45)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!ouvert)
        .accessibilityLabel("Palier \(palier.numero), \(palier.nom)")
        .accessibilityValue(etatTexte(ouvert: ouvert, acquis: acquis, maitrise: maitrise))
    }

    private func etatTexte(ouvert: Bool, acquis: Bool, maitrise: Bool) -> String {
        if !ouvert { return "verrouillé" }
        if maitrise { return "maîtrisé" }
        if acquis { return "acquis" }
        return "à travailler"
    }

    private func pastille(numero: Int, acquis: Bool, maitrise: Bool,
                          enCours: Bool, ouvert: Bool) -> some View {
        ZStack {
            Circle()
                .fill(acquis ? Nocturne.accent900 : enCours ? Nocturne.accent : Nocturne.fond)
            Circle()
                .strokeBorder(acquis || enCours ? Nocturne.accent : Nocturne.neutre700,
                              lineWidth: 1.5)
            if maitrise {
                Image(systemName: "star.fill").police(13).foregroundStyle(Nocturne.accent200)
            } else if acquis {
                Image(systemName: "checkmark").police(13, .medium).foregroundStyle(Nocturne.accent200)
            } else if !ouvert {
                Image(systemName: "lock").police(12).foregroundStyle(Nocturne.neutre500)
            } else {
                Text("\(numero)")
                    .police(13, .medium)
                    .monospacedDigit()
                    .foregroundStyle(enCours ? Nocturne.accent900 : Nocturne.neutre300)
            }
        }
        .frame(width: 34, height: 34)
    }

    // MARK: La question

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
                    .police(12)
                    .monospacedDigit()
                    .foregroundStyle(Nocturne.neutre400)
                if midi.estConnecte {
                    Image(systemName: "pianokeys")
                        .police(12)
                        .foregroundStyle(Nocturne.accent300)
                }
            }

            VStack(spacing: 3) {
                Kicker(texte: "Palier \(vm.palier.numero) · \(vm.palier.nom)")
                Text("Quelle est cette note ?")
                    .police(18, .medium)
            }
            .padding(.top, 16)

            chrono(vm)
                .padding(.top, 12)

            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LinearGradient(colors: [Nocturne.neutre800, Nocturne.fond],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Nocturne.neutre700, lineWidth: 1)
                PorteeView(note: vm.note, enSurbrillance: reponseJuste(vm) == true)
            }
            .frame(maxHeight: .infinity)
            .padding(.top, 12)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Portée, note à identifier")

            bandeau(vm)
                .frame(height: 58)
                .padding(.vertical, 6)

            ClavierReponse(correcte: toucheCorrecte(vm), fausse: toucheFausse(vm),
                           active: vm.phase == .question) { touche in
                vm.repondre(touche)
            }
            // Le clavier garde des proportions de piano : on borne la mise à
            // l'échelle du texte pour que les noms de touches restent dedans.
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 26)
        // Rafraîchit le chrono affiché, dix fois par seconde.
        .task(id: vm.numero) {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                vm.tic()
            }
        }
    }

    /// La barre de chrono : un repère, jamais une sanction.
    private func chrono(_ vm: QuizViewModel) -> some View {
        HStack(spacing: 9) {
            Image(systemName: "timer")
                .police(13)
                .foregroundStyle(Nocturne.neutre400)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Nocturne.neutre800)
                    Capsule()
                        .fill(LinearGradient(colors: [Nocturne.accent700, Nocturne.accent],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(geo.size.width * vm.fractionChrono, 3))
                }
            }
            .frame(height: 4)
            Text(tempsTexte(vm.secondesQuestion))
                .police(11.5)
                .monospacedDigit()
                .foregroundStyle(Nocturne.neutre400)
                .frame(width: 44, alignment: .trailing)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Temps sur cette note")
        .accessibilityValue(tempsTexte(vm.secondesQuestion))
    }

    private var boutonFermer: some View {
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
        .accessibilityLabel("Fermer le quiz")
    }

    private func bandeau(_ vm: QuizViewModel) -> some View {
        Group {
            switch vm.phase {
            case .repondu(_, let juste) where juste:
                ligneBandeau(icone: "checkmark.circle.fill", teinte: Nocturne.accent300,
                             texte: "Juste ! \(vm.note.nomComplet) — \(vm.note.libellePosition).",
                             fond: Nocturne.accent900, bord: Nocturne.accent700)
            case .repondu:
                ligneBandeau(icone: "arrow.counterclockwise.circle.fill", teinte: Nocturne.neutre300,
                             texte: "Pas encore — c'était \(vm.note.nomComplet), \(vm.note.libellePosition).",
                             fond: Nocturne.surface, bord: Nocturne.neutre700)
            default:
                HStack(spacing: 6) {
                    if vm.serieEnCours >= 2 {
                        Image(systemName: "flame.fill").police(13)
                        Text("\(vm.serieEnCours) d'affilée").police(12.5)
                    }
                }
                .foregroundStyle(Nocturne.accent300)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func ligneBandeau(icone: String, teinte: Color, texte: String,
                              fond: Color, bord: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icone)
                .police(18)
                .foregroundStyle(teinte)
            Text(texte)
                .police(13)
                .foregroundStyle(teinte)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
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
        let ouvre = RouteLecture.ouvreLeSuivant(palier: vm.palier, score: vm.score,
                                                meilleurScorePrecedent: meilleurAvant)
        let maitrise = RouteLecture.estMaitrise(score: vm.score,
                                                total: QuizNotes.questionsParSerie,
                                                tempsMoyen: vm.tempsMoyen)
        return ScrollView {
            VStack(spacing: 0) {
                Kicker(texte: "Palier \(vm.palier.numero) · \(vm.palier.nom)")
                    .padding(.top, 40)
                Text("\(vm.score) / \(QuizNotes.questionsParSerie)")
                    .police(60, .medium)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(Nocturne.accent200)
                    .shadow(color: Nocturne.lueur, radius: 15)
                    .padding(.top, 10)
                Text(messageFin(vm, maitrise: maitrise))
                    .police(13)
                    .foregroundStyle(Nocturne.neutre300)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .frame(maxWidth: 290)
                    .padding(.top, 10)

                tuiles(vm)
                    .padding(.top, 20)

                if ouvre, let suivant = RouteLecture.suivant(vm.palier) {
                    banniere(icone: "lock.open.fill",
                             titre: "Palier \(suivant.numero) ouvert",
                             sousTitre: suivant.nom + " — " + suivant.sousTitre)
                        .padding(.top, 16)
                } else if maitrise {
                    banniere(icone: "star.fill",
                             titre: "Palier maîtrisé",
                             sousTitre: "Sans faute et sous \(Int(RouteLecture.secondesPourMaitrise)) s par note.")
                        .padding(.top, 16)
                }

                if let lente = vm.noteLaPlusLente, lente.secondes > 1 {
                    carteNoteLente(lente, reference: vm.secondesRepere)
                        .padding(.top, 16)
                }

                Spacer(minLength: 24)

                if ouvre, let suivant = RouteLecture.suivant(vm.palier) {
                    BoutonPilule(titre: "Passer au palier \(suivant.numero)") {
                        commencer(suivant)
                    }
                    Button("Refaire ce palier") { commencer(vm.palier) }
                        .police(13)
                        .foregroundStyle(Nocturne.neutre400)
                        .padding(.top, 14)
                } else {
                    BoutonPilule(titre: "Rejouer ce palier") { commencer(vm.palier) }
                    Button("Revenir à la route") { self.vm = nil }
                        .police(13)
                        .foregroundStyle(Nocturne.neutre400)
                        .padding(.top, 14)
                }
                Button("Terminer") { fermer() }
                    .police(13)
                    .foregroundStyle(Nocturne.neutre500)
                    .padding(.top, 10)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 26)
            .padding(.bottom, 26)
        }
    }

    private func tuiles(_ vm: QuizViewModel) -> some View {
        HStack(spacing: 10) {
            tuile(valeur: vm.tempsMoyen.map(tempsTexte) ?? "—",
                  legende: legendeTemps(vm),
                  accent: true)
            tuile(valeur: "\(vm.meilleureSerie)",
                  legende: "d'affilée sans faute")
        }
    }

    /// Situe le temps moyen par rapport au record du palier.
    private func legendeTemps(_ vm: QuizViewModel) -> String {
        guard let moyen = vm.tempsMoyen else { return "par note" }
        // Le record enregistré inclut déjà cette série : on compare aux autres.
        let autres = series
            .filter { $0.palierNumero == vm.palier.numero }
            .dropFirst()
            .compactMap(\.tempsMoyenSecondes)
        guard let record = autres.min() else { return "par note · premier temps" }
        if moyen < record { return "par note · nouveau record" }
        return "par note · record \(tempsTexte(record))"
    }

    private func tuile(valeur: String, legende: String, accent: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(valeur)
                .police(20, .medium)
                .monospacedDigit()
                .foregroundStyle(accent ? Nocturne.accent300 : Nocturne.texte)
            Text(legende)
                .police(10.5)
                .foregroundStyle(Nocturne.neutre400)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .carteNocturne()
    }

    private func banniere(icone: String, titre: String, sousTitre: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icone)
                .police(21)
                .foregroundStyle(Nocturne.accent300)
            VStack(alignment: .leading, spacing: 2) {
                Text(titre)
                    .police(14, .medium)
                    .foregroundStyle(Nocturne.accent200)
                Text(sousTitre)
                    .police(11.5)
                    .foregroundStyle(Nocturne.neutre300)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Nocturne.accent900.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(Nocturne.accent700, lineWidth: 1))
    }

    private func carteNoteLente(_ reponse: QuizViewModel.Reponse,
                                reference: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("La note qui t'a coûté le plus de temps")
                .police(12, .medium)
                .foregroundStyle(Nocturne.neutre300)
            HStack(spacing: 10) {
                Text(reponse.note.nomComplet)
                    .police(15, .medium)
                    .frame(width: 46, alignment: .leading)
                BarreProgression(fraction: min(reponse.secondes / reference, 1))
                Text(tempsTexte(reponse.secondes))
                    .police(11)
                    .monospacedDigit()
                    .foregroundStyle(Nocturne.neutre400)
                    .frame(width: 44, alignment: .trailing)
            }
            Text(reponse.note.libellePosition.prefix(1).uppercased()
                 + reponse.note.libellePosition.dropFirst())
                .police(11)
                .foregroundStyle(Nocturne.neutre500)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .carteNocturne()
    }

    private func messageFin(_ vm: QuizViewModel, maitrise: Bool) -> String {
        if maitrise { return "Sans faute, et vite. Ce palier est derrière toi." }
        switch vm.score {
        case QuizNotes.questionsParSerie:
            return "Sans faute. Gagne encore un peu de vitesse et le palier sera maîtrisé."
        case RouteLecture.scorePourOuvrir...:
            return "Le palier est acquis. La suite t'attend."
        case 5...:
            return "Ça vient. La lecture se gagne comme les heures — en répétant."
        default:
            return "Tous les grands lecteurs ont commencé ici. Rejoue une série."
        }
    }

    // MARK: Actions

    private func tempsTexte(_ secondes: Double) -> String {
        String(format: "%.1f s", secondes).replacingOccurrences(of: ".", with: ",")
    }

    /// Lance une série sur ce palier et branche le clavier MIDI dessus.
    private func commencer(_ palier: Palier) {
        meilleurAvant = meilleursScores[palier.numero] ?? 0
        let nouveau = QuizViewModel(palier: palier)
        vm = nouveau
        midi.abonner("quiz") { [weak nouveau] noteMIDI in
            nouveau?.repondre(Touche.depuisNoteMIDI(noteMIDI))
        }
    }

    /// Enregistre la série terminée et chacune de ses réponses.
    private func enregistrerSerie() {
        guard let vm, !vm.reponses.isEmpty else { return }
        let serie = SerieQuiz(cleLibelle: vm.palier.cles.map(\.libelle).joined(separator: " + "),
                              avecAlterations: vm.palier.avecAlterations,
                              score: vm.score,
                              total: QuizNotes.questionsParSerie,
                              palierNumero: vm.palier.numero,
                              tempsMoyenSecondes: vm.tempsMoyen)
        contexte.insert(serie)
        for reponse in vm.reponses {
            let ligne = ReponseQuiz(note: reponse.note.nomComplet,
                                    position: reponse.note.position,
                                    juste: reponse.juste,
                                    secondes: reponse.secondes)
            ligne.serie = serie
            contexte.insert(ligne)
        }
    }
}
