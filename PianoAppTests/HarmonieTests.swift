import XCTest
@testable import PianoApp

final class HarmonieTests: XCTestCase {

    // MARK: Notes écrites — l'orthographe et le son sont deux choses

    func testClasseDeHauteurDesNotesPieges() {
        // Les quatre notes qui n'ont pas de touche noire à elles.
        XCTAssertEqual(NoteEcrite(.do, .bemol).classeDeHauteur, 11)  // Do♭ = Si
        XCTAssertEqual(NoteEcrite(.si, .diese).classeDeHauteur, 0)   // Si♯ = Do
        XCTAssertEqual(NoteEcrite(.mi, .diese).classeDeHauteur, 5)   // Mi♯ = Fa
        XCTAssertEqual(NoteEcrite(.fa, .bemol).classeDeHauteur, 4)   // Fa♭ = Mi
    }

    func testToucheDesNotesPieges() {
        // Le point qui justifie de ne pas réutiliser NotePortee.toucheAttendue :
        // on passe par la classe de hauteur, donc ces quatre-là tombent juste.
        XCTAssertEqual(NoteEcrite(.do, .bemol).touche, .blanche(.si))
        XCTAssertEqual(NoteEcrite(.mi, .diese).touche, .blanche(.fa))
        XCTAssertEqual(NoteEcrite(.si, .diese).touche, .blanche(.do))
        XCTAssertEqual(NoteEcrite(.fa, .bemol).touche, .blanche(.mi))
    }

    func testEnharmonieMemeToucheNomsDifferents() {
        let solDiese = NoteEcrite(.sol, .diese)
        let laBemol = NoteEcrite(.la, .bemol)
        XCTAssertEqual(solDiese.classeDeHauteur, laBemol.classeDeHauteur)
        XCTAssertEqual(solDiese.touche, laBemol.touche)
        XCTAssertNotEqual(solDiese.libelle, laBemol.libelle)
        XCTAssertEqual(solDiese.libelle, "Sol♯")
        XCTAssertEqual(laBemol.libelle, "La♭")
    }

    // MARK: Armures

    func testNombreDAlterationsDesDouzeMajeures() {
        let attendu: [String: Int] = [
            "Do majeur": 0, "Sol majeur": 1, "Ré majeur": 2, "La majeur": 3,
            "Mi majeur": 4, "Si majeur": 5, "Sol♭ majeur": -6, "Ré♭ majeur": -5,
            "La♭ majeur": -4, "Mi♭ majeur": -3, "Si♭ majeur": -2, "Fa majeur": -1,
        ]
        for tonalite in CercleDesQuintes.majeures {
            XCTAssertEqual(tonalite.nbAlterations, attendu[tonalite.libelle],
                           tonalite.libelle)
        }
    }

    func testUneMineurePartageLArmureDeSaRelative() {
        for majeure in CercleDesQuintes.majeures {
            XCTAssertEqual(majeure.relative.nbAlterations, majeure.nbAlterations,
                           majeure.libelle)
        }
    }

    func testOrdreDEcritureDesAlterations() {
        // Une armure de dièses commence toujours par Fa♯, une de bémols par Si♭.
        XCTAssertEqual(Tonalite(NoteEcrite(.sol), .majeur).armure.map(\.libelle), ["Fa♯"])
        XCTAssertEqual(Tonalite(NoteEcrite(.re), .majeur).armure.map(\.libelle),
                       ["Fa♯", "Do♯"])
        XCTAssertEqual(Tonalite(NoteEcrite(.fa), .majeur).armure.map(\.libelle), ["Si♭"])
        XCTAssertEqual(Tonalite(NoteEcrite(.mi, .bemol), .majeur).armure.map(\.libelle),
                       ["Si♭", "Mi♭", "La♭"])
        XCTAssertTrue(Tonalite(NoteEcrite(.do), .majeur).armure.isEmpty)
    }

    // MARK: Gammes — le vrai piège

    func testFaMajeurPorteUnSiBemolEtJamaisUnLaDiese() {
        let gamme = Tonalite(NoteEcrite(.fa), .majeur).gamme.map(\.libelle)
        XCTAssertEqual(gamme, ["Fa", "Sol", "La", "Si♭", "Do", "Ré", "Mi"])
    }

    func testSolBemolMajeurContientUnDoBemol() {
        let gamme = Tonalite(NoteEcrite(.sol, .bemol), .majeur).gamme.map(\.libelle)
        XCTAssertEqual(gamme, ["Sol♭", "La♭", "Si♭", "Do♭", "Ré♭", "Mi♭", "Fa"])
    }

    func testFaDieseMajeurContientUnMiDiese() {
        // Fa♯ n'est pas retenue sur le cercle, mais le domaine sait l'écrire.
        let gamme = Tonalite(NoteEcrite(.fa, .diese), .majeur).gamme.map(\.libelle)
        XCTAssertEqual(gamme, ["Fa♯", "Sol♯", "La♯", "Si", "Do♯", "Ré♯", "Mi♯"])
    }

    func testDoMajeurNAAucuneAlteration() {
        let gamme = Tonalite(NoteEcrite(.do), .majeur).gamme
        XCTAssertEqual(gamme.map(\.libelle), ["Do", "Ré", "Mi", "Fa", "Sol", "La", "Si"])
        XCTAssertTrue(gamme.allSatisfy { $0.alteration == .naturelle })
    }

    func testMiBemolMineurNaturel() {
        let gamme = Tonalite(NoteEcrite(.mi, .bemol), .mineur).gamme.map(\.libelle)
        XCTAssertEqual(gamme, ["Mi♭", "Fa", "Sol♭", "La♭", "Si♭", "Do♭", "Ré♭"])
    }

    func testChaqueGammeASeptNomsEtSeptSonsDistincts() {
        // Cette seule propriété attrape toutes les fautes d'orthographe
        // possibles : une gamme ne peut pas nommer deux fois la même lettre,
        // ni sonner deux fois la même note.
        for tonalite in CercleDesQuintes.toutes {
            let gamme = tonalite.gamme
            XCTAssertEqual(Set(gamme.map(\.nom)).count, 7, tonalite.libelle)
            XCTAssertEqual(Set(gamme.map(\.classeDeHauteur)).count, 7, tonalite.libelle)
        }
    }

    func testIntervallesDesDeuxModes() {
        func intervalles(_ tonalite: Tonalite) -> [Int] {
            let classes = tonalite.gamme.map(\.classeDeHauteur)
            return (0..<7).map { (classes[($0 + 1) % 7] - classes[$0] + 12) % 12 }
        }
        for majeure in CercleDesQuintes.majeures {
            XCTAssertEqual(intervalles(majeure), [2, 2, 1, 2, 2, 2, 1], majeure.libelle)
            XCTAssertEqual(intervalles(majeure.relative), [2, 1, 2, 2, 1, 2, 2],
                           majeure.relative.libelle)
        }
    }

    // MARK: Relatives

    func testRelativeDeDoMajeurEstLaMineur() {
        let doMajeur = Tonalite(NoteEcrite(.do), .majeur)
        XCTAssertEqual(doMajeur.relative.libelle, "la mineur")
        XCTAssertEqual(doMajeur.relative.touches, doMajeur.touches)
    }

    func testLaRelativeDeLaRelativeRamenneAuDepart() {
        for tonalite in CercleDesQuintes.toutes {
            XCTAssertEqual(tonalite.relative.relative, tonalite, tonalite.libelle)
        }
    }

    // MARK: Degrés et accords

    func testQualitesDesDegresEnMajeur() {
        for majeure in CercleDesQuintes.majeures {
            XCTAssertEqual(majeure.degres.map(\.chiffrage),
                           ["I", "ii", "iii", "IV", "V", "vi", "vii°"], majeure.libelle)
        }
    }

    func testQualitesDesDegresEnMineurNaturel() {
        for majeure in CercleDesQuintes.majeures {
            let mineure = majeure.relative
            XCTAssertEqual(mineure.degres.map(\.chiffrage),
                           ["i", "ii°", "III", "iv", "v", "VI", "VII"], mineure.libelle)
        }
    }

    func testOrthographeDesTriadesEnFaMajeur() {
        let degres = Tonalite(NoteEcrite(.fa), .majeur).degres
        XCTAssertEqual(degres[3].accord.notes.map(\.libelle), ["Si♭", "Ré", "Fa"])
        XCTAssertEqual(degres[3].accord.libelle, "Si♭")
        XCTAssertEqual(degres[6].accord.notes.map(\.libelle), ["Mi", "Sol", "Si♭"])
        XCTAssertEqual(degres[6].accord.libelle, "Mi°")
    }

    func testUneMajeureEtSaRelativePartagentLesMemesTriades() {
        let doMajeur = Tonalite(NoteEcrite(.do), .majeur)
        let laMineur = doMajeur.relative
        XCTAssertEqual(Set(doMajeur.degres.map(\.accord)),
                       Set(laMineur.degres.map(\.accord)))
    }

    func testCadences() {
        let doMajeur = Tonalite(NoteEcrite(.do), .majeur)
        XCTAssertEqual(doMajeur.cadence.map(\.accord.libelle), ["Do", "Fa", "Sol", "Do"])
        let miBemol = Tonalite(NoteEcrite(.mi, .bemol), .majeur)
        XCTAssertEqual(miBemol.cadence.map(\.accord.libelle),
                       ["Mi♭", "La♭", "Si♭", "Mi♭"])
    }

    func testEnMineurNaturelLaDominanteEstMineure() {
        // Décision assumée : le mineur harmonique demanderait des doubles
        // dièses que le type Alteration ne sait pas écrire.
        let laMineur = Tonalite(NoteEcrite(.la), .mineur)
        XCTAssertEqual(laMineur.cadence.map(\.accord.libelle),
                       ["La m", "Ré m", "Mi m", "La m"])
        XCTAssertEqual(laMineur.degres[4].accord.qualite, .mineur)
    }

    func testFonctionsTonales() {
        let degres = Tonalite(NoteEcrite(.do), .majeur).degres
        XCTAssertEqual(degres[0].fonction, "tonique")
        XCTAssertEqual(degres[3].fonction, "sous-dominante")
        XCTAssertEqual(degres[4].fonction, "dominante")
        XCTAssertNil(degres[1].fonction)
    }
}
