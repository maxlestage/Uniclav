import { site } from "../config.ts";
import { LegalLayout } from "./LegalLayout.tsx";

export function Confidentialite() {
  return (
    <LegalLayout title="Politique de confidentialité" updated={site.legalUpdatedAt}>
      <p className="legal__lede">
        Un clavier voit tout ce qu’on écrit. Celui-ci est construit pour ne rien
        pouvoir en faire.
      </p>

      <h2>Le clavier n’a aucun accès au réseau</h2>
      <p>
        L’extension clavier ne demande pas l’<em>Accès complet</em> d’iOS. Sans
        cette autorisation, le système lui interdit toute connexion : elle ne
        peut techniquement émettre aucune donnée, quelle qu’elle soit. Ce n’est
        pas une promesse d’usage, c’est une limite imposée par iOS et vérifiable
        dans les réglages de votre appareil.
      </p>

      <h2>Ce qui reste sur l’appareil</h2>
      <ul>
        <li>
          Les mots que vous tapez et leur fréquence d’usage, servant à améliorer
          les suggestions.
        </li>
        <li>Vos réglages : disposition, côté de la main, taille des touches.</li>
        <li>Le dictionnaire français.</li>
      </ul>
      <p>
        Ces éléments sont conservés dans le conteneur partagé de l’application,
        sur votre appareil. Ils ne sont transmis à personne, ne sont pas
        sauvegardés sur un serveur, et sont supprimés avec l’application.
      </p>

      <h2>Ce qui peut quitter l’appareil</h2>
      <p>
        Seule l’application — jamais le clavier — se connecte à Internet, pour
        enrichir le dictionnaire auprès du{" "}
        <a href="https://fr.wiktionary.org" rel="external">
          Wiktionnaire francophone
        </a>
        , une fois par jour au plus.
      </p>

      <h3>Vocabulaire de base</h3>
      <p>
        L’application télécharge une liste de mots courants publiée par le
        Wiktionnaire. Cette requête ne contient rien qui vous concerne.
      </p>

      <h3>Mots inconnus — désactivé par défaut</h3>
      <p>
        L’application peut aussi vérifier auprès du Wiktionnaire les mots que le
        clavier n’a pas reconnus, afin de les ajouter au dictionnaire avec leur
        orthographe exacte. <strong>Cette option est désactivée par défaut</strong>{" "}
        et doit être activée explicitement dans les réglages de l’application.
      </p>
      <p>
        La raison de ce choix mérite d’être dite : un mot absent d’un
        dictionnaire français est le plus souvent un nom propre — un prénom, une
        commune, le nom d’un praticien. Ce sont précisément les mots qu’on
        n’envoie pas à un tiers sans l’avoir demandé. Si vous activez l’option,
        ces mots sont transmis à la Wikimedia Foundation, qui reçoit également
        l’adresse IP de votre connexion, selon{" "}
        <a href="https://foundation.wikimedia.org/wiki/Policy:Privacy_policy/fr" rel="external">
          sa propre politique de confidentialité
        </a>
        . Aucun identifiant de compte, d’appareil ou de session n’est joint à ces
        requêtes par {site.name}.
      </p>
      <p>
        Désactivée, l’option n’empêche pas le clavier d’apprendre : vos mots
        continuent de remonter dans les suggestions, mais uniquement en local.
      </p>

      <h2>Ce que nous ne faisons pas</h2>
      <ul>
        <li>Aucune mesure d’audience, aucun traceur, aucun cookie publicitaire.</li>
        <li>Aucune revente ni partage de données à des fins commerciales.</li>
        <li>Aucun compte utilisateur, donc aucun profil.</li>
        <li>Aucune collecte de frappe, de contenu de message ou de contact.</li>
      </ul>

      <h2>Ce site</h2>
      <p>
        Ce site est statique et ne dépose aucun cookie. Votre hébergeur peut
        conserver des journaux de connexion techniques, à des fins de sécurité et
        pour la durée qu’impose la réglementation.
      </p>

      <h2>Vos droits</h2>
      <p>
        Le règlement (UE) 2016/679 vous ouvre un droit d’accès, de rectification,
        d’effacement, de limitation, d’opposition et de portabilité. Les données
        de {site.name} résidant sur votre appareil, vous les exercez
        directement : désinstaller l’application les efface toutes. Pour toute
        autre demande, écrivez à{" "}
        <a href={`mailto:${site.publisher.email}`}>{site.publisher.email}</a>.
      </p>
      <p>
        Vous pouvez également introduire une réclamation auprès de la{" "}
        <a href="https://www.cnil.fr" rel="external">
          Commission nationale de l’informatique et des libertés
        </a>
        .
      </p>
    </LegalLayout>
  );
}
