import { useId } from "react";
import {
  BRAND_GROUND,
  GHOSTS,
  GHOST_ROTATION,
  GROUND_BLEND,
  KEY,
  LETTER,
  LETTER_STROKE,
  VIEW_BOX,
} from "../lib/icon.ts";
import { blended, fromHex, toHex } from "../lib/themes.ts";

/**
 * La marque : l'icône de l'application, au trait près.
 *
 * Sans couleurs, c'est la marque elle-même — fond sable, touche encre — dont
 * la paire de fond est relevée sur l'icône livrée. Avec un thème, le fond des
 * touches devient le haut du dégradé et la couleur des lettres devient la
 * touche.
 *
 * `trail` reprend la décision de l'application : la traînée est dessinée sur
 * l'iPhone et retirée sur la montre, où le masque circulaire l'aurait
 * tronquée. Ici, elle est retirée en petit — à 32 px, deux touches fantômes ne
 * sont plus qu'une salissure.
 */
export function Mark({
  className,
  face,
  text,
  trail = false,
  label = "Uniclav",
}: {
  className?: string;
  /** Fond des touches du thème ; absent, la marque garde ses couleurs. */
  face?: string;
  /** Couleur des lettres du thème, qui devient celle de la touche. */
  text?: string;
  trail?: boolean;
  label?: string;
}) {
  const inkHex = `#${text ?? BRAND_GROUND.ink}`;
  const topRgb = fromHex(face ?? BRAND_GROUND.top);
  const topHex = toHex(topRgb);
  const bottomHex = face
    ? toHex(blended(topRgb, fromHex(text ?? BRAND_GROUND.ink), GROUND_BLEND))
    : `#${BRAND_GROUND.bottom}`;

  // Un identifiant par instance : deux marques de mêmes couleurs sur la même
  // page partageraient sinon leur id, ce qu'HTML interdit — et `url(#id)`
  // résoudrait vers la première d'entre elles.
  const gradientId = useId();
  const inkRgb = fromHex(text ?? BRAND_GROUND.ink);

  return (
    <svg
      className={className}
      viewBox={`0 0 ${VIEW_BOX} ${VIEW_BOX}`}
      role="img"
      aria-label={label}
      focusable="false"
    >
      <defs>
        <linearGradient id={gradientId} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor={topHex} />
          <stop offset="1" stopColor={bottomHex} />
        </linearGradient>
      </defs>

      <rect width={VIEW_BOX} height={VIEW_BOX} rx="220" fill={`url(#${gradientId})`} />

      {trail
        ? GHOSTS.map((ghost) => (
            <rect
              key={ghost.x}
              x={ghost.x}
              y={ghost.y}
              width={ghost.size}
              height={ghost.size}
              rx={ghost.radius}
              // Le fantôme se mélange depuis le fond qu'il recouvre. Le
              // dégradé étant court, le haut du fond en tient lieu.
              fill={toHex(blended(fromHex(bottomHex.slice(1)), inkRgb, ghost.blend))}
              transform={`rotate(${GHOST_ROTATION} ${ghost.x + ghost.size / 2} ${
                ghost.y + ghost.size / 2
              })`}
            />
          ))
        : null}

      <rect
        x={KEY.x}
        y={KEY.y}
        width={KEY.size}
        height={KEY.size}
        rx={KEY.radius}
        fill={inkHex}
      />
      <path
        d={LETTER}
        fill="none"
        stroke={topHex}
        strokeWidth={LETTER_STROKE}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}
