# Uniclav

Clavier iOS conçu pour les personnes hémiplégiques : frappe à une main, grandes
touches, prédiction de mots en français avec dictionnaire embarqué.

## Fonctionnalités

- **Deux dispositions** : AZERTY complet, ou **grosses touches** — huit touches
  de trois ou quatre lettres que le dictionnaire désambiguïse. Chaque touche est
  alors près de trois fois plus large, ce qui pardonne l'imprécision du geste.
  La touche ⊞ bascule de l'une à l'autre sans quitter le clavier.
- **Clavier à une main** : les touches sont regroupées du côté de la main valide
  (gauche ou droite), avec une flèche ⇄ pour changer de côté en un geste.
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
  Assets.xcassets         Icône de l'app (1024 px, déclinée par Xcode)
UniclavWatch/             App compagnon watchOS : phrases rapides
  PhraseLibrary           Phrases classées par urgence
  PhraseListView          Liste au poignet
  PhraseDisplayView       Affichage plein écran + lecture vocale
  Assets.xcassets         Icône montre (composition tenant dans le cercle)
UniclavKeyboard/          Extension clavier (UIKit)
  KeyboardViewController  Point d'entrée de l'extension
  KeyboardView            Disposition à une main, suggestions, gestion des touches
  KeyButton               Style et libellés des touches
  AccentPopupView         Popup d'accents à l'appui long
Shared/                   Code commun aux deux cibles
  KeyboardSettings        Réglages partagés via l'App Group
  LetterGroups            Répartition des lettres sur les grosses touches
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
   (iOS 16 minimum). L'extension clavier et l'app montre sont construites et
   embarquées automatiquement comme dépendances.
4. Pour travailler sur la montre seule, choisissez le schéma `UniclavWatch`
   (watchOS 9 minimum).

## Activation du clavier sur l'appareil

1. **Réglages** › **Général** › **Clavier** › **Claviers** › **Ajouter un
   clavier…** › **Uniclav**.
2. Dans n'importe quelle app, maintenir le globe 🌐 et choisir **Uniclav**.

## Icône

Chaque application a son catalogue, avec une seule image de 1024 × 1024 px
dont Xcode dérive toutes les tailles requises :

- `Uniclav/Assets.xcassets` pour l'iPhone ;
- `UniclavWatch/Assets.xcassets` pour la montre.

Le motif est une touche de clavier unique, portant un A dessiné au trait.
Un seul élément, très grand : c'est ce qui reste lisible à 40 px sur un écran
d'accueil, là où une grille de touches devient une texture indistincte.

La palette est **encre sur sable**, définie dans `Shared/Palette.swift` et
partagée par les trois cibles. Le fond clair n'est pas un choix décoratif : un
écran d'accueil est un mur de carrés sombres et saturés, et une icône claire
s'y repère par inversion plutôt que par nuance. C'est aussi, des variantes
essayées, celle qui donne le plus fort contraste sur la lettre — ce qui compte
pour une personne dont le champ visuel peut être amputé après un AVC.

L'accent de l'interface suit la même encre, et inverse ses rôles en mode
sombre, où l'encre disparaîtrait.

Sur iPhone, deux touches fantômes traînent vers le bas à gauche — la course de
la main qui vient chercher la touche. Sur la montre, cette traînée disparaît :
**watchOS masque l'icône en cercle** et l'aurait tronquée, la touche seule y
tient parfaitement.

Le A est tracé par trois segments à extrémités arrondies, sans dépendance à
une police : le rendu est identique partout.

Pour la remplacer, déposez votre propre PNG **opaque et sans canal alpha** de
1024 × 1024 px sous le nom `AppIcon-1024.png` : l'App Store refuse les icônes
comportant de la transparence. N'arrondissez pas les angles, iOS applique
lui-même son masque.

L'extension clavier n'a pas d'icône propre : iOS affiche celle de
l'application dans les réglages de clavier.

## App montre

`UniclavWatch` est une app compagnon watchOS : un tableau de phrases prêtes à
l'emploi, classées par urgence (Urgent, Besoins, Échanges). Une phrase touchée
s'affiche en grand — pour être montrée à un tiers — et est lue à voix haute en
français, avec une vibration de confirmation.

watchOS n'expose aucune API de clavier tiers : le clavier Uniclav ne peut pas
fonctionner sur la montre. C'est la communication rapide, quand la parole ou le
déplacement manquent, que cette app couvre.

Pour modifier les phrases, éditez `UniclavWatch/PhraseLibrary.swift`.

## Saisie à grosses touches

Les lettres se répartissent sur huit touches, comme sur un clavier
téléphonique : `ABC` `DEF` `GHI` `JKL` `MNO` `PQRS` `TUV` `WXYZ`. On tape la
touche qui porte la lettre, sans viser la lettre elle-même ; le dictionnaire
retrouve le mot, et la barre de suggestions propose les autres lectures
possibles de la même frappe.

Mesuré sur le dictionnaire fourni : **94,7 % des mots sont trouvés du premier
coup, 98 % parmi les cent plus fréquents**. Surtout, le plus gros groupe de
collision compte trois mots — avec trois emplacements de suggestion, le mot
voulu est donc toujours visible, au pire à une touche. Les collisions restantes
sont presque toutes des paires accentuées (`donne` / `donné`) ou des voisins
évidents (`mon` / `non` / `nom`).

Les accents, apostrophes et traits d'union sont ignorés dans la frappe : taper
les lettres de « aujourdhui » produit « aujourd'hui », correctement
orthographié. Les mots appris par le clavier rejoignent l'index et deviennent
saisissables de la même façon.

Un mot absent du dictionnaire — un nom propre, souvent — ne peut pas être
deviné : la touche ⊞ ramène alors l'AZERTY le temps de l'écrire. C'est la
limite assumée de cette disposition, et la raison pour laquelle les deux
coexistent.

Le script qui mesure ces collisions n'est pas versionné ; la répartition des
lettres se modifie dans `Shared/LetterGroups.swift`.

## Dictionnaire et Wiktionnaire

`Shared/dictionnaire_fr.txt` est la base livrée avec l'app : un mot par ligne,
du plus fréquent au moins fréquent (les lignes commençant par `#` sont
ignorées). L'application l'enrichit ensuite depuis le
[Wiktionnaire francophone](https://fr.wiktionary.org) et dépose le résultat
dans l'App Group, d'où le clavier le relit.

### Qui accède au réseau

**Le clavier, jamais.** `RequestsOpenAccess` reste à `false` : une extension de
clavier autorisée à émettre des requêtes pourrait aussi émettre ce qu'on tape,
et ce clavier sert notamment à écrire des choses médicales. C'est
l'application, et elle seule, qui télécharge ; le clavier lit un fichier local.
`WiktionaryClient` et `DictionaryUpdate` vivent donc dans `Uniclav/`, hors de
la cible de l'extension.

### Ce que le Wiktionnaire apporte, et ce qu'il n'apporte pas

Il apporte la **couverture** : des millions d'entrées, les noms propres, les
formes fléchies, l'orthographe accentuée exacte.

Il n'apporte **aucune fréquence d'usage** — c'est un dictionnaire, pas un
corpus. Or la désambiguïsation des grosses touches repose entièrement sur le
classement par fréquence : sans lui, rien ne dit que « vous » doit passer avant
« tous ». Les mots venus du Wiktionnaire sont donc ajoutés **en fin de liste**,
sans jamais déranger le classement de la base d'origine ; ce sont vos propres
usages, comptés localement, qui les font remonter.

### Deux sources, dans cet ordre

1. **Le vocabulaire de base** du Wiktionnaire (la liste des mots que tous les
   Wiktionnaires devraient avoir), soit un millier de mots obtenus en une seule
   requête. Fusionné une fois pour toutes.
2. **Les mots que le clavier n'a pas reconnus.** L'extension les note dans
   l'App Group sans pouvoir les vérifier ; l'application demande au
   Wiktionnaire s'ils sont français et, si oui, les ajoute définitivement avec
   leurs accents. C'est la source qui compte le plus : ce sont les mots que
   cette personne écrit réellement, noms propres compris — précisément ce que
   les grosses touches ne savaient pas deviner.

### Rythme des mises à jour

Au lancement de l'app, puis par réveil en arrière-plan (`BGAppRefreshTask`),
**une fois par jour au plus**. Trois raisons de ne pas faire davantage :
l'API de Wikimédia limite le débit et renvoie une erreur 429 au bout de
quelques requêtes rapprochées ; un dictionnaire évolue lentement ; et iOS
décide seul du moment réel des réveils en arrière-plan. Ce qui se met à jour
en permanence, en revanche, c'est l'apprentissage personnel — il est local et
prend effet au mot suivant.

Une énumération complète du français est hors de portée d'un téléphone :
plusieurs millions d'entrées, cinq cents par requête, sans marquage de langue
exploitable. C'est pourquoi l'enrichissement est ciblé plutôt qu'exhaustif.

## Intégration continue

Le workflow [`.github/workflows/ci.yml`](.github/workflows/ci.yml) compile le
projet à chaque push et pull request : il sélectionne l'Xcode le plus récent du
runner, compile le schéma `Uniclav` (application, extension clavier et app
montre embarquée) pour le simulateur iOS, puis le schéma `UniclavWatch` pour le
simulateur watchOS — le tout sans signature de code.
