import UIKit

/// Les icônes de l'application : la principale, et une par thème de couleurs.
///
/// Elles vivent dans la cible de l'application seule. `setAlternateIconName`
/// passe par `UIApplication.shared`, indisponible dans une extension — le
/// clavier ne peut donc pas changer l'icône, et n'a pas à le pouvoir.
///
/// Les fichiers sont des PNG posés à la racine du paquet, déclarés sous
/// `CFBundleIcons` → `CFBundleAlternateIcons` dans `Info.plist`, et engendrés
/// par `tools/make_icons.py` à partir des mêmes couleurs que les thèmes.
struct AppIconChoice: Identifiable, Equatable {

    /// Nom déclaré dans `Info.plist`, ou `nil` pour l'icône principale —
    /// c'est ce `nil` que `setAlternateIconName` attend pour y revenir.
    let alternateName: String?
    let label: String
    /// Le thème dont l'icône reprend les couleurs.
    let theme: KeyboardTheme

    var id: String { alternateName ?? "principale" }

    /// L'image réellement livrée, pour que l'aperçu ne soit pas une imitation.
    var image: UIImage? {
        UIImage(named: alternateName.map { "AppIcon-\($0)" } ?? "AppIcon")
    }

    static let all: [AppIconChoice] = [
        AppIconChoice(alternateName: nil, label: "Encre sur sable", theme: .inkOnSand),
        AppIconChoice(alternateName: "Nuit", label: "Nuit", theme: .night),
        AppIconChoice(alternateName: "ContrasteMaximal", label: "Contraste maximal", theme: .maxContrast),
        AppIconChoice(alternateName: "JauneSurNoir", label: "Jaune sur noir", theme: .yellowOnBlack),
        AppIconChoice(alternateName: "NoirSurJaune", label: "Noir sur jaune", theme: .blackOnYellow),
        AppIconChoice(alternateName: "BleuProfond", label: "Bleu profond", theme: .deepBlue),
        AppIconChoice(alternateName: "VertDEau", label: "Vert d'eau", theme: .seaGreen),
    ]

    /// L'icône posée en ce moment.
    static var current: AppIconChoice {
        let name = UIApplication.shared.alternateIconName
        return all.first { $0.alternateName == name } ?? all[0]
    }

    static var isSupported: Bool { UIApplication.shared.supportsAlternateIcons }

    /// Change l'icône. iOS affiche lui-même une alerte de confirmation à
    /// chaque changement : c'est le système qui la pose, aucune API publique
    /// ne permet de s'en passer, et l'interface prévient donc à l'avance.
    static func apply(_ choice: AppIconChoice, completion: @escaping (Bool) -> Void) {
        guard isSupported else {
            completion(false)
            return
        }
        guard choice.alternateName != UIApplication.shared.alternateIconName else {
            completion(true)
            return
        }
        UIApplication.shared.setAlternateIconName(choice.alternateName) { error in
            DispatchQueue.main.async { completion(error == nil) }
        }
    }
}
