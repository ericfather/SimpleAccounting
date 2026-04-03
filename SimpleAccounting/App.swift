import SwiftUI
import SwiftData

@main
struct SimpleAccountingApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                Transaction.self,
                Category.self,
                Budget.self,
                Tag.self,
                Ledger.self
            ])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
        }
    }
}