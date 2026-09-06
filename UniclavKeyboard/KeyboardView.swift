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
    /// Voile transparent posé sous un popup resté ouvert : un appui à côté le
    /// ferme, sans atteindre la touche qui se trouve dessous.
    private var popupDismissLayer: UIView?
    /// Le doigt a-t-il glissé depuis le début de l'appui long ? S'il n'a pas
    /// bougé, relâcher laisse le popup ouvert au lieu de choisir à l'aveugle.
    private var longPressMoved = false
    private var longPressOrigin: CGPoint = .zero
    /// Au carré, pour comparer sans racine carrée.
    private static let longPressMoveThreshold: CGFloat = 12 * 12

    private var handSide = KeyboardSettings.handSide
    /// Le mode choisi dans l'application.
    private var layout = KeyboardSettings.layout
    /// Repli temporaire vers l'AZERTY, le temps d'écrire un mot que le
    /// dictionnaire ignore — un nom propre, le plus souvent. La touche ⊞ fait
    /// l'aller-retour : avec cinq modes, les faire défiler éloignerait la
    /// sortie de secours au lieu de la rapprocher.
    private var usingFallback = false
    private var scale = KeyboardSettings.keyboardScale
    private var keyHeight = KeyboardSettings.keyHeight

    /// Saisie groupée : suite des touches frappées pour le mot en cours…
    private var pendingSignature = ""
    /// …et le texte actuellement inséré dans le champ pour ce mot, qui sera
    /// remplacé à chaque nouvelle touche.
    private var pendingText = ""
    /// Majuscule demandée au moment de la première touche du mot.
    private var pendingCapitalized = false

    /// Appuis répétés : touche en cours de cyclage, rang de la lettre
    /// affichée, et le compte à rebours qui valide la lettre.
    private var multiTapGroup: Int?
    private var multiTapIndex = 0
    private var multiTapTimer: Timer?

    private var palette = KeyboardSettings.palette

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
    /// Largeur d'une touche de service de la rangée basse, en fraction de la
    /// rangée ; l'espace absorbe ce qui reste. Elle se resserre quand les
    /// touches de service se multiplient, pour que l'espace — la plus grande
    /// cible du clavier, et la plus utilisée — ne descende jamais sous le
    /// tiers de la rangée.
    private static let maximumServiceKeyWidth: CGFloat = 0.14
    private static let minimumSpaceShare: CGFloat = 0.33

    private static func serviceKeyWidth(forServiceKeys count: Int) -> CGFloat {
        guard count > 0 else { return maximumServiceKeyWidth }
        return min(maximumServiceKeyWidth, (1 - minimumSpaceShare) / CGFloat(count))
    }

    /// Disposition réellement affichée, repli compris.
    private var effectiveLayout: KeyboardSettings.Layout {
        usingFallback ? .azerty : layout
    }

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
        dismissAccentPopup()
        handSide = KeyboardSettings.handSide
        layout = KeyboardSettings.layout
        palette = KeyboardSettings.palette
        usingFallback = false
        commitMultiTap()
        predictionEngine.prepare(grouping: effectiveLayout.grouping)
        scale = KeyboardSettings.keyboardScale
        keyHeight = KeyboardSettings.keyHeight
        // Le champ de saisie a pu changer entre deux apparitions : on repart
        // d'un mot vide plutôt que d'effacer du texte qui ne nous appartient
        // plus.
        pendingSignature = ""
        pendingText = ""
        pendingCapitalized = false
        // On revient toujours aux lettres : rester sur le pavé accentué ou
        // les chiffres d'une saisie précédente ferait chercher l'alphabet.
        currentLayer = .letters
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

        for row in currentLayer.rows(layout: effectiveLayout) {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = Self.keySpacing
            rowStack.heightAnchor.constraint(equalToConstant: keyHeight).isActive = true

            // Une rangée sans espace répartit ses touches à parts égales ;
            // celle qui porte l'espace lui laisse la place restante.
            let hasSpace = row.contains(.space)
            rowStack.distribution = hasSpace ? .fill : .fillEqually

            // En AZERTY, la touche de repli n'aurait nulle part où mener.
            for key in row where !(key == .switchLayout && layout == .azerty) {
                let button = KeyButton(key: key)
                configureActions(for: button)
                rowStack.addArrangedSubview(button)
                if key == .shift { shiftButton = button }
            }
            containerStack.addArrangedSubview(rowStack)
            rowStacks.append(rowStack)

            guard hasSpace else { continue }
            let serviceCount = rowStack.arrangedSubviews
                .compactMap { $0 as? KeyButton }
                .filter { $0.key != .space }
                .count
            let width = Self.serviceKeyWidth(forServiceKeys: serviceCount)
            for case let button as KeyButton in rowStack.arrangedSubviews {
                if button.key == .space {
                    button.setContentHuggingPriority(.init(1), for: .horizontal)
                    button.setContentCompressionResistancePriority(.init(1), for: .horizontal)
                } else {
                    button.widthAnchor.constraint(equalTo: rowStack.widthAnchor,
                                                  multiplier: width).isActive = true
                }
            }
        }
    }

    private func configureActions(for button: KeyButton) {
        switch button.key {
        case .character, .letterGroup:
            button.addTarget(self, action: #selector(keyTapped(_:)), for: .touchUpInside)
            if !button.key.longPressVariants.isEmpty {
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
                button.applyStyle(largeLabels: large, highContrast: contrast,
                                  shiftActive: shiftState != .off, palette: palette)
            }
        }
        updateShiftAppearance()
        backgroundColor = palette.backdrop.uiColor
        for button in suggestionButtons {
            button.backgroundColor = palette.specialKeyFace.uiColor
            button.setTitleColor(palette.keyText.uiColor, for: .normal)
        }
        sideSwitchButton.tintColor = palette.keyText.uiColor
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
        // Hors frappe groupée, le texte du champ est réel dans tous les modes :
        // la prédiction par préfixe s'applique donc partout, y compris en
        // grosses touches, où elle prend le relais dès qu'une lettre a été
        // écrite autrement — au pavé accentué, par exemple. La réserver aux
        // modes sans dictionnaire laissait la barre vide précisément là où
        // elle aurait servi.
        showSuggestions(predictionEngine.suggestions(forPrefix: currentWord))
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
        case let .letterGroup(index, _):
            if effectiveLayout.usesDictionary {
                appendGroup(index)
            } else {
                handleMultiTap(index)
            }
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
        case .special:
            switchLayer(to: .special)
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
        commitMultiTap()
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
        dismissAccentPopup()
        commitPending()
        currentLayer = layer
        rebuildRows()
        restyle()
    }

    /// Aller-retour vers l'AZERTY. Le mode choisi n'est pas modifié : on
    /// revient à celui-ci en touchant ⊞ de nouveau.
    private func toggleLayout() {
        dismissAccentPopup()
        commitPending()
        usingFallback.toggle()
        predictionEngine.prepare(grouping: effectiveLayout.grouping)
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
        guard effectiveLayout.usesDictionary, let grouping = effectiveLayout.grouping else { return }
        let matches = predictionEngine.groupedMatches(forSignature: pendingSignature)
        // Le champ montre un mot de la longueur frappée, pour qu'effacer se
        // voie. À défaut de mot connu, la première lettre de chaque touche :
        // le texte est faux, mais il réagit à la frappe.
        let typed = matches.exact.first ?? LetterGroups.literal(for: pendingSignature, grouping: grouping)
        replacePending(with: capitalizedIfNeeded(typed))
        // Les complétions restent offertes dans la barre, à une touche.
        let bar = Array((matches.exact + matches.completions).prefix(3))
        showSuggestions(bar.map(capitalizedIfNeeded))
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
        commitMultiTap()
        guard !pendingSignature.isEmpty else { return }
        if !pendingText.isEmpty {
            predictionEngine.learn(word: pendingText)
        }
        pendingSignature = ""
        pendingText = ""
        pendingCapitalized = false
    }

    // MARK: - Appuis répétés

    /// Chaque appui sur la même touche remplace la lettre par la suivante du
    /// groupe. Passé le délai, la lettre est validée et l'appui suivant
    /// recommence un cycle — c'est ce qui permet d'écrire deux lettres de la
    /// même touche à la suite.
    private func handleMultiTap(_ index: Int) {
        guard let grouping = effectiveLayout.grouping else { return }
        let groups = grouping.groups
        guard groups.indices.contains(index) else { return }
        let letters = Array(groups[index])
        guard !letters.isEmpty else { return }

        let proxy = controller.textDocumentProxy
        if multiTapGroup == index {
            multiTapIndex = (multiTapIndex + 1) % letters.count
            proxy.deleteBackward()
        } else {
            multiTapGroup = index
            multiTapIndex = 0
        }

        let letter = String(letters[multiTapIndex])
        proxy.insertText(shiftState != .off
                         ? letter.uppercased(with: Locale(identifier: "fr_FR"))
                         : letter)
        if shiftState == .on {
            shiftState = .off
            updateShiftAppearance()
        }

        multiTapTimer?.invalidate()
        multiTapTimer = Timer.scheduledTimer(withTimeInterval: KeyboardSettings.multiTapDelay,
                                             repeats: false) { [weak self] _ in
            self?.commitMultiTap()
        }
    }

    /// Fige la lettre en cours : le prochain appui sur la même touche
    /// écrira une nouvelle lettre au lieu de remplacer celle-ci.
    private func commitMultiTap() {
        multiTapTimer?.invalidate()
        multiTapTimer = nil
        multiTapGroup = nil
        multiTapIndex = 0
    }

    @objc private func suggestionTapped(_ button: UIButton) {
        guard let word = button.title(for: .normal), !word.isEmpty else { return }
        UIDevice.current.playInputClick()
        let proxy = controller.textDocumentProxy
        // Sans cela, la lettre encore en cours de cyclage restait « vivante » :
        // le prochain appui sur sa touche effaçait la dernière lettre du mot
        // qu'on venait de choisir.
        commitMultiTap()

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
            commitMultiTap()
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
        guard let button = gesture.view as? KeyButton else { return }
        let variants = button.key.longPressVariants
        guard !variants.isEmpty else { return }

        switch gesture.state {
        case .began:
            dismissAccentPopup()
            longPressMoved = false
            longPressOrigin = gesture.location(in: self)
            let displayed = shiftState != .off
                ? variants.map { $0.uppercased(with: Locale(identifier: "fr_FR")) }
                : variants
            let popup = AccentPopupView(variants: displayed)
            popup.onPick = { [weak self] variant in
                self?.insertVariant(variant)
                self?.dismissAccentPopup()
            }
            addSubview(popup)
            let buttonFrame = button.convert(button.bounds, to: self)
            popup.place(above: buttonFrame, in: bounds)
            accentPopup = popup
        case .changed:
            let point = gesture.location(in: self)
            let dx = point.x - longPressOrigin.x
            let dy = point.y - longPressOrigin.y
            if dx * dx + dy * dy > Self.longPressMoveThreshold {
                longPressMoved = true
            }
            guard longPressMoved else { return }
            accentPopup?.updateSelection(for: point)
        case .ended:
            // Le doigt a glissé : on écrit la variante survolée, comme sur iOS.
            // Il n'a pas bougé : le popup reste, et la variante se touche.
            if longPressMoved {
                if let selected = accentPopup?.selectedVariant {
                    insertVariant(selected)
                }
                dismissAccentPopup()
            } else {
                latchAccentPopup()
            }
        case .cancelled, .failed:
            dismissAccentPopup()
        default:
            break
        }
    }

    /// Écrit une variante comme une lettre ordinaire : elle interrompt le mot
    /// groupé en cours et le cycle d'appuis répétés, sans quoi la touche
    /// suivante effacerait la lettre qu'on vient de choisir.
    private func insertVariant(_ variant: String) {
        commitPending()
        controller.textDocumentProxy.insertText(variant)
        if shiftState == .on {
            shiftState = .off
            updateShiftAppearance()
        }
        updateFromContext()
    }

    /// Laisse le popup ouvert, sous un voile qui absorbe l'appui à côté.
    private func latchAccentPopup() {
        guard let popup = accentPopup else { return }
        let veil = UIView(frame: bounds)
        veil.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        veil.backgroundColor = .clear
        veil.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                         action: #selector(dismissAccentPopupFromTap)))
        insertSubview(veil, belowSubview: popup)
        popupDismissLayer = veil
        popup.enableTapSelection()
    }

    @objc private func dismissAccentPopupFromTap() {
        dismissAccentPopup()
    }

    private func dismissAccentPopup() {
        accentPopup?.removeFromSuperview()
        accentPopup = nil
        popupDismissLayer?.removeFromSuperview()
        popupDismissLayer = nil
    }
}
