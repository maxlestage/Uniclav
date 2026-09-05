import SwiftUI
import UIKit

struct ContentView: View {
    @State private var handSide = KeyboardSettings.handSide
    @State private var keyboardScale = KeyboardSettings.keyboardScale
    @State private var keyHeight = KeyboardSettings.keyHeight
    @State private var largeLabels = KeyboardSettings.largeLabels
    @State private var highContrast = KeyboardSettings.highContrast
    @State private var testText = ""

    var body: some View {
        NavigationStack {
            Form {
                activationSection
                handSection
                sizeSection
                displaySection
                testSection
                aboutSection
            }
            .navigationTitle("Uniclav")
        }
    }

    private var activationSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Label("Activer le clavier", systemImage: "keyboard.badge.ellipsis")
                    .font(.headline)
                Text("1. Ouvrez **Réglages** › **Général** › **Clavier** › **Claviers**\n2. Touchez **Ajouter un clavier…**\n3. Sélectionnez **Uniclav**")
                    .font(.callout)
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Ouvrir les Réglages", systemImage: "gear")
                }
            }
            .padding(.vertical, 4)
        } footer: {
            Text("Une fois activé, maintenez le globe 🌐 sur n'importe quel clavier pour passer sur Uniclav.")
        }
    }

    private var handSection: some View {
        Section("Main utilisée") {
            Picker("Côté du clavier", selection: $handSide) {
                ForEach(KeyboardSettings.HandSide.allCases) { side in
                    Text(side.label).tag(side)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: handSide) { KeyboardSettings.handSide = $0 }

            Text("Le clavier se regroupe du côté de votre main valide pour limiter les mouvements du bras. Vous pourrez aussi changer de côté directement depuis le clavier avec la flèche ⇄.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var sizeSection: some View {
        Section("Taille") {
            VStack(alignment: .leading) {
                Text("Largeur du clavier : \(Int(keyboardScale * 100)) % de l'écran")
                Slider(value: $keyboardScale, in: 0.6...1.0, step: 0.02)
                    .onChange(of: keyboardScale) { KeyboardSettings.keyboardScale = $0 }
            }
            VStack(alignment: .leading) {
                Text("Hauteur des touches : \(Int(keyHeight)) pt")
                Slider(value: $keyHeight, in: 44...66, step: 1)
                    .onChange(of: keyHeight) { KeyboardSettings.keyHeight = $0 }
            }
        }
    }

    private var displaySection: some View {
        Section("Affichage") {
            Toggle("Grandes lettres sur les touches", isOn: $largeLabels)
                .onChange(of: largeLabels) { KeyboardSettings.largeLabels = $0 }
            Toggle("Contraste renforcé", isOn: $highContrast)
                .onChange(of: highContrast) { KeyboardSettings.highContrast = $0 }
        }
    }

    private var testSection: some View {
        Section("Zone d'essai") {
            TextField("Essayez le clavier ici…", text: $testText, axis: .vertical)
                .lineLimit(3...6)
        } footer: {
            Text("Touchez le champ puis maintenez le globe 🌐 pour choisir Uniclav.")
        }
    }

    private var aboutSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Conçu pour la frappe à une main")
                    .font(.headline)
                Text("• Clavier AZERTY regroupé à gauche ou à droite\n• Grandes touches espacées\n• Prédiction de mots en français avec apprentissage\n• Accents par appui long (e → é è ê ë)\n• Majuscule automatique en début de phrase")
                    .font(.callout)
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    ContentView()
}
