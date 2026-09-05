import Foundation

/// Une phrase prête à montrer ou à faire dire par la montre.
struct Phrase: Identifiable, Hashable {
    var id: String { text }
    let text: String
    let symbol: String
}

/// Un groupe de phrases affiché comme une section de la liste.
struct PhraseSection: Identifiable {
    var id: String { title }
    let title: String
    let phrases: [Phrase]
}

/// Phrases proposées au poignet. Elles couvrent les besoins immédiats que
/// l'on ne peut pas toujours formuler à temps : d'abord l'urgence et la
/// douleur, puis le quotidien, enfin les échanges courants.
enum PhraseLibrary {
    static let sections: [PhraseSection] = [
        PhraseSection(title: "Urgent", phrases: [
            Phrase(text: "J'ai besoin d'aide", symbol: "exclamationmark.triangle.fill"),
            Phrase(text: "J'ai mal", symbol: "bolt.heart.fill"),
            Phrase(text: "Appelez un médecin", symbol: "cross.case.fill"),
            Phrase(text: "Je ne me sens pas bien", symbol: "waveform.path.ecg"),
            Phrase(text: "Je suis tombé", symbol: "figure.fall"),
        ]),
        PhraseSection(title: "Besoins", phrases: [
            Phrase(text: "J'ai soif", symbol: "drop.fill"),
            Phrase(text: "J'ai faim", symbol: "fork.knife"),
            Phrase(text: "Je dois aller aux toilettes", symbol: "figure.walk"),
            Phrase(text: "J'ai froid", symbol: "snowflake"),
            Phrase(text: "J'ai chaud", symbol: "thermometer.sun.fill"),
            Phrase(text: "Je suis fatigué", symbol: "bed.double.fill"),
            Phrase(text: "Mes médicaments", symbol: "pills.fill"),
        ]),
        PhraseSection(title: "Échanges", phrases: [
            Phrase(text: "Oui", symbol: "checkmark.circle.fill"),
            Phrase(text: "Non", symbol: "xmark.circle.fill"),
            Phrase(text: "Merci", symbol: "hands.sparkles.fill"),
            Phrase(text: "Attendez, s'il vous plaît", symbol: "hand.raised.fill"),
            Phrase(text: "Plus lentement", symbol: "tortoise.fill"),
            Phrase(text: "Je n'ai pas compris", symbol: "questionmark.circle.fill"),
            Phrase(text: "Laissez-moi le temps", symbol: "clock.fill"),
        ]),
    ]
}
