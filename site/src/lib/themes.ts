/**
 * Portage littéral de Shared/KeyboardTheme.swift.
 *
 * Les rapports de contraste affichés sur le site ne sont pas recopiés à la
 * main : ils sont recalculés ici par la formule de luminance relative de
 * WCAG 2.1, la même que celle de l'application. Un chiffre saisi à la main
 * finirait par mentir le jour où une couleur change ; celui-ci ne peut pas.
 */

export type Rgb = { red: number; green: number; blue: number };

export function fromHex(hex: string): Rgb {
  const value = Number.parseInt(hex.replace("#", ""), 16);
  return {
    red: ((value >> 16) & 0xff) / 255,
    green: ((value >> 8) & 0xff) / 255,
    blue: (value & 0xff) / 255,
  };
}

export function toHex({ red, green, blue }: Rgb): string {
  const byte = (channel: number) =>
    Math.round(channel * 255)
      .toString(16)
      .padStart(2, "0");
  return `#${byte(red)}${byte(green)}${byte(blue)}`;
}

/** Luminance relative au sens de WCAG 2.1. */
export function relativeLuminance({ red, green, blue }: Rgb): number {
  const channel = (value: number) =>
    value <= 0.03928 ? value / 12.92 : ((value + 0.055) / 1.055) ** 2.4;
  return 0.2126 * channel(red) + 0.7152 * channel(green) + 0.0722 * channel(blue);
}

/** Rapport de contraste, de 1 (couleurs identiques) à 21 (noir sur blanc). */
export function contrastRatio(a: Rgb, b: Rgb): number {
  const [x, y] = [relativeLuminance(a), relativeLuminance(b)];
  return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05);
}

/** Mélange vers une autre couleur : c'est ainsi que l'application dérive les
 *  teintes secondaires sans demander un réglage de plus. */
export function blended(from: Rgb, toward: Rgb, amount: number): Rgb {
  return {
    red: from.red + (toward.red - from.red) * amount,
    green: from.green + (toward.green - from.green) * amount,
    blue: from.blue + (toward.blue - from.blue) * amount,
  };
}

/** Niveau WCAG atteint pour du texte de grande taille comme les lettres d'une
 *  touche. AAA à partir de 7:1, AA à partir de 4,5:1. */
export function wcagLevel(ratio: number): "AAA" | "AA" | "insuffisant" {
  if (ratio >= 7) return "AAA";
  if (ratio >= 4.5) return "AA";
  return "insuffisant";
}

/** Rapport écrit à la française : « 14,9:1 ». */
export function formatRatio(ratio: number): string {
  return `${ratio.toFixed(1).replace(".", ",")}:1`;
}

export type Theme = {
  id: string;
  label: string;
  /** Fond des touches. */
  face: string;
  /** Couleur des lettres. */
  text: string;
  /** Ce à quoi ce thème répond. */
  note: string;
};

/** Le thème « Automatique » : deux palettes, choisies par l'apparence de
 *  l'iPhone. Il n'a pas d'icône — une icône de rechange iOS n'en a qu'une. */
export const SYSTEM_THEME = {
  label: "Automatique",
  note: "Encre sur sable le jour, Nuit le soir. Le clavier suit l’apparence de l’iPhone, comme celui du système.",
  light: { face: "FBF8F2", text: "26221D" },
  dark: { face: "3A3A3E", text: "F2EBDE" },
} as const;

/** Les sept thèmes fournis, avec les valeurs exactes de l'application. */
export const THEMES: readonly Theme[] = [
  {
    id: "inkOnSand",
    label: "Encre sur sable",
    face: "FBF8F2",
    text: "26221D",
    note: "Le thème par défaut, repris de l’identité de l’application.",
  },
  {
    id: "night",
    label: "Nuit",
    face: "3A3A3E",
    text: "F2EBDE",
    note: "Pour écrire le soir sans éblouir, en gardant le niveau AAA.",
  },
  {
    id: "maxContrast",
    label: "Contraste maximal",
    face: "FFFFFF",
    text: "000000",
    note: "Le rapport le plus élevé possible : 21:1, la limite de l’échelle.",
  },
  {
    id: "yellowOnBlack",
    label: "Jaune sur noir",
    face: "141414",
    text: "FFD400",
    note: "Le couple retenu par les aides à la basse vision.",
  },
  {
    id: "blackOnYellow",
    label: "Noir sur jaune",
    face: "FFD400",
    text: "141414",
    note: "Le même couple inversé : certains yeux préfèrent le fond clair.",
  },
  {
    id: "deepBlue",
    label: "Bleu profond",
    face: "12284B",
    text: "F5F7FA",
    note: "Un fond sombre moins neutre, pour ceux que le gris fatigue.",
  },
  {
    id: "seaGreen",
    label: "Vert d’eau",
    face: "E8F1EC",
    text: "16352B",
    note: "Un fond clair moins blanc, plus doux sous une lumière crue.",
  },
];

/** Les thèmes qui n'ont d'autre raison d'être que le plaisir. Ils passent la
 *  même mesure que les autres : l'amusement ne dispense pas de lire. */
export const FANCIFUL_THEMES: readonly Theme[] = [
  {
    id: "neon",
    label: "Néon",
    face: "0B0B12",
    text: "39FF14",
    note: "Vert fluo sur presque noir.",
  },
  {
    id: "amberTerminal",
    label: "Terminal ambre",
    face: "0D1F0D",
    text: "FFB000",
    note: "L’ambre des écrans à phosphore.",
  },
  {
    id: "candy",
    label: "Bonbon",
    face: "FFD9E8",
    text: "4A0E2E",
    note: "Rose dragée, lettres prune.",
  },
  {
    id: "citrus",
    label: "Agrume",
    face: "FFB703",
    text: "3A1F04",
    note: "Un fond d’écorce d’orange.",
  },
  {
    id: "lavender",
    label: "Lavande",
    face: "EDE7FF",
    text: "2E1065",
    note: "Lilas pâle, lettres violettes.",
  },
  {
    id: "plum",
    label: "Prune",
    face: "2A0A3D",
    text: "F3D9FF",
    note: "L’inverse de Lavande : fond profond, lettres pâles.",
  },
];

/** Les quatre teintes effectivement posées sur le clavier, dérivées du seul
 *  couple fond / lettres — exactement comme KeyboardPalette. */
export function paletteOf(faceHex: string, textHex: string) {
  const face = fromHex(faceHex);
  const text = fromHex(textHex);
  return {
    face,
    text,
    specialFace: blended(face, text, 0.2),
    backdrop: blended(face, text, 0.1),
    ratio: contrastRatio(face, text),
  };
}
