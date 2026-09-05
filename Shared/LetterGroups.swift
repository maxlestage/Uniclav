import Foundation

/// Répartition des lettres sur les grosses touches. Huit groupes, comme sur
/// un clavier téléphonique : cette disposition est connue de presque tout le
/// monde et ne demande aucun apprentissage.
enum LetterGroups {
    static let all: [String] = ["abc", "def", "ghi", "jkl",
                                "mno", "pqrs", "tuv", "wxyz"]

    private static let indexOfLetter: [Character: Int] = {
        var map: [Character: Int] = [:]
        for (index, group) in all.enumerated() {
            for letter in group { map[letter] = index }
        }
        return map
    }()

    /// Signature d'un mot : un chiffre par lettre, désignant la touche qui la
    /// porte. Les accents sont ignorés (« ecole » retrouve « école »), ainsi
    /// que les apostrophes et traits d'union — si bien que « aujourdhui »
    /// suffit à obtenir « aujourd'hui », correctement orthographié.
    /// Renvoie nil pour un mot contenant un caractère hors des huit groupes.
    static func signature(of word: String) -> String? {
        var out = ""
        for character in PredictionEngine.normalize(word) {
            if character == "'" || character == "\u{2019}" || character == "-" || character == " " {
                continue
            }
            guard let index = indexOfLetter[character] else { return nil }
            out.append(Character(String(index)))
        }
        return out.isEmpty ? nil : out
    }

    /// Repli quand aucun mot ne correspond à la frappe : la première lettre de
    /// chaque touche. Le texte reste faux, mais il bouge à chaque appui, ce
    /// qui vaut mieux qu'un champ figé.
    static func literal(for signature: String) -> String {
        String(signature.compactMap { character in
            guard let index = Int(String(character)), all.indices.contains(index) else { return nil }
            return all[index].first
        })
    }
}
