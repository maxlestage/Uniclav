import Foundation
import CoreGraphics

/// Réglages partagés entre l'application et l'extension clavier via l'App Group.
enum KeyboardSettings {
    static let appGroupID = "group.com.maxlestage.uniclav"

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
        static let keyboardScale = "keyboardScale"
        static let keyHeight = "keyHeight"
        static let largeLabels = "largeLabels"
        static let highContrast = "highContrast"
        static let userWords = "userWords"
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

    /// Mots appris depuis la frappe de l'utilisateur, avec leur fréquence.
    static var userWords: [String: Int] {
        get { defaults.dictionary(forKey: Key.userWords) as? [String: Int] ?? [:] }
        set { defaults.set(newValue, forKey: Key.userWords) }
    }
}
