/** Aperçu schématique d'une disposition : on compare des largeurs de touches,
 *  pas des lettres. */
const SHAPES = {
  azerty: { rows: [10, 10, 9], label: "dix touches étroites par rangée" },
  grouped: { rows: [4, 4, 4], label: "quatre touches larges par rangée" },
  "grouped-large": { rows: [3, 3, 4], label: "trois touches très larges par rangée" },
} as const;

export function LayoutPreview({ variant }: { variant: keyof typeof SHAPES }) {
  const shape = SHAPES[variant];
  return (
    <div
      className={`layout-preview layout-preview--${variant}`}
      role="img"
      aria-label={`Disposition : ${shape.label}`}
    >
      {shape.rows.map((count, row) => (
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
