/**
 * Identité et liens du site.
 *
 * Les valeurs marquées « À COMPLÉTER » sont des mentions légales obligatoires
 * en France (article 6-III de la LCEN pour l'éditeur et l'hébergeur, RGPD pour
 * le délégué à la protection des données). Elles ne sont pas inventées ici :
 * il faut les renseigner avant toute mise en ligne.
 */
export const site = {
  name: "Uniclav",
  tagline: "Le clavier iPhone qui se tape d'une seule main.",
  description:
    "Conçu pour les personnes hémiplégiques : touches regroupées du côté de la main valide, grosses touches désambiguïsées par le dictionnaire français, et rien qui sorte de l'appareil.",

  /** Éditeur du site et de l'application. */
  publisher: {
    legalName: "À COMPLÉTER — raison sociale de l'éditeur",
    form: "À COMPLÉTER — forme juridique et capital",
    address: "À COMPLÉTER — adresse du siège social",
    registration: "À COMPLÉTER — RCS / SIRET",
    vat: "À COMPLÉTER — numéro de TVA intracommunautaire",
    publicationDirector: "À COMPLÉTER — directeur ou directrice de la publication",
    email: "contact@example.com",
  },

  /** Hébergeur du site, mention obligatoire. */
  host: {
    name: "À COMPLÉTER — nom de l'hébergeur",
    address: "À COMPLÉTER — adresse de l'hébergeur",
    phone: "À COMPLÉTER — téléphone de l'hébergeur",
  },

  /** Date affichée en tête de chaque page légale. */
  legalUpdatedAt: "6 septembre 2026",

  /**
   * Pages légales. Ce sont des fichiers statiques distincts : l'extension
   * .html garantit qu'ils s'ouvrent sur n'importe quel hébergeur, sans
   * réécriture d'URL ni repli d'application monopage.
   */
  legalLinks: [
    { label: "Mentions légales", href: "./mentions-legales.html" },
    { label: "Politique de confidentialité", href: "./confidentialite.html" },
    { label: "Conditions générales d'utilisation", href: "./cgu.html" },
    { label: "Déclaration d'accessibilité", href: "./accessibilite.html" },
  ],

  /**
   * Tous les liens internes sont relatifs. Un site de projet GitHub Pages est
   * servi sous un sous-répertoire — /Uniclav/ — où un chemin absolu pointerait
   * à la racine du domaine et casserait.
   */
  productLinks: [
    { label: "Les deux dispositions", href: "./#dispositions" },
    { label: "Essayer la frappe", href: "./#demonstration" },
    { label: "Confidentialité", href: "./#confidentialite" },
    { label: "Application montre", href: "./#montre" },
  ],

  supportLinks: [
    { label: "Nous écrire", href: "mailto:contact@example.com" },
    { label: "Assistance", href: "mailto:support@example.com" },
    { label: "Signaler un problème d'accessibilité", href: "mailto:accessibilite@example.com" },
  ],

  /** L'application n'est pas encore publiée : pas de faux lien App Store. */
  appStoreUrl: null as string | null,

  copyrightHolder: "À COMPLÉTER — titulaire des droits",
  firstPublicationYear: 2026,
} as const;
