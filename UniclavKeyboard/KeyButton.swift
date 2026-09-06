import UIKit

/// Une touche du clavier, avec son style et son libellé.
final class KeyButton: UIButton {

    let key: Key
    private var uppercase = false
    private var largeLabels = true
    private var highContrast = false
    private var palette = KeyboardSettings.palette

    init(key: Key) {
        self.key = key
        super.init(frame: .zero)
        layer.cornerRadius = 9
        layer.shadowColor = UIColor.black.cgColor  // l'ombre reste neutre
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowOpacity = 0.25
        layer.shadowRadius = 0
        translatesAutoresizingMaskIntoConstraints = false
        applyStyle(largeLabels: true, highContrast: false, shiftActive: false,
                   palette: KeyboardSettings.palette)
        refreshTitle()
        configureAccessibility()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) non géré") }

    func applyStyle(largeLabels: Bool, highContrast: Bool, shiftActive: Bool,
                    palette: KeyboardPalette) {
        self.largeLabels = largeLabels
        self.highContrast = highContrast
        self.palette = palette

        let isSpecial: Bool
        switch key {
        case .character, .space, .letterGroup:
            isSpecial = false
        default:
            isSpecial = true
        }

        // Le contraste renforcé pousse les touches de service vers la même
        // teinte que les lettres : elles cessent d'être un aplat discret.
        let face = isSpecial
            ? (highContrast
               ? palette.keyFace.blended(toward: palette.keyText, amount: 0.34)
               : palette.specialKeyFace)
            : palette.keyFace
        backgroundColor = face.uiColor
        setTitleColor(palette.keyText.uiColor, for: .normal)
        tintColor = palette.keyText.uiColor

        let letterSize: CGFloat = largeLabels ? 28 : 23
        let specialSize: CGFloat = largeLabels ? 18 : 15
        switch key {
        case .character:
            titleLabel?.font = .systemFont(ofSize: letterSize, weight: .regular)
        case .letterGroup:
            // « MNOPQ » est le libellé le plus long : il doit tenir sans
            // déborder, quitte à se réduire.
            titleLabel?.font = .systemFont(ofSize: largeLabels ? 21 : 18, weight: .semibold)
            titleLabel?.adjustsFontSizeToFitWidth = true
            titleLabel?.minimumScaleFactor = 0.55
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
        case let .letterGroup(_, letters):
            setTitle(letters.uppercased(), for: .normal)
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
        case .switchLayout:
            setImage(symbolImage("square.grid.2x2"), for: .normal)
        }
    }

    private func symbolImage(_ name: String) -> UIImage? {
        UIImage(systemName: name, withConfiguration: UIImage.SymbolConfiguration(pointSize: largeLabels ? 20 : 17, weight: .medium))
    }

    private func configureAccessibility() {
        switch key {
        case let .character(char): accessibilityLabel = char
        case let .letterGroup(_, letters):
            accessibilityLabel = "Lettres " + letters.uppercased()
        case .shift: accessibilityLabel = "Majuscule"
        case .delete: accessibilityLabel = "Effacer"
        case .space: accessibilityLabel = "Espace"
        case .ret: accessibilityLabel = "Retour"
        case .numbers: accessibilityLabel = "Chiffres et ponctuation"
        case .letters: accessibilityLabel = "Lettres"
        case .symbols: accessibilityLabel = "Symboles"
        case .globe: accessibilityLabel = "Clavier suivant"
        case .switchLayout: accessibilityLabel = "Changer de disposition"
        }
    }

    // Retour visuel à l'appui : la touche s'assombrit légèrement.
    override var isHighlighted: Bool {
        didSet {
            alpha = isHighlighted ? 0.55 : 1.0
        }
    }
}
