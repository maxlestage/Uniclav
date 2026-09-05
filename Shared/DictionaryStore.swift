import Foundation

/// Emplacement du dictionnaire actif.
///
/// L'application enrichit le dictionnaire depuis le Wiktionnaire et dépose le
/// résultat dans l'App Group. L'extension clavier, elle, ne fait que lire ce
/// fichier : elle n'a pas accès au réseau, et c'est délibéré — un clavier qui
/// peut émettre des requêtes peut aussi émettre ce qu'on tape.
enum DictionaryStore {
    private static var containerURL: URL? {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: KeyboardSettings.appGroupID)
    }

    /// Version enrichie, écrite par l'application.
    static var enrichedURL: URL? {
        containerURL?.appendingPathComponent("dictionnaire_fr.txt")
    }

    /// Version livrée avec l'app, utilisée tant qu'aucune mise à jour n'a eu
    /// lieu — et filet de sécurité si le fichier partagé devient illisible.
    static var bundledURL: URL? {
        Bundle(for: PredictionEngine.self).url(forResource: "dictionnaire_fr", withExtension: "txt")
    }

    /// Mots du dictionnaire actif, du plus fréquent au moins fréquent.
    static func loadWords() -> [String] {
        for url in [enrichedURL, bundledURL].compactMap({ $0 }) {
            guard let content = try? String(contentsOf: url, encoding: .utf8) else { continue }
            let words = parse(content)
            if !words.isEmpty { return words }
        }
        return []
    }

    static func parse(_ content: String) -> [String] {
        content
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }
    }

    /// Écriture atomique : l'extension ne doit jamais tomber sur un fichier à
    /// moitié réécrit pendant qu'elle charge son dictionnaire.
    static func save(words: [String]) throws {
        guard let url = enrichedURL else { throw StoreError.appGroupUnavailable }
        let header = """
        # Dictionnaire Uniclav, enrichi depuis le Wiktionnaire francophone.
        # \(words.count) mots, du plus fréquent au moins fréquent.
        # Les mots ajoutés sont placés en fin de liste : le classement par
        # fréquence de la base d'origine reste intact, car c'est lui qui fait
        # marcher la désambiguïsation des grosses touches.

        """
        try (header + words.joined(separator: "\n") + "\n")
            .write(to: url, atomically: true, encoding: .utf8)
    }

    enum StoreError: Error {
        case appGroupUnavailable
    }
}
