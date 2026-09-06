import { site } from "./config.ts";
import { Mark } from "./components/Mark.tsx";
import { KeyPadDemo } from "./components/KeyPadDemo.tsx";
import { LayoutPreview } from "./components/LayoutPreview.tsx";
import { Footer } from "./components/Footer.tsx";

export function App() {
  return (
    <>
      <a className="skip-link" href="#contenu">
        Aller au contenu
      </a>

      <header className="shell hero">
        <Mark className="hero__mark" />
        <h1>{site.tagline}</h1>
        <p className="lede">{site.description}</p>

        <div className="hero__actions">
          <a className="button" href="#demonstration">
            Essayer la frappe
          </a>
          <a className="button button--secondary" href="#dispositions">
            Voir les deux dispositions
          </a>
        </div>

        <p className="hero__note">
          {site.appStoreUrl === null
            ? "L’application n’est pas encore publiée sur l’App Store. Écrivez-nous pour participer aux essais."
            : "Disponible sur l’App Store."}
        </p>
      </header>

      <main id="contenu">
        <section className="shell section" aria-labelledby="probleme">
          <p className="eyebrow">Le problème</p>
          <h2 id="probleme">Après un AVC, on tape d’un seul doigt.</h2>
          <p className="prose">
            Un clavier d’iPhone suppose deux pouces, une visée précise et un
            poignet mobile. L’hémiplégie retire les trois. Réduire la taille du
            clavier ne suffit pas : ce qui coûte, c’est le nombre de touches à
            atteindre, et le prix d’une erreur — corriger, à une main, coûte plus
            cher qu’écrire.
          </p>
          <p className="prose">
            Uniclav s’attaque aux deux : moins de touches, beaucoup plus larges,
            et un dictionnaire qui devine le mot.
          </p>
        </section>

        <section className="shell section" aria-labelledby="dispositions" id="dispositions">
          <p className="eyebrow">Cinq modes</p>
          <h2 id="dispositions-titre">Selon ce que votre main permet.</h2>
          <p className="prose">
            Aucun mode n’est meilleur qu’un autre. Les chiffres ci-dessous sont
            mesurés sur le dictionnaire de l’application, pas estimés.
          </p>

          <h3 className="subhead">Une lettre par touche</h3>
          <div className="cards">
            <article className="card">
              <h3>AZERTY</h3>
              <p>
                La disposition que vous connaissez déjà. Rien à apprendre, mais
                dix touches étroites par rangée.
              </p>
              <LayoutPreview variant="azerty" />
            </article>
            <article className="card">
              <h3>Alphabétique</h3>
              <p>
                Les lettres de A à Z. Le déplacement du doigt est{" "}
                <strong>identique</strong> à celui de l’AZERTY — ce qui change,
                c’est qu’on trouve une lettre du regard, sans connaître la
                disposition.
              </p>
              <LayoutPreview variant="azerty" />
            </article>
            <article className="card">
              <h3>Fréquence</h3>
              <p>
                Les lettres fréquentes rassemblées au centre :{" "}
                <strong>43 % de déplacement en moins</strong>. En contrepartie,
                la disposition est entièrement à apprendre.
              </p>
              <LayoutPreview variant="azerty" />
            </article>
          </div>

          <h3 className="subhead">Plusieurs lettres par touche</h3>
          <p className="prose">
            On tape la touche qui porte la lettre, sans viser la lettre. Le
            dictionnaire retrouve le mot.
          </p>
          <div className="cards">
            <article className="card">
              <h3>Grosses touches</h3>
              <p>
                Huit touches, près de trois fois plus larges. 94,7 % des mots
                trouvés du premier coup — et le mot voulu{" "}
                <strong>toujours</strong> visible dans les suggestions.
              </p>
              <LayoutPreview variant="grouped" />
            </article>
            <article className="card">
              <h3>Très grosses touches</h3>
              <p>
                Six touches, les plus larges possible, pour une main qui
                tremble. 88,5 % du premier coup, et le mot reste visible dans
                99 % des cas.
              </p>
              <LayoutPreview variant="grouped-large" />
            </article>
          </div>

          <div className="stats">
            <div className="stat">
              <span className="stat__value">−43 %</span>
              <span className="stat__label">
                de déplacement du doigt, en mode fréquence
              </span>
            </div>
            <div className="stat">
              <span className="stat__value">94,7 %</span>
              <span className="stat__label">
                des mots trouvés du premier coup en grosses touches
              </span>
            </div>
            <div className="stat">
              <span className="stat__value">×3</span>
              <span className="stat__label">
                la largeur d’une touche, comparée à un AZERTY comprimé
              </span>
            </div>
          </div>
        </section>

        <section className="shell section" aria-labelledby="demonstration" id="demonstration">
          <p className="eyebrow">Démonstration</p>
          <h2 id="demonstration-titre">Tapez ici, avec un seul doigt.</h2>
          <p className="prose">
            Cette démonstration utilise le dictionnaire de l’application et la
            même désambiguïsation.
          </p>
          <KeyPadDemo />
        </section>

        <section className="shell section" aria-labelledby="dictionnaire">
          <p className="eyebrow">Dictionnaire</p>
          <h2 id="dictionnaire">Il apprend vos mots, pas ceux de tout le monde.</h2>
          <ul className="list">
            <li>
              Les mots que vous écrivez remontent dans les suggestions, comptés
              sur l’appareil.
            </li>
            <li>
              Les accents et apostrophes sont ignorés à la frappe : les lettres de
              « aujourdhui » donnent « aujourd’hui », correctement orthographié.
            </li>
            <li>
              Un mot inconnu — un nom propre, souvent — est vérifié auprès du
              Wiktionnaire par l’application, puis ajouté définitivement avec ses
              accents.
            </li>
          </ul>
        </section>

        <section className="shell section" aria-labelledby="confidentialite" id="confidentialite">
          <p className="eyebrow">Confidentialité</p>
          <h2 id="confidentialite-titre">Le clavier n’a aucun accès au réseau.</h2>
          <p className="prose">
            Un clavier autorisé à émettre des requêtes peut aussi émettre ce que
            vous tapez. Celui-ci ne demande jamais l’<em>Accès complet</em> d’iOS :
            il ne peut techniquement rien envoyer. Vos mots appris restent sur
            l’appareil.
          </p>
          <p className="prose">
            Quand le dictionnaire s’enrichit, c’est l’application — et non le
            clavier — qui interroge le Wiktionnaire, une fois par jour au plus.
          </p>
        </section>

        <section className="shell section" aria-labelledby="montre" id="montre">
          <p className="eyebrow">Au poignet</p>
          <h2 id="montre-titre">Des phrases prêtes, quand parler ne va pas de soi.</h2>
          <p className="prose">
            L’application montre affiche des phrases classées par urgence —
            « j’ai besoin d’aide », « j’ai mal », « appelez un médecin ». Une
            phrase touchée s’affiche en grand, pour être montrée, et se lit à voix
            haute.
          </p>
        </section>

        <section className="shell section" aria-labelledby="contact">
          <p className="eyebrow">Disponibilité</p>
          <h2 id="contact">Participer aux essais.</h2>
          <p className="prose">
            Uniclav se règle à l’usage : côté de la main, taille des touches,
            vocabulaire. Si vous accompagnez une personne hémiplégique ou si vous
            l’êtes, votre retour vaut plus qu’une mesure.
          </p>
          <div className="hero__actions">
            <a className="button" href={`mailto:${site.publisher.email}`}>
              Nous écrire
            </a>
          </div>
        </section>
      </main>

      <Footer />
    </>
  );
}
