import UIKit

/// Point d'entrée de l'extension clavier.
final class KeyboardViewController: UIInputViewController {

    private var keyboardView: KeyboardView?
    private var heightConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()

        let keyboard = KeyboardView(controller: self)
        keyboard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(keyboard)
        NSLayoutConstraint.activate([
            keyboard.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboard.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keyboard.topAnchor.constraint(equalTo: view.topAnchor),
            keyboard.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        keyboardView = keyboard
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Recharge les réglages (l'utilisateur a pu les changer dans l'app)
        // et ajuste la hauteur totale du clavier en conséquence.
        keyboardView?.reloadConfiguration()
        let height = KeyboardView.preferredHeight
        if let constraint = heightConstraint {
            constraint.constant = height
        } else {
            let constraint = view.heightAnchor.constraint(equalToConstant: height)
            constraint.priority = .init(999)
            constraint.isActive = true
            heightConstraint = constraint
        }
        keyboardView?.updateFromContext()
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        keyboardView?.updateFromContext()
    }
}
