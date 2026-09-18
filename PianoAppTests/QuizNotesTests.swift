import XCTest
@testable import PianoApp

final class QuizNotesTests: XCTestCase {

    // MARK: Positions sur la portée

    func testPositionsDesLignes() {
        XCTAssertEqual(NotePortee(nom: .mi, octave: 4).position, 0)   // 1ʳᵉ ligne
        XCTAssertEqual(NotePortee(nom: .sol, octave: 4).position, 2)  // 2ᵉ ligne
        XCTAssertEqual(NotePortee(nom: .si, octave: 4).position, 4)   // 3ᵉ ligne
        XCTAssertEqual(NotePortee(nom: .re, octave: 5).position, 6)   // 4ᵉ ligne
        XCTAssertEqual(NotePortee(nom: .fa, octave: 5).position, 8)   // 5ᵉ ligne
    }

    func testPositionsDesInterlignes() {
        XCTAssertEqual(NotePortee(nom: .fa, octave: 4).position, 1)   // 1ᵉʳ interligne
        XCTAssertEqual(NotePortee(nom: .la, octave: 4).position, 3)   // 2ᵉ interligne
        XCTAssertEqual(NotePortee(nom: .do, octave: 5).position, 5)   // 3ᵉ interligne
        XCTAssertEqual(NotePortee(nom: .mi, octave: 5).position, 7)   // 4ᵉ interligne
    }

    func testDo4SousLaPortee() {
        let do4 = NotePortee(nom: .do, octave: 4)
        XCTAssertEqual(do4.position, -2)
        XCTAssertTrue(do4.ligneSupplementaire)
        XCTAssertFalse(NotePortee(nom: .re, octave: 4).ligneSupplementaire)
        XCTAssertFalse(NotePortee(nom: .mi, octave: 4).ligneSupplementaire)
    }

    func testDirectionDeLaHampe() {
        XCTAssertFalse(NotePortee(nom: .si, octave: 4).hampeVersLeBas)  // ligne du milieu : vers le haut
        XCTAssertFalse(NotePortee(nom: .do, octave: 4).hampeVersLeBas)
        XCTAssertTrue(NotePortee(nom: .do, octave: 5).hampeVersLeBas)
        XCTAssertTrue(NotePortee(nom: .fa, octave: 5).hampeVersLeBas)
    }

    // MARK: Libellés pédagogiques

    func testLibellesDePosition() {
        XCTAssertEqual(NotePortee(nom: .mi, octave: 4).libellePosition, "1ʳᵉ ligne")
        XCTAssertEqual(NotePortee(nom: .fa, octave: 4).libellePosition, "1ᵉʳ interligne")
        XCTAssertEqual(NotePortee(nom: .la, octave: 4).libellePosition, "2ᵉ interligne")
        XCTAssertEqual(NotePortee(nom: .fa, octave: 5).libellePosition, "5ᵉ ligne")
        XCTAssertEqual(NotePortee(nom: .do, octave: 4).libellePosition,
                       "sur la petite ligne sous la portée")
        XCTAssertEqual(NotePortee(nom: .re, octave: 4).libellePosition,
                       "suspendu sous la portée")
    }

    // MARK: Périmètre et tirage

    func testPerimetreDesNotes() {
        XCTAssertEqual(QuizNotes.notes.count, 11)
        XCTAssertEqual(QuizNotes.notes.first, NotePortee(nom: .do, octave: 4))
        XCTAssertEqual(QuizNotes.notes.last, NotePortee(nom: .fa, octave: 5))
        // Toutes tiennent sur la portée élargie : de Do4 (-2) à Fa5 (8).
        for note in QuizNotes.notes {
            XCTAssertTrue((-2...8).contains(note.position), "\(note.nom.rawValue)\(note.octave)")
        }
    }

    func testTirageEviteLaRepetitionDuNom() {
        var generateur = GenerateurTest(etat: 42)
        var precedente: NotePortee? = nil
        for _ in 0..<200 {
            let note = QuizNotes.tirer(differenteDe: precedente, avec: &generateur)
            XCTAssertNotEqual(note.nom, precedente?.nom)
            XCTAssertTrue(QuizNotes.notes.contains(note))
            precedente = note
        }
    }

    func testTirageCouvreLesOnzeNotes() {
        var generateur = GenerateurTest(etat: 7)
        var vues = Set<Int>()
        var precedente: NotePortee? = nil
        for _ in 0..<300 {
            let note = QuizNotes.tirer(differenteDe: precedente, avec: &generateur)
            vues.insert(note.position)
            precedente = note
        }
        XCTAssertEqual(vues.count, QuizNotes.notes.count)
    }
}

/// Générateur déterministe (SplitMix64) pour des tests reproductibles.
private struct GenerateurTest: RandomNumberGenerator {
    var etat: UInt64
    mutating func next() -> UInt64 {
        etat &+= 0x9E37_79B9_7F4A_7C15
        var z = etat
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
