/**
 * La géométrie de l'icône de l'application, reprise telle quelle de
 * `tools/make_icons.py`.
 *
 * Le site en dessinait jusqu'ici une approximation — et le favicon une
 * deuxième, différente de la première. Trois dessins pour une seule icône,
 * dont deux ne ressemblaient pas à ce qui est réellement livré. Les nombres
 * ci-dessous sont ceux du générateur, à l'échelle 1000 plutôt que 0–1.
 *
 * Ils sont recopiés, faute d'un format que Python et TypeScript liraient tous
 * deux ; s'ils changeaient d'un côté, rien ne le signalerait de l'autre.
 */

export const VIEW_BOX = 1000;

/** La touche : x, y, largeur, hauteur, rayon. */
export const KEY = { x: 330, y: 200, width: 490, height: 484, radius: 55 };

/** La traînée : la course de la main qui vient chercher la touche. */
export const GHOSTS = [
  { x: 237, y: 557, size: 196, radius: 28, blend: 0.3 },
  { x: 87, y: 707, size: 170, radius: 26, blend: 0.22 },
];

/** Rotation des touches fantômes, en degrés. */
export const GHOST_ROTATION = -17.8;

/** Les trois traits du A, à extrémités arrondies. Aucune police n'intervient. */
export const LETTER = "M575 287 L472 585 M575 287 L678 585 M512 492 L638 492";
export const LETTER_STROKE = 46;

/** Le mélange qui donne le bas du dégradé de fond. */
export const BACKDROP_BLEND = 0.14;
