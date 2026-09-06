import { site } from "../config.ts";
import { LegalLayout } from "./LegalLayout.tsx";

export function Cgu() {
  return (
    <LegalLayout
      title="Conditions générales d’utilisation"
      updated={site.legalUpdatedAt}
    >
      <h2>Objet</h2>
      <p>
        Les présentes conditions régissent l’utilisation de l’application {site.name},
        de son extension clavier, de son application pour montre et du présent
        site. L’installation de l’application vaut acceptation.
      </p>

      <h2>Licence d’utilisation</h2>
      <p>
        L’éditeur concède un droit d’usage personnel, non exclusif, non cessible
        et révocable, sur un appareil dont vous avez la disposition. {site.name}{" "}
        n’est pas un logiciel libre : la reproduction, la modification, la
        distribution, la location et la décompilation sont interdites, hors les
        exceptions impératives du code de la propriété intellectuelle.
      </p>

      <h2 className="legal__warning-title">
        {site.name} n’est pas un dispositif médical
      </h2>
      <p>
        {site.name} est une aide à la saisie et à la communication. Il ne
        constitue pas un dispositif médical au sens du règlement (UE) 2017/745,
        n’a fait l’objet d’aucun marquage CE à ce titre, et ne remplace ni un
        avis médical, ni une rééducation, ni l’accompagnement d’un professionnel
        de santé.
      </p>
      <p>
        <strong>
          En particulier, les phrases classées « Urgent » dans l’application pour
          montre se contentent d’afficher et d’énoncer un texte. Elles n’alertent
          personne, ne transmettent aucun message et n’appellent aucun service de
          secours.
        </strong>{" "}
        En cas d’urgence, composez le 15, le 112, ou le 114 par message si vous ne
        pouvez pas parler.
      </p>

      <h2>Disponibilité et évolutions</h2>
      <p>
        L’éditeur s’efforce d’assurer le bon fonctionnement du service sans y être
        tenu à une obligation de résultat. Les fonctionnalités peuvent évoluer,
        être suspendues ou retirées, notamment pour des raisons techniques ou
        réglementaires.
      </p>
      <p>
        L’enrichissement du dictionnaire dépend d’un service tiers, le
        Wiktionnaire francophone, dont l’éditeur ne maîtrise ni la disponibilité
        ni le contenu.
      </p>

      <h2>Garanties et responsabilité</h2>
      <p>
        Le service est fourni en l’état. L’éditeur ne garantit pas que les
        suggestions de mots soient exemptes d’erreur : une désambiguïsation
        propose le mot le plus probable, pas le mot certain. Il vous appartient de
        relire ce que vous écrivez avant de l’envoyer.
      </p>
      <p>
        La responsabilité de l’éditeur ne saurait être engagée pour les dommages
        indirects, ni pour les conséquences d’un usage non conforme aux présentes
        conditions. Aucune stipulation ne limite les droits que la loi reconnaît
        aux consommateurs.
      </p>

      <h2>Modification des conditions</h2>
      <p>
        Les présentes conditions peuvent être modifiées. La version applicable est
        celle publiée sur ce site à la date de votre utilisation.
      </p>

      <h2>Droit applicable</h2>
      <p>
        Les présentes conditions sont soumises au droit français. À défaut de
        résolution amiable, le litige relève des juridictions françaises
        compétentes. Vous pouvez recourir gratuitement à un médiateur de la
        consommation avant toute action judiciaire.
      </p>
    </LegalLayout>
  );
}
