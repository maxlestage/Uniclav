import UIKit

/// Vue principale du clavier : barre de suggestions + touches, le tout
/// regroupé du côté de la main valide de l'utilisateur.
final class KeyboardView: UIView, UIInputViewAudioFeedback {

    // MARK: - État

    private enum ShiftState {
        case off, on, locked
    }

    private unowned let controller: KeyboardViewController
    private let predictionEngine = PredictionEngine()

    private var currentLayer: KeyboardLayer = .letters
    private var shiftState: ShiftState = .off
    private var lastShiftTap: Date = .distantPast
    private var lastSpaceTap: Date = .distantPast
    private var deleteTimer: Timer?
    private var accentPopup: AccentPopupView?

    private var handSide = KeyboardSettings.handSide
    private var scale = KeyboardSettings.keyboardScale
    private var keyHeight = KeyboardSettings.keyHeight

    // MARK: - Sous-vues

    private let containerStack = UIStackView()
    private let suggestionStack = UIStackView()
    private var suggestionButtons: [UIButton] = []
    private var rowStacks: [UIStackView] = []
    private var shiftButton: KeyButton?
    private let sideSwitchButton = UIButton(type: .system)
    private var containerConstraints: [NSLayoutConstraint] = []

    private static let suggestionBarHeight: CGFloat = 46
    private static let rowSpacing: CGFloat = 8
    private static let keySpacing: CGFloat = 5
    private static let outerPadding: CGFloat = 4

    static var preferredHeight: CGFloat {
        suggestionBarHeight + 4 * KeyboardSettings.keyHeight + 3 * rowSpacing + 2 * outerPadding + 8
    }

    var enableInputClicksWhenVisible: Bool { true }

    // MARK: - Initialisation

    init(controller: KeyboardViewController) {
        self.controller = controller
        super.init(frame: .zero)
        backgroundColor = .clear
        buildStructure()
        reloadConfiguration()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) non géré") }

    private func buildStructure() {
        containerStack.axis = .vertical
        containerStack.spacing = Self.rowSpacing
        containerStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStack)

        suggestionStack.axis = .horizontal
        suggestionStack.distribution = .fillEqually
        suggestionStack.spacing = 6
        for index in 0..<3 {
            let button = UIButton(type: .system)
            button.titleLabel?.font = .systemFont(ofSize: 19, weight: .medium)
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            button.titleLabel?.minimumScaleFactor = 0.6
            button.layer.cornerRadius = 8
            button.tag = index
            button.addTarget(self, action: #selector(suggestionTapped(_:)), for: .touchUpInside)
            suggestionStack.addArrangedSubview(button)
            suggestionButtons.append(button)
        }
        suggestionStack.heightAnchor.constraint(equalToConstant: Self.suggestionBarHeight).isActive = true
        containerStack.addArrangedSubview(suggestionStack)

        sideSwitchButton.setImage(
            UIImage(systemName: "arrow.left.arrow.right",
                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)),
            for: .normal)
        sideSwitchButton.accessibilityLabel = "Changer le clavier de côté"
        sideSwitchButton.addTarget(self, action: #selector(switchSide), for: .touchUpInside)
        sideSwitchButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(sideSwitchButton)
    }

    // MARK: - Configuration (réglages + plan de touches)

    /// Relit les réglages partagés et reconstruit le clavier.
    func reloadConfiguration() {
        handSide = KeyboardSettings.handSide
        scale = KeyboardSettings.keyboardScale
        keyHeight = KeyboardSettings.keyHeight
        rebuildRows()
        layoutContainer()
        restyle()
    }

    private func layoutContainer() {
        NSLayoutConstraint.deactivate(containerConstraints)
        var constraints: [NSLayoutConstraint] = [
            containerStack.topAnchor.constraint(equalTo: topAnchor, constant: Self.outerPadding),
            containerStack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -Self.outerPadding),
            containerStack.widthAnchor.constraint(equalTo: widthAnchor, multiplier: scale, constant: -2 * Self.outerPadding),
        ]
        switch handSide {
        case .left:
            constraints.append(containerStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.outerPadding))
            constraints.append(sideSwitchButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10))
        case .right:
            constraints.append(containerStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.outerPadding))
            constraints.append(sideSwitchButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10))
        }
        constraints.append(sideSwitchButton.centerYAnchor.constraint(equalTo: containerStack.centerYAnchor))
        containerConstraints = constraints
        NSLayoutConstraint.activate(constraints)
        sideSwitchButton.isHidden = scale > 0.94
    }

    private func rebuildRows() {
        rowStacks.forEach { $0.removeFromSuperview() }
        rowStacks = []
        shiftButton = nil

        var referenceKey: KeyButton?
        for row in currentLayer.rows {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = Self.keySpacing
            rowStack.distribution = .fill
            rowStack.heightAnchor.constraint(equalToConstant: keyHeight).isActive = true

            var rowUnitKeys: [KeyButton] = []
            for key in row {
                let button = KeyButton(key: key)
                configureActions(for: button)
                rowStack.addArrangedSubview(button)
                switch key {
                case .character:
                    rowUnitKeys.append(button)
                    if referenceKey == nil { referenceKey = button }
                case .shift:
                    shiftButton = button
                default:
                    break
                }
            }
            containerStack.addArrangedSubview(rowStack)
            rowStacks.append(rowStack)

            // Toutes les touches « lettre » d'une rangée ont la même largeur.
            if let first = rowUnitKeys.first {
                for other in rowUnitKeys.dropFirst() {
                    other.widthAnchor.constraint(equalTo: first.widthAnchor).isActive = true
                }
            }
        }

        // Largeurs des touches spéciales, relatives à une touche lettre.
        guard let reference = referenceKey else { return }
        for rowStack in rowStacks {
            for case let button as KeyButton in rowStack.arrangedSubviews {
                switch button.key {
                case .shift, .delete, .numbers, .letters, .symbols:
                    button.widthAnchor.constraint(equalTo: reference.widthAnchor, multiplier: 1.35).isActive = true
                case .globe:
                    button.widthAnchor.constraint(equalTo: reference.widthAnchor, multiplier: 1.1).isActive = true
                case .ret:
                    button.widthAnchor.constraint(equalTo: reference.widthAnchor, multiplier: 1.9).isActive = true
                case .space, .character:
                    break // l'espace s'étire, les lettres sont déjà contraintes
                }
                if case .space = button.key {
                    button.setContentHuggingPriority(.init(1), for: .horizontal)
                    button.setContentCompressionResistancePriority(.init(1), for: .horizontal)
                }
            }
        }
    }

    private func configureActions(for button: KeyButton) {
        switch button.key {
        case .character:
            button.addTarget(self, action: #selector(keyTapped(_:)), for: .touchUpInside)
            if case let .character(char) = button.key, Key.accentVariants[char] != nil {
                let longPress = UILongPressGestureRecognizer(target: self, action: #selector(keyLongPressed(_:)))
                longPress.minimumPressDuration = 0.35
                button.addGestureRecognizer(longPress)
            }
        case .delete:
            button.addTarget(self, action: #selector(deleteTouchDown), for: .touchDown)
            button.addTarget(self, action: #selector(deleteTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
        case .globe:
            button.addTarget(controller, action: #selector(UIInputViewController.handleInputModeList(from:with:)), for: .allTouchEvents)
        default:
            button.addTarget(self, action: #selector(keyTapped(_:)), for: .touchUpInside)
        }
    }

    private func restyle() {
        let large = KeyboardSettings.largeLabels
        let contrast = KeyboardSettings.highContrast
        for rowStack in rowStacks {
            for case let button as KeyButton in rowStack.arrangedSubviews {
                button.applyStyle(largeLabels: large, highContrast: contrast, shiftActive: shiftState != .off)
            }
        }
        updateShiftAppearance()
        let suggestionBackground: UIColor = contrast
            ? UIColor.label.withAlphaComponent(0.12)
            : UIColor.secondarySystemFill
        for button in suggestionButtons {
            button.backgroundColor = suggestionBackground
            button.setTitleColor(.label, for: .normal)
        }
        sideSwitchButton.tintColor = .label
    }

    // MARK: - Contexte et suggestions

    /// Mot en cours de frappe, extrait du contexte du champ de texte.
    private var currentWord: String {
        guard let before = controller.textDocumentProxy.documentContextBeforeInput else { return "" }
        let separators = CharacterSet.letters.union(CharacterSet(charactersIn: "'’-")).inverted
        if let range = before.rangeOfCharacter(from: separators, options: .backwards) {
            return String(before[range.upperBound...])
        }
        return before
    }

    /// À appeler quand le texte du champ change : met à jour suggestions,
    /// majuscule automatique et libellés des touches.
    func updateFromContext() {
        updateSuggestions()
        applyAutoShiftIfNeeded()
    }

    private func updateSuggestions() {
        let suggestions = predictionEngine.suggestions(forPrefix: currentWord)
        for (index, button) in suggestionButtons.enumerated() {
            if index < suggestions.count {
                button.setTitle(suggestions[index], for: .normal)
                button.isHidden = false
                button.accessibilityLabel = "Suggestion : \(suggestions[index])"
            } else {
                button.setTitle(nil, for: .normal)
                button.isHidden = suggestions.isEmpty ? false : true
            }
        }
    }

    private func applyAutoShiftIfNeeded() {
        guard shiftState != .locked, currentLayer == .letters else { return }
        let before = controller.textDocumentProxy.documentContextBeforeInput ?? ""
        let trimmed = before.trimmingCharacters(in: .whitespacesAndNewlines)
        let shouldCapitalize = trimmed.isEmpty
            || (before.hasSuffix(" ") || before.hasSuffix("\n"))
                && [".", "!", "?"].contains(where: { trimmed.hasSuffix($0) })
        if shouldCapitalize != (shiftState == .on) {
            shiftState = shouldCapitalize ? .on : .off
            updateShiftAppearance()
        }
    }

    private func updateShiftAppearance() {
        for rowStack in rowStacks {
            for case let button as KeyButton in rowStack.arrangedSubviews {
                button.updateCase(uppercase: shiftState != .off)
            }
        }
        shiftButton?.setShiftIndicator(state: shiftState == .locked ? 2 : (shiftState == .on ? 1 : 0))
    }

    // MARK: - Actions des touches

    @objc private func keyTapped(_ button: KeyButton) {
        UIDevice.current.playInputClick()
        let proxy = controller.textDocumentProxy
        switch button.key {
        case let .character(char):
            insertCharacter(char)
        case .shift:
            handleShiftTap()
        case .space:
            handleSpaceTap()
        case .ret:
            learnCurrentWord()
            proxy.insertText("\n")
        case .numbers:
            switchLayer(to: .numbers)
        case .letters:
            switchLayer(to: .letters)
        case .symbols:
            switchLayer(to: .symbols)
        case .delete, .globe:
            break // gérés séparément
        }
        updateFromContext()
    }

    private func insertCharacter(_ char: String) {
        let text = shiftState != .off ? char.uppercased(with: Locale(identifier: "fr_FR")) : char
        controller.textDocumentProxy.insertText(text)
        if shiftState == .on {
            shiftState = .off
            updateShiftAppearance()
        }
    }

    private func handleShiftTap() {
        let now = Date()
        if now.timeIntervalSince(lastShiftTap) < 0.35 {
            shiftState = .locked
        } else {
            shiftState = shiftState == .off ? .on : .off
        }
        lastShiftTap = now
        updateShiftAppearance()
    }

    private func handleSpaceTap() {
        let proxy = controller.textDocumentProxy
        let now = Date()
        let before = proxy.documentContextBeforeInput ?? ""
        // Double espace -> « . » suivi d'un espace, comme le clavier iOS.
        if now.timeIntervalSince(lastSpaceTap) < 0.45,
           before.hasSuffix(" "),
           let beforeSpace = before.dropLast().last,
           beforeSpace.isLetter || beforeSpace.isNumber {
            proxy.deleteBackward()
            proxy.insertText(". ")
        } else {
            learnCurrentWord()
            proxy.insertText(" ")
        }
        lastSpaceTap = now
    }

    private func learnCurrentWord() {
        let word = currentWord
        guard !word.isEmpty else { return }
        predictionEngine.learn(word: word)
    }

    private func switchLayer(to layer: KeyboardLayer) {
        currentLayer = layer
        rebuildRows()
        restyle()
    }

    @objc private func suggestionTapped(_ button: UIButton) {
        guard let word = button.title(for: .normal), !word.isEmpty else { return }
        UIDevice.current.playInputClick()
        let proxy = controller.textDocumentProxy
        let typed = currentWord
        for _ in 0..<typed.count {
            proxy.deleteBackward()
        }
        // Préserve la majuscule initiale tapée par l'utilisateur.
        var final = word
        if let first = typed.first, first.isUppercase {
            final = word.prefix(1).uppercased(with: Locale(identifier: "fr_FR")) + word.dropFirst()
        }
        proxy.insertText(final + " ")
        predictionEngine.learn(word: final)
        updateFromContext()
    }

    @objc private func switchSide() {
        handSide = handSide == .left ? .right : .left
        KeyboardSettings.handSide = handSide
        layoutContainer()
    }

    // MARK: - Effacement (avec répétition)

    @objc private func deleteTouchDown() {
        UIDevice.current.playInputClick()
        controller.textDocumentProxy.deleteBackward()
        updateFromContext()
        deleteTimer?.invalidate()
        // Après un délai, efface en continu — utile à une main pour
        // éviter les frappes répétées.
        deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.startRepeatingDelete()
        }
    }

    private func startRepeatingDelete() {
        deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.09, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.controller.textDocumentProxy.deleteBackward()
            self.updateFromContext()
        }
    }

    @objc private func deleteTouchUp() {
        deleteTimer?.invalidate()
        deleteTimer = nil
    }

    // MARK: - Accents par appui long

    @objc private func keyLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard let button = gesture.view as? KeyButton,
              case let .character(char) = button.key,
              let variants = Key.accentVariants[char] else { return }

        switch gesture.state {
        case .began:
            let displayed = shiftState != .off
                ? variants.map { $0.uppercased(with: Locale(identifier: "fr_FR")) }
                : variants
            let popup = AccentPopupView(variants: displayed)
            addSubview(popup)
            let buttonFrame = button.convert(button.bounds, to: self)
            popup.place(above: buttonFrame, in: bounds)
            accentPopup = popup
        case .changed:
            accentPopup?.updateSelection(for: gesture.location(in: self))
        case .ended:
            if let selected = accentPopup?.selectedVariant {
                controller.textDocumentProxy.insertText(selected)
                if shiftState == .on {
                    shiftState = .off
                    updateShiftAppearance()
                }
                updateFromContext()
            }
            dismissAccentPopup()
        case .cancelled, .failed:
            dismissAccentPopup()
        default:
            break
        }
    }

    private func dismissAccentPopup() {
        accentPopup?.removeFromSuperview()
        accentPopup = nil
    }
}
