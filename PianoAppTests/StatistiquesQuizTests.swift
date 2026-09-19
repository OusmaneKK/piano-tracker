import XCTest
@testable import PianoApp

final class StatistiquesQuizTests: XCTestCase {

    /// Fabrique `justes` bonnes réponses et `ratees` mauvaises pour une note.
    private func reponses(_ note: String, justes: Int, ratees: Int)
    -> [(note: String, juste: Bool)] {
        Array(repeating: (note: note, juste: true), count: justes)
        + Array(repeating: (note: note, juste: false), count: ratees)
    }

    // MARK: Taux de réussite

    func testTauxSansReponse() {
        XCTAssertNil(StatistiquesQuiz.tauxDeReussite(reponses: []))
    }

    func testTauxDeReussite() {
        let lot = reponses("Sol", justes: 3, ratees: 1)
        XCTAssertEqual(StatistiquesQuiz.tauxDeReussite(reponses: lot) ?? 0, 0.75, accuracy: 0.001)
    }

    // MARK: Notes qui résistent

    func testUneNoteRareNeRemontePasEnTete() {
        // « La » n'a été vue qu'une fois et ratée : 100 % d'erreur, mais
        // l'échantillon ne veut rien dire. « Do », vu 5 fois et raté 3 fois,
        // est le vrai problème.
        let lot = reponses("La", justes: 0, ratees: 1) + reponses("Do", justes: 2, ratees: 3)
        let bilan = StatistiquesQuiz.notesQuiResistent(reponses: lot)
        XCTAssertEqual(bilan.map(\.note), ["Do"])
    }

    func testClassementParTauxDErreur() {
        let lot = reponses("Do", justes: 3, ratees: 1)      // 25 %
            + reponses("Ré", justes: 1, ratees: 3)          // 75 %
            + reponses("Mi", justes: 2, ratees: 2)          // 50 %
        let bilan = StatistiquesQuiz.notesQuiResistent(reponses: lot)
        XCTAssertEqual(bilan.map(\.note), ["Ré", "Mi", "Do"])
        XCTAssertEqual(bilan.first?.ratees, 3)
        XCTAssertEqual(bilan.first?.tentatives, 4)
    }

    func testNotesParfaitementSuesNApparaissentPas() {
        let lot = reponses("Sol", justes: 6, ratees: 0) + reponses("Fa", justes: 2, ratees: 2)
        let bilan = StatistiquesQuiz.notesQuiResistent(reponses: lot)
        XCTAssertEqual(bilan.map(\.note), ["Fa"])
    }

    func testLimiteDuClassement() {
        let lot = reponses("Do", justes: 1, ratees: 3)
            + reponses("Ré", justes: 1, ratees: 3)
            + reponses("Mi", justes: 1, ratees: 3)
            + reponses("Fa", justes: 1, ratees: 3)
        XCTAssertEqual(StatistiquesQuiz.notesQuiResistent(reponses: lot).count, 3)
        XCTAssertEqual(StatistiquesQuiz.notesQuiResistent(reponses: lot, limite: 2).count, 2)
    }

    func testClassementStableAEgalite() {
        // À taux et nombre d'erreurs égaux, l'ordre alphabétique évite que
        // l'affichage saute d'une fois sur l'autre.
        let lot = reponses("Si", justes: 2, ratees: 2) + reponses("La", justes: 2, ratees: 2)
        XCTAssertEqual(StatistiquesQuiz.notesQuiResistent(reponses: lot).map(\.note), ["La", "Si"])
    }

    func testAlterationsComptéesSeparement() {
        // Sol et Sol♯ ne s'apprennent pas ensemble : ce sont deux lignes.
        let lot = reponses("Sol", justes: 4, ratees: 0) + reponses("Sol♯", justes: 1, ratees: 3)
        XCTAssertEqual(StatistiquesQuiz.notesQuiResistent(reponses: lot).map(\.note), ["Sol♯"])
    }

    // MARK: Progression

    func testProgressionDemandeAssezDeSeries() {
        XCTAssertNil(StatistiquesQuiz.progression(taux: [1, 0.9, 0.8]))
        XCTAssertNil(StatistiquesQuiz.progression(taux: [1, 0.9, 0.8, 0.7, 0.6]))
    }

    func testProgressionPositive() {
        // Trois séries à 90 % après trois séries à 60 % : +30 points.
        let taux = [0.9, 0.9, 0.9, 0.6, 0.6, 0.6]
        XCTAssertEqual(StatistiquesQuiz.progression(taux: taux) ?? 0, 30, accuracy: 0.001)
    }

    func testProgressionNegative() {
        let taux = [0.5, 0.5, 0.5, 0.8, 0.8, 0.8]
        XCTAssertEqual(StatistiquesQuiz.progression(taux: taux) ?? 0, -30, accuracy: 0.001)
    }

    func testProgressionIgnoreLesSeriesPlusAnciennes() {
        // Seules les 3 dernières et les 3 précédentes comptent.
        let taux = [1, 1, 1, 0.5, 0.5, 0.5, 0, 0, 0]
        XCTAssertEqual(StatistiquesQuiz.progression(taux: taux) ?? 0, 50, accuracy: 0.001)
    }
}
