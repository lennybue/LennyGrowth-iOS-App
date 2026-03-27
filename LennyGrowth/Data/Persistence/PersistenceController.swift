import Foundation
import SwiftData

@MainActor
final class PersistenceController {
    static let shared = PersistenceController()

    let container: ModelContainer

    private init() {
        let schema = Schema([
            ArticleSwiftDataModel.self,
            ProductSwiftDataModel.self,
            PostDraftSwiftDataModel.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    /// In-memory container for testing
    static func makeInMemory() -> PersistenceController {
        let controller = PersistenceController.testInstance()
        return controller
    }

    private static func testInstance() -> PersistenceController {
        // Use a separate init path for testing
        return PersistenceController(inMemory: true)
    }

    private init(inMemory: Bool) {
        let schema = Schema([
            ArticleSwiftDataModel.self,
            ProductSwiftDataModel.self,
            PostDraftSwiftDataModel.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            allowsSave: true
        )
        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Failed to create in-memory ModelContainer: \(error)")
        }
    }
}
