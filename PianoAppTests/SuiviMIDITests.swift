import XCTest
@testable import PianoApp

final class SuiviMIDITests: XCTestCase {
    private let reference = Date(timeIntervalSince1970: 1_700_000_000)

    func testSansNoteAucunePause() {
        // Suivi armé mais aucune note entendue : rien à mettre en pause.
        XCTAssertFalse(SuiviMIDI.doitMettreEnPause(derniereNote: nil, maintenant: reference))
    }

    func testSilenceCourtNeCoupePas() {
        // Tourner une page, chercher un doigté : la session continue.
        let ilYaUneMinute = reference.addingTimeInterval(-60)
        XCTAssertFalse(SuiviMIDI.doitMettreEnPause(derniereNote: ilYaUneMinute,
                                                   maintenant: reference))
    }

    func testSilenceLongMetEnPause() {
        let ilYaDeuxMinutes = reference.addingTimeInterval(-SuiviMIDI.silenceAvantPause)
        XCTAssertTrue(SuiviMIDI.doitMettreEnPause(derniereNote: ilYaDeuxMinutes,
                                                  maintenant: reference))
        let ilYaDixMinutes = reference.addingTimeInterval(-600)
        XCTAssertTrue(SuiviMIDI.doitMettreEnPause(derniereNote: ilYaDixMinutes,
                                                  maintenant: reference))
    }

    func testJusteAvantLeSeuil() {
        let presqueDeuxMinutes = reference.addingTimeInterval(-SuiviMIDI.silenceAvantPause + 1)
        XCTAssertFalse(SuiviMIDI.doitMettreEnPause(derniereNote: presqueDeuxMinutes,
                                                   maintenant: reference))
    }

    func testLaPauseRemonteALaDerniereNote() {
        // Le silence ne doit pas être compté comme de la pratique :
        // on arrête le décompte à la dernière note entendue.
        let derniere = reference.addingTimeInterval(-300)
        XCTAssertEqual(SuiviMIDI.dateDePause(derniereNote: derniere, maintenant: reference),
                       derniere)
    }

    func testSansNoteLaPauseEstImmediate() {
        XCTAssertEqual(SuiviMIDI.dateDePause(derniereNote: nil, maintenant: reference),
                       reference)
    }
}
