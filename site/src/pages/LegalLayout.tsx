import type { ReactNode } from "react";
import { site } from "../config.ts";
import { Mark } from "../components/Mark.tsx";
import { Footer } from "../components/Footer.tsx";

export function LegalLayout({
  title,
  updated,
  children,
}: {
  title: string;
  updated: string;
  children: ReactNode;
}) {
  return (
    <>
      <a className="skip-link" href="#contenu">
        Aller au contenu
      </a>
      <header className="shell legal-header">
        <a className="legal-header__home" href="/">
          <Mark className="legal-header__mark" />
          <span>{site.name}</span>
        </a>
      </header>
      <main id="contenu" className="shell legal">
        <h1>{title}</h1>
        <p className="legal__updated">Dernière mise à jour : {updated}</p>
        {children}
      </main>
      <Footer />
    </>
  );
}
