import XCTest
@testable import PianoApp

final class CercleDesQuintesTests: XCTestCase {

    private let doMajeur = Tonalite(NoteEcrite(.do), .majeur)
    private let faMajeur = Tonalite(NoteEcrite(.fa), .majeur)

    /// L'accord bâti sur ces touches, tel que le cercle le nomme.
    private func accord(_ touches: Touche...) -> Accord {
        CercleDesQuintes.accord(pour: Set(touches))!
    }

    // MARK: Le cercle

    func testDouzePositionsDepuisDo() {
        XCTAssertEqual(CercleDesQuintes.majeures.count, 12)
        XCTAssertEqual(CercleDesQuintes.majeures.first?.libelle, "Do majeur")
        XCTAssertEqual(CercleDesQuintes.majeures.last?.libelle, "Fa majeur")
    }

    func testChaquePositionMonteDUneQuinte() {
        let classes = CercleDesQuintes.majeures.map(\.tonique.classeDeHauteur)
        for indice in 0..<12 {
            let suivante = classes[(indice + 1) % 12]
            XCTAssertEqual((classes[indice] + 7) % 12, suivante,
                           "position \(indice)")
        }
    }

    func testVingtQuatreTonalitesToutesDistinctes() {
        let toutes = CercleDesQuintes.toutes
        XCTAssertEqual(toutes.count, 24)
        XCTAssertEqual(Set(toutes.map(\.libelle)).count, 24)
    }

    func testASixAlterationsOnEcritSolBemol() {
        // Décision actée : Sol♭ majeur et mi♭ mineur, pas Fa♯ / ré♯.
        let sixiemePosition = CercleDesQuintes.majeures[6]
        XCTAssertEqual(sixiemePosition.libelle, "Sol♭ majeur")
        XCTAssertEqual(sixiemePosition.relative.libelle, "mi♭ mineur")
    }

    func testUneMineureOccupeLaPositionDeSaRelative() {
        XCTAssertEqual(CercleDesQuintes.index(de: doMajeur), 0)
        XCTAssertEqual(CercleDesQuintes.index(de: doMajeur.relative), 0)
        XCTAssertEqual(CercleDesQuintes.index(de: faMajeur), 11)
    }

    func testAnglesDuCercle() {
        XCTAssertEqual(CercleDesQuintes.angle(index: 0), -90)   // Do en haut
        XCTAssertEqual(CercleDesQuintes.angle(index: 3), 0)     // La à droite
        XCTAssertEqual(CercleDesQuintes.angle(index: 6), 90)    // Sol♭ en bas
    }

    func testVoisinesDeDoMajeur() {
        let voisines = CercleDesQuintes.voisines(de: doMajeur).map(\.libelle)
        XCTAssertEqual(Set(voisines), ["Sol majeur", "Fa majeur", "la mineur"])
    }

    func testLeCercleBoucle() {
        // Fa est en position 11 : sa voisine « une quinte au-dessus » est Do,
        // en position 0. C'est le modulo qu'on oublie une fois sur deux.
        let voisines = CercleDesQuintes.voisines(de: faMajeur).map(\.libelle)
        XCTAssertTrue(voisines.contains("Do majeur"), "\(voisines)")
        XCTAssertTrue(voisines.contains("Si♭ majeur"), "\(voisines)")
    }

    // MARK: Lire un accord joué

    func testAccordMajeurReconnuEtNomme() {
        let joue = accord(.blanche(.do), .blanche(.mi), .blanche(.sol))
        XCTAssertEqual(joue.libelle, "Do")
        XCTAssertEqual(joue.qualite, .majeur)
    }

    func testAccordMineurReconnuEtNomme() {
        let joue = accord(.blanche(.re), .blanche(.fa), .blanche(.la))
        XCTAssertEqual(joue.libelle, "Ré m")
        XCTAssertEqual(joue.qualite, .mineur)
    }

    func testAccordSurTouchesNoiresReconnu() {
        // Si♭ – Ré – Fa : la tierce fait quatre demi-tons, l'accord est majeur,
        // et il se nomme « Si♭ » et non « La♯ » — le cercle choisit l'écriture.
        let joue = accord(.noire(entre: .la), .blanche(.re), .blanche(.fa))
        XCTAssertEqual(joue.qualite, .majeur)
        XCTAssertEqual(joue.libelle, "Si♭")
        XCTAssertEqual(joue.notes.map(\.libelle), ["Si♭", "Ré", "Fa"])
    }

    func testDeuxNotesNeFontPasUnAccord() {
        XCTAssertNil(CercleDesQuintes.accord(pour: [.blanche(.do), .blanche(.mi)]))
    }

    func testUnAmasDeNotesNEstPasUnAccord() {
        // Do, Ré, Mi ne forme aucune triade du système tonal.
        XCTAssertNil(CercleDesQuintes.accord(
            pour: [.blanche(.do), .blanche(.re), .blanche(.mi)]))
    }

    // MARK: Ce qui arrive du clavier MIDI

    func testAccordJoueAuPianoAvecDoublureDOctave() {
        // Do2, Mi3, Sol3 et un Do4 par-dessus : quatre notes MIDI, trois
        // touches, un accord de Do majeur.
        let touches = Set([36, 52, 55, 72].map { Touche.depuisNoteMIDI(UInt8($0)) })
        XCTAssertEqual(touches.count, 3)
        XCTAssertEqual(CercleDesQuintes.accord(pour: touches)?.libelle, "Do")
    }

    func testAccordJoueEnRenversementAuPiano() {
        // Mi3 Sol3 Do4 — premier renversement de Do majeur.
        let touches = Set([52, 55, 60].map { Touche.depuisNoteMIDI(UInt8($0)) })
        XCTAssertEqual(CercleDesQuintes.accord(pour: touches)?.libelle, "Do")
    }

    func testUneNoteFantomeEmpecheLaReconnaissance() {
        // Ce qui arrive si un note-off se perd : la quatrième touche traîne et
        // plus rien ne se reconnaît. D'où `oublierLesTouchesTenues`.
        let touches = Set([60, 64, 67, 62].map { Touche.depuisNoteMIDI(UInt8($0)) })
        XCTAssertNil(CercleDesQuintes.accord(pour: touches))
    }

    // MARK: Où l'accord se situe sur le cercle

    func testDoMajeurAppartientATroisTonalitesMajeures() {
        let places = CercleDesQuintes.placesDe(accord(.blanche(.do), .blanche(.mi),
                                                      .blanche(.sol)))
        let majeures = places.filter { $0.tonalite.mode == .majeur }
        XCTAssertEqual(Set(majeures.map(\.tonalite.libelle)),
                       ["Do majeur", "Sol majeur", "Fa majeur"])
        // Et son rôle diffère dans chacune : I, IV, V.
        let roles = Dictionary(uniqueKeysWithValues:
            majeures.map { ($0.tonalite.libelle, $0.degre.chiffrage) })
        XCTAssertEqual(roles["Do majeur"], "I")
        XCTAssertEqual(roles["Sol majeur"], "IV")
        XCTAssertEqual(roles["Fa majeur"], "V")
    }

    func testUnSeulFoyerParAccord() {
        // Le foyer est la tonalité où l'accord est le premier degré.
        for tonalite in [doMajeur, faMajeur] {
            let places = CercleDesQuintes.placesDe(tonalite.degres[0].accord)
            let foyers = places.filter(\.estFoyer)
            XCTAssertEqual(foyers.count, 1, tonalite.libelle)
            XCTAssertEqual(foyers.first?.tonalite, tonalite)
        }
    }

    func testLeFoyerDUnAccordMineurEstUneTonaliteMineure() {
        let places = CercleDesQuintes.placesDe(accord(.blanche(.re), .blanche(.fa),
                                                      .blanche(.la)))
        XCTAssertEqual(places.first(where: \.estFoyer)?.tonalite.libelle, "ré mineur")
        // L'arc a glissé vers les bémols : ii de Do, vi de Fa, iii de Si♭.
        let majeures = Dictionary(uniqueKeysWithValues: places
            .filter { $0.tonalite.mode == .majeur }
            .map { ($0.tonalite.libelle, $0.degre.chiffrage) })
        XCTAssertEqual(majeures["Do majeur"], "ii")
        XCTAssertEqual(majeures["Fa majeur"], "vi")
        XCTAssertEqual(majeures["Si♭ majeur"], "iii")
    }

    func testUnAccordDiminueNAppartientQuAUneSeuleMajeure() {
        // Le vii° est le seul degré diminué : l'arc se réduit à une case.
        let diminue = doMajeur.degres[6].accord
        let majeures = CercleDesQuintes.placesDe(diminue)
            .filter { $0.tonalite.mode == .majeur }
        XCTAssertEqual(majeures.map(\.tonalite.libelle), ["Do majeur"])
    }

    // MARK: Validation de ce qui est joué

    func testRenversementsEtDoublagesValident() {
        let doMajeur = accord(.blanche(.do), .blanche(.mi), .blanche(.sol))
        // Fondamentale, 1er et 2e renversement : les mêmes touches.
        XCTAssertTrue(Harmonie.correspond(
            touches: [.blanche(.do), .blanche(.mi), .blanche(.sol)], a: doMajeur))
        XCTAssertTrue(Harmonie.correspond(
            touches: [.blanche(.mi), .blanche(.sol), .blanche(.do)], a: doMajeur))
        // Une doublure d'octave ne change pas l'ensemble des touches.
        XCTAssertTrue(Harmonie.correspond(
            touches: Set([Touche.depuisNoteMIDI(48), .depuisNoteMIDI(64),
                          .depuisNoteMIDI(67), .depuisNoteMIDI(72)]), a: doMajeur))
    }

    func testUneNoteEnTropInvalide() {
        // Sinon poser toute la gamme validerait n'importe quel accord.
        let doMajeur = accord(.blanche(.do), .blanche(.mi), .blanche(.sol))
        XCTAssertFalse(Harmonie.correspond(
            touches: [.blanche(.do), .blanche(.re), .blanche(.mi), .blanche(.sol)],
            a: doMajeur))
    }

    func testUnAccordIncompletNeValidePas() {
        let doMajeur = accord(.blanche(.do), .blanche(.mi), .blanche(.sol))
        XCTAssertFalse(Harmonie.correspond(
            touches: [.blanche(.do), .blanche(.mi)], a: doMajeur))
    }

    func testUnLaDieseJoueValideUnSiBemolEcrit() {
        // On compare des touches, jamais des noms.
        let siBemol = faMajeur.degres[3].accord               // Si♭ Ré Fa
        XCTAssertEqual(siBemol.libelle, "Si♭")
        XCTAssertTrue(Harmonie.correspond(
            touches: [.noire(entre: .la), .blanche(.re), .blanche(.fa)], a: siBemol))
    }

    // MARK: Bilan d'improvisation

    func testTauxDansLaGamme() {
        let gamme = doMajeur.touches
        let joue: [Touche] = [.blanche(.do), .blanche(.mi), .noire(entre: .fa),
                              .blanche(.sol)]
        XCTAssertEqual(Harmonie.tauxDansLaGamme(touches: joue, gamme: gamme) ?? 0,
                       0.75, accuracy: 0.001)
    }

    func testSansNoteJoueeAucunTaux() {
        // nil et non 0 %, qui laisserait croire qu'on a tout raté.
        XCTAssertNil(Harmonie.tauxDansLaGamme(touches: [], gamme: doMajeur.touches))
    }

    func testDegresLesPlusJoues() {
        let joue: [Touche] = [.blanche(.do), .blanche(.do), .blanche(.do),
                              .blanche(.sol), .blanche(.sol), .blanche(.mi)]
        let bilan = Harmonie.degresLesPlusJoues(touches: joue, tonalite: doMajeur)
        XCTAssertEqual(bilan.map(\.degre), [1, 5, 3])
        XCTAssertEqual(bilan.map(\.occurrences), [3, 2, 1])
    }

    func testLesNotesHorsGammeNeComptentPourAucunDegre() {
        let joue: [Touche] = [.noire(entre: .fa), .noire(entre: .do), .blanche(.do)]
        let bilan = Harmonie.degresLesPlusJoues(touches: joue, tonalite: doMajeur)
        XCTAssertEqual(bilan.map(\.degre), [1])
    }

    func testEgalitesDepartageesParLOrdreDesDegres() {
        // Pour que l'affichage ne saute pas d'une consultation à l'autre.
        let joue: [Touche] = [.blanche(.sol), .blanche(.do)]
        let bilan = Harmonie.degresLesPlusJoues(touches: joue, tonalite: doMajeur)
        XCTAssertEqual(bilan.map(\.degre), [1, 5])
    }
}
