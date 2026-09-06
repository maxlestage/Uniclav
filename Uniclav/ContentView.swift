import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var updater: DictionaryUpdater
    @State private var autoUpdate = KeyboardSettings.autoUpdateDictionary
    @State private var shareUnknown = KeyboardSettings.shareUnknownWords
    @State private var handSide = KeyboardSettings.handSide
    @State private var layout = KeyboardSettings.layout
    @State private var keyboardScale = KeyboardSettings.keyboardScale
    @State private var keyHeight = KeyboardSettings.keyHeight
    @State private var largeLabels = KeyboardSettings.largeLabels
    @State private var highContrast = KeyboardSettings.highContrast
    @State private var testText = ""

    var body: some View {
        NavigationStack {
            Form {
                activationSection
                layoutSection
                handSection
                sizeSection
                displaySection
                dictionarySection
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

    private var layoutSection: some View {
        Section {
            // Une liste plutôt qu'un sélecteur segmenté : à cinq modes, les
            // libellés seraient illisibles, et surtout chaque mode a besoin
            // d'une phrase pour qu'on puisse choisir en connaissance de cause.
            ForEach(KeyboardSettings.Layout.allCases) { mode in
                Button {
                    layout = mode
                    KeyboardSettings.layout = mode
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: mode == layout ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(mode == layout ? Color.accentColor : Color.secondary)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(mode.label)
                                .font(.headline)
                            Text(mode.summary)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(mode == layout ? [.isButton, .isSelected] : .isButton)
            }
        } header: {
            Text("Mode de clavier")
        } footer: {
            Text("Aucun mode n'est meilleur qu'un autre : le bon est celui qui convient à votre main, et vous pouvez en changer à tout moment.\n\nDans les modes à touches groupées, la touche ⊞ du clavier ramène l'AZERTY le temps d'écrire un mot que le dictionnaire ignore — un nom propre, le plus souvent — puis vous y ramène.")
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

    private var dictionarySection: some View {
        Section {
            HStack {
                Text("Mots connus")
                Spacer()
                Text(wordCountText).foregroundStyle(.secondary)
            }
            HStack {
                Text("Dernière mise à jour")
                Spacer()
                Text(lastUpdateText).foregroundStyle(.secondary)
            }
            Toggle("Mise à jour automatique", isOn: $autoUpdate)
                .onChange(of: autoUpdate) { KeyboardSettings.autoUpdateDictionary = $0 }

            Toggle("Soumettre les mots inconnus", isOn: $shareUnknown)
                .onChange(of: shareUnknown) { KeyboardSettings.shareUnknownWords = $0 }
            Text("Un mot que le clavier ne connaît pas est le plus souvent un nom propre : un prénom, une commune, le nom d'un praticien. Activez cette option pour que ces mots soient vérifiés auprès du Wiktionnaire et ajoutés avec leurs accents — ils quitteront alors l'appareil. Désactivée, la frappe continue d'apprendre vos mots, mais uniquement en local.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button {
                Task { await updater.update(force: true) }
            } label: {
                if updater.status == .running {
                    HStack { ProgressView(); Text("Mise à jour…") }
                } else {
                    Label("Mettre à jour maintenant", systemImage: "arrow.clockwise")
                }
            }
            .disabled(updater.status == .running)

            if case let .done(added, _) = updater.status {
                Text(added == 0
                     ? "Dictionnaire déjà à jour."
                     : "\(added) mot\(added > 1 ? "s" : "") ajouté\(added > 1 ? "s" : "") depuis le Wiktionnaire.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            if case let .failed(message) = updater.status {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }
        } header: {
            Text("Dictionnaire")
        } footer: {
            Text("Le clavier n'accède jamais au réseau : c'est cette application qui télécharge, une fois par jour au plus, et elle seule.")
        }
    }

    private var wordCountText: String {
        let count = KeyboardSettings.dictionaryWordCount
        return count > 0 ? "\(count)" : "dictionnaire livré"
    }

    private var lastUpdateText: String {
        guard let date = KeyboardSettings.lastDictionaryUpdate else { return "jamais" }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private var testSection: some View {
        Section {
            TextField("Essayez le clavier ici…", text: $testText, axis: .vertical)
                .lineLimit(3...6)
        } header: {
            Text("Zone d'essai")
        } footer: {
            Text("Touchez le champ puis maintenez le globe 🌐 pour choisir Uniclav.")
        }
    }

    private var aboutSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Conçu pour la frappe à une main")
                    .font(.headline)
                Text("• Clavier regroupé à gauche ou à droite\n• Disposition à grosses touches, désambiguïsée par le dictionnaire\n• Prédiction de mots en français avec apprentissage\n• Accents par appui long (e → é è ê ë)\n• Majuscule automatique en début de phrase")
                    .font(.callout)
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    ContentView().environmentObject(DictionaryUpdater())
}
