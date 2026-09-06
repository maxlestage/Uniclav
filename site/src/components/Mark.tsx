import { useId } from "react";
import {
  BACKDROP_BLEND,
  GHOSTS,
  GHOST_ROTATION,
  KEY,
  LETTER,
  LETTER_STROKE,
  VIEW_BOX,
} from "../lib/icon.ts";
import { blended, fromHex, toHex } from "../lib/themes.ts";

/**
 * La marque : l'icône de l'application, au trait près.
 *
 * `trail` reprend la décision de l'application elle-même : la traînée est
 * dessinée sur l'iPhone, et retirée sur la montre où le masque circulaire
 * l'aurait tronquée. Ici, elle est retirée en petit — à 32 px, deux touches
 * fantômes ne sont plus qu'une salissure.
 */
export function Mark({
  className,
  face = "FBF8F2",
  text = "26221D",
  trail = false,
  label = "Uniclav",
}: {
  className?: string;
  face?: string;
  text?: string;
  trail?: boolean;
  label?: string;
}) {
  const faceRgb = fromHex(face);
  const textRgb = fromHex(text);
  const faceHex = toHex(faceRgb);
  const textHex = toHex(textRgb);
  const bottom = toHex(blended(faceRgb, textRgb, BACKDROP_BLEND));
  // Un identifiant par instance : deux marques de mêmes couleurs sur la même
  // page partageraient sinon leur id, ce qu'HTML interdit — et `url(#id)`
  // résoudrait vers la première d'entre elles.
  const gradientId = useId();

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
          <stop offset="0" stopColor={faceHex} />
          <stop offset="1" stopColor={bottom} />
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
              fill={toHex(blended(faceRgb, textRgb, ghost.blend))}
              transform={`rotate(${GHOST_ROTATION} ${ghost.x + ghost.size / 2} ${
                ghost.y + ghost.size / 2
              })`}
            />
          ))
        : null}

      <rect
        x={KEY.x}
        y={KEY.y}
        width={KEY.width}
        height={KEY.height}
        rx={KEY.radius}
        fill={textHex}
      />
      <path
        d={LETTER}
        fill="none"
        stroke={faceHex}
        strokeWidth={LETTER_STROKE}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}
