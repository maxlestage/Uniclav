import Foundation

/// Une touche du clavier.
enum Key: Equatable {
    case character(String)
    /// Touche portant plusieurs lettres : indice du groupe, puis les lettres
    /// à afficher. Le libellé voyage avec la touche pour que le bouton n'ait
    /// pas à connaître le découpage en cours.
    case letterGroup(Int, String)
    case shift
    case delete
    case space
    case ret
    case numbers   // passe au pavé chiffres/ponctuation
    case letters   // revient aux lettres
    case symbols   // passe aux symboles secondaires
    case globe     // changement de clavier iOS
    case switchLayout  // bascule vers l'AZERTY, et retour

    /// Variantes proposées par appui long (accents français).
    static let accentVariants: [String: [String]] = [
        "a": ["à", "â", "æ", "á", "ä"],
        "e": ["é", "è", "ê", "ë"],
        "i": ["î", "ï", "í"],
        "o": ["ô", "œ", "ö", "ó"],
        "u": ["ù", "û", "ü", "ú"],
        "c": ["ç"],
        "y": ["ÿ"],
        "n": ["ñ"],
    ]
}

/// Plan de clavier : lettres, chiffres ou symboles. Le plan des lettres
/// dépend du mode choisi.
enum KeyboardLayer {
    case letters
    case numbers
    case symbols

    func rows(layout: KeyboardSettings.Layout) -> [[Key]] {
        switch self {
        case .letters:
            switch layout {
            case .azerty: return Self.azertyRows
            case .alphabetical: return Self.alphabeticalRows
            case .frequency: return Self.frequencyRows
            case .grouped, .groupedLarge, .multiTap:
                return Self.groupedRows(for: layout.grouping ?? .eight)
            }
        case .numbers:
            return [
                ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"].map(Key.character),
                ["-", "/", ":", ";", "(", ")", "€", "&", "@", "\""].map(Key.character),
                [Key.symbols] + [".", ",", "?", "!", "'"].map(Key.character) + [Key.delete],
                [.letters, .globe, .space, .ret],
            ]
        case .symbols:
            return [
                ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="].map(Key.character),
                ["_", "\\", "|", "~", "<", ">", "$", "£", "¥", "·"].map(Key.character),
                [Key.numbers] + [".", ",", "?", "!", "'"].map(Key.character) + [Key.delete],
                [.letters, .globe, .space, .ret],
            ]
        }
    }

    private static func letterRow(_ letters: String) -> [Key] {
        letters.map { Key.character(String($0)) }
    }

    private static let bottomRow: [Key] = [.switchLayout, .numbers, .globe, .space, .ret]

    private static let azertyRows: [[Key]] = [
        letterRow("azertyuiop"),
        letterRow("qsdfghjklm"),
        [Key.shift] + letterRow("wxcvbn'") + [Key.delete],
        bottomRow,
    ]

    /// L'ordre alphabétique ne raccourcit pas le trajet du doigt — il est
    /// identique à celui de l'AZERTY, mesuré sur le même corpus. Ce qu'il
    /// change, c'est qu'on trouve une lettre du regard sans connaître la
    /// disposition.
    private static let alphabeticalRows: [[Key]] = [
        letterRow("abcdefghij"),
        letterRow("klmnopqrst"),
        [Key.shift] + letterRow("uvwxyz'") + [Key.delete],
        bottomRow,
    ]

    /// Les lettres sont posées en spirale depuis le centre, par fréquence
    /// décroissante en français : les plus courantes se touchent presque.
    /// Mesuré sur le dictionnaire fourni, le doigt parcourt 43 % de moins
    /// qu'en AZERTY. Le prix est une disposition entièrement à apprendre.
    private static let frequencyRows: [[Key]] = [
        letterRow("yhdtrupfk"),
        letterRow("xqlseambz") + [Key.character("'")],
        [Key.shift] + letterRow("wgcinovj") + [Key.delete],
        bottomRow,
    ]

    /// Trois ou quatre colonnes seulement : chaque touche devient bien plus
    /// large qu'en AZERTY, ce qui pardonne l'imprécision du geste.
    private static func groupedRows(for grouping: LetterGroups.Grouping) -> [[Key]] {
        let groups = grouping.groups
        func group(_ index: Int) -> Key {
            .letterGroup(index, groups.indices.contains(index) ? groups[index] : "")
        }
        switch grouping {
        case .eight:
            return [
                [group(0), group(1), group(2), .delete],
                [group(3), group(4), group(5), .shift],
                [group(6), group(7), .character("'"), .ret],
                [.switchLayout, .numbers, .globe, .space],
            ]
        case .six:
            return [
                [group(0), group(1), group(2)],
                [group(3), group(4), group(5)],
                [.shift, .character("'"), .delete, .ret],
                [.switchLayout, .numbers, .globe, .space],
            ]
        }
    }
}
