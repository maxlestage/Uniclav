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
    private var layout = KeyboardSettings.layout
    private var scale = KeyboardSettings.keyboardScale
    private var keyHeight = KeyboardSettings.keyHeight

    /// Saisie groupée : suite des touches frappées pour le mot en cours…
    private var pendingSignature = ""
    /// …et le texte actuellement inséré dans le champ pour ce mot, qui sera
    /// remplacé à chaque nouvelle touche.
    private var pendingText = ""
    /// Majuscule demandée au moment de la première touche du mot.
    private var pendingCapitalized = false

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
    /// Largeur des touches de service de la rangée basse, en fraction de la
    /// rangée ; l'espace absorbe ce qui reste.
    private static let serviceKeyWidth: CGFloat = 0.14

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
        layout = KeyboardSettings.layout
        scale = KeyboardSettings.keyboardScale
        keyHeight = KeyboardSettings.keyHeight
        // Le champ de saisie a pu changer entre deux apparitions : on repart
        // d'un mot vide plutôt que d'effacer du texte qui ne nous appartient
        // plus.
        pendingSignature = ""
        pendingText = ""
        pendingCapitalized = false
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

        for row in currentLayer.rows(layout: layout) {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = Self.keySpacing
            rowStack.heightAnchor.constraint(equalToConstant: keyHeight).isActive = true

            // Une rangée sans espace répartit ses touches à parts égales ;
            // celle qui porte l'espace lui laisse la place restante.
            let hasSpace = row.contains(.space)
            rowStack.distribution = hasSpace ? .fill : .fillEqually

            for key in row {
                let button = KeyButton(key: key)
                configureActions(for: button)
                rowStack.addArrangedSubview(button)
                if key == .shift { shiftButton = button }
            }
            containerStack.addArrangedSubview(rowStack)
            rowStacks.append(rowStack)

            guard hasSpace else { continue }
            for case let button as KeyButton in rowStack.arrangedSubviews {
                if button.key == .space {
                    button.setContentHuggingPriority(.init(1), for: .horizontal)
                    button.setContentCompressionResistancePriority(.init(1), for: .horizontal)
                } else {
                    button.widthAnchor.constraint(equalTo: rowStack.widthAnchor,
                                                  multiplier: Self.serviceKeyWidth).isActive = true
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
        // Pendant la frappe groupée, la barre et le champ sont pilotés par
        // `refreshPending` : le contexte ne doit pas les contredire.
        guard pendingSignature.isEmpty else { return }
        showSuggestions(layout == .grouped ? [] : predictionEngine.suggestions(forPrefix: currentWord))
        applyAutoShiftIfNeeded()
    }

    private func showSuggestions(_ words: [String]) {
        for (index, button) in suggestionButtons.enumerated() {
            let word = index < words.count ? words[index] : nil
            button.setTitle(word, for: .normal)
            button.accessibilityLabel = word.map { "Suggestion : \($0)" }
            // Les emplacements vides s'effacent sans déplacer les autres.
            button.alpha = word == nil ? 0 : 1
            button.isUserInteractionEnabled = word != nil
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
            commitPending()
            insertCharacter(char)
        case let .letterGroup(index):
            appendGroup(index)
        case .shift:
            handleShiftTap()
        case .space:
            handleSpaceTap()
        case .ret:
            commitPending()
            learnCurrentWord()
            proxy.insertText("\n")
        case .numbers:
            switchLayer(to: .numbers)
        case .letters:
            switchLayer(to: .letters)
        case .symbols:
            switchLayer(to: .symbols)
        case .switchLayout:
            toggleLayout()
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
           pendingSignature.isEmpty,
           before.hasSuffix(" "),
           let beforeSpace = before.dropLast().last,
           beforeSpace.isLetter || beforeSpace.isNumber {
            proxy.deleteBackward()
            proxy.insertText(". ")
        } else {
            if pendingSignature.isEmpty {
                learnCurrentWord()
            } else {
                commitPending()
            }
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
        commitPending()
        currentLayer = layer
        rebuildRows()
        restyle()
    }

    private func toggleLayout() {
        commitPending()
        layout = layout == .azerty ? .grouped : .azerty
        KeyboardSettings.layout = layout
        currentLayer = .letters
        rebuildRows()
        restyle()
        showSuggestions([])
    }

    // MARK: - Saisie groupée

    /// Ajoute une touche au mot en cours et remplace, dans le champ, le mot
    /// affiché par le meilleur candidat du dictionnaire.
    private func appendGroup(_ index: Int) {
        if pendingSignature.isEmpty {
            pendingCapitalized = shiftState != .off
        }
        pendingSignature.append(String(index))
        refreshPending()
        if shiftState == .on {
            shiftState = .off
            updateShiftAppearance()
        }
    }

    private func refreshPending() {
        let candidates = predictionEngine.groupedCandidates(forSignature: pendingSignature)
        // Aucun mot connu : on montre au moins la première lettre de chaque
        // touche, pour que le champ réagisse à la frappe.
        let shown = candidates.isEmpty ? [LetterGroups.literal(for: pendingSignature)] : candidates
        let display = shown.map(capitalizedIfNeeded)
        replacePending(with: display[0])
        showSuggestions(display)
    }

    private func capitalizedIfNeeded(_ word: String) -> String {
        guard pendingCapitalized, let first = word.first else { return word }
        return String(first).uppercased(with: Locale(identifier: "fr_FR")) + word.dropFirst()
    }

    private func replacePending(with text: String) {
        let proxy = controller.textDocumentProxy
        for _ in 0..<pendingText.count {
            proxy.deleteBackward()
        }
        if !text.isEmpty {
            proxy.insertText(text)
        }
        pendingText = text
    }

    /// Fige le mot en cours : il devient du texte ordinaire et alimente
    /// l'apprentissage.
    private func commitPending() {
        guard !pendingSignature.isEmpty else { return }
        if !pendingText.isEmpty {
            predictionEngine.learn(word: pendingText)
        }
        pendingSignature = ""
        pendingText = ""
        pendingCapitalized = false
    }

    @objc private func suggestionTapped(_ button: UIButton) {
        guard let word = button.title(for: .normal), !word.isEmpty else { return }
        UIDevice.current.playInputClick()
        let proxy = controller.textDocumentProxy

        if pendingSignature.isEmpty {
            let typed = currentWord
            for _ in 0..<typed.count {
                proxy.deleteBackward()
            }
            // Préserve la majuscule initiale tapée par l'utilisateur.
            var final = word
            if let first = typed.first, first.isUppercase {
                final = String(word.prefix(1)).uppercased(with: Locale(identifier: "fr_FR")) + word.dropFirst()
            }
            proxy.insertText(final + " ")
            predictionEngine.learn(word: final)
        } else {
            replacePending(with: word)
            commitPending()
            proxy.insertText(" ")
        }
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
        performDelete()
        deleteTimer?.invalidate()
        // Après un délai, efface en continu — utile à une main pour
        // éviter les frappes répétées.
        deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.startRepeatingDelete()
        }
    }

    /// En saisie groupée, effacer retire la dernière touche frappée et
    /// recalcule le mot ; le texte validé n'est atteint qu'ensuite.
    private func performDelete() {
        if pendingSignature.isEmpty {
            controller.textDocumentProxy.deleteBackward()
        } else {
            pendingSignature.removeLast()
            if pendingSignature.isEmpty {
                replacePending(with: "")
                pendingCapitalized = false
                showSuggestions([])
            } else {
                refreshPending()
            }
        }
        updateFromContext()
    }

    private func startRepeatingDelete() {
        deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.09, repeats: true) { [weak self] _ in
            self?.performDelete()
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
