# Site Uniclav

Site vitrine du clavier, en React + TypeScript, construit et servi par Bun.
Pensé pour le téléphone d'abord : la mise en page part de 360 px, les paliers
n'élargissent que la disposition, jamais le propos.

## Pages

Le site est constitué de cinq pages statiques distinctes — accueil, mentions
légales, confidentialité, CGU, accessibilité — et non d'une application
monopage. Les pages légales s'ouvrent donc sur n'importe quel hébergeur, sans
réécriture d'URL ni repli côté serveur, ce qui compte pour des documents dont
l'accessibilité est une obligation.

## Démarrer

```bash
bun install
bun run dev        # serveur de développement avec rechargement à chaud
bun run build      # sortie de production dans dist/
bun run typecheck  # tsc --noEmit, mode strict
```

## Ce qu'il faut compléter avant la mise en ligne

`src/config.ts` contient des valeurs marquées **À COMPLÉTER**. Ce sont des
mentions légales obligatoires en France — identité de l'éditeur, directeur de
la publication et hébergeur au titre de l'article 6-III de la LCEN. Elles n'ont
pas été inventées ; le pied de page les affiche telles quelles pour qu'on ne
puisse pas les oublier.

Les quatre pages légales sont écrites, mais leur contenu dépend de ces mêmes
valeurs : tant qu'elles ne sont pas renseignées, les mentions légales affichent
« À COMPLÉTER » à l'écran.

La déclaration d'accessibilité annonce qu'**aucun audit RGAA n'a été conduit**.
C'est exact : elle ne doit pas être modifiée pour annoncer une conformité tant
qu'un audit n'a pas eu lieu.

## La démonstration

`src/lib/groupedInput.ts` reprend la désambiguïsation du clavier, et
`src/lib/words.ts` est extrait de `Shared/dictionnaire_fr.txt` — la
démonstration s'appuie donc sur les mêmes données que l'application.

Le champ n'affiche qu'un mot de la longueur frappée, les mots plus longs
restant proposés dans la barre. Sans cela, effacer une touche laisserait
souvent le même mot à l'écran et paraîtrait sans effet. L'application suit la
même règle depuis `PredictionEngine.groupedMatches`.

La démonstration propose les deux façons de se servir des grosses touches. Le
mode « appuis répétés » rejoue la mécanique de `KeyboardView.handleMultiTap` :
un nouvel appui sur la même touche remplace la lettre tant que le délai court,
et en écrit une de plus une fois qu'il est écoulé. Le délai est réglable sur la
page, dans les mêmes bornes que l'application (0,6 à 3 s), parce que c'est
justement ce réglage qui décide si le mode est utilisable ou non.

## La marque et l'icône

`src/lib/icon.ts` porte la géométrie de l'icône de l'application, reprise de
`tools/make_icons.py` : la touche, les trois traits du A, la traînée des deux
touches fantômes.

Le site en dessinait auparavant une approximation dans `Mark.tsx`, et le
favicon une deuxième, différente de la première — trois dessins pour une seule
icône, dont deux ne ressemblaient pas à ce qui est livré. Ils partagent
désormais les mêmes nombres.

Ces nombres sont **recopiés**, faute d'un format que Python et TypeScript
liraient tous deux : s'ils changeaient d'un côté, rien ne le signalerait de
l'autre.

Ces nombres ont été relevés sur l'icône livrée, pixel par pixel : la version
précédente s'en écartait de 15,45/255 en moyenne. Voir *Icône* dans le README
de la racine pour le détail des mesures.

Le signe de la rotation des fantômes n'a pas été deviné non plus. Le SVG a été rendu
dans les deux sens et comparé pixel à pixel au PNG produit par le générateur,
sur la zone de la traînée : `rotate(-17,8)` donne un écart moyen de 2,99/255,
`rotate(17,8)` de 5,59.

La traînée est retirée en petit — favicon, pied de page, en-tête des pages
légales — comme l'application la retire sur la montre : à cette taille, deux
touches fantômes ne sont plus qu'une salissure.

Chaque marque tire son identifiant de dégradé de `useId()`. Deux marques de
mêmes couleurs sur une même page partageaient sinon leur `id`, ce qu'HTML
interdit et que `url(#id)` résoudrait vers la première d'entre elles — c'était
le cas de l'accueil, avec neuf marques pour sept identifiants.

## Les thèmes de couleurs

`src/lib/themes.ts` porte `Shared/KeyboardTheme.swift` : les sept couples de
couleurs, la formule de luminance relative de WCAG 2.1 et la dérivation des
teintes secondaires par mélange.

Les rapports de contraste affichés sur la page sont **calculés à l'exécution**,
jamais recopiés. Un chiffre saisi à la main finit par mentir le jour où une
couleur change — c'est d'ailleurs arrivé : le vert d'eau avait été annoncé à
11,6:1 alors qu'il vaut 11,5:1.

## Publication sur GitHub Pages

Le workflow [`.github/workflows/pages.yml`](../.github/workflows/pages.yml)
construit et publie le site à chaque poussée sur `master` touchant `site/`.

Deux points qui font échouer la plupart des sites de projet sur Pages, et qui
sont traités ici :

- **Le sous-répertoire.** Un site de projet est servi sous `/Uniclav/`, pas à la
  racine du domaine. Tous les liens internes sont donc relatifs ; un seul
  `href="/quelque-chose"` suffirait à tout casser. Bun produit déjà des chemins
  relatifs pour les ressources. Le rendu sous sous-répertoire est vérifié dans
  un navigateur avant chaque livraison.
- **Le nettoyage.** `bun run build` supprime `dist/` avant de reconstruire :
  sans cela, les fichiers hachés des builds précédents s'accumulent et
  finissent publiés.

Un `.nojekyll` est déposé pour que Pages serve les fichiers tels quels, et une
`404.html` en HTML statique évite d'embarquer React pour annoncer une page
absente.

### Une activation manuelle, une seule fois

Avant la première publication, un administrateur du dépôt doit choisir
**Réglages › Pages › Source : GitHub Actions**.

Cette étape ne peut pas être automatisée : créer un site Pages est une
opération d'administration que le jeton du workflow n'a pas le droit
d'effectuer. L'option `enablement` de `actions/configure-pages` échoue sur
« Resource not accessible by integration ». Une fois l'activation faite, le
workflow se déroule seul à chaque poussée.

## Licence

Le clavier Uniclav n'est pas un logiciel libre. Ce site et son contenu sont
protégés ; aucune licence n'est concédée au-delà de la consultation.
