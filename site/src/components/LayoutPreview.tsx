/** Aperçu schématique d'une disposition : on compare des largeurs de touches,
 *  pas des lettres. */
export function LayoutPreview({ variant }: { variant: "azerty" | "grouped" }) {
  const rows = variant === "azerty" ? [10, 10, 9] : [4, 4, 4];
  return (
    <div
      className={`layout-preview layout-preview--${variant}`}
      role="img"
      aria-label={
        variant === "azerty"
          ? "Disposition AZERTY : dix touches étroites par rangée"
          : "Disposition à grosses touches : quatre touches larges par rangée"
      }
    >
      {rows.map((count, row) => (
        <div
          key={row}
          className="layout-preview__row"
          style={{ gridTemplateColumns: `repeat(${count}, 1fr)` }}
        >
          {Array.from({ length: count }, (_, key) => (
            <div key={key} className="layout-preview__key" />
          ))}
        </div>
      ))}
    </div>
  );
}
