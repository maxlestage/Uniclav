import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var updater: DictionaryUpdater
    @State private var autoUpdate = KeyboardSettings.autoUpdateDictionary
    @State private var shareUnknown = KeyboardSettings.shareUnknownWords
    @State private var theme = KeyboardSettings.theme
    @State private var customFace = KeyboardSettings.customKeyFace.color
    @State private var customText = KeyboardSettings.customKeyText.color
    @State private var multiTapDelay = KeyboardSettings.multiTapDelay
    @State private var handSide = KeyboardSettings.handSide
    @State private var layout = KeyboardSettings.layout
    @State private var keyboardScale = KeyboardSettings.keyboardScale
    @State private var keyHeight = KeyboardSettings.keyHeight
    @State private var largeLabels = KeyboardSettings.largeLabels
    @State private var highContrast = KeyboardSettings.highContrast
    @State private var appIcon = AppIconChoice.current
    @State private var iconFailed = false
    @State private var testText = ""

    var body: some View {
        NavigationStack {
            Form {
                activationSection
                layoutSection
                handSection
                sizeSection
                displaySection
                colorSection
                iconSection
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
            if layout == .multiTap {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Délai de validation : \(multiTapDelay, specifier: "%.1f") s")
                    Slider(value: $multiTapDelay, in: 0.6...3.0, step: 0.1)
                        .onChange(of: multiTapDelay) { KeyboardSettings.multiTapDelay = $0 }
                    Text("Temps d'attente avant qu'une lettre soit figée. Passé ce délai, un nouvel appui sur la même touche écrit une lettre de plus au lieu de changer la précédente — c'est ainsi qu'on écrit deux lettres de la même touche à la suite.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
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

    // MARK: - Couleurs

    private func keyboardColor(from color: Color) -> KeyboardColor {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return KeyboardColor(red: Double(red), green: Double(green), blue: Double(blue))
    }

    private var customPalette: KeyboardPalette {
        KeyboardPalette(keyFace: keyboardColor(from: customFace),
                        keyText: keyboardColor(from: customText))
    }

    private func palette(for theme: KeyboardTheme) -> KeyboardPalette {
        guard let preset = theme.preset else { return customPalette }
        return KeyboardPalette(keyFace: preset.face, keyText: preset.text)
    }

    /// Aperçu d'une touche dans le thème, plus parlant qu'une pastille de
    /// couleur : c'est le contraste entre le fond et la lettre qui compte.
    private func swatch(_ palette: KeyboardPalette) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8).fill(palette.keyFace.color)
            Text("A")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(palette.keyText.color)
        }
        .frame(width: 46, height: 46)
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.quaternary))
        .accessibilityHidden(true)
    }

    private var iconSection: some View {
        Section {
            if AppIconChoice.isSupported {
                ForEach(AppIconChoice.all) { choice in
                    Button {
                        AppIconChoice.apply(choice) { succeeded in
                            if succeeded {
                                appIcon = choice
                                iconFailed = false
                            } else {
                                // On ne prétend pas avoir changé l'icône :
                                // l'affichage revient à celle réellement posée.
                                appIcon = AppIconChoice.current
                                iconFailed = true
                            }
                        }
                    } label: {
                        HStack(spacing: 12) {
                            iconPreview(choice)
                            Text(choice.label)
                                .font(.headline)
                            Spacer()
                            Image(systemName: choice == appIcon ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(choice == appIcon ? Color.accentColor : Color.secondary)
                                .accessibilityHidden(true)
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(choice == appIcon ? [.isButton, .isSelected] : .isButton)
                }

                if iconFailed {
                    Label("L'icône n'a pas pu être changée.", systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(Color.orange)
                }
            } else {
                Text("Cet appareil ne permet pas de changer l'icône de l'application.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Icône")
        } footer: {
            Text("L'icône reprend les couleurs d'un thème, et se choisit indépendamment de celui du clavier. iOS affiche sa propre alerte de confirmation à chaque changement : elle vient du système, pas de l'application.")
        }
    }

    /// L'image livrée, quand elle se charge ; à défaut, un aperçu dessiné aux
    /// couleurs du thème plutôt qu'une case vide.
    @ViewBuilder
    private func iconPreview(_ choice: AppIconChoice) -> some View {
        let side: CGFloat = 44
        if let image = choice.image {
            Image(uiImage: image)
                .resizable()
                .frame(width: side, height: side)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .accessibilityHidden(true)
        } else {
            let colors = palette(for: choice.theme)
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(colors.keyFace.color)
                .frame(width: side, height: side)
                .overlay(
                    Text("A")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(colors.keyText.color)
                )
                .accessibilityHidden(true)
        }
    }

    private var colorSection: some View {
        Section {
            ForEach(KeyboardTheme.allCases) { option in
                Button {
                    theme = option
                    KeyboardSettings.theme = option
                } label: {
                    HStack(spacing: 12) {
                        swatch(palette(for: option))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(option.label)
                                .font(.headline)
                            Text(contrastLabel(palette(for: option).contrastRatio))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: option == theme ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(option == theme ? Color.accentColor : Color.secondary)
                            .accessibilityHidden(true)
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(option == theme ? [.isButton, .isSelected] : .isButton)
            }

            if theme == .custom {
                ColorPicker("Fond des touches", selection: $customFace, supportsOpacity: false)
                    .onChange(of: customFace) { KeyboardSettings.customKeyFace = keyboardColor(from: $0) }
                ColorPicker("Lettres", selection: $customText, supportsOpacity: false)
                    .onChange(of: customText) { KeyboardSettings.customKeyText = keyboardColor(from: $0) }

                // Rien n'empêche de choisir deux teintes proches : le clavier
                // deviendrait illisible sans prévenir. On mesure, et on le dit.
                let ratio = customPalette.contrastRatio
                Label {
                    Text(contrastAdvice(ratio))
                } icon: {
                    Image(systemName: ratio >= 4.5 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                }
                .font(.footnote)
                .foregroundStyle(ratio >= 4.5 ? Color.secondary : Color.orange)
            }
        } header: {
            Text("Couleurs")
        } footer: {
            Text("Le fond des touches et la couleur des lettres se règlent séparément. Les autres teintes du clavier — touches de service, fond général — en sont dérivées, pour qu'un seul choix suffise.")
        }
    }

    private func contrastLabel(_ ratio: Double) -> String {
        String(format: "Contraste %.1f:1 — %@", ratio, contrastGrade(ratio))
    }

    private func contrastGrade(_ ratio: Double) -> String {
        if ratio >= 7 { return "excellent" }
        if ratio >= 4.5 { return "correct" }
        if ratio >= 3 { return "faible" }
        return "illisible"
    }

    private func contrastAdvice(_ ratio: Double) -> String {
        if ratio >= 7 {
            return String(format: "Contraste %.1f:1 — excellent, y compris pour une vue fatiguée.", ratio)
        }
        if ratio >= 4.5 {
            return String(format: "Contraste %.1f:1 — lisible, mais 7:1 serait plus confortable.", ratio)
        }
        return String(format: "Contraste %.1f:1 — trop faible. Les lettres seront difficiles à distinguer du fond ; éloignez les deux couleurs.", ratio)
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
