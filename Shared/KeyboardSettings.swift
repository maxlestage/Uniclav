import Foundation
import CoreGraphics

/// Réglages partagés entre l'application et l'extension clavier via l'App Group.
enum KeyboardSettings {
    static let appGroupID = "group.com.maxlestage.uniclav"

    /// Disposition des touches de lettres.
    ///
    /// Chaque mode répond à une gêne différente, et aucun n'est meilleur dans
    /// l'absolu : le bon mode est celui qui convient à cette main-là.
    /// Les valeurs brutes `azerty` et `grouped` sont conservées telles quelles,
    /// pour ne pas réinitialiser le réglage des utilisateurs existants.
    enum Layout: String, CaseIterable, Identifiable {
        /// Une lettre par touche, dix par rangée, dans l'ordre habituel.
        case azerty
        /// Les mêmes touches, mais dans l'ordre alphabétique.
        case alphabetical
        /// Les lettres les plus fréquentes rassemblées au centre.
        case frequency
        /// Huit touches de trois ou quatre lettres, désambiguïsées par le
        /// dictionnaire.
        case grouped
        /// Six touches de quatre ou cinq lettres : les plus larges possible.
        case groupedLarge

        var id: String { rawValue }

        var label: String {
            switch self {
            case .azerty: return "AZERTY"
            case .alphabetical: return "Alphabétique"
            case .frequency: return "Fréquence"
            case .grouped: return "Grosses touches"
            case .groupedLarge: return "Très grosses touches"
            }
        }

        /// Ce que le mode apporte, et ce qu'il coûte. Mesuré, pas supposé.
        var summary: String {
            switch self {
            case .azerty:
                return "La disposition que vous connaissez déjà. Aucune adaptation à faire, mais dix touches étroites par rangée."
            case .alphabetical:
                return "Les lettres de A à Z. Le déplacement du doigt est identique à l'AZERTY : ce qui change, c'est qu'une lettre se trouve du regard, sans connaître la disposition."
            case .frequency:
                return "Les lettres fréquentes rassemblées au centre, ce qui réduit de 43 % le déplacement du doigt. En contrepartie, la disposition est à apprendre entièrement."
            case .grouped:
                return "Huit touches trois fois plus larges. Le dictionnaire retrouve le mot : 94,7 % du premier coup, et le mot voulu toujours visible dans les suggestions."
            case .groupedLarge:
                return "Six touches, les plus larges possible, pour une main qui tremble. 88,5 % du premier coup, et le mot reste visible dans 99 % des cas."
            }
        }

        /// Répartition des lettres quand le mode regroupe plusieurs lettres
        /// par touche ; nil lorsqu'une touche ne porte qu'une lettre.
        var grouping: LetterGroups.Grouping? {
            switch self {
            case .grouped: return .eight
            case .groupedLarge: return .six
            case .azerty, .alphabetical, .frequency: return nil
            }
        }
    }

    enum HandSide: String, CaseIterable, Identifiable {
        case left
        case right

        var id: String { rawValue }

        var label: String {
            switch self {
            case .left: return "Main gauche"
            case .right: return "Main droite"
            }
        }
    }

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    private enum Key {
        static let handSide = "handSide"
        static let layout = "layout"
        static let keyboardScale = "keyboardScale"
        static let keyHeight = "keyHeight"
        static let largeLabels = "largeLabels"
        static let highContrast = "highContrast"
        static let userWords = "userWords"
        static let autoUpdateDictionary = "autoUpdateDictionary"
        static let lastDictionaryUpdate = "lastDictionaryUpdate"
        static let dictionaryWordCount = "dictionaryWordCount"
        static let coreVocabularyMerged = "coreVocabularyMerged"
        static let shareUnknownWords = "shareUnknownWords"
    }

    /// Disposition des lettres.
    static var layout: Layout {
        get { Layout(rawValue: defaults.string(forKey: Key.layout) ?? "") ?? .azerty }
        set { defaults.set(newValue.rawValue, forKey: Key.layout) }
    }

    /// Côté d'ancrage du clavier (main valide de l'utilisateur).
    static var handSide: HandSide {
        get { HandSide(rawValue: defaults.string(forKey: Key.handSide) ?? "") ?? .right }
        set { defaults.set(newValue.rawValue, forKey: Key.handSide) }
    }

    /// Largeur du clavier en fraction de l'écran (0.6 … 1.0).
    static var keyboardScale: CGFloat {
        get {
            let value = defaults.double(forKey: Key.keyboardScale)
            return value == 0 ? 0.78 : CGFloat(min(max(value, 0.6), 1.0))
        }
        set { defaults.set(Double(newValue), forKey: Key.keyboardScale) }
    }

    /// Hauteur d'une rangée de touches en points (44 … 66).
    static var keyHeight: CGFloat {
        get {
            let value = defaults.double(forKey: Key.keyHeight)
            return value == 0 ? 54 : CGFloat(min(max(value, 44), 66))
        }
        set { defaults.set(Double(newValue), forKey: Key.keyHeight) }
    }

    /// Affiche les lettres en plus grand sur les touches.
    static var largeLabels: Bool {
        get { defaults.object(forKey: Key.largeLabels) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.largeLabels) }
    }

    /// Contraste renforcé (touches sombres sur fond clair et inversement).
    static var highContrast: Bool {
        get { defaults.object(forKey: Key.highContrast) as? Bool ?? false }
        set { defaults.set(newValue, forKey: Key.highContrast) }
    }

    /// Enrichir le dictionnaire depuis le Wiktionnaire, en arrière-plan.
    static var autoUpdateDictionary: Bool {
        get { defaults.object(forKey: Key.autoUpdateDictionary) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.autoUpdateDictionary) }
    }

    /// Date de la dernière mise à jour réussie.
    static var lastDictionaryUpdate: Date? {
        get { defaults.object(forKey: Key.lastDictionaryUpdate) as? Date }
        set { defaults.set(newValue, forKey: Key.lastDictionaryUpdate) }
    }

    /// Nombre de mots du dictionnaire actif, pour l'affichage.
    static var dictionaryWordCount: Int {
        get { defaults.integer(forKey: Key.dictionaryWordCount) }
        set { defaults.set(newValue, forKey: Key.dictionaryWordCount) }
    }

    /// Soumettre au Wiktionnaire les mots que le clavier n'a pas reconnus.
    ///
    /// Désactivé par défaut, et volontairement séparé de la mise à jour du
    /// dictionnaire. Un mot absent d'un dictionnaire français est le plus
    /// souvent un nom propre — un prénom, une commune, le nom d'un
    /// praticien : ce sont précisément les mots qu'on n'envoie pas à un tiers
    /// sans l'avoir demandé. Le vocabulaire de base, lui, ne révèle rien.
    static var shareUnknownWords: Bool {
        get { defaults.bool(forKey: Key.shareUnknownWords) }
        set { defaults.set(newValue, forKey: Key.shareUnknownWords) }
    }

    /// Le vocabulaire de base du Wiktionnaire n'est fusionné qu'une fois.
    static var coreVocabularyMerged: Bool {
        get { defaults.bool(forKey: Key.coreVocabularyMerged) }
        set { defaults.set(newValue, forKey: Key.coreVocabularyMerged) }
    }

    /// Mots appris depuis la frappe de l'utilisateur, avec leur fréquence.
    static var userWords: [String: Int] {
        get { defaults.dictionary(forKey: Key.userWords) as? [String: Int] ?? [:] }
        set { defaults.set(newValue, forKey: Key.userWords) }
    }
}
