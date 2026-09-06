import Foundation
import BackgroundTasks

/// Enrichissement du dictionnaire depuis le Wiktionnaire.
///
/// Deux sources, dans cet ordre : le vocabulaire de base du Wiktionnaire, une
/// fois pour toutes, puis les mots que le clavier n'a pas su reconnaître —
/// ceux-là comptent le plus, puisque ce sont ceux que cette personne écrit.
enum DictionaryUpdate {
    static let taskIdentifier = "com.maxlestage.uniclav.dictionary-refresh"
    /// Un dictionnaire bouge lentement, et l'API limite le débit : une fois
    /// par jour suffit largement.
    static let minimumInterval: TimeInterval = 24 * 3600

    struct Result {
        let added: Int
        let total: Int
    }

    /// Renvoie nil quand il n'y avait rien à faire (mise à jour trop récente
    /// ou désactivée).
    @discardableResult
    static func run(force: Bool) async throws -> Result? {
        if !force {
            guard KeyboardSettings.autoUpdateDictionary else { return nil }
            if let last = KeyboardSettings.lastDictionaryUpdate,
               Date().timeIntervalSince(last) < minimumInterval {
                return nil
            }
        }

        let client = WiktionaryClient()
        var words = DictionaryStore.loadWords()
        var known = Set(words.map { PredictionEngine.normalize($0) })
        var added = 0

        // Les nouveaux mots sont ajoutés en fin de liste. Le classement par
        // fréquence de la base d'origine reste donc intact : c'est lui qui
        // permet aux grosses touches de trancher entre « vous » et « tous ».
        func append(_ candidates: [String]) {
            for word in candidates {
                guard known.insert(PredictionEngine.normalize(word)).inserted else { continue }
                words.append(word)
                added += 1
            }
        }

        if !KeyboardSettings.coreVocabularyMerged {
            append(try await client.coreVocabulary())
            KeyboardSettings.coreVocabularyMerged = true
        }

        let pending = KeyboardSettings.shareUnknownWords ? PendingWords.all : []
        if !pending.isEmpty {
            append(try await client.frenchWords(among: pending))
            PendingWords.remove(pending)
        }

        if added > 0 {
            try DictionaryStore.save(words: words)
        }
        KeyboardSettings.lastDictionaryUpdate = Date()
        KeyboardSettings.dictionaryWordCount = words.count
        return Result(added: added, total: words.count)
    }

    /// Demande au système une prochaine exécution en arrière-plan. iOS décide
    /// du moment réel selon l'usage de l'appareil ; rien ne garantit l'heure.
    static func scheduleNextRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: minimumInterval)
        try? BGTaskScheduler.shared.submit(request)
    }
}

/// Enveloppe observable pour l'interface.
@MainActor
final class DictionaryUpdater: ObservableObject {
    enum Status: Equatable {
        case idle
        case running
        case done(added: Int, total: Int)
        case failed(String)
    }

    @Published private(set) var status: Status = .idle

    func update(force: Bool) async {
        guard status != .running else { return }
        status = .running
        do {
            if let result = try await DictionaryUpdate.run(force: force) {
                status = .done(added: result.added, total: result.total)
            } else {
                status = .idle
            }
        } catch {
            status = .failed(error.localizedDescription)
        }
    }
}
