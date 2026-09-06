/** La marque : une touche portant un A, comme l'icône de l'application. */
export function Mark({ className }: { className?: string }) {
  return (
    <svg
      className={className}
      viewBox="0 0 100 100"
      role="img"
      aria-label="Uniclav"
      focusable="false"
    >
      <rect x="4" y="4" width="92" height="92" rx="24" fill="var(--ink)" />
      <path
        d="M31 72 L50 28 L69 72 M38.5 57 H61.5"
        fill="none"
        stroke="var(--sand)"
        strokeWidth="9.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}
