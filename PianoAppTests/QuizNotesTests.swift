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
        XCTAssertTrue(do4.ligneSupplementaireBas)
        XCTAssertFalse(NotePortee(nom: .re, octave: 4).ligneSupplementaireBas)
        XCTAssertFalse(NotePortee(nom: .mi, octave: 4).ligneSupplementaireBas)
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

    // MARK: Clé de fa

    func testPositionsEnCleDeFa() {
        XCTAssertEqual(NotePortee(nom: .sol, octave: 2, cle: .fa).position, 0)   // 1ʳᵉ ligne
        XCTAssertEqual(NotePortee(nom: .re, octave: 3, cle: .fa).position, 4)    // 3ᵉ ligne
        XCTAssertEqual(NotePortee(nom: .la, octave: 3, cle: .fa).position, 8)    // 5ᵉ ligne
        XCTAssertEqual(NotePortee(nom: .do, octave: 4, cle: .fa).position, 10)   // au-dessus
    }

    func testDoCentralDansLesDeuxCles() {
        // Le Do central (Do4) : petite ligne sous la portée en clé de sol,
        // petite ligne au-dessus en clé de fa.
        let enSol = NotePortee(nom: .do, octave: 4, cle: .sol)
        let enFa = NotePortee(nom: .do, octave: 4, cle: .fa)
        XCTAssertTrue(enSol.ligneSupplementaireBas)
        XCTAssertFalse(enSol.ligneSupplementaireHaut)
        XCTAssertTrue(enFa.ligneSupplementaireHaut)
        XCTAssertFalse(enFa.ligneSupplementaireBas)
        XCTAssertEqual(enFa.libellePosition, "sur la petite ligne au-dessus de la portée")
    }

    // MARK: Altérations et touches

    func testToucheAttendue() {
        XCTAssertEqual(NotePortee(nom: .sol, octave: 4).toucheAttendue, .blanche(.sol))
        XCTAssertEqual(NotePortee(nom: .sol, octave: 4, alteration: .diese).toucheAttendue,
                       .noire(entre: .sol))
        XCTAssertEqual(NotePortee(nom: .la, octave: 4, alteration: .bemol).toucheAttendue,
                       .noire(entre: .sol))
    }

    func testEnharmonie() {
        // Sol♯ et La♭ : la même touche noire répond juste aux deux.
        let solDiese = NotePortee(nom: .sol, octave: 4, alteration: .diese)
        let laBemol = NotePortee(nom: .la, octave: 4, alteration: .bemol)
        XCTAssertEqual(solDiese.toucheAttendue, laBemol.toucheAttendue)
        XCTAssertNotEqual(solDiese.nomComplet, laBemol.nomComplet)
    }

    func testNomComplet() {
        XCTAssertEqual(NotePortee(nom: .fa, octave: 4, alteration: .diese).nomComplet, "Fa♯")
        XCTAssertEqual(NotePortee(nom: .si, octave: 4, alteration: .bemol).nomComplet, "Si♭")
        XCTAssertEqual(NotePortee(nom: .mi, octave: 4).nomComplet, "Mi")
    }

    // MARK: Périmètre et tirage

    func testPerimetreDesNotes() {
        for cle in Cle.allCases {
            let notes = QuizNotes.notes(cle: cle)
            XCTAssertEqual(notes.count, 11, "\(cle.libelle)")
            for note in notes {
                XCTAssertTrue((-2...10).contains(note.position),
                              "\(note.nomComplet)\(note.octave) en \(cle.libelle)")
                XCTAssertEqual(note.cle, cle)
            }
        }
        XCTAssertEqual(QuizNotes.notes(cle: .sol).first, NotePortee(nom: .do, octave: 4))
        XCTAssertEqual(QuizNotes.notes(cle: .fa).last, NotePortee(nom: .do, octave: 4, cle: .fa))
    }

    func testTirageEviteLaRepetitionDuNomComplet() {
        var generateur = GenerateurTest(etat: 42)
        var precedente: NotePortee? = nil
        for _ in 0..<200 {
            let note = QuizNotes.tirer(cle: .sol, avecAlterations: true,
                                       differenteDe: precedente, avec: &generateur)
            XCTAssertNotEqual(note.nomComplet, precedente?.nomComplet)
            precedente = note
        }
    }

    func testTirageSansAlterationsResteNaturel() {
        var generateur = GenerateurTest(etat: 9)
        var precedente: NotePortee? = nil
        for _ in 0..<100 {
            let note = QuizNotes.tirer(cle: .fa, avecAlterations: false,
                                       differenteDe: precedente, avec: &generateur)
            XCTAssertEqual(note.alteration, .naturelle)
            XCTAssertEqual(note.cle, .fa)
            precedente = note
        }
    }

    func testTirageAltereRespecteLesTouchesNoires() {
        var generateur = GenerateurTest(etat: 3)
        var precedente: NotePortee? = nil
        var nbAlterees = 0
        for _ in 0..<300 {
            let note = QuizNotes.tirer(cle: .sol, avecAlterations: true,
                                       differenteDe: precedente, avec: &generateur)
            switch note.alteration {
            case .diese:
                nbAlterees += 1
                XCTAssertTrue(QuizNotes.nomsDiese.contains(note.nom), note.nomComplet)
            case .bemol:
                nbAlterees += 1
                XCTAssertTrue(QuizNotes.nomsBemol.contains(note.nom), note.nomComplet)
            case .naturelle:
                break
            }
            precedente = note
        }
        // Environ une question sur trois est altérée : large fourchette, sans hasard flou.
        XCTAssertGreaterThan(nbAlterees, 40)
        XCTAssertLessThan(nbAlterees, 180)
    }

    func testTirageCouvreLesOnzeNotes() {
        var generateur = GenerateurTest(etat: 7)
        var vues = Set<Int>()
        var precedente: NotePortee? = nil
        for _ in 0..<300 {
            let note = QuizNotes.tirer(cle: .sol, avecAlterations: false,
                                       differenteDe: precedente, avec: &generateur)
            vues.insert(note.position)
            precedente = note
        }
        XCTAssertEqual(vues.count, QuizNotes.notes(cle: .sol).count)
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
