import Foundation
import Security

/// Le résumé de pratique que le widget affiche : quelques nombres, rien de plus.
/// Compilé dans l'app **et** dans le widget (les deux processus le partagent).
struct ResumePratique: Codable, Equatable {
    var minutesAujourdhui: Int
    var objectifQuotidienMinutes: Int
    var serie: Int
    var heuresTotales: Double
    /// Date d'écriture : le widget sait ainsi si le résumé date d'hier.
    var ecritLe: Date

    static let vide = ResumePratique(minutesAujourdhui: 0, objectifQuotidienMinutes: 60,
                                     serie: 0, heuresTotales: 0, ecritLe: .distantPast)

    /// Part de l'objectif du jour, bornée à 1.
    var fractionObjectif: Double {
        guard objectifQuotidienMinutes > 0 else { return 0 }
        return min(Double(minutesAujourdhui) / Double(objectifQuotidienMinutes), 1)
    }

    /// Pourcentage de la route des 10 000 heures.
    var pourcentageRoute: Double {
        min(heuresTotales / 10_000 * 100, 100)
    }

    /// Le résumé a-t-il été écrit aujourd'hui ? Sinon les minutes du jour
    /// affichées seraient celles d'hier.
    func estDuJour(_ calendrier: Calendar = .current, maintenant: Date = .now) -> Bool {
        calendrier.isDate(ecritLe, inSameDayAs: maintenant)
    }

    /// Le résumé tel qu'il doit être affiché maintenant : après minuit,
    /// les minutes du jour repartent de zéro même sans nouvelle écriture.
    func actualise(maintenant: Date = .now) -> ResumePratique {
        guard !estDuJour(maintenant: maintenant) else { return self }
        var resume = self
        resume.minutesAujourdhui = 0
        return resume
    }
}

/// Le passage de l'app au widget. Les deux processus n'ont pas de conteneur
/// commun (un App Group demande un compte développeur payant), mais ils
/// partagent un groupe de trousseau — le résumé y est déposé, lisible même
/// écran verrouillé (`AfterFirstUnlock`).
enum PartageResume {
    /// Groupe de trousseau commun à l'app et au widget (préfixe = identifiant
    /// d'équipe, autorisé par le joker `92RVF22PBP.*` du profil de signature).
    private static let groupe = "92RVF22PBP.com.ousmanekonate.ostinato"
    private static let service = "com.ousmanekonate.ostinato.resume"
    private static let compte = "pratique"

    private static var requeteDeBase: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: compte,
         kSecAttrAccessGroup as String: groupe]
    }

    static func ecrire(_ resume: ResumePratique) {
        guard let donnees = try? JSONEncoder().encode(resume) else { return }
        SecItemDelete(requeteDeBase as CFDictionary)
        var ajout = requeteDeBase
        ajout[kSecValueData as String] = donnees
        ajout[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(ajout as CFDictionary, nil)
    }

    static func lire() -> ResumePratique? {
        var requete = requeteDeBase
        requete[kSecReturnData as String] = true
        requete[kSecMatchLimit as String] = kSecMatchLimitOne
        var resultat: CFTypeRef?
        guard SecItemCopyMatching(requete as CFDictionary, &resultat) == errSecSuccess,
              let donnees = resultat as? Data else { return nil }
        return try? JSONDecoder().decode(ResumePratique.self, from: donnees)
    }
}
