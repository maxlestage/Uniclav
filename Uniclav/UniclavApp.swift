import SwiftUI

@main
struct UniclavApp: App {
    @StateObject private var updater = DictionaryUpdater()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(updater)
                .tint(Palette.accent)
                .task {
                    // Au lancement : mise à jour si elle est due, puis on
                    // replanifie le réveil en arrière-plan.
                    await updater.update(force: false)
                    DictionaryUpdate.scheduleNextRefresh()
                }
        }
        .backgroundTask(.appRefresh(DictionaryUpdate.taskIdentifier)) {
            _ = try? await DictionaryUpdate.run(force: false)
            DictionaryUpdate.scheduleNextRefresh()
        }
    }
}
