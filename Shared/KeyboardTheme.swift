import SwiftUI
import UIKit

/// Une couleur du clavier, stockable en hexadécimal dans l'App Group.
struct KeyboardColor: Equatable {
    let red: Double
    let green: Double
    let blue: Double

    init(red: Double, green: Double, blue: Double) {
        self.red = min(max(red, 0), 1)
        self.green = min(max(green, 0), 1)
        self.blue = min(max(blue, 0), 1)
    }

    init?(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        guard cleaned.count == 6, let value = Int(cleaned, radix: 16) else { return nil }
        self.init(red: Double((value >> 16) & 0xFF) / 255,
                  green: Double((value >> 8) & 0xFF) / 255,
                  blue: Double(value & 0xFF) / 255)
    }

    var hex: String {
        String(format: "%02X%02X%02X",
               Int(red * 255 + 0.5), Int(green * 255 + 0.5), Int(blue * 255 + 0.5))
    }

    var uiColor: UIColor {
        UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: 1)
    }

    var color: Color { Color(red: red, green: green, blue: blue) }

    /// Luminance relative au sens de WCAG 2.1.
    var relativeLuminance: Double {
        func channel(_ value: Double) -> Double {
            value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(red) + 0.7152 * channel(green) + 0.0722 * channel(blue)
    }

    /// Rapport de contraste WCAG, de 1 (identiques) à 21 (noir sur blanc).
    func contrastRatio(with other: KeyboardColor) -> Double {
        let a = relativeLuminance, b = other.relativeLuminance
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }

    /// Mélange vers une autre couleur, pour dériver les teintes secondaires
    /// sans demander un troisième réglage à l'utilisateur.
    func blended(toward other: KeyboardColor, amount: Double) -> KeyboardColor {
        KeyboardColor(red: red + (other.red - red) * amount,
                      green: green + (other.green - green) * amount,
                      blue: blue + (other.blue - blue) * amount)
    }
}

/// Les couleurs effectivement appliquées au clavier.
struct KeyboardPalette {
    let keyFace: KeyboardColor
    let keyText: KeyboardColor

    /// Touches de service : la même teinte, poussée vers le texte, pour se
    /// distinguer des lettres sans introduire une couleur de plus.
    var specialKeyFace: KeyboardColor { keyFace.blended(toward: keyText, amount: 0.20) }
    /// Fond du clavier, derrière les touches.
    var backdrop: KeyboardColor { keyFace.blended(toward: keyText, amount: 0.10) }

    var contrastRatio: Double { keyFace.contrastRatio(with: keyText) }
}

/// Thèmes proposés. Tous atteignent le niveau AAA de WCAG (rapport ≥ 7:1) :
/// un clavier illisible n'est pas une option esthétique.
enum KeyboardTheme: String, CaseIterable, Identifiable {
    case inkOnSand
    case night
    case maxContrast
    case yellowOnBlack
    case blackOnYellow
    case deepBlue
    case seaGreen
    /// Couleurs choisies par l'utilisateur, dans les réglages.
    case custom

    var id: String { rawValue }

    var label: String {
        switch self {
        case .inkOnSand: return "Encre sur sable"
        case .night: return "Nuit"
        case .maxContrast: return "Contraste maximal"
        case .yellowOnBlack: return "Jaune sur noir"
        case .blackOnYellow: return "Noir sur jaune"
        case .deepBlue: return "Bleu profond"
        case .seaGreen: return "Vert d'eau"
        case .custom: return "Mes couleurs"
        }
    }

    /// Couleurs du thème ; nil pour « Mes couleurs », qui les tire des
    /// réglages.
    var preset: (face: KeyboardColor, text: KeyboardColor)? {
        func pair(_ face: String, _ text: String) -> (KeyboardColor, KeyboardColor)? {
            guard let f = KeyboardColor(hex: face), let t = KeyboardColor(hex: text) else { return nil }
            return (f, t)
        }
        switch self {
        case .inkOnSand: return pair("FBF8F2", "26221D")
        case .night: return pair("3A3A3E", "F2EBDE")
        case .maxContrast: return pair("FFFFFF", "000000")
        case .yellowOnBlack: return pair("141414", "FFD400")
        case .blackOnYellow: return pair("FFD400", "141414")
        case .deepBlue: return pair("12284B", "F5F7FA")
        case .seaGreen: return pair("E8F1EC", "16352B")
        case .custom: return nil
        }
    }
}
