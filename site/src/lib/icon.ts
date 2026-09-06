/**
 * La géométrie de l'icône de l'application, reprise telle quelle de
 * `tools/make_icons.py` — où elle a elle-même été relevée pixel par pixel sur
 * l'icône livrée, et non dessinée d'après une intention.
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

/** La touche : un carré, x, y, côté, rayon. */
export const KEY = { x: 334, y: 203, size: 476, radius: 63.5 };

/** La traînée : la course de la main qui vient chercher la touche. */
export const GHOSTS = [
  { x: 244.6, y: 570.3, size: 164.1, radius: 21.9, blend: 0.218 },
  { x: 104.5, y: 693.4, size: 156.3, radius: 20.9, blend: 0.129 },
];

/** Rotation des touches fantômes, en degrés. */
export const GHOST_ROTATION = -17.8;

/** Les trois traits du A, à extrémités arrondies. Aucune police n'intervient. */
export const LETTER =
  "M571.8 314.1 L471.7 566.4 M571.8 314.1 L671.9 566.4 M507.7 475.6 L635.8 475.6";
export const LETTER_STROKE = 54.7;

/** Le bas du dégradé d'un thème, quand aucune paire n'est donnée. */
export const GROUND_BLEND = 0.16;

/** Le fond de la marque : la paire « sable » de l'identité, relevée sur
 *  l'icône livrée. Ce n'est pas un mélange uniforme du fond des touches vers
 *  l'encre — les trois canaux y descendent de 12,7 %, 14,9 % et 19,7 %. */
export const BRAND_GROUND = { top: "F2EBDE", bottom: "D8CDB8", ink: "26221D" };
