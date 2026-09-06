# Site Uniclav

Site vitrine du clavier, en React + TypeScript, construit et servi par Bun.
Pensé pour le téléphone d'abord : la mise en page part de 360 px, les paliers
n'élargissent que la disposition, jamais le propos.

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

Les quatre pages légales référencées dans le pied de page (mentions légales,
confidentialité, CGU, déclaration d'accessibilité) restent à écrire : le site
est une page unique et ces liens ne mènent nulle part pour l'instant.

## La démonstration

`src/lib/groupedInput.ts` reprend la désambiguïsation du clavier, et
`src/lib/words.ts` est extrait de `Shared/dictionnaire_fr.txt` — la
démonstration s'appuie donc sur les mêmes données que l'application.

Une différence assumée : le champ n'affiche qu'un mot de la longueur frappée,
les mots plus longs restant proposés dans la barre. Sans cela, effacer une
touche laisserait souvent le même mot à l'écran et paraîtrait sans effet.
L'application affiche aujourd'hui la meilleure complétion ; les aligner
demanderait une modification de `KeyboardView.refreshPending`.

## Licence

Le clavier Uniclav n'est pas un logiciel libre. Ce site et son contenu sont
protégés ; aucune licence n'est concédée au-delà de la consultation.
