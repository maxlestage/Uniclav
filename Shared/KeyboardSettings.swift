import Foundation
import CoreGraphics

/// Réglages partagés entre l'application et l'extension clavier via l'App Group.
enum KeyboardSettings {
    static let appGroupID = "group.com.maxlestage.uniclav"

    /// Disposition des touches de lettres.
    enum Layout: String, CaseIterable, Identifiable {
        /// AZERTY complet : une lettre par touche, dix par rangée.
        case azerty
        /// Huit grosses touches de trois ou quatre lettres, désambiguïsées
        /// par le dictionnaire.
        case grouped

        var id: String { rawValue }

        var label: String {
            switch self {
            case .azerty: return "AZERTY complet"
            case .grouped: return "Grosses touches"
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
