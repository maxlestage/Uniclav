# Uniclav

Clavier iOS conçu pour les personnes hémiplégiques : frappe à une main, grandes
touches, prédiction de mots en français avec dictionnaire embarqué.

## Fonctionnalités

- **Six modes de clavier**, au choix de l'utilisateur : AZERTY, alphabétique,
  fréquence, grosses touches, très grosses touches et appuis répétés. Chacun
  répond à une gêne différente ; aucun n'est meilleur dans l'absolu. Voir
  *Modes de clavier*.
- **Couleurs réglables** : sept thèmes, tous mesurés au niveau AAA de WCAG, ou
  vos propres couleurs — fond des touches et lettres réglés séparément, avec le
  rapport de contraste affiché en direct.
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
  KeyboardTheme           Couleurs du clavier et calcul de contraste WCAG
  LetterGroups            Découpages des lettres sur les touches groupées
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

## Modes de clavier

Six modes, choisis dans l'application. Le choix n'est pas cosmétique : chacun
répond à une gêne distincte, et les chiffres ci-dessous sont mesurés sur le
dictionnaire fourni, pas estimés.

### Une lettre par touche

| Mode | Déplacement du doigt | Pour qui |
|---|---|---|
| **AZERTY** | 3,72 | ceux qui connaissent déjà la disposition |
| **Alphabétique** | 3,72 | ceux qui cherchent les lettres du regard |
| **Fréquence** | **2,11** (−43 %) | ceux qui tapent beaucoup et bougent peu le bras |

Le déplacement est la distance moyenne parcourue par un doigt unique entre deux
lettres consécutives, en largeurs de touche, sur le dictionnaire pondéré par la
fréquence des mots. Une rangée compte 1,4 fois une colonne : le pouce s'écarte
moins facilement en hauteur qu'en largeur.

L'ordre alphabétique **ne raccourcit pas** le trajet — il est identique à
l'AZERTY à 0,1 % près. Ce qu'il change est ailleurs : on y trouve une lettre
sans connaître la disposition, ce qui compte quand la mémoire du clavier a été
perdue ou n'a jamais existé.

La disposition « fréquence » pose les lettres en spirale depuis le centre, par
fréquence décroissante en français. Elle économise 43 % du déplacement, mais
elle est entièrement à apprendre : c'est un pari qui ne vaut que pour un usage
soutenu.

### Plusieurs lettres par touche

On tape la touche qui porte la lettre, sans viser la lettre elle-même ; le
dictionnaire retrouve le mot, et la barre propose les autres lectures possibles
de la même frappe.

| Mode | Premier coup | Visible dans les 3 suggestions | Pire collision |
|---|---|---|---|
| **Grosses touches** (8) | 94,7 % | **100 %** | 3 mots |
| **Très grosses touches** (6) | 88,5 % | 99,1 % | 5 mots |

À huit touches, le mot voulu est *toujours* visible : le plus gros groupe de
collision compte trois mots, et la barre en affiche trois. À six touches, on
échange un peu de précision contre des cibles nettement plus larges — le bon
compromis pour une main qui tremble.

Un découpage à quatre touches a été mesuré puis écarté : 84,2 % du premier coup
pour un gain de largeur marginal, et une liste de modes déjà longue. Au-delà de
cinq choix, le réglage devient lui-même un obstacle.

Les collisions restantes sont presque toutes des paires accentuées
(`donne` / `donné`) ou des voisins évidents (`mon` / `non` / `nom`).

### Appuis répétés

Les mêmes huit grosses touches, mais **sans dictionnaire** : on appuie
plusieurs fois sur la même touche jusqu'à obtenir la lettre voulue, comme sur
un téléphone d'avant. C'est plus lent, et c'est le seul mode totalement
prévisible — aucun mot ne peut être refusé, noms propres compris. Il rend donc
inutile le repli vers l'AZERTY qu'exigent les deux modes à dictionnaire.

Une lettre est figée passé un délai réglable de 0,6 à 3 secondes, généreux par
défaut à 1,5 s. Ce réglage compte : un délai court rend le mode inutilisable
pour une main lente, et c'est précisément la main qu'on vise ici. Passé le
délai, un nouvel appui sur la même touche écrit une lettre de plus au lieu de
changer la précédente — c'est ainsi qu'on écrit deux lettres du même groupe à
la suite.

## Couleurs

Sept thèmes, et la possibilité de choisir ses propres couleurs. Le fond des
touches et la couleur des lettres se règlent **séparément** ; les autres teintes
— touches de service, fond général — en sont dérivées par mélange, pour qu'un
seul choix suffise.

| Thème | Contraste |
|---|---|
| Encre sur sable | 14,9:1 |
| Nuit | 9,6:1 |
| Contraste maximal | 21,0:1 |
| Jaune sur noir | 12,9:1 |
| Noir sur jaune | 12,9:1 |
| Bleu profond | 13,7:1 |
| Vert d'eau | 11,6:1 |

Tous atteignent le niveau **AAA** de WCAG 2.1 (rapport ≥ 7:1). Ce n'est pas une
coquetterie : sur un clavier destiné à des personnes dont la vue peut avoir été
touchée par le même AVC, un thème illisible n'est pas une option esthétique.

Rien n'empêche en revanche de choisir soi-même deux teintes trop proches.
L'application calcule donc le rapport de contraste **en direct** et le dit
franchement quand il descend sous 4,5:1 — `KeyboardTheme.swift` implémente la
formule de luminance relative de WCAG.

Les accents, apostrophes et traits d'union sont ignorés dans la frappe : taper
les lettres de « aujourdhui » produit « aujourd'hui », correctement
orthographié. Les mots appris par le clavier rejoignent l'index et deviennent
saisissables de la même façon.

Un mot absent du dictionnaire — un nom propre, souvent — ne peut pas être
deviné : la touche ⊞ ramène alors l'AZERTY le temps de l'écrire, puis y
ramène. Elle fait un aller-retour plutôt que de faire défiler les cinq modes :
une sortie de secours doit rester à une touche.

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
2. **Les mots que le clavier n'a pas reconnus**, si — et seulement si —
   l'utilisateur l'a autorisé. L'extension les note dans l'App Group sans
   pouvoir les vérifier ; l'application demande au Wiktionnaire s'ils sont
   français et, si oui, les ajoute définitivement avec leurs accents. C'est la
   source qui compte le plus : ce sont les mots que cette personne écrit
   réellement, noms propres compris — précisément ce que les grosses touches ne
   savaient pas deviner.

### Les mots inconnus ne partent pas par défaut

Un mot absent d'un dictionnaire français est le plus souvent un nom propre : un
prénom, une commune, le nom d'un praticien. Ce sont exactement les mots qu'on
n'envoie pas à un tiers sans l'avoir demandé.

Leur soumission au Wiktionnaire fait donc l'objet d'un réglage distinct de la
mise à jour du dictionnaire — `KeyboardSettings.shareUnknownWords` — **désactivé
tant qu'il n'est pas explicitement activé**. Le vocabulaire de base, lui, ne
révèle rien et continue d'être téléchargé.

Désactivé, le clavier n'arrête pas d'apprendre : vos mots remontent toujours
dans les suggestions, mais le calcul reste sur l'appareil.

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

## Site vitrine

`site/` contient le site de présentation, en React + TypeScript construit par
Bun, pensé pour le téléphone d'abord. Il est publié sur GitHub Pages par
[`.github/workflows/pages.yml`](.github/workflows/pages.yml) à chaque poussée
sur `master`.

Voir [`site/README.md`](site/README.md) — notamment les mentions légales qui
restent à renseigner, et les précautions liées au sous-répertoire d'un site de
projet.

## Intégration continue

Le workflow [`.github/workflows/ci.yml`](.github/workflows/ci.yml) compile le
projet à chaque push et pull request : il sélectionne l'Xcode le plus récent du
runner, compile le schéma `Uniclav` (application, extension clavier et app
montre embarquée) pour le simulateur iOS, puis le schéma `UniclavWatch` pour le
simulateur watchOS — le tout sans signature de code. Un second job, sur runner
Linux, vérifie les types et la compilation du site.
