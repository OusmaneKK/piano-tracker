import XCTest
@testable import PianoApp

final class ProgressionTests: XCTestCase {

    // Calendrier et repère fixes pour des tests déterministes.
    private var calendrier: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/Paris")!
        return c
    }()

    /// Le 15 septembre 2026 à midi.
    private var aujourdHui: Date {
        calendrier.date(from: DateComponents(year: 2026, month: 9, day: 15, hour: 12))!
    }

    private func jour(moins decalage: Int, heure: Int = 9) -> Date {
        let base = calendrier.date(byAdding: .day, value: -decalage, to: aujourdHui)!
        return calendrier.date(bySettingHour: heure, minute: 0, second: 0, of: base)!
    }

    // MARK: Pourcentage

    func testPourcentageZeroHeure() {
        XCTAssertEqual(Progression.pourcentage(heuresTotales: 0), 0)
    }

    func testPourcentageIntermediaire() {
        XCTAssertEqual(Progression.pourcentage(heuresTotales: 137), 1.37, accuracy: 0.001)
    }

    func testPourcentageBorneACent() {
        XCTAssertEqual(Progression.pourcentage(heuresTotales: 12_000), 100)
    }

    // MARK: Prochain jalon

    func testProchainJalonAuDepart() {
        XCTAssertEqual(Progression.prochainJalon(heuresTotales: 0)?.heures, 25)
    }

    func testProchainJalonApresNovice() {
        XCTAssertEqual(Progression.prochainJalon(heuresTotales: 137)?.heures, 500)
    }

    func testProchainJalonSurLeSeuil() {
        // À exactement 100 h, Novice est atteint : le prochain est Engagé (500 h).
        XCTAssertEqual(Progression.prochainJalon(heuresTotales: 100)?.heures, 500)
    }

    func testProchainJalonRouteTerminee() {
        XCTAssertNil(Progression.prochainJalon(heuresTotales: 10_000))
    }

    // MARK: Série (tolérance d'un jour)

    func testSerieVide() {
        XCTAssertEqual(Progression.serie(joursDePratique: [], aujourdHui: aujourdHui,
                                         calendrier: calendrier), 0)
    }

    func testSerieAujourdHuiSeulement() {
        XCTAssertEqual(Progression.serie(joursDePratique: [jour(moins: 0)],
                                         aujourdHui: aujourdHui, calendrier: calendrier), 1)
    }

    func testSerieJoursConsecutifs() {
        let jours = [jour(moins: 0), jour(moins: 1), jour(moins: 2)]
        XCTAssertEqual(Progression.serie(joursDePratique: jours,
                                         aujourdHui: aujourdHui, calendrier: calendrier), 3)
    }

    func testSerieToleranceUnJourManque() {
        // Pratique aujourd'hui et avant-hier : la journée manquée ne casse pas la série.
        let jours = [jour(moins: 0), jour(moins: 2)]
        XCTAssertEqual(Progression.serie(joursDePratique: jours,
                                         aujourdHui: aujourdHui, calendrier: calendrier), 2)
    }

    func testSerieCasseeApresDeuxJoursManques() {
        // Trois jours d'écart entre deux pratiques : la série repart de la plus récente.
        let jours = [jour(moins: 0), jour(moins: 3)]
        XCTAssertEqual(Progression.serie(joursDePratique: jours,
                                         aujourdHui: aujourdHui, calendrier: calendrier), 1)
    }

    func testSerieVivanteSansPratiqueAujourdHui() {
        // Dernière pratique hier : la série reste vivante.
        let jours = [jour(moins: 1), jour(moins: 2)]
        XCTAssertEqual(Progression.serie(joursDePratique: jours,
                                         aujourdHui: aujourdHui, calendrier: calendrier), 2)
    }

    func testSerieMorteApresTroisJoursSansPratique() {
        let jours = [jour(moins: 3), jour(moins: 4)]
        XCTAssertEqual(Progression.serie(joursDePratique: jours,
                                         aujourdHui: aujourdHui, calendrier: calendrier), 0)
    }

    func testSerieLongueAvecTolerances() {
        // Aujourd'hui, hier, un trou toléré, puis deux jours collés : 4 jours pratiqués.
        let jours = [jour(moins: 0), jour(moins: 1), jour(moins: 3), jour(moins: 4)]
        XCTAssertEqual(Progression.serie(joursDePratique: jours,
                                         aujourdHui: aujourdHui, calendrier: calendrier), 4)
    }

    func testSeriePlusieursSessionsLeMemeJour() {
        // Deux sessions le même jour ne comptent qu'un jour.
        let jours = [jour(moins: 0, heure: 8), jour(moins: 0, heure: 20), jour(moins: 1)]
        XCTAssertEqual(Progression.serie(joursDePratique: jours,
                                         aujourdHui: aujourdHui, calendrier: calendrier), 2)
    }

    // MARK: Prévisions

    func testAnneesRestantesRythmeNul() {
        XCTAssertNil(Progression.anneesRestantes(heuresTotales: 0, heuresCible: 1_000,
                                                 heuresParSemaine: 0))
    }

    func testAnneesRestantes() {
        let annees = Progression.anneesRestantes(heuresTotales: 0, heuresCible: 1_000,
                                                 heuresParSemaine: 10)
        XCTAssertEqual(annees!, 1.923, accuracy: 0.001)
    }

    func testAnneesRestantesCibleDejaAtteinte() {
        XCTAssertEqual(Progression.anneesRestantes(heuresTotales: 600, heuresCible: 500,
                                                   heuresParSemaine: 5), 0)
    }

    func testMoisPourAtteindreObjectifNul() {
        XCTAssertNil(Progression.moisPourAtteindre(heuresCible: 100, minutesParJour: 0))
    }

    func testMoisPourAtteindreNovice() {
        // 60 min/jour ≈ 30,4 h/mois → 100 h ≈ 3 mois.
        XCTAssertEqual(Progression.moisPourAtteindre(heuresCible: 100, minutesParJour: 60), 3)
    }

    func testMoisPourAtteindreMinimumUnMois() {
        XCTAssertEqual(Progression.moisPourAtteindre(heuresCible: 1, minutesParJour: 180), 1)
    }
}
