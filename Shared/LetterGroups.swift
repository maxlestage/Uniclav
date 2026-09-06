import Foundation

/// Répartition des lettres sur les touches, quand une touche en porte
/// plusieurs. Deux découpages sont proposés : huit touches, comme sur un
/// clavier téléphonique, ou six pour des cibles encore plus larges.
enum LetterGroups {

    enum Grouping: String, CaseIterable {
        /// Le découpage du clavier téléphonique, connu de presque tout le
        /// monde. Mesuré sur le dictionnaire fourni : 94,7 % des mots trouvés
        /// du premier coup, et le plus gros groupe de collision compte trois
        /// mots — le mot voulu tient donc toujours dans les suggestions.
        case eight
        /// Six touches : 88,5 % du premier coup, et le mot reste visible dans
        /// 99,1 % des cas. On échange un peu de précision contre des cibles
        /// nettement plus larges.
        case six

        var groups: [String] {
            switch self {
            case .eight: return ["abc", "def", "ghi", "jkl", "mno", "pqrs", "tuv", "wxyz"]
            case .six: return ["abcd", "efgh", "ijkl", "mnopq", "rstu", "vwxyz"]
            }
        }

        fileprivate var indexOfLetter: [Character: Int] {
            var map: [Character: Int] = [:]
            for (index, group) in groups.enumerated() {
                for letter in group { map[letter] = index }
            }
            return map
        }
    }

    /// Les tables d'indices sont construites une fois : `signature` est
    /// appelée pour chaque mot du dictionnaire à chaque changement de mode.
    private static let indexTables: [Grouping: [Character: Int]] = {
        var tables: [Grouping: [Character: Int]] = [:]
        for grouping in Grouping.allCases { tables[grouping] = grouping.indexOfLetter }
        return tables
    }()

    /// Signature d'un mot : un chiffre par lettre, désignant la touche qui la
    /// porte. Les accents sont ignorés (« ecole » retrouve « école »), ainsi
    /// que les apostrophes et traits d'union — si bien que « aujourdhui »
    /// suffit à obtenir « aujourd'hui », correctement orthographié.
    /// Renvoie nil pour un mot contenant un caractère hors des groupes.
    static func signature(of word: String, grouping: Grouping) -> String? {
        guard let table = indexTables[grouping] else { return nil }
        var out = ""
        for character in PredictionEngine.normalize(word) {
            if character == "'" || character == "\u{2019}" || character == "-" || character == " " {
                continue
            }
            guard let index = table[character] else { return nil }
            out.append(Character(String(index)))
        }
        return out.isEmpty ? nil : out
    }

    /// Repli quand aucun mot ne correspond à la frappe : la première lettre de
    /// chaque touche. Le texte reste faux, mais il bouge à chaque appui, ce
    /// qui vaut mieux qu'un champ figé.
    static func literal(for signature: String, grouping: Grouping) -> String {
        let groups = grouping.groups
        return String(signature.compactMap { character in
            guard let index = Int(String(character)), groups.indices.contains(index) else { return nil }
            return groups[index].first
        })
    }
}
