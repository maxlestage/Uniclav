import { useEffect, useRef, useState } from "react";
import { LETTER_GROUPS, candidates, literalFor, resolve } from "../lib/groupedInput.ts";

type Mode = "dictionnaire" | "appuis";

/**
 * Démonstration des deux façons de se servir des grosses touches. C'est le
 * même algorithme que le clavier, sur le même dictionnaire : on tape la
 * touche qui porte la lettre, sans viser la lettre.
 *
 * Le mode « appuis répétés » rejoue la même mécanique que l'application : un
 * nouvel appui sur la même touche remplace la lettre tant que le délai n'est
 * pas écoulé, et en écrit une de plus une fois qu'il l'est.
 */
export function KeyPadDemo() {
  const [mode, setMode] = useState<Mode>("dictionnaire");

  // Mode dictionnaire : le texte validé, et la suite de touches en cours.
  const [committed, setCommitted] = useState("");
  const [signature, setSignature] = useState("");

  // Mode appuis répétés : le texte écrit, et la lettre encore modifiable.
  const [typed, setTyped] = useState("");
  const [active, setActive] = useState<{ group: number; index: number } | null>(null);
  const [delay, setDelay] = useState(1.5);
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);

  // Le champ montre ce qui a été frappé — une correspondance de la même
  // longueur — pour qu'effacer se voie. Les mots plus longs restent proposés
  // dans la barre.
  const { exact } = resolve(signature);
  const pending = signature === "" ? "" : (exact[0] ?? literalFor(signature));
  const suggestions = mode === "dictionnaire" && signature !== "" ? candidates(signature) : [];

  function stopTimer() {
    if (timer.current !== null) clearTimeout(timer.current);
    timer.current = null;
  }

  /** Fige la lettre en cours : elle ne peut plus être remplacée. */
  function freeze() {
    stopTimer();
    setActive(null);
  }

  useEffect(() => stopTimer, []);

  function pressGroup(index: number) {
    if (mode === "dictionnaire") {
      setSignature((current) => current + String(index));
      return;
    }

    const letters = LETTER_GROUPS[index];
    if (letters === undefined) return;

    if (active !== null && active.group === index) {
      // Même touche, délai non écoulé : on remplace la lettre.
      const next = (active.index + 1) % letters.length;
      setTyped((current) => current.slice(0, -1) + letters[next]);
      setActive({ group: index, index: next });
    } else {
      setTyped((current) => current + letters[0]);
      setActive({ group: index, index: 0 });
    }

    stopTimer();
    timer.current = setTimeout(() => setActive(null), delay * 1000);
  }

  function commit(word: string) {
    setCommitted((current) => (current === "" ? word : `${current} ${word}`));
    setSignature("");
  }

  function pressSpace() {
    if (mode === "appuis") {
      freeze();
      setTyped((current) => (current === "" ? current : `${current} `));
      return;
    }
    if (pending === "") return;
    commit(pending);
  }

  /** Effacer retire d'abord une touche du mot en cours, comme sur le clavier :
   *  corriger une frappe ne doit pas coûter le mot entier. */
  function pressDelete() {
    if (mode === "appuis") {
      freeze();
      setTyped((current) => current.slice(0, -1));
      return;
    }
    if (signature !== "") {
      setSignature((current) => current.slice(0, -1));
      return;
    }
    setCommitted((current) => current.replace(/\s*\S+\s*$/, ""));
  }

  function clearAll() {
    freeze();
    setCommitted("");
    setSignature("");
    setTyped("");
  }

  function switchMode(next: Mode) {
    clearAll();
    setMode(next);
  }

  const screenText = mode === "appuis" ? typed : committed;
  const screenPending = mode === "appuis" ? "" : pending;
  const isEmpty = screenText === "" && screenPending === "";

  return (
    <div className="demo">
      <div className="demo__modes" role="group" aria-label="Mode de frappe">
        {(
          [
            ["dictionnaire", "Dictionnaire"],
            ["appuis", "Appuis répétés"],
          ] as const
        ).map(([value, label]) => (
          <button
            key={value}
            type="button"
            className="demo__mode"
            aria-pressed={mode === value}
            onClick={() => switchMode(value)}
          >
            {label}
          </button>
        ))}
      </div>

      <p className="visually-hidden" aria-live="polite">
        {mode === "appuis"
          ? typed === ""
            ? "Rien d’écrit"
            : `Texte : ${typed}`
          : pending === ""
            ? "Aucun mot en cours"
            : `Mot proposé : ${pending}`}
      </p>

      <div className="demo__screen">
        {isEmpty ? (
          <span className="demo__placeholder">
            {mode === "appuis"
              ? "Appuyez plusieurs fois sur une touche…"
              : "Tapez les touches qui portent vos lettres…"}
          </span>
        ) : (
          <>
            {mode === "appuis" && active !== null ? (
              <>
                {screenText.slice(0, -1)}
                <mark className="demo__pending">{screenText.slice(-1)}</mark>
              </>
            ) : (
              screenText
            )}
            {screenText !== "" && screenPending !== "" ? " " : null}
            {screenPending !== "" ? (
              <mark className="demo__pending">{screenPending}</mark>
            ) : null}
            <span className="demo__caret" aria-hidden="true">
              |
            </span>
          </>
        )}
      </div>

      {mode === "dictionnaire" ? (
        <div className="demo__suggestions">
          {[0, 1, 2].map((slot) => {
            const word = suggestions[slot];
            return (
              <button
                key={slot}
                type="button"
                className="suggestion"
                data-empty={word === undefined}
                disabled={word === undefined}
                aria-hidden={word === undefined}
                onClick={() => word !== undefined && commit(word)}
              >
                {word ?? ""}
              </button>
            );
          })}
        </div>
      ) : (
        <p className="demo__delay">
          <label htmlFor="delai">
            Délai de validation : <strong>{delay.toFixed(1).replace(".", ",")} s</strong>
          </label>
          <input
            id="delai"
            type="range"
            min={0.6}
            max={3}
            step={0.1}
            value={delay}
            onChange={(event) => setDelay(Number(event.target.value))}
          />
        </p>
      )}

      <div className="demo__keys">
        {LETTER_GROUPS.map((group, index) => (
          <button
            key={group}
            type="button"
            className="key"
            data-active={mode === "appuis" && active?.group === index}
            onClick={() => pressGroup(index)}
            aria-label={`Lettres ${group.toUpperCase()}`}
          >
            {group.toUpperCase()}
          </button>
        ))}
        <button
          type="button"
          className="key key--service"
          onClick={pressDelete}
          aria-label="Effacer"
        >
          ⌫
        </button>
        <button
          type="button"
          className="key key--service"
          onClick={pressSpace}
          aria-label={mode === "appuis" ? "Espace" : "Espace, valider le mot"}
          style={{ gridColumn: "span 2" }}
        >
          espace
        </button>
        <button
          type="button"
          className="key key--service"
          onClick={clearAll}
          aria-label="Tout effacer"
        >
          ✕
        </button>
      </div>

      <p className="demo__hint">
        {mode === "appuis" ? (
          <>
            Essayez <strong>PQRS PQRS PQRS PQRS</strong> — quatre appuis sur la
            même touche donnent le « s ». Attendez le délai avant d’y revenir, et
            l’appui suivant écrit une lettre de plus au lieu de changer la
            précédente : c’est ainsi qu’on tape deux lettres du même groupe à la
            suite.
          </>
        ) : (
          <>
            Essayez <strong>MNO · DEF · PQRS · ABC · GHI</strong> — cinq touches,
            et le mot « merci » apparaît. Les autres lectures possibles de la même
            frappe restent à portée dans la barre.
          </>
        )}
      </p>
    </div>
  );
}
