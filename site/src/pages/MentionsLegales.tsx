import { site } from "../config.ts";
import { LegalLayout } from "./LegalLayout.tsx";

export function MentionsLegales() {
  return (
    <LegalLayout title="Mentions légales" updated={site.legalUpdatedAt}>
      <p>
        Informations requises par l’article 6-III de la loi n° 2004-575 du
        21 juin 2004 pour la confiance dans l’économie numérique.
      </p>

      <h2>Éditeur du site et de l’application</h2>
      <dl>
        <dt>Raison sociale</dt>
        <dd>{site.publisher.legalName}</dd>
        <dt>Forme juridique et capital</dt>
        <dd>{site.publisher.form}</dd>
        <dt>Siège social</dt>
        <dd>{site.publisher.address}</dd>
        <dt>Immatriculation</dt>
        <dd>{site.publisher.registration}</dd>
        <dt>Numéro de TVA intracommunautaire</dt>
        <dd>{site.publisher.vat}</dd>
        <dt>Contact</dt>
        <dd>
          <a href={`mailto:${site.publisher.email}`}>{site.publisher.email}</a>
        </dd>
      </dl>

      <h2>Direction de la publication</h2>
      <p>{site.publisher.publicationDirector}</p>

      <h2>Hébergement</h2>
      <dl>
        <dt>Hébergeur</dt>
        <dd>{site.host.name}</dd>
        <dt>Adresse</dt>
        <dd>{site.host.address}</dd>
        <dt>Téléphone</dt>
        <dd>{site.host.phone}</dd>
      </dl>

      <h2>Propriété intellectuelle</h2>
      <p>
        {site.name}, son logiciel, son interface, ses textes et ses éléments
        graphiques sont protégés par le droit de la propriété intellectuelle et
        demeurent la propriété exclusive de l’éditeur. {site.name} n’est pas un
        logiciel libre : aucune licence de reproduction, de modification, de
        distribution ou de décompilation n’est concédée, hors les exceptions
        prévues par la loi. La consultation éventuelle du code source ne vaut
        pas licence.
      </p>
      <p>
        Les données lexicales issues du Wiktionnaire francophone sont publiées
        par leurs auteurs sous licence Creative Commons BY-SA 4.0 et le restent ;
        leur intégration dans {site.name} ne modifie pas leur régime.
      </p>

      <h2>Signaler un contenu</h2>
      <p>
        Toute demande relative au contenu de ce site peut être adressée à{" "}
        <a href={`mailto:${site.publisher.email}`}>{site.publisher.email}</a>.
      </p>
    </LegalLayout>
  );
}
