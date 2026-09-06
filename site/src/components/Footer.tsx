import { site } from "../config.ts";
import { Mark } from "./Mark.tsx";

const currentYear = new Date().getFullYear();
const copyrightRange =
  currentYear > site.firstPublicationYear
    ? `${site.firstPublicationYear}–${currentYear}`
    : String(site.firstPublicationYear);

export function Footer() {
  return (
    <footer className="footer">
      <div className="shell">
        <div className="footer__top">
          <div className="footer__brand">
            <Mark className="footer__mark" />
            <p>
              <strong>{site.name}</strong>
            </p>
            <p className="footer__tagline">{site.tagline}</p>
          </div>

          <nav className="footer__columns" aria-label="Pied de page">
            <div>
              <h2 className="footer__heading">Produit</h2>
              <ul className="footer__list">
                {site.productLinks.map((link) => (
                  <li key={link.href}>
                    <a href={link.href}>{link.label}</a>
                  </li>
                ))}
              </ul>
            </div>
            <div>
              <h2 className="footer__heading">Assistance</h2>
              <ul className="footer__list">
                {site.supportLinks.map((link) => (
                  <li key={link.href}>
                    <a href={link.href}>{link.label}</a>
                  </li>
                ))}
              </ul>
            </div>
            <div>
              <h2 className="footer__heading">Informations légales</h2>
              <ul className="footer__list">
                {site.legalLinks.map((link) => (
                  <li key={link.href}>
                    <a href={link.href}>{link.label}</a>
                  </li>
                ))}
              </ul>
            </div>
          </nav>
        </div>

        {/* Mentions imposées par l'article 6-III de la LCEN : identité de
            l'éditeur, du directeur de publication et de l'hébergeur. */}
        <div className="footer__legal">
          <dl>
            <div>
              <dt>Éditeur</dt>
              <dd>
                {site.publisher.legalName}
                <br />
                {site.publisher.form}
                <br />
                {site.publisher.address}
                <br />
                {site.publisher.registration} — {site.publisher.vat}
              </dd>
            </div>
            <div>
              <dt>Directeur de la publication</dt>
              <dd>{site.publisher.publicationDirector}</dd>
              <dt>Hébergeur</dt>
              <dd>
                {site.host.name}
                <br />
                {site.host.address}
                <br />
                {site.host.phone}
              </dd>
            </div>
          </dl>
          <p>
            {site.name} et son logiciel sont des œuvres protégées. Le code source
            n'est pas public et aucune licence d'utilisation, de reproduction ou
            de modification n'est concédée au-delà de l'usage prévu par les
            conditions générales.
          </p>
        </div>

        <div className="footer__bottom">
          <p>
            © {copyrightRange} {site.copyrightHolder}. Tous droits réservés.
          </p>
          <p>
            <a href="/accessibilite">Accessibilité : déclaration de conformité</a>
          </p>
        </div>
      </div>
    </footer>
  );
}
