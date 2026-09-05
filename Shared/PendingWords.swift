import Foundation

/// File d'attente des mots que le clavier n'a pas reconnus.
///
/// L'extension ne peut pas interroger le Wiktionnaire elle-même ; elle se
/// contente de noter le mot. L'application le vérifie à sa prochaine mise à
/// jour et, s'il s'agit bien d'un mot français, l'ajoute définitivement au
/// dictionnaire — avec ses accents.
enum PendingWords {
    private static let storageKey = "pendingWiktionaryWords"
    /// Au-delà, on oublie les plus anciens : la file n'est pas un journal.
    private static let maximum = 300

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: KeyboardSettings.appGroupID) ?? .standard
    }

    static var all: [String] {
        defaults.stringArray(forKey: storageKey) ?? []
    }

    static func enqueue(_ word: String) {
        var queue = all
        guard !queue.contains(word) else { return }
        queue.append(word)
        if queue.count > maximum {
            queue.removeFirst(queue.count - maximum)
        }
        defaults.set(queue, forKey: storageKey)
    }

    /// Retire les mots traités, qu'ils aient été confirmés ou non : un mot
    /// que le Wiktionnaire ignore ne doit pas être redemandé sans fin.
    static func remove(_ words: [String]) {
        let handled = Set(words)
        defaults.set(all.filter { !handled.contains($0) }, forKey: storageKey)
    }
}
