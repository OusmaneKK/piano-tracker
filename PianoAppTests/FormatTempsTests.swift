import XCTest
@testable import PianoApp

final class FormatTempsTests: XCTestCase {

    // MARK: minutes:secondes

    func testZeroSeconde() {
        XCTAssertEqual(FormatTemps.minutesSecondes(0), "00:00")
    }

    func testQuatreMinutesTrenteDeux() {
        XCTAssertEqual(FormatTemps.minutesSecondes(272), "04:32")
    }

    func testValeurNegativeBorneeAZero() {
        XCTAssertEqual(FormatTemps.minutesSecondes(-5), "00:00")
    }

    func testAuDelaDUneHeureResteEnMinutes() {
        XCTAssertEqual(FormatTemps.minutesSecondes(3_600), "60:00")
    }

    // MARK: heures localisées

    func testHeuresEntieresSimples() {
        XCTAssertEqual(FormatTemps.heuresEntieres(137.6), "138")
    }

    func testHeuresEntieresNegativesBorneesAZero() {
        XCTAssertEqual(FormatTemps.heuresEntieres(-3), "0")
    }

    func testHeuresEntieresAvecSeparateurDeMilliers() {
        // Le séparateur français est une espace (fine ou insécable selon l'OS) :
        // on vérifie les chiffres sans présumer du caractère exact.
        let texte = FormatTemps.heuresEntieres(10_000)
        let chiffres = texte.filter(\.isNumber)
        XCTAssertEqual(chiffres, "10000")
        XCTAssertEqual(texte.count, 6, "attendu « 10 000 » avec un séparateur de milliers")
    }

    func testHeuresUneDecimale() {
        let texte = FormatTemps.heuresUneDecimale(6.24)
        XCTAssertEqual(texte, "6,2 h")
    }

    func testHeuresUneDecimaleEntiere() {
        XCTAssertEqual(FormatTemps.heuresUneDecimale(6.0), "6 h")
    }
}
