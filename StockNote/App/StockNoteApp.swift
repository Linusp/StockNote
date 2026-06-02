import SwiftUI
import SwiftData

@main
struct StockNoteApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Stock.self,
            Tag.self,
            Strategy.self,
            Deal.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
