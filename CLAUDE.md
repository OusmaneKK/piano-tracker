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
    QuizNotes.swift    notes en clé de sol (Do4–Fa5), positions sur la portée, tirage
    SuiviMIDI.swift    comptage automatique : seuil de silence, date de pause
  Fonctionnalites/
    RacineView.swift   barre d'onglets custom + aiguillage onboarding
    Onboarding/        4 étapes : principe, objectif quotidien, créneau agenda, clavier
    Aujourdhui/        anneau d'objectif, route des 10 000 h, suggestions
    Session/           SessionView + SessionViewModel (timer)
    Quiz/              QuizView + QuizViewModel (lecture de notes, série de 10)
    MIDI/              GestionnaireMIDI (CoreMIDI) + appairage Bluetooth (CoreAudioKit)
    Parcours/          heures investies + frise des jalons
    Statistiques/      tuiles, barres hebdo, prévision
  Persistance/         modèles SwiftData : SessionPratique, Profil
  Ressources/          Assets.xcassets
Partage/               code compilé dans l'app ET dans le widget
  ResumePratique.swift résumé du jour + dépôt/lecture dans le trousseau partagé
OstinatoWidget/        extension WidgetKit (écran verrouillé + écran d'accueil)
Config/                entitlements des deux cibles, Info.plist du widget
PianoAppTests/
  ProgressionTests.swift
  FormatTempsTests.swift
  QuizNotesTests.swift
  SuiviMIDITests.swift
  ResumePratiqueTests.swift
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
- Comptage automatique (clavier MIDI branché) : la première note démarre la
  session, 2 minutes de silence la mettent en pause — rétroactivement à la
  dernière note, pour que le silence ne soit jamais compté comme pratique.

### 4. Parcours
- Total d'heures investies, pourcentage de la route, rythme hebdomadaire.
- Frise des 7 jalons (25 → 10 000 h), jalons atteints en accent.

### 5. Stats
- Tuiles : heures cette semaine, moyenne quotidienne, série, heures totales.
- Barres des 7 derniers jours (minutes/jour), aujourd'hui en accent.
- Prévision « à ce rythme » calculée sur le rythme réel.
- Historique : dernières sessions, ajout manuel d'une session oubliée
  (jour passé + durée), suppression avec confirmation.

### 6. Quiz de notes (première fonctionnalité post-MVP, design « mini-clavier »)
- Accès depuis Aujourd'hui, plein écran. Réglages avant la série : clé de sol
  (Do4–Fa5) ou clé de fa (Sol2–Do4, le Do central au-dessus), altérations ♯/♭
  en option (~1 question sur 3 ; enharmonie : Sol♯ et La♭ = la même touche noire).
- Réponse en touchant la touche du mini-clavier (une octave complète, touches
  noires actives quand les altérations le sont).
- Série de 10, score final, bandeau pédagogique (« C'était La — 2ᵉ interligne »).
- Un clavier MIDI (Bluetooth ou USB) répond au quiz : note jouée = touche pressée.
- Le quiz n'entame pas le compteur des 10 000 heures (théorie ≠ pratique).

### 7. Widget (écran verrouillé et écran d'accueil)
- Anneau des minutes du jour, série, pourcentage de la route.
- L'app dépose un `ResumePratique` (quelques nombres) dans un **groupe de
  trousseau partagé**, faute d'App Group : celui-ci demande un compte
  développeur payant, le trousseau non. À remplacer par un App Group + store
  SwiftData partagé le jour d'un compte payant.
- Le widget ne lit jamais la base SwiftData : il n'a que le résumé.

### Règles du domaine
- La série (« jours consécutifs avec au moins une session ») tolère **une** journée manquée
  si l'utilisateur reprend le lendemain. Le but est de tenir des mois, pas de culpabiliser.
- Les prévisions se basent sur le rythme réel des 4 dernières semaines ; à défaut, sur l'objectif quotidien.

## Hors périmètre du MVP (ne pas implémenter, ne pas préparer « au cas où »)
- Détection audio, métronome fonctionnel (les mentions à l'écran restent du texte).
  **Exception actée (2026-09-18)** : le MIDI (CoreMIDI / Bluetooth) est réel — il
  répond au quiz de notes (note jouée = touche pressée, l'octave est ignorée) et
  pilote le comptage automatique des sessions. Le clavier ne compte que l'app au
  premier plan : iOS suspend les apps en arrière-plan, et l'écran reste allumé
  pendant qu'on attend ou qu'on joue.
- Lecture de partition complète (le quiz de notes v1 existe ; altérations,
  clé de fa et partitions restent à venir)
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
