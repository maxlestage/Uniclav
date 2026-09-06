import { site } from "../config.ts";
import { LegalLayout } from "./LegalLayout.tsx";

export function Accessibilite() {
  return (
    <LegalLayout title="Déclaration d’accessibilité" updated={site.legalUpdatedAt}>
      <p className="legal__lede">
        Une application d’accessibilité qui ne serait pas accessible serait une
        contradiction. Voici où nous en sommes, sans embellir.
      </p>

      <h2>État de conformité</h2>
      <p>
        <strong>
          Ce site n’a pas fait l’objet d’un audit de conformité au Référentiel
          général d’amélioration de l’accessibilité (RGAA).
        </strong>{" "}
        Aucun taux de conformité ne peut donc être annoncé : le déclarer sans
        audit reviendrait à l’inventer. Un audit est nécessaire pour établir un
        état de conformité réel.
      </p>

      <h2>Ce qui a été vérifié</h2>
      <p>
        À défaut d’audit, les points suivants ont été contrôlés lors du
        développement, sur un navigateur et sans outil automatique de
        certification :
      </p>
      <ul>
        <li>Langue de la page déclarée et titre unique de premier niveau.</li>
        <li>
          Structure en sections titrées, repères de navigation et lien
          d’évitement vers le contenu.
        </li>
        <li>
          Contenu utilisable sans défilement horizontal à partir de 320 px de
          large.
        </li>
        <li>
          Éléments interactifs en boutons et liens natifs, tous porteurs d’un
          nom accessible, avec un indicateur de focus visible.
        </li>
        <li>
          Cibles tactiles d’au moins 48 px de haut, au-delà du minimum
          recommandé.
        </li>
        <li>Animations réduites lorsque le système le demande.</li>
        <li>Contraste du texte principal supérieur au rapport 7:1.</li>
      </ul>

      <h2>Ce qui reste à faire</h2>
      <ul>
        <li>Un audit RGAA complet par un tiers, et la publication de son résultat.</li>
        <li>Un test avec des lecteurs d’écran réels, VoiceOver en premier lieu.</li>
        <li>
          Un test auprès de personnes concernées : c’est le seul qui puisse
          valider les choix d’ergonomie de l’application elle-même.
        </li>
      </ul>

      <h2>L’accessibilité de l’application</h2>
      <p>
        L’application {site.name} vise l’accessibilité motrice : six modes de
        frappe, dont un à huit grosses touches et un sans dictionnaire, clavier
        regroupé du côté de la main valide, taille des touches réglable,
        libellés vocalisés pour VoiceOver. Ces choix n’ont pas encore été
        validés par un usage prolongé auprès des personnes concernées.
      </p>

      <h2>Le contraste du clavier</h2>
      <p>
        Les sept thèmes de couleurs fournis atteignent tous le niveau AAA de
        WCAG 2.1, soit un rapport de contraste supérieur à 7:1 entre le fond
        d’une touche et ses lettres. C’est un calcul, pas un audit : la formule
        de luminance relative est appliquée aux couleurs exactes du clavier, et
        le résultat est vérifiable sur la page d’accueil.
      </p>
      <p>
        Le réglage libre, lui, n’est pas contraint : rien n’empêche de choisir
        deux teintes trop proches. L’application calcule alors le rapport en
        direct et avertit sous 4,5:1, sans interdire le choix — laisser
        quelqu’un se fabriquer un clavier illisible sans le prévenir serait un
        défaut, le lui interdire serait de la condescendance.
      </p>

      <h2>Signaler un problème</h2>
      <p>
        Si vous rencontrez un obstacle, écrivez-nous : la description du blocage
        vaut mieux qu’un rapport d’audit.{" "}
        <a href="mailto:accessibilite@example.com">accessibilite@example.com</a>
      </p>

      <h2>Voie de recours</h2>
      <p>
        Si un signalement reste sans réponse satisfaisante, vous pouvez saisir le{" "}
        <a href="https://www.defenseurdesdroits.fr" rel="external">
          Défenseur des droits
        </a>
        , par son formulaire en ligne, auprès de son délégué dans votre
        département, ou par courrier sans affranchissement : Défenseur des
        droits, Libre réponse 71120, 75342 Paris CEDEX 07.
      </p>
    </LegalLayout>
  );
}
