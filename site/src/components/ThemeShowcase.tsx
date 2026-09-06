import {
  SYSTEM_THEME,
  THEMES,
  formatRatio,
  paletteOf,
  toHex,
  wcagLevel,
} from "../lib/themes.ts";
import type { Theme } from "../lib/themes.ts";
import { Mark } from "./Mark.tsx";

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

/** Le thème automatique : deux vignettes, parce qu'un seul aperçu mentirait. */
export function SystemTheme() {
  const clair = paletteOf(SYSTEM_THEME.light.face, SYSTEM_THEME.light.text).ratio;
  const sombre = paletteOf(SYSTEM_THEME.dark.face, SYSTEM_THEME.dark.text).ratio;
  return (
    <ul className="themes">
      <li className="theme theme--system">
        <div className="theme__pair">
          <ThemeSwatch
            face={SYSTEM_THEME.light.face}
            text={SYSTEM_THEME.light.text}
            label="Automatique, le jour"
          />
          <ThemeSwatch
            face={SYSTEM_THEME.dark.face}
            text={SYSTEM_THEME.dark.text}
            label="Automatique, le soir"
          />
        </div>
        <div className="theme__body">
          <h3 className="theme__name">{SYSTEM_THEME.label}</h3>
          <p className="theme__note">{SYSTEM_THEME.note}</p>
          <p className="theme__ratio">
            <strong>{formatRatio(clair)}</strong> le jour,{" "}
            <strong>{formatRatio(sombre)}</strong> le soir{" "}
            <span className="badge">{wcagLevel(Math.min(clair, sombre))}</span>
          </p>
        </div>
      </li>
    </ul>
  );
}

export function ThemeShowcase({ themes = THEMES }: { themes?: readonly Theme[] }) {
  return (
    <ul className="themes">
      {themes.map((theme) => {
        const ratio = paletteOf(theme.face, theme.text).ratio;
        return (
          <li key={theme.id} className="theme">
            <ThemeSwatch face={theme.face} text={theme.text} label={theme.label} />
            <div className="theme__body">
              <div className="theme__head">
                <Mark
                  className="theme__icon"
                  face={theme.face}
                  text={theme.text}
                  trail
                  label={`Icône de l’application, thème ${theme.label}`}
                />
                <h3 className="theme__name">{theme.label}</h3>
              </div>
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
