import { THEMES, formatRatio, paletteOf, toHex, wcagLevel } from "../lib/themes.ts";

/**
 * Les sept thèmes, rendus avec leurs vraies couleurs et leur rapport de
 * contraste réellement calculé.
 *
 * Montrer un thème par un aplat de couleur serait insuffisant : ce qui compte
 * est le couple fond / lettres, et la façon dont les teintes secondaires en
 * sont dérivées. Chaque vignette rejoue donc les quatre teintes que
 * l'application pose sur le clavier.
 */
function ThemeSwatch({ face, text, label }: { face: string; text: string; label: string }) {
  const palette = paletteOf(face, text);
  return (
    <div
      className="swatch"
      style={{ background: toHex(palette.backdrop) }}
      role="img"
      aria-label={`Aperçu du thème ${label}`}
    >
      {["ABC", "DEF", "GHI"].map((letters) => (
        <span
          key={letters}
          className="swatch__key"
          style={{ background: toHex(palette.face), color: toHex(palette.text) }}
        >
          {letters}
        </span>
      ))}
      <span
        className="swatch__key swatch__key--service"
        style={{ background: toHex(palette.specialFace), color: toHex(palette.text) }}
      >
        ⌫
      </span>
    </div>
  );
}

export function ThemeShowcase() {
  return (
    <ul className="themes">
      {THEMES.map((theme) => {
        const ratio = paletteOf(theme.face, theme.text).ratio;
        return (
          <li key={theme.id} className="theme">
            <ThemeSwatch face={theme.face} text={theme.text} label={theme.label} />
            <div className="theme__body">
              <h3 className="theme__name">{theme.label}</h3>
              <p className="theme__note">{theme.note}</p>
              <p className="theme__ratio">
                <strong>{formatRatio(ratio)}</strong>{" "}
                <span className="badge">{wcagLevel(ratio)}</span>
              </p>
            </div>
          </li>
        );
      })}
    </ul>
  );
}
