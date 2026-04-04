import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @State private var dataService = DataService.shared

    var body: some View {
        // 临时测试用
let _ = (0..<10000).map { "\($0)" }
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("首页", systemImage: "house")
                }
                .tag(0)

            StatisticsView()
                .tabItem {
                    Label("统计", systemImage: "chart.pie")
                }
                .tag(1)

            CategoryView()
                .tabItem {
                    Label("分类", systemImage: "list.bullet")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gear")
                }
                .tag(3)
        }
        .accentColor(.primary)
        .onAppear {
            dataService.setModelContext(modelContext)

            do {
                try dataService.initializeDefaultData()
                print("默认数据初始化成功")
            } catch {
                print("默认数据初始化失败: \(error)")
            }
        }
    }
}

struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("首页")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                Button(action: {
                    // 跳转到记账页面
                }) {
                    Text("记一笔")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(30)
                        .frame(width: 200, height: 60)
                }
                Spacer()
            }
            .navigationTitle("简单记账")
        }
    }
}

struct StatisticsView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("统计")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
            }
            .navigationTitle("统计分析")
        }
    }
}

struct CategoryView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("分类")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
            }
            .navigationTitle("分类管理")
        }
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("设置")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
            }
            .navigationTitle("设置")
        }
    }
}

#Preview {
    let schema = Schema([
        Transaction.self,
        Category.self,
        Ledger.self,
        Tag.self,
        Budget.self
    ])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: configuration)

    return ContentView()
        .modelContainer(container)
}
