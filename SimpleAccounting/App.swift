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
            print("警告: 无法初始化持久化存储: \(error)，使用内存存储作为降级方案")
            do {
                let schema = Schema([
                    Transaction.self,
                    Category.self,
                    Budget.self,
                    Tag.self,
                    Ledger.self
                ])
                let memoryConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: true
                )
                modelContainer = try ModelContainer(
                    for: schema,
                    configurations: [memoryConfiguration]
                )
            } catch {
                fatalError("无法创建 ModelContainer: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
        }
    }
}
