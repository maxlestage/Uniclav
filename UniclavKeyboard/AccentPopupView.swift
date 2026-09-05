import UIKit

/// Popup affiché au-dessus d'une touche lors d'un appui long, proposant les
/// variantes accentuées. La sélection se fait en glissant le doigt.
final class AccentPopupView: UIView {

    private let variants: [String]
    private var labels: [UILabel] = []
    private var selectedIndex = 0

    private let cellWidth: CGFloat = 46
    private let cellHeight: CGFloat = 54

    var selectedVariant: String? {
        variants.indices.contains(selectedIndex) ? variants[selectedIndex] : nil
    }

    init(variants: [String]) {
        self.variants = variants
        super.init(frame: .zero)
        backgroundColor = .systemBackground
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
            label.backgroundColor = i == index ? .systemBlue : .clear
            label.textColor = i == index ? .white : .label
        }
    }
}
