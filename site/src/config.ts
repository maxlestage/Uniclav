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

  /** Liens légaux. Les pages restent à écrire. */
  legalLinks: [
    { label: "Mentions légales", href: "/mentions-legales" },
    { label: "Politique de confidentialité", href: "/confidentialite" },
    { label: "Conditions générales d'utilisation", href: "/cgu" },
    { label: "Déclaration d'accessibilité", href: "/accessibilite" },
  ],

  productLinks: [
    { label: "Les deux dispositions", href: "#dispositions" },
    { label: "Essayer la frappe", href: "#demonstration" },
    { label: "Confidentialité", href: "#confidentialite" },
    { label: "Application montre", href: "#montre" },
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
