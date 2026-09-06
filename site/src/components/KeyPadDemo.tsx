import { useState } from "react";
import { LETTER_GROUPS, candidates, literalFor, resolve } from "../lib/groupedInput.ts";

/**
 * Démonstration de la frappe groupée. C'est le même algorithme que le
 * clavier, sur le même dictionnaire : on tape la touche qui porte la lettre,
 * sans viser la lettre.
 */
export function KeyPadDemo() {
  const [committed, setCommitted] = useState("");
  const [signature, setSignature] = useState("");

  // Le champ montre ce qui a été frappé — une correspondance de la même
  // longueur — pour qu'effacer se voie. Les mots plus longs restent proposés
  // dans la barre.
  const { exact } = resolve(signature);
  const pending = signature === "" ? "" : (exact[0] ?? literalFor(signature));
  const suggestions = signature === "" ? [] : candidates(signature);

  function pressGroup(index: number) {
    setSignature((current) => current + String(index));
  }

  function commit(word: string) {
    setCommitted((current) => (current === "" ? word : `${current} ${word}`));
    setSignature("");
  }

  function pressSpace() {
    if (pending === "") return;
    commit(pending);
  }

  /** Effacer retire d'abord une touche du mot en cours, comme sur le clavier :
   *  corriger une frappe ne doit pas coûter le mot entier. */
  function pressDelete() {
    if (signature !== "") {
      setSignature((current) => current.slice(0, -1));
      return;
    }
    setCommitted((current) => current.replace(/\s*\S+\s*$/, ""));
  }

  return (
    <div className="demo">
      <p className="visually-hidden" aria-live="polite">
        {pending === "" ? "Aucun mot en cours" : `Mot proposé : ${pending}`}
      </p>

      <div className="demo__screen">
        {committed === "" && pending === "" ? (
          <span className="demo__placeholder">
            Tapez les touches qui portent vos lettres…
          </span>
        ) : (
          <>
            {committed}
            {committed !== "" && pending !== "" ? " " : null}
            {pending !== "" ? <mark className="demo__pending">{pending}</mark> : null}
            <span className="demo__caret" aria-hidden="true">
              |
            </span>
          </>
        )}
      </div>

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

      <div className="demo__keys">
        {LETTER_GROUPS.map((group, index) => (
          <button
            key={group}
            type="button"
            className="key"
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
          aria-label="Espace, valider le mot"
          style={{ gridColumn: "span 2" }}
        >
          espace
        </button>
        <button
          type="button"
          className="key key--service"
          onClick={() => {
            setCommitted("");
            setSignature("");
          }}
          aria-label="Tout effacer"
        >
          ✕
        </button>
      </div>

      <p className="demo__hint">
        Essayez <strong>MNO · DEF · PQRS · ABC · GHI</strong> — cinq touches, et le
        mot « merci » apparaît. Les autres lectures possibles de la même frappe
        restent à portée dans la barre.
      </p>
    </div>
  );
}
