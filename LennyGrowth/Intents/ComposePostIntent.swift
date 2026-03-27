import AppIntents
import Foundation

// MARK: – Compose Post Intent

struct ComposePostIntent: AppIntent {
    static var title: LocalizedStringResource = "Post erstellen"
    static var description = IntentDescription("Öffnet LennyGrowth zum Erstellen eines neuen Posts.")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Inhalt", description: "Optionaler Text für den neuen Post")
    var content: String?

    func perform() async throws -> some IntentResult {
        // The app will handle opening the Compose tab via DeepLinkHandler
        // openAppWhenRun=true brings the app to foreground automatically
        return .result()
    }
}

// MARK: – Open Feed Intent

struct OpenFeedIntent: AppIntent {
    static var title: LocalizedStringResource = "Feed öffnen"
    static var description = IntentDescription("Öffnet den LennyGrowth Marketing-Feed.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

// MARK: – Shortcuts Provider

struct LennyGrowthShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ComposePostIntent(),
            phrases: [
                "Neuen Post in \(.applicationName) erstellen",
                "Post mit \(.applicationName) verfassen",
                "\(.applicationName) öffnen zum Schreiben",
            ],
            shortTitle: "Post erstellen",
            systemImageName: "pencil.and.outline"
        )
        AppShortcut(
            intent: OpenFeedIntent(),
            phrases: [
                "\(.applicationName) Feed öffnen",
                "Marketing-Feed in \(.applicationName) anzeigen",
            ],
            shortTitle: "Feed öffnen",
            systemImageName: "newspaper"
        )
    }
}
