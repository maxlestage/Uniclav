import Foundation

/// Une touche du clavier.
enum Key: Equatable {
    case character(String)
    case shift
    case delete
    case space
    case ret
    case numbers   // passe au pavé chiffres/ponctuation
    case letters   // revient aux lettres
    case symbols   // passe aux symboles secondaires
    case globe     // changement de clavier iOS

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

/// Disposition d'un plan de clavier : des rangées de touches.
enum KeyboardLayer {
    case letters
    case numbers
    case symbols

    var rows: [[Key]] {
        switch self {
        case .letters:
            return [
                ["a", "z", "e", "r", "t", "y", "u", "i", "o", "p"].map(Key.character),
                ["q", "s", "d", "f", "g", "h", "j", "k", "l", "m"].map(Key.character),
                [.shift] + ["w", "x", "c", "v", "b", "n", "'"].map(Key.character) + [.delete],
                [.numbers, .globe, .space, .ret],
            ]
        case .numbers:
            return [
                ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"].map(Key.character),
                ["-", "/", ":", ";", "(", ")", "€", "&", "@", "\""].map(Key.character),
                [.symbols] + [".", ",", "?", "!", "'"].map(Key.character) + [.delete],
                [.letters, .globe, .space, .ret],
            ]
        case .symbols:
            return [
                ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="].map(Key.character),
                ["_", "\\", "|", "~", "<", ">", "$", "£", "¥", "·"].map(Key.character),
                [.numbers] + [".", ",", "?", "!", "'"].map(Key.character) + [.delete],
                [.letters, .globe, .space, .ret],
            ]
        }
    }
}
