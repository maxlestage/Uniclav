# Uniclav

Clavier iOS conçu pour les personnes hémiplégiques : frappe à une main, grandes
touches, prédiction de mots en français avec dictionnaire embarqué.

## Fonctionnalités

- **Clavier à une main** : les touches AZERTY sont regroupées du côté de la main
  valide (gauche ou droite), avec une flèche ⇄ pour changer de côté en un geste.
- **Grandes touches réglables** : largeur du clavier (60 à 100 % de l'écran) et
  hauteur des touches (44 à 66 pt) ajustables dans l'application.
- **Prédiction de mots** : barre de 3 suggestions alimentée par un dictionnaire
  français classé par fréquence (`Shared/dictionnaire_fr.txt`), incluant du
  vocabulaire du quotidien et de la santé/rééducation. Les mots tapés par
  l'utilisateur sont appris et remontent dans les suggestions.
- **Accents par appui long** : maintenir `e` propose é è ê ë, etc. Glisser le
  doigt pour choisir. La recherche de suggestions ignore les accents
  (« ecol » → « école »).
- **Confort de frappe** : majuscule automatique en début de phrase, verrouillage
  majuscules par double appui sur ⇧, point par double espace, effacement continu
  en maintenant ⌫, contraste renforcé et grandes lettres en option.
- **Respect de la vie privée** : aucun accès réseau demandé (`RequestsOpenAccess`
  à `false`), tout fonctionne en local. Les mots appris restent sur l'appareil
  (App Group).

## Structure du projet

```
Uniclav.xcodeproj/        Projet Xcode (versionné)
Uniclav/                  Application conteneur (SwiftUI) : réglages + activation
UniclavKeyboard/          Extension clavier (UIKit)
  KeyboardViewController  Point d'entrée de l'extension
  KeyboardView            Disposition à une main, suggestions, gestion des touches
  KeyButton               Style et libellés des touches
  AccentPopupView         Popup d'accents à l'appui long
Shared/                   Code commun aux deux cibles
  KeyboardSettings        Réglages partagés via l'App Group
  PredictionEngine        Moteur de prédiction (dictionnaire + apprentissage)
  dictionnaire_fr.txt     Dictionnaire français classé par fréquence
```

Les deux cibles partagent les fichiers de `Shared/` : `Info.plist` et
`.entitlements` de chaque cible sont versionnés à côté de ses sources.

## Compilation

Le projet Xcode est versionné directement — aucun outil de génération n'est
nécessaire :

```bash
open Uniclav.xcodeproj
```

Dans Xcode :

1. Sélectionnez votre **équipe de développement** (Signing & Capabilities) pour
   les deux cibles `Uniclav` et `UniclavKeyboard`.
2. Si votre identifiant d'équipe impose d'autres bundle IDs, changez-les dans
   les réglages des deux cibles (ainsi que l'App Group
   `group.com.maxlestage.uniclav`, présent dans les deux fichiers
   `.entitlements` et dans `Shared/KeyboardSettings.swift`).
3. Compilez et lancez le schéma `Uniclav` sur un iPhone ou un simulateur
   (iOS 16 minimum). L'extension clavier est construite et embarquée
   automatiquement comme dépendance.

## Activation du clavier sur l'appareil

1. **Réglages** › **Général** › **Clavier** › **Claviers** › **Ajouter un
   clavier…** › **Uniclav**.
2. Dans n'importe quelle app, maintenir le globe 🌐 et choisir **Uniclav**.

## Enrichir le dictionnaire

`Shared/dictionnaire_fr.txt` contient un mot par ligne, du plus fréquent au
moins fréquent (les lignes commençant par `#` sont ignorées). Vous pouvez le
remplacer par une liste de fréquence plus complète, par exemple issue de
[Lexique.org](http://www.lexique.org/) — vérifiez la licence de la liste
utilisée avant distribution.

## Intégration continue

Le workflow [`.github/workflows/ci.yml`](.github/workflows/ci.yml) compile le
projet à chaque push et pull request : il sélectionne l'Xcode le plus récent du
runner puis compile le schéma `Uniclav` (application + extension clavier) pour
le simulateur iOS, sans signature de code.
