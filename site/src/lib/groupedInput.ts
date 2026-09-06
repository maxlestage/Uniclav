import { WORDS } from "./words.ts";

/**
 * Même algorithme que le clavier : huit groupes de lettres, un mot retrouvé
 * par sa signature, les candidats classés par fréquence.
 *
 * Le portage est volontairement littéral — si la démonstration du site et
 * l'application divergeaient, la démonstration mentirait.
 */
export const LETTER_GROUPS = [
  "abc",
  "def",
  "ghi",
  "jkl",
  "mno",
  "pqrs",
  "tuv",
  "wxyz",
] as const;

const INDEX_OF_LETTER = new Map<string, number>();
for (const [index, group] of LETTER_GROUPS.entries()) {
  for (const letter of group) INDEX_OF_LETTER.set(letter, index);
}

/** Minuscules sans diacritiques : « École » et « ecole » se rejoignent. */
export function normalize(word: string): string {
  return word.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();
}

/**
 * Un chiffre par lettre, désignant la touche qui la porte. Apostrophes et
 * traits d'union sont ignorés : taper les lettres de « aujourdhui » retrouve
 * « aujourd'hui », correctement orthographié.
 */
export function signatureOf(word: string): string | null {
  let out = "";
  for (const character of normalize(word)) {
    if (character === "'" || character === "’" || character === "-" || character === " ") {
      continue;
    }
    const index = INDEX_OF_LETTER.get(character);
    if (index === undefined) return null;
    out += String(index);
  }
  return out === "" ? null : out;
}

const INDEXED: readonly { word: string; signature: string }[] = WORDS.flatMap((word) => {
  const signature = signatureOf(word);
  return signature === null ? [] : [{ word, signature }];
});

/**
 * Mots correspondant à une suite de touches, séparés en deux : ceux qui font
 * exactement la longueur frappée, et les mots plus longs qui valent
 * complétion.
 *
 * La distinction n'est pas cosmétique. Si le champ affichait la meilleure
 * complétion, effacer une touche laisserait souvent le même mot à l'écran —
 * quatre touches de « merci » proposent encore « merci » — et l'effacement
 * paraîtrait sans effet. Le mot affiché suit donc la frappe ; les complétions
 * restent offertes dans la barre.
 */
export function resolve(signature: string): { exact: string[]; completions: string[] } {
  if (signature === "") return { exact: [], completions: [] };

  const exact: string[] = [];
  const completions: string[] = [];
  const seen = new Set<string>();

  for (const entry of INDEXED) {
    if (!entry.signature.startsWith(signature)) continue;
    const key = normalize(entry.word);
    if (seen.has(key)) continue;
    seen.add(key);
    (entry.signature.length === signature.length ? exact : completions).push(entry.word);
  }
  return { exact, completions };
}

/** Liste unique proposée à l'utilisateur : exactes d'abord, complétions ensuite. */
export function candidates(signature: string, limit = 3): string[] {
  const { exact, completions } = resolve(signature);
  return [...exact, ...completions].slice(0, limit);
}

/** Repli du clavier quand aucun mot ne correspond : la première lettre de
 *  chaque touche frappée. Le texte est faux, mais il réagit à la frappe. */
export function literalFor(signature: string): string {
  let out = "";
  for (const character of signature) {
    const group = LETTER_GROUPS[Number(character)];
    if (group) out += group[0];
  }
  return out;
}
