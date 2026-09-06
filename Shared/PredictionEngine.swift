import Foundation

/// Moteur de prédiction de mots : dictionnaire français embarqué (classé par
/// fréquence) + mots appris depuis la frappe de l'utilisateur.
final class PredictionEngine {

    /// Mots du dictionnaire, du plus fréquent au moins fréquent.
    private var words: [String] = []
    /// Version normalisée (minuscules, sans accents) alignée sur `words`.
    private var normalizedWords: [String] = []
    /// Signature de saisie groupée de chaque mot, alignée sur `words` ; nil
    /// pour les mots contenant un caractère hors des groupes.
    private var signatures: [String?] = []
    /// Découpage pour lequel `signatures` a été calculé. Changer de mode le
    /// change aussi, et l'index doit alors être reconstruit.
    private var signatureGrouping: LetterGroups.Grouping?
    /// Mots appris : mot -> nombre d'utilisations.
    private var userWords: [String: Int] = [:]
    /// Formes normalisées du dictionnaire, pour reconnaître d'un coup si un
    /// mot y figure déjà.
    private var knownNormalized: Set<String> = []

    private let userWordMinLength = 3
    private let saveQueue = DispatchQueue(label: "com.maxlestage.uniclav.prediction", qos: .utility)

    init() {
        loadDictionary()
        userWords = KeyboardSettings.userWords
    }

    private func loadDictionary() {
        // Version enrichie par l'application si elle existe, sinon celle
        // livrée avec l'app.
        words = DictionaryStore.loadWords()
        normalizedWords = words.map { Self.normalize($0) }
        knownNormalized = Set(normalizedWords)
        signatureGrouping = nil
        signatures = []
    }

    /// Minuscules et suppression des diacritiques, pour qu'un préfixe tapé
    /// sans accent (« ecol ») retrouve le mot accentué (« école »).
    static func normalize(_ word: String) -> String {
        word.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "fr_FR"))
    }

    /// Suggestions pour le préfixe en cours de frappe.
    /// Les mots appris de l'utilisateur passent avant le dictionnaire.
    func suggestions(forPrefix rawPrefix: String, limit: Int = 3) -> [String] {
        let prefix = Self.normalize(rawPrefix)
        guard !prefix.isEmpty else { return [] }

        var results: [String] = []
        var seen = Set<String>()

        let matchingUserWords = userWords
            .filter { Self.normalize($0.key).hasPrefix(prefix) && Self.normalize($0.key) != prefix }
            .sorted { $0.value > $1.value }
            .map { $0.key }
        for word in matchingUserWords where results.count < limit {
            if seen.insert(Self.normalize(word)).inserted {
                results.append(word)
            }
        }

        for (index, normalized) in normalizedWords.enumerated() where results.count < limit {
            guard normalized.hasPrefix(prefix) else { continue }
            let word = words[index]
            // Le mot identique au préfixe reste utile s'il porte des accents
            // (« ecole » -> « école »), sinon il n'apporte rien.
            if normalized == prefix && word.lowercased() == rawPrefix.lowercased() { continue }
            if seen.insert(normalized).inserted {
                results.append(word)
            }
        }
        return results
    }

    /// Construit l'index des signatures pour le découpage demandé. Appelée à
    /// chaque configuration du clavier ; ne recalcule rien si le découpage
    /// n'a pas changé.
    func prepare(grouping: LetterGroups.Grouping?) {
        guard let grouping = grouping else { return }
        guard signatureGrouping != grouping else { return }
        signatureGrouping = grouping
        signatures = words.map { LetterGroups.signature(of: $0, grouping: grouping) }
    }

    /// Mots correspondant à une suite de touches groupées, séparés en deux :
    /// ceux qui font exactement la longueur frappée, et les mots plus longs
    /// qui valent complétion.
    ///
    /// La distinction n'est pas cosmétique. Si le champ affichait la meilleure
    /// complétion, effacer une touche laisserait souvent le même mot à
    /// l'écran — quatre touches de « merci » proposent encore « merci » — et
    /// l'effacement paraîtrait sans effet.
    func groupedMatches(forSignature signature: String) -> (exact: [String], completions: [String]) {
        guard !signature.isEmpty, let grouping = signatureGrouping else { return ([], []) }

        var exact: [String] = []
        var longer: [String] = []
        var seen = Set<String>()

        func consider(_ word: String, _ wordSignature: String) {
            guard wordSignature.hasPrefix(signature),
                  seen.insert(Self.normalize(word)).inserted else { return }
            if wordSignature.count == signature.count {
                exact.append(word)
            } else {
                longer.append(word)
            }
        }

        // Les mots appris passent devant, comme pour les suggestions.
        for (word, _) in userWords.sorted(by: { $0.value > $1.value }) {
            if let wordSignature = LetterGroups.signature(of: word, grouping: grouping) {
                consider(word, wordSignature)
            }
        }
        for (index, wordSignature) in signatures.enumerated() {
            if let wordSignature = wordSignature {
                consider(words[index], wordSignature)
            }
        }
        return (exact, longer)
    }

    /// Liste unique proposée dans la barre : exactes d'abord, complétions
    /// ensuite.
    func groupedCandidates(forSignature signature: String, limit: Int = 3) -> [String] {
        let matches = groupedMatches(forSignature: signature)
        return Array((matches.exact + matches.completions).prefix(limit))
    }

    /// Mémorise un mot validé par l'utilisateur (espace, ponctuation ou
    /// suggestion choisie) pour améliorer les prédictions suivantes.
    func learn(word rawWord: String) {
        let word = rawWord.trimmingCharacters(in: .whitespacesAndNewlines)
        guard word.count >= userWordMinLength,
              word.rangeOfCharacter(from: CharacterSet.decimalDigits) == nil else { return }

        let normalized = Self.normalize(word)
        // Mot absent du dictionnaire : l'application ira demander au
        // Wiktionnaire s'il est français, et l'ajoutera pour de bon — mais
        // seulement si l'utilisateur l'a explicitement autorisé, ces mots-là
        // étant surtout des noms propres.
        if KeyboardSettings.shareUnknownWords, !knownNormalized.contains(normalized) {
            PendingWords.enqueue(word)
        }
        // Inutile d'apprendre un mot déjà en tête du dictionnaire.
        if let index = normalizedWords.firstIndex(of: normalized), index < 200 { return }

        userWords[word, default: 0] += 1
        let snapshot = userWords
        saveQueue.async {
            KeyboardSettings.userWords = snapshot
        }
    }
}
