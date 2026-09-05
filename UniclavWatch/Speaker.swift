import AVFoundation

/// Lecture vocale des phrases, en français.
enum Speaker {
    private static let synthesizer = AVSpeechSynthesizer()

    static func say(_ text: String) {
        // Sans session audio active, watchOS n'émet rien sur le haut-parleur.
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio)
        try? session.setActive(true)

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "fr-FR")
        // Un peu plus lent que le débit par défaut : la phrase s'adresse
        // souvent à un tiers qui la découvre.
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.92
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.speak(utterance)
    }
}
