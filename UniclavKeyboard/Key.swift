import Foundation

/// Une touche du clavier.
enum Key: Equatable {
    case character(String)
    /// Touche portant plusieurs lettres, en saisie groupée : indice dans
    /// `LetterGroups.all`.
    case letterGroup(Int)
    case shift
    case delete
    case space
    case ret
    case numbers   // passe au pavé chiffres/ponctuation
    case letters   // revient aux lettres
    case symbols   // passe aux symboles secondaires
    case globe     // changement de clavier iOS
    case switchLayout  // bascule AZERTY / grosses touches

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
/// dépend de la disposition choisie.
enum KeyboardLayer {
    case letters
    case numbers
    case symbols

    func rows(layout: KeyboardSettings.Layout) -> [[Key]] {
        switch self {
        case .letters:
            return layout == .grouped ? Self.groupedRows : Self.azertyRows
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

    private static let azertyRows: [[Key]] = [
        ["a", "z", "e", "r", "t", "y", "u", "i", "o", "p"].map(Key.character),
        ["q", "s", "d", "f", "g", "h", "j", "k", "l", "m"].map(Key.character),
        [Key.shift] + ["w", "x", "c", "v", "b", "n", "'"].map(Key.character) + [Key.delete],
        [.switchLayout, .numbers, .globe, .space, .ret],
    ]

    /// Quatre colonnes seulement : chaque touche est près de trois fois plus
    /// large qu'en AZERTY, ce qui pardonne l'imprécision du geste.
    private static let groupedRows: [[Key]] = [
        [.letterGroup(0), .letterGroup(1), .letterGroup(2), .delete],
        [.letterGroup(3), .letterGroup(4), .letterGroup(5), .shift],
        [.letterGroup(6), .letterGroup(7), .character("'"), .ret],
        [.switchLayout, .numbers, .globe, .space],
    ]
}
