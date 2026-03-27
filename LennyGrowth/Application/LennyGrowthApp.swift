import SwiftUI
import SwiftData

@main
struct LennyGrowthApp: App {
    @StateObject private var container = DependencyContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(container)
                .modelContainer(container.persistenceController.container)
        }
    }
}
