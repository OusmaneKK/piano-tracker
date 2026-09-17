# CLAUDE.md — App piano iOS (MVP)

## Objectif du projet

Application iOS (Swift / SwiftUI) de suivi de pratique pour pianiste autodidacte adulte.
Vision long terme : routines journalières, MIDI Bluetooth, lecture de partition, abonnement.
**Le MVP fait une chose : compter les heures de pratique sur la route des 10 000 heures.**
Timer de session, objectif quotidien, série de jours, jalons de progression, statistiques.
Un seul utilisateur au départ : l'auteur. Pas de backend, pas de compte, pas d'abonnement.

Le design de référence est le projet Claude Design « Piano Learning App Design System »
(écrans : Onboarding ×3, Aujourd'hui, Session, Parcours, Stats — thème « Nocturne »).
Voir DESIGN.md pour la correspondance design → SwiftUI et les jetons de couleur.

## Stack et contraintes

- Swift 5.10+, SwiftUI, iOS 17 minimum. Xcode 16 ou plus récent (Xcode 26 sur la machine de dev).
- Persistance : SwiftData. Pas de CoreData brut, pas de UserDefaults pour les données métier.
- **Zéro dépendance externe** (pas de SPM tiers) tant que ce n'est pas indispensable. Les anneaux de progression et graphiques se dessinent en SwiftUI pur.
- Architecture : MVVM léger. `@Observable` (Observation framework), pas de Combine.
- Tests : XCTest. Toute la logique du domaine (progression, jalons, série, prévisions, formatage du temps) est testée. Pas de test UI pour le MVP.
- Langue : interface, contenu, noms de types métier, commentaires et commits en **français**. Les identifiants techniques SwiftUI restent en anglais (`body`, `View`, etc.).
- Commits : Conventional Commits, ex. `feat(session): timer de pratique`.

## Structure attendue

```
PianoApp/
  App/                 PianoApp.swift, point d'entrée
  Theme/               Nocturne.swift — jetons de couleur importés du design system
  Domaine/             Modèles purs, sans import SwiftUI
    Jalon.swift        les 7 jalons de la route des 10 000 heures
    Progression.swift  pourcentage, prochain jalon, série (tolérance 1 jour), prévisions
    FormatTemps.swift  mm:ss, heures localisées
  Fonctionnalites/
    RacineView.swift   barre d'onglets custom + aiguillage onboarding
    Onboarding/        4 étapes : principe, objectif quotidien, créneau agenda, clavier
    Aujourdhui/        anneau d'objectif, route des 10 000 h, suggestions
    Session/           SessionView + SessionViewModel (timer)
    Parcours/          heures investies + frise des jalons
    Statistiques/      tuiles, barres hebdo, prévision
  Persistance/         modèles SwiftData : SessionPratique, Profil
  Ressources/          Assets.xcassets
PianoAppTests/
  ProgressionTests.swift
  FormatTempsTests.swift
```

## Fonctionnalités du MVP (dans l'ordre)

### 1. Onboarding (4 étapes, à la première ouverture)
1. Le principe : 10 000 heures vers la maîtrise, pas de raccourci.
2. Choix de l'objectif quotidien : 30 / 45 / 60 / 90 min, avec prévision (« à ce rythme… »).
3. Réservation du créneau quotidien : choix de l'heure, fiche système EventKitUI
   pré-remplie (événement récurrent quotidien). Étape passable (« Plus tard »),
   aussi accessible depuis Aujourd'hui.
4. Écran clavier (le vrai MIDI est hors périmètre : texte d'attente, un bouton pour commencer).

### 2. Aujourd'hui
- Salutation selon l'heure, date du jour.
- Anneau de progression : minutes pratiquées aujourd'hui / objectif quotidien.
- Série en cours (flamme), route des 10 000 heures (barre + pourcentage).
- Suggestions « Continuer » (contenu statique pour le MVP) → onglet Session.

### 3. Session (timer)
- Grand anneau (cible visuelle 25 min), timer mm:ss, lecture/pause, remise à zéro, terminer.
- Le timer survit au changement d'onglet (état porté par la racine).
- Terminer enregistre une `SessionPratique` (durée ≥ 60 s) en SwiftData.

### 4. Parcours
- Total d'heures investies, pourcentage de la route, rythme hebdomadaire.
- Frise des 7 jalons (25 → 10 000 h), jalons atteints en accent.

### 5. Stats
- Tuiles : heures cette semaine, moyenne quotidienne, série, heures totales.
- Barres des 7 derniers jours (minutes/jour), aujourd'hui en accent.
- Prévision « à ce rythme » calculée sur le rythme réel.

### Règles du domaine
- La série (« jours consécutifs avec au moins une session ») tolère **une** journée manquée
  si l'utilisateur reprend le lendemain. Le but est de tenir des mois, pas de culpabiliser.
- Les prévisions se basent sur le rythme réel des 4 dernières semaines ; à défaut, sur l'objectif quotidien.

## Hors périmètre du MVP (ne pas implémenter, ne pas préparer « au cas où »)
- MIDI / Bluetooth réels, détection audio, métronome fonctionnel (les mentions à l'écran restent du texte)
- Lecture de partition, quiz de notes (prochaine grande fonctionnalité, après le MVP)
- Routines hebdomadaires, planning, notifications.
  **Exception actée (2026-09-18)** : l'écriture d'un événement récurrent « créneau
  quotidien » via la fiche système EventKitUI (aucune permission requise sur iOS 17+).
  La frontière tient : pas de lecture d'agenda, pas de replanification, pas de rappels.
- Abonnement, StoreKit, compte utilisateur, sync iCloud
- macOS / iPad (iOS seul ; SwiftUI rend le portage facile plus tard)

## Règles de travail
- Avant de coder une fonctionnalité, proposer en 5 lignes max le découpage, puis coder.
- Une fonctionnalité = une branche = une PR, même en solo.
- Ne jamais introduire d'abstraction pour un besoin futur listé « hors périmètre ».
- Si une décision produit n'est pas tranchée ici, demander plutôt que supposer.
- Après chaque modification du domaine : `xcodebuild test -scheme PianoApp -destination 'platform=iOS Simulator,name=iPhone 17'` doit passer.
- Le .gitignore respecte les règles de sécurité (jamais de secrets, certificats ni xcuserdata).
- À la fin de chaque tâche, committer les fichiers.

## Glossaire
| Terme | Sens |
|---|---|
| Route | Le chemin vers 10 000 heures de pratique délibérée |
| Jalon | Palier de la route (25, 100, 500, 1 000, 2 500, 5 000, 10 000 h) |
| Session | Une période de pratique chronométrée, enregistrée à la fin |
| Objectif quotidien | Minutes visées par jour, choisi à l'onboarding |
| Série | Jours consécutifs avec au moins une session (tolérance d'un jour) |
| Nocturne | Le design system sombre du projet (jetons dans Theme/Nocturne.swift) |
