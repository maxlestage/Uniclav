import UIKit

/// Une touche du clavier, avec son style et son libellé.
final class KeyButton: UIButton {

    let key: Key
    private var uppercase = false
    private var largeLabels = true
    private var highContrast = false

    init(key: Key) {
        self.key = key
        super.init(frame: .zero)
        layer.cornerRadius = 9
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowOpacity = 0.25
        layer.shadowRadius = 0
        translatesAutoresizingMaskIntoConstraints = false
        applyStyle(largeLabels: true, highContrast: false, shiftActive: false)
        refreshTitle()
        configureAccessibility()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) non géré") }

    func applyStyle(largeLabels: Bool, highContrast: Bool, shiftActive: Bool) {
        self.largeLabels = largeLabels
        self.highContrast = highContrast

        let isSpecial: Bool
        switch key {
        case .character, .space:
            isSpecial = false
        default:
            isSpecial = true
        }

        if highContrast {
            backgroundColor = isSpecial ? UIColor.label.withAlphaComponent(0.25) : UIColor.systemBackground
            setTitleColor(.label, for: .normal)
        } else {
            backgroundColor = isSpecial
                ? UIColor.secondarySystemFill
                : UIColor { trait in
                    trait.userInterfaceStyle == .dark ? UIColor(white: 0.42, alpha: 1) : .white
                }
            setTitleColor(.label, for: .normal)
        }
        tintColor = .label

        let letterSize: CGFloat = largeLabels ? 28 : 23
        let specialSize: CGFloat = largeLabels ? 18 : 15
        switch key {
        case .character:
            titleLabel?.font = .systemFont(ofSize: letterSize, weight: .regular)
        default:
            titleLabel?.font = .systemFont(ofSize: specialSize, weight: .medium)
        }
        refreshTitle()
    }

    /// Bascule l'affichage minuscules/majuscules des lettres.
    func updateCase(uppercase: Bool) {
        guard self.uppercase != uppercase else { return }
        self.uppercase = uppercase
        refreshTitle()
    }

    /// 0 = inactif, 1 = majuscule ponctuelle, 2 = verrouillage majuscules.
    func setShiftIndicator(state: Int) {
        let symbolName: String
        switch state {
        case 2: symbolName = "capslock.fill"
        case 1: symbolName = "shift.fill"
        default: symbolName = "shift"
        }
        setImage(symbolImage(symbolName), for: .normal)
    }

    private func refreshTitle() {
        switch key {
        case let .character(char):
            let title = uppercase ? char.uppercased(with: Locale(identifier: "fr_FR")) : char
            setTitle(title, for: .normal)
        case .space:
            setTitle("espace", for: .normal)
        case .numbers:
            setTitle("?123", for: .normal)
        case .letters:
            setTitle("ABC", for: .normal)
        case .symbols:
            setTitle("#+=", for: .normal)
        case .ret:
            setImage(symbolImage("return"), for: .normal)
        case .delete:
            setImage(symbolImage("delete.left"), for: .normal)
        case .shift:
            setImage(symbolImage("shift"), for: .normal)
        case .globe:
            setImage(symbolImage("globe"), for: .normal)
        }
    }

    private func symbolImage(_ name: String) -> UIImage? {
        UIImage(systemName: name, withConfiguration: UIImage.SymbolConfiguration(pointSize: largeLabels ? 20 : 17, weight: .medium))
    }

    private func configureAccessibility() {
        switch key {
        case let .character(char): accessibilityLabel = char
        case .shift: accessibilityLabel = "Majuscule"
        case .delete: accessibilityLabel = "Effacer"
        case .space: accessibilityLabel = "Espace"
        case .ret: accessibilityLabel = "Retour"
        case .numbers: accessibilityLabel = "Chiffres et ponctuation"
        case .letters: accessibilityLabel = "Lettres"
        case .symbols: accessibilityLabel = "Symboles"
        case .globe: accessibilityLabel = "Clavier suivant"
        }
    }

    // Retour visuel à l'appui : la touche s'assombrit légèrement.
    override var isHighlighted: Bool {
        didSet {
            alpha = isHighlighted ? 0.55 : 1.0
        }
    }
}
