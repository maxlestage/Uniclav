import Foundation

/// Lecture du Wiktionnaire francophone.
///
/// Ce code ne vit que dans l'application : l'extension clavier ne doit même
/// pas être liée à du réseau. Elle lit le dictionnaire déjà enrichi.
struct WiktionaryClient {
    private let endpoint = URL(string: "https://fr.wiktionary.org/w/api.php")!
    /// L'API de Wikimédia exige un agent identifiable, sous peine de blocage.
    private let userAgent = "Uniclav/1.0 (clavier accessible; +https://github.com/maxlestage/Uniclav)"
    /// L'API accepte cinquante titres par requête.
    private let batchSize = 50

    enum ClientError: LocalizedError {
        case rateLimited
        case unexpectedResponse

        var errorDescription: String? {
            switch self {
            case .rateLimited:
                return "Le Wiktionnaire limite le nombre de requêtes. Réessayez plus tard."
            case .unexpectedResponse:
                return "Réponse inattendue du Wiktionnaire."
            }
        }
    }

    private func fetch(_ items: [URLQueryItem]) async throws -> Data {
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = items + [
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "formatversion", value: "2"),
        ]
        var request = URLRequest(url: components.url!)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 20

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ClientError.unexpectedResponse }
        // 429 : on s'arrête net plutôt que d'insister et de se faire bloquer.
        if http.statusCode == 429 { throw ClientError.rateLimited }
        guard http.statusCode == 200 else { throw ClientError.unexpectedResponse }
        return data
    }

    // MARK: - Existence en français

    private struct CategoriesResponse: Decodable {
        struct Page: Decodable {
            struct Category: Decodable { let title: String }
            let title: String
            let missing: Bool?
            let categories: [Category]?
        }
        struct Query: Decodable { let pages: [Page] }
        let query: Query
    }

    /// Parmi les mots proposés, ceux qui ont réellement une entrée française.
    /// Un mot peut exister sur le Wiktionnaire dans une autre langue : on
    /// vérifie donc les catégories, pas la simple présence de la page.
    func frenchWords(among words: [String]) async throws -> [String] {
        var confirmed: [String] = []
        var start = 0
        while start < words.count {
            let chunk = Array(words[start..<min(start + batchSize, words.count)])
            start += batchSize

            let data = try await fetch([
                URLQueryItem(name: "action", value: "query"),
                URLQueryItem(name: "prop", value: "categories"),
                URLQueryItem(name: "cllimit", value: "max"),
                URLQueryItem(name: "titles", value: chunk.joined(separator: "|")),
            ])
            let decoded = try JSONDecoder().decode(CategoriesResponse.self, from: data)
            for page in decoded.query.pages {
                guard page.missing != true,
                      let categories = page.categories,
                      categories.contains(where: { $0.title.contains("français") }) else { continue }
                confirmed.append(page.title)
            }
        }
        return confirmed
    }

    // MARK: - Vocabulaire de base

    private struct ParseResponse: Decodable {
        struct Parse: Decodable {
            struct Link: Decodable {
                let ns: Int
                let title: String
                let exists: Bool?
            }
            let links: [Link]
        }
        let parse: Parse
    }

    /// Le vocabulaire que le Wiktionnaire juge indispensable : un millier de
    /// mots obtenus en une seule requête, là où énumérer le français entier
    /// demanderait des milliers d'appels pour des millions d'entrées.
    func coreVocabulary() async throws -> [String] {
        let data = try await fetch([
            URLQueryItem(name: "action", value: "parse"),
            URLQueryItem(name: "page", value: "Wiktionnaire:Liste des mots français que tous les Wiktionnaires devraient avoir"),
            URLQueryItem(name: "prop", value: "links"),
            URLQueryItem(name: "redirects", value: "1"),
        ])
        let decoded = try JSONDecoder().decode(ParseResponse.self, from: data)
        return decoded.parse.links
            .filter { $0.ns == 0 && $0.exists == true }
            .map(\.title)
    }
}
