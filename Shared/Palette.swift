import SwiftUI
import UIKit

/// Identité visuelle « papier » : un fond sable, une encre chaude.
///
/// Le choix n'est pas seulement esthétique. Un écran d'accueil est un mur de
/// carrés sombres et saturés ; une icône claire s'y repère par inversion. Et
/// l'encre sur sable donne le meilleur contraste de lettre, ce qui compte
/// pour une personne dont le champ visuel peut être amputé après un AVC.
enum Palette {
    struct Tone {
        let red: Double
        let green: Double
        let blue: Double

        var color: Color {
            Color(red: red, green: green, blue: blue)
        }

        var uiColor: UIColor {
            UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: 1)
        }
    }

    /// Fond clair, celui de l'icône.            #F2EBDE
    static let sand = Tone(red: 0.949, green: 0.922, blue: 0.871)
    /// Sable plus dense, pour les aplats.       #D8CDB8
    static let sandDeep = Tone(red: 0.847, green: 0.804, blue: 0.722)
    /// Encre profonde, celle de la touche.      #26221D
    static let ink = Tone(red: 0.149, green: 0.133, blue: 0.114)
    /// Encre adoucie, couleur d'accent : le noir pur sur un interrupteur
    /// iOS se lit comme un élément désactivé.   #3A322A
    static let inkSoft = Tone(red: 0.227, green: 0.196, blue: 0.165)

#if os(iOS)
    /// Accent de l'interface. L'encre disparaîtrait sur un fond sombre :
    /// les rôles s'inversent alors, l'accent devient le sable.
    static var accentUIColor: UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? sand.uiColor : inkSoft.uiColor }
    }

    /// Couleur du texte posé sur l'accent.
    static var onAccentUIColor: UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? ink.uiColor : sand.uiColor }
    }

    static var accent: Color { Color(uiColor: accentUIColor) }
#else
    /// watchOS n'a qu'un mode sombre.
    static var accent: Color { sand.color }
#endif
}
