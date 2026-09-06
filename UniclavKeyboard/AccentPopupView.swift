import UIKit

/// Popup affiché au-dessus d'une touche lors d'un appui long, proposant les
/// variantes accentuées.
///
/// Deux façons de choisir, parce qu'une seule exclurait quelqu'un. En glissant
/// le doigt sans relâcher, comme sur iOS. Ou, si le doigt n'a pas bougé, en
/// relâchant puis en touchant la variante : le popup reste alors ouvert. Tenir
/// une touche immobile, glisser, puis relâcher au bon endroit fait trois gestes
/// précis enchaînés — c'est beaucoup demander à la main qu'on vise ici.
final class AccentPopupView: UIView {

    private let variants: [String]
    private let palette: KeyboardPalette
    private var labels: [UILabel] = []
    private var selectedIndex = 0

    /// Appelé quand une variante est touchée, le popup étant resté ouvert.
    var onPick: ((String) -> Void)?

    /// 50 pt de large : au-dessus du minimum tactile d'iOS, puisque la
    /// variante peut désormais être visée d'un appui.
    private let cellWidth: CGFloat = 50
    private let cellHeight: CGFloat = 56

    var selectedVariant: String? {
        variants.indices.contains(selectedIndex) ? variants[selectedIndex] : nil
    }

    init(variants: [String], palette: KeyboardPalette) {
        self.variants = variants
        self.palette = palette
        super.init(frame: .zero)
        backgroundColor = palette.keyFace.uiColor
        layer.cornerRadius = 10
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 4

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        for variant in variants {
            let label = UILabel()
            label.text = variant
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 26)
            label.layer.cornerRadius = 8
            label.layer.masksToBounds = true
            label.isAccessibilityElement = true
            label.accessibilityLabel = variant
            label.accessibilityTraits = .button
            stack.addArrangedSubview(label)
            labels.append(label)
        }
        highlight(index: 0)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) non géré") }

    /// Positionne le popup au-dessus de la touche, sans sortir de l'écran.
    func place(above keyFrame: CGRect, in bounds: CGRect) {
        let width = CGFloat(variants.count) * cellWidth
        var x = keyFrame.midX - width / 2
        x = max(4, min(x, bounds.maxX - width - 4))
        var y = keyFrame.minY - cellHeight - 8
        if y < 0 { y = keyFrame.maxY + 8 }
        frame = CGRect(x: x, y: y, width: width, height: cellHeight)
    }

    /// Laisse le popup ouvert : on choisit ensuite d'un appui, sans avoir à
    /// maintenir la touche. Plus rien n'est présélectionné — relâcher ne doit
    /// pas écrire une variante qu'on n'a pas visée.
    func enableTapSelection() {
        isUserInteractionEnabled = true
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(_:))))
        highlight(index: -1)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let index = Int(floor(gesture.location(in: self).x / cellWidth))
        guard variants.indices.contains(index) else { return }
        onPick?(variants[index])
    }

    /// Met à jour la variante sélectionnée selon la position du doigt.
    func updateSelection(for point: CGPoint) {
        guard let superview else { return }
        let local = superview.convert(point, to: self)
        let index = Int(floor(local.x / cellWidth))
        highlight(index: max(0, min(index, variants.count - 1)))
    }

    private func highlight(index: Int) {
        selectedIndex = index
        for (i, label) in labels.enumerated() {
            label.backgroundColor = i == index ? palette.keyText.uiColor : .clear
            label.textColor = i == index ? palette.keyFace.uiColor : palette.keyText.uiColor
        }
    }
}
