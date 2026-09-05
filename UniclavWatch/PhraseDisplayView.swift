import SwiftUI
import WatchKit

/// Affiche une phrase en grand, pour la montrer à quelqu'un, et la fait
/// lire à voix haute. L'écran reste volontairement dépouillé : le texte
/// doit être lisible d'un mètre par un tiers.
struct PhraseDisplayView: View {
    let phrase: Phrase

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text(phrase.text)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                Button {
                    Speaker.say(phrase.text)
                    WKInterfaceDevice.current().play(.click)
                } label: {
                    Label("Répéter", systemImage: "speaker.wave.2.fill")
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("")
        .onAppear {
            // Une vibration confirme l'envoi sans qu'il faille regarder
            // l'écran, et la phrase est dite dans la foulée.
            WKInterfaceDevice.current().play(.notification)
            Speaker.say(phrase.text)
        }
    }
}

#Preview {
    PhraseDisplayView(phrase: PhraseLibrary.sections[0].phrases[0])
}
