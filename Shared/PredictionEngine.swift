import Foundation

/// Moteur de prédiction de mots : dictionnaire français embarqué (classé par
/// fréquence) + mots appris depuis la frappe de l'utilisateur.
final class PredictionEngine {

    /// Mots du dictionnaire, du plus fréquent au moins fréquent.
    private var words: [String] = []
    /// Version normalisée (minuscules, sans accents) alignée sur `words`.
    private var normalizedWords: [String] = []
    /// Mots appris : mot -> nombre d'utilisations.
    private var userWords: [String: Int] = [:]

    private let userWordMinLength = 3
    private let saveQueue = DispatchQueue(label: "com.maxlestage.uniclav.prediction", qos: .utility)

    init() {
        loadDictionary()
        userWords = KeyboardSettings.userWords
    }

    private func loadDictionary() {
        guard let url = Bundle(for: PredictionEngine.self).url(forResource: "dictionnaire_fr", withExtension: "txt"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            return
        }
        words = content
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }
        normalizedWords = words.map { Self.normalize($0) }
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

    /// Mémorise un mot validé par l'utilisateur (espace, ponctuation ou
    /// suggestion choisie) pour améliorer les prédictions suivantes.
    func learn(word rawWord: String) {
        let word = rawWord.trimmingCharacters(in: .whitespacesAndNewlines)
        guard word.count >= userWordMinLength,
              word.rangeOfCharacter(from: CharacterSet.decimalDigits) == nil else { return }

        let normalized = Self.normalize(word)
        // Inutile d'apprendre un mot déjà en tête du dictionnaire.
        if let index = normalizedWords.firstIndex(of: normalized), index < 200 { return }

        userWords[word, default: 0] += 1
        let snapshot = userWords
        saveQueue.async {
            KeyboardSettings.userWords = snapshot
        }
    }
}
