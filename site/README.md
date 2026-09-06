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

L'étape `configure-pages` active Pages automatiquement si ce n'est pas déjà
fait. À défaut, il reste à choisir **Réglages › Pages › Source : GitHub
Actions** dans le dépôt.

## Licence

Le clavier Uniclav n'est pas un logiciel libre. Ce site et son contenu sont
protégés ; aucune licence n'est concédée au-delà de la consultation.
