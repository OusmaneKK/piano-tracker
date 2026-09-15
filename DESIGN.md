# DESIGN.md — Correspondance design → SwiftUI

Source : projet Claude Design « Piano Learning App Design System »
(`Piano App.dc.html`, design system **Nocturne** `_ds/nocturne-…`).

## Écrans

| Écran du design | Implémentation |
|---|---|
| Onboarding 1 — The practice principle | `Fonctionnalites/Onboarding/OnboardingView.swift` (étape 1) |
| Onboarding 2 — How much time, each day? | idem (étape 2, choix 30/45/60/90 min + prévision) |
| Onboarding 3 — Connect your keyboard | idem (étape 3, adapté : voir « Adaptations ») |
| Today | `Fonctionnalites/Aujourdhui/AujourdhuiView.swift` |
| Practice (timer) | `Fonctionnalites/Session/SessionView.swift` + `SessionViewModel` |
| Journey (10 000 h) | `Fonctionnalites/Parcours/ParcoursView.swift` |
| Stats | `Fonctionnalites/Statistiques/StatistiquesView.swift` |
| Barre d'onglets custom | `Fonctionnalites/RacineView.swift` |

## Jetons Nocturne (styles.css → Theme/Nocturne.swift)

- Fond `#161826`, surface `#232532`, texte `#E9E9ED`, accent `#9184D9`.
- Rampes tonales neutres et accent 100–900 reprises telles quelles.
- Fond de section (héros Parcours) : `#262A60` → `#353B80`.
- Rayons : 14 pt pour les cartes (`--radius-lg`), boutons pilule `999`.
- L'accent s'utilise en **trait et lueur**, jamais en aplat (règle Nocturne) ;
  boutons principaux = contour accent sur fond transparent.

## Adaptations volontaires (design → iOS natif, zéro dépendance)

- **Icônes** : SF Symbols au lieu de Phosphor (house, timer, chart.bar, flame.fill,
  pianokeys, metronome, play/pause, checkmark…).
- **Police** : SF (système) au lieu d'Inter — pas de police embarquée dans le MVP ;
  chiffres en `monospacedDigit`.
- **Langue** : UI traduite en français (CLAUDE.md), textes du design adaptés.
- **MIDI** : le design annonce un suivi automatique via MIDI ; le vrai MIDI est hors
  périmètre. Les textes à l'écran le présentent comme « à venir », le suivi réel
  passe par le timer de session.
- **Données** : les valeurs du design (137 h, série de 12 jours, « Marie »…) sont des
  données de démonstration ; l'app calcule tout depuis SwiftData (départ à zéro).
  Le prénom n'est pas demandé à l'onboarding (le design ne le demande pas non plus) :
  la salutation reste « Bonjour / Bonsoir », l'avatar affiche une note de musique.
- Les cartes « Continuer » (Clair de Lune, gammes) restent du contenu statique MVP.
