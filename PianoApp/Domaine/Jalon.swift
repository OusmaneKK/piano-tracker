import Foundation

/// Un jalon sur la route des 10 000 heures.
struct Jalon: Equatable, Identifiable {
    let heures: Double
    let titre: String
    let detail: String

    var id: Double { heures }

    /// Les 7 jalons, du premier contact à la maîtrise.
    static let tous: [Jalon] = [
        Jalon(heures: 25, titre: "Premières notes",
              detail: "Les deux mains sur le clavier. Des morceaux simples joués en entier."),
        Jalon(heures: 100, titre: "Novice",
              detail: "Rythme fiable, bases de lecture, un premier morceau par cœur."),
        Jalon(heures: 500, titre: "Engagé",
              detail: "À l'aise avec les gammes et les accords dans la plupart des tonalités."),
        Jalon(heures: 1_000, titre: "Intermédiaire",
              detail: "Un répertoire intermédiaire joué avec expression."),
        Jalon(heures: 2_500, titre: "Avancé",
              detail: "Pièces complexes, nuances travaillées, une interprétation personnelle."),
        Jalon(heures: 5_000, titre: "Quasi professionnel",
              detail: "Prêt pour la scène. La technique n'est plus l'obstacle."),
        Jalon(heures: 10_000, titre: "Maîtrise",
              detail: "Le seuil d'Ericsson — la pratique délibérée devenue expertise."),
    ]
}
