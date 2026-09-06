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
    case special   // passe aux caractères accentués et à la typographie
    case globe     // changement de clavier iOS
    case switchLayout  // bascule vers l'AZERTY, et retour

    /// Variantes proposées par appui long. Les lettres portent leurs accents,
    /// la ponctuation sa typographie française — l'apostrophe courbe et les
    /// guillemets ne s'obtiennent nulle part ailleurs sur un clavier iOS.
    static let accentVariants: [String: [String]] = [
        "a": ["à", "â", "ä", "á", "æ"],
        "e": ["é", "è", "ê", "ë"],
        "i": ["î", "ï", "í"],
        "o": ["ô", "ö", "œ", "ó"],
        "u": ["ù", "û", "ü", "ú"],
        "c": ["ç"],
        "y": ["ÿ"],
        "n": ["ñ"],
        "'": ["’"],
        "\"": ["«", "»"],
        "-": ["–", "—"],
        ".": ["…"],
    ]

    /// Variantes d'une touche qui porte plusieurs lettres : celles de chacune
    /// de ses lettres, dans l'ordre, sans doublon.
    ///
    /// C'est ce qui rend l'appui long utilisable dans les modes à grosses
    /// touches, où il n'existait pas : « ABC » maintenue propose à â ä á æ ç.
    static func variants(forLetters letters: String) -> [String] {
        var result: [String] = []
        for letter in letters {
            for variant in accentVariants[String(letter)] ?? [] where !result.contains(variant) {
                result.append(variant)
            }
        }
        return result
    }

    /// Variantes de n'importe quelle touche, quel que soit le mode.
    var longPressVariants: [String] {
        switch self {
        case let .character(char): return Key.accentVariants[char] ?? []
        case let .letterGroup(_, letters): return Key.variants(forLetters: letters)
        default: return []
        }
    }
}

/// Plan de clavier : lettres, chiffres ou symboles. Le plan des lettres
/// dépend du mode choisi.
enum KeyboardLayer {
    case letters
    case numbers
    case symbols
    case special

    /// Caractères que le clavier ne peut pas produire autrement : toutes les
    /// voyelles accentuées du français, la cédille, la ligature, l'apostrophe
    /// typographique et les guillemets.
    ///
    /// Ils tenaient jusqu'ici dans l'appui long d'une lettre, qui n'existe
    /// qu'avec une lettre par touche. En grosses touches le dictionnaire les
    /// rétablissait ; en appuis répétés, qui n'en a pas, « café » était
    /// simplement impossible à écrire.
    static let specialCharacters = [
        "é", "è", "ê", "ë", "à", "â",
        "î", "ï", "ô", "ö", "ù", "û",
        "ü", "ç", "œ", "’", "«", "»",
    ]

    /// Six colonnes, dans les six modes. Les toucher demande de la précision
    /// quel que soit le mode choisi : les élargir n'est pas un luxe réservé
    /// aux dispositions à grosses touches.
    private static let specialColumns = 6

    func rows(layout: KeyboardSettings.Layout) -> [[Key]] {
        switch self {
        case .special:
            let letters = Self.specialCharacters.map(Key.character)
            let columns = Self.specialColumns
            var rows: [[Key]] = stride(from: 0, to: letters.count, by: columns).map {
                Array(letters[$0..<min($0 + columns, letters.count)])
            }
            // L'effacement doit rester à portée : une lettre accentuée se tape
            // rarement du premier coup.
            if !rows.isEmpty { rows[rows.count - 1].append(.delete) }
            // La majuscule doit être là : « École » et « À bientôt » sont des
            // débuts de phrase, donc le cas courant, pas l'exception.
            rows.append([.letters, .shift, .numbers, .globe, .space, .ret])
            return rows
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
                [.letters, .special, .globe, .space, .ret],
            ]
        case .symbols:
            return [
                ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="].map(Key.character),
                ["_", "\\", "|", "~", "<", ">", "$", "£", "¥", "·"].map(Key.character),
                [Key.numbers] + [".", ",", "?", "!", "'"].map(Key.character) + [Key.delete],
                [.letters, .special, .globe, .space, .ret],
            ]
        }
    }

    private static func letterRow(_ letters: String) -> [Key] {
        letters.map { Key.character(String($0)) }
    }

    private static let bottomRow: [Key] = [.switchLayout, .special, .numbers, .globe, .space, .ret]

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
                [.switchLayout, .special, .numbers, .globe, .space],
            ]
        case .six:
            return [
                [group(0), group(1), group(2)],
                [group(3), group(4), group(5)],
                [.shift, .character("'"), .delete, .ret],
                [.switchLayout, .special, .numbers, .globe, .space],
            ]
        }
    }
}
