import SwiftUI

/// Liste des phrases, groupées par urgence décroissante.
struct PhraseListView: View {
    var body: some View {
        NavigationStack {
            List {
                ForEach(PhraseLibrary.sections) { section in
                    Section(section.title) {
                        ForEach(section.phrases) { phrase in
                            NavigationLink(value: phrase) {
                                Label(phrase.text, systemImage: phrase.symbol)
                                    .font(.headline)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.7)
                                    .padding(.vertical, 6)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Uniclav")
            .tint(Palette.accent)
            .navigationDestination(for: Phrase.self) { phrase in
                PhraseDisplayView(phrase: phrase)
            }
        }
    }
}

#Preview {
    PhraseListView()
}
