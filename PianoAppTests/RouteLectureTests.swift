import XCTest
@testable import PianoApp

final class RouteLectureTests: XCTestCase {

    // MARK: Les paliers

    func testSeptPaliersNumerotesDansLOrdre() {
        XCTAssertEqual(RouteLecture.paliers.map(\.numero), [1, 2, 3, 4, 5, 6, 7])
    }

    func testChaquePalierTireAuMoinsQuatreNotes() {
        // En dessous, la série de dix questions tournerait en rond.
        for palier in RouteLecture.paliers {
            let notes = RouteLecture.notes(du: palier)
            XCTAssertGreaterThanOrEqual(notes.count, 4, palier.nom)
            XCTAssertGreaterThan(Set(notes.map(\.nom)).count, 1, palier.nom)
        }
    }

    func testPalierUnNeContientQueLesLignes() {
        let notes = RouteLecture.notes(du: RouteLecture.paliers[0])
        XCTAssertEqual(notes.map(\.position).sorted(), [0, 2, 4, 6, 8])
        XCTAssertEqual(notes.map(\.nom.rawValue).sorted(),
                       ["Fa", "Mi", "Ré", "Si", "Sol"].sorted())
        XCTAssertTrue(notes.allSatisfy { $0.cle == .sol })
    }

    func testPalierDeuxNeContientQueLesInterlignes() {
        let notes = RouteLecture.notes(du: RouteLecture.paliers[1])
        XCTAssertEqual(notes.map(\.position).sorted(), [1, 3, 5, 7])
    }

    func testPalierTroisContientLeDoCentral() {
        let notes = RouteLecture.notes(du: RouteLecture.paliers[2])
        XCTAssertEqual(notes.count, 11)
        XCTAssertTrue(notes.contains { $0.nom == .do && $0.octave == 4 })
    }

    func testLesPaliersDeCleDeFaNeMelangentPas() {
        for numero in [4, 5] {
            let palier = RouteLecture.palier(numero: numero)!
            XCTAssertTrue(RouteLecture.notes(du: palier).allSatisfy { $0.cle == .fa },
                          palier.nom)
        }
    }

    func testLesDeuxDerniersPaliersMelangentLesCles() {
        for numero in [6, 7] {
            let palier = RouteLecture.palier(numero: numero)!
            let cles = Set(RouteLecture.notes(du: palier).map(\.cle))
            XCTAssertEqual(cles, [.sol, .fa], palier.nom)
            XCTAssertTrue(palier.avecAlterations, palier.nom)
        }
    }

    // MARK: Ouverture

    func testLePremierPalierEstToujoursOuvert() {
        XCTAssertTrue(RouteLecture.estOuvert(RouteLecture.paliers[0], meilleursScores: [:]))
    }

    func testUnPalierResteFermeSansScoreSuffisant() {
        let deuxieme = RouteLecture.paliers[1]
        XCTAssertFalse(RouteLecture.estOuvert(deuxieme, meilleursScores: [:]))
        XCTAssertFalse(RouteLecture.estOuvert(deuxieme, meilleursScores: [1: 8]))
        XCTAssertTrue(RouteLecture.estOuvert(deuxieme, meilleursScores: [1: 9]))
        XCTAssertTrue(RouteLecture.estOuvert(deuxieme, meilleursScores: [1: 10]))
    }

    func testLOuvertureNeDependQueDuPalierPrecedent() {
        // Avoir brillé au palier 1 n'ouvre pas le palier 3.
        let troisieme = RouteLecture.paliers[2]
        XCTAssertFalse(RouteLecture.estOuvert(troisieme, meilleursScores: [1: 10]))
        XCTAssertTrue(RouteLecture.estOuvert(troisieme, meilleursScores: [1: 10, 2: 9]))
    }

    // MARK: Palier en cours

    func testPalierEnCoursAuDepart() {
        XCTAssertEqual(RouteLecture.palierEnCours(meilleursScores: [:]).numero, 1)
    }

    func testPalierEnCoursAvance() {
        XCTAssertEqual(RouteLecture.palierEnCours(meilleursScores: [1: 9]).numero, 2)
        XCTAssertEqual(RouteLecture.palierEnCours(meilleursScores: [1: 10, 2: 9]).numero, 3)
    }

    func testPalierEnCoursIgnoreLesScoresInsuffisants() {
        // Le palier 1 joué à 7/10 reste le palier à travailler.
        XCTAssertEqual(RouteLecture.palierEnCours(meilleursScores: [1: 7]).numero, 1)
    }

    func testRouteTerminee() {
        let tout = Dictionary(uniqueKeysWithValues: (1...7).map { ($0, 10) })
        XCTAssertEqual(RouteLecture.palierEnCours(meilleursScores: tout).numero, 7)
    }

    // MARK: Maîtrise

    func testMaitriseDemandeSansFauteEtVitesse() {
        XCTAssertTrue(RouteLecture.estMaitrise(score: 10, total: 10, tempsMoyen: 2.5))
        // Sans faute mais trop lent : pas encore la maîtrise.
        XCTAssertFalse(RouteLecture.estMaitrise(score: 10, total: 10, tempsMoyen: 4))
        // Rapide mais une faute : pas la maîtrise non plus.
        XCTAssertFalse(RouteLecture.estMaitrise(score: 9, total: 10, tempsMoyen: 1.5))
        // Sans chrono (séries d'avant cette version), pas de maîtrise rétroactive.
        XCTAssertFalse(RouteLecture.estMaitrise(score: 10, total: 10, tempsMoyen: nil))
    }

    func testMaitriseALaLimiteExacte() {
        XCTAssertTrue(RouteLecture.estMaitrise(score: 10, total: 10,
                                               tempsMoyen: RouteLecture.secondesPourMaitrise))
    }

    // MARK: Ouverture du suivant

    func testOuvertureAnnonceeUneSeuleFois() {
        let premier = RouteLecture.paliers[0]
        // La première fois qu'on atteint 9 : le palier suivant s'ouvre.
        XCTAssertTrue(RouteLecture.ouvreLeSuivant(palier: premier, score: 9,
                                                  meilleurScorePrecedent: 7))
        // Les fois d'après, il est déjà ouvert : on ne le réannonce pas.
        XCTAssertFalse(RouteLecture.ouvreLeSuivant(palier: premier, score: 10,
                                                   meilleurScorePrecedent: 9))
        XCTAssertFalse(RouteLecture.ouvreLeSuivant(palier: premier, score: 8,
                                                   meilleurScorePrecedent: 0))
    }

    func testLeDernierPalierNOuvreRien() {
        let dernier = RouteLecture.paliers[6]
        XCTAssertFalse(RouteLecture.ouvreLeSuivant(palier: dernier, score: 10,
                                                   meilleurScorePrecedent: 0))
    }
}
