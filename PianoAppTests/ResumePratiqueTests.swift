import XCTest
@testable import PianoApp

final class ResumePratiqueTests: XCTestCase {
    private let calendrier = Calendar(identifier: .gregorian)

    private func resume(minutes: Int = 0, objectif: Int = 60, serie: Int = 0,
                        heures: Double = 0, ecritLe: Date = .now) -> ResumePratique {
        ResumePratique(minutesAujourdhui: minutes, objectifQuotidienMinutes: objectif,
                       serie: serie, heuresTotales: heures, ecritLe: ecritLe)
    }

    func testFractionObjectif() {
        XCTAssertEqual(resume(minutes: 30, objectif: 60).fractionObjectif, 0.5)
        XCTAssertEqual(resume(minutes: 60, objectif: 60).fractionObjectif, 1)
        // Au-delà de l'objectif, l'anneau reste plein.
        XCTAssertEqual(resume(minutes: 90, objectif: 60).fractionObjectif, 1)
        // Objectif nul : pas de division par zéro.
        XCTAssertEqual(resume(minutes: 30, objectif: 0).fractionObjectif, 0)
    }

    func testPourcentageRoute() {
        XCTAssertEqual(resume(heures: 100).pourcentageRoute, 1, accuracy: 0.0001)
        XCTAssertEqual(resume(heures: 10_000).pourcentageRoute, 100, accuracy: 0.0001)
        XCTAssertEqual(resume(heures: 12_000).pourcentageRoute, 100, accuracy: 0.0001)
    }

    func testResumeDHierRepartAZeroApresMinuit() {
        // Le widget peut se réveiller sans que l'app ait tourné : les minutes
        // d'hier ne doivent pas s'afficher comme celles d'aujourd'hui.
        let hier = Date.now.addingTimeInterval(-26 * 3600)
        let veille = resume(minutes: 45, serie: 3, heures: 12, ecritLe: hier)
        XCTAssertFalse(veille.estDuJour())
        let actualise = veille.actualise()
        XCTAssertEqual(actualise.minutesAujourdhui, 0)
        // Le reste du résumé survit à la nuit.
        XCTAssertEqual(actualise.serie, 3)
        XCTAssertEqual(actualise.heuresTotales, 12)
    }

    func testResumeDuJourResteIntact() {
        let duJour = resume(minutes: 45, ecritLe: .now)
        XCTAssertTrue(duJour.estDuJour())
        XCTAssertEqual(duJour.actualise(), duJour)
    }

    func testConstructionDepuisLesSessions() {
        let maintenant = Date(timeIntervalSince1970: 1_700_000_000)
        let hier = maintenant.addingTimeInterval(-24 * 3600)
        let sessions = [
            SessionPratique(date: maintenant, dureeSecondes: 25 * 60),
            SessionPratique(date: maintenant, dureeSecondes: 20 * 60),
            SessionPratique(date: hier, dureeSecondes: 60 * 60),
        ]
        let profil = Profil(objectifQuotidienMinutes: 45, onboardingTermine: true)
        let calcule = ResumePratique.depuis(sessions: sessions, profil: profil,
                                            maintenant: maintenant, calendrier: calendrier)
        XCTAssertEqual(calcule.minutesAujourdhui, 45)      // seules les sessions du jour
        XCTAssertEqual(calcule.objectifQuotidienMinutes, 45)
        XCTAssertEqual(calcule.heuresTotales, 1.75, accuracy: 0.0001)  // tout l'historique
        XCTAssertEqual(calcule.serie, 2)
    }

    func testSansProfilLObjectifATrenteJoursParDefaut() {
        let calcule = ResumePratique.depuis(sessions: [], profil: nil)
        XCTAssertEqual(calcule.objectifQuotidienMinutes, 60)
        XCTAssertEqual(calcule.minutesAujourdhui, 0)
        XCTAssertEqual(calcule.serie, 0)
    }

    func testEncodageDecodage() {
        // Le résumé transite par le trousseau en JSON : l'aller-retour doit être fidèle.
        let original = resume(minutes: 45, objectif: 90, serie: 7, heures: 123.5)
        let donnees = try? JSONEncoder().encode(original)
        XCTAssertNotNil(donnees)
        let relu = donnees.flatMap { try? JSONDecoder().decode(ResumePratique.self, from: $0) }
        XCTAssertEqual(relu?.minutesAujourdhui, 45)
        XCTAssertEqual(relu?.objectifQuotidienMinutes, 90)
        XCTAssertEqual(relu?.serie, 7)
        XCTAssertEqual(relu?.heuresTotales ?? 0, 123.5, accuracy: 0.0001)
    }
}
