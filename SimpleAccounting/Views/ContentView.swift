import SwiftUI
import SwiftData
import Charts

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("首页", systemImage: "house")
                }
                .tag(0)

            TransactionListView()
                .tabItem {
                    Label("记录", systemImage: "list.bullet")
                }
                .tag(1)

            StatisticsView()
                .tabItem {
                    Label("统计", systemImage: "chart.pie")
                }
                .tag(2)

            CategoryView()
                .tabItem {
                    Label("分类", systemImage: "tag")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gear")
                }
                .tag(4)
        }
        .accentColor(.primary)
        .onAppear {
            DataService.shared.setModelContext(modelContext)

            do {
                try DataService.shared.initializeDefaultData()
                print("默认数据初始化成功")
            } catch {
                print("默认数据初始化失败: \(error)")
            }
        }
    }
}

struct HomeView: View {
    @State private var showAddTransaction = false
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]

    // 本月结余计算
    private var currentMonthTransactions: [Transaction] {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        return allTransactions.filter { $0.date >= startOfMonth }
    }

    private var monthlyIncome: Double {
        currentMonthTransactions
            .filter { $0.type == "income" }
            .reduce(0) { $0 + $1.amount }
    }

    private var monthlyExpense: Double {
        currentMonthTransactions
            .filter { $0.type == "expense" }
            .reduce(0) { $0 + $1.amount }
    }

    private var monthlyBalance: Double {
        monthlyIncome - monthlyExpense
    }

    // 今日收支计算
    private var todayTransactions: [Transaction] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        return allTransactions.filter { $0.date >= startOfDay }
    }

    private var todayIncome: Double {
        todayTransactions
            .filter { $0.type == "income" }
            .reduce(0) { $0 + $1.amount }
    }

    private var todayExpense: Double {
        todayTransactions
            .filter { $0.type == "expense" }
            .reduce(0) { $0 + $1.amount }
    }

    // 最近5条记录
    private var recentTransactions: [Transaction] {
        Array(allTransactions.prefix(5))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 本月结余卡片
                    VStack(spacing: 12) {
                        Text("本月结余")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text(String(format: "%.2f", monthlyBalance))
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(monthlyBalance >= 0 ? .green : .red)

                        HStack(spacing: 30) {
                            VStack {
                                Text("收入")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(String(format: "+%.2f", monthlyIncome))
                                    .font(.headline)
                                    .foregroundColor(.green)
                            }

                            VStack {
                                Text("支出")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(String(format: "-%.2f", monthlyExpense))
                                    .font(.headline)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // 今日收支概览
                    VStack(alignment: .leading, spacing: 12) {
                        Text("今日收支")
                            .font(.headline)
                            .padding(.horizontal)

                        HStack(spacing: 16) {
                            TodayStatCard(title: "收入", amount: todayIncome, color: .green, icon: "arrow.up.circle.fill")
                            TodayStatCard(title: "支出", amount: todayExpense, color: .red, icon: "arrow.down.circle.fill")
                        }
                        .padding(.horizontal)
                    }

                    // 最近记录列表
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("最近记录")
                                .font(.headline)
                            Spacer()
                            NavigationLink {
                                TransactionListView()
                            } label: {
                                Text("查看全部")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)

                        if recentTransactions.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "list.bullet.clipboard")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("暂无记录")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("点击下方按钮开始记账")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(recentTransactions) { transaction in
                                    HomeTransactionRow(transaction: transaction)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    Spacer(minLength: 80)
                }
                .padding(.top)
            }
            .navigationTitle("简单记账")
            .overlay(alignment: .bottom) {
                Button(action: {
                    showAddTransaction = true
                }) {
                    Text("记一笔")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(30)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            }
            .sheet(isPresented: $showAddTransaction) {
                AddTransactionView()
            }
        }
    }
}

// 今日统计卡片组件
struct TodayStatCard: View {
    let title: String
    let amount: Double
    let color: Color
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(format: "%.2f", amount))
                    .font(.headline)
                    .foregroundColor(color)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// 首页交易记录行组件
struct HomeTransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack {
            Image(systemName: transaction.category?.icon ?? "questionmark")
                .foregroundColor(Color(hex: transaction.category?.color ?? "#95A5A6"))
                .frame(width: 36, height: 36)
                .background(Color(hex: transaction.category?.color ?? "#95A5A6").opacity(0.1))
                .cornerRadius(18)

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.category?.name ?? "未分类")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(transaction.type == "income" ? "+\(String(format: "%.2f", transaction.amount))" : "-\(String(format: "%.2f", transaction.amount))")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(transaction.type == "income" ? .green : .red)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [Transaction]

    @State private var selectedMonth: Date = Date()
    @State private var selectedSegment: String = "expense"

    // 月度数据
    private var currentMonthTransactions: [Transaction] {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!

        return transactions.filter { transaction in
            transaction.date >= startOfMonth && transaction.date <= endOfMonth
        }
    }

    private var monthlyIncome: Double {
        currentMonthTransactions
            .filter { $0.type == "income" }
            .reduce(0) { $0 + $1.amount }
    }

    private var monthlyExpense: Double {
        currentMonthTransactions
            .filter { $0.type == "expense" }
            .reduce(0) { $0 + $1.amount }
    }

    private var monthlyBalance: Double {
        monthlyIncome - monthlyExpense
    }

    // 按分类统计数据
    private var categoryStatistics: [CategoryStatistic] {
        let filteredTransactions = currentMonthTransactions.filter { $0.type == selectedSegment }

        var categoryMap: [UUID: CategoryStatistic] = [:]

        for transaction in filteredTransactions {
            if let category = transaction.category {
                if var stat = categoryMap[category.id] {
                    stat.amount += transaction.amount
                    stat.count += 1
                    categoryMap[category.id] = stat
                } else {
                    categoryMap[category.id] = CategoryStatistic(
                        category: category,
                        amount: transaction.amount,
                        count: 1
                    )
                }
            } else {
                let unknownId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
                if var stat = categoryMap[unknownId] {
                    stat.amount += transaction.amount
                    stat.count += 1
                    categoryMap[unknownId] = stat
                } else {
                    let unknownCategory = Category(name: "未分类", icon: "questionmark", color: "#95A5A6", type: selectedSegment)
                    categoryMap[unknownId] = CategoryStatistic(
                        category: unknownCategory,
                        amount: transaction.amount,
                        count: 1
                    )
                }
            }
        }

        return categoryMap.values.sorted { $0.amount > $1.amount }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 月度选择器
                    HStack {
                        Button(action: {
                            selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                        }

                        Spacer()

                        Text(selectedMonth, format: Date.FormatStyle().year().month())
                            .font(.headline)

                        Spacer()

                        Button(action: {
                            selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.title3)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                    // 月度收支概览
                    VStack(spacing: 15) {
                        HStack(spacing: 20) {
                            StatCard(title: "收入", amount: monthlyIncome, color: .green, icon: "arrow.up.circle")
                            StatCard(title: "支出", amount: monthlyExpense, color: .red, icon: "arrow.down.circle")
                        }

                        HStack {
                            Text("结余")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(monthlyBalance >= 0 ? "+" : "")\(String(format: "%.2f", monthlyBalance))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(monthlyBalance >= 0 ? .green : .red)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)

                    // 类型选择
                    Picker("类型", selection: $selectedSegment) {
                        Text("支出").tag("expense")
                        Text("收入").tag("income")
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // 分类占比饼图
                    if !categoryStatistics.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("分类占比")
                                .font(.headline)
                                .padding(.horizontal)

                            PieChartView(categoryStatistics: categoryStatistics)
                                .frame(height: 300)
                                .padding(.horizontal)
                        }

                        // 分类详细列表
                        VStack(alignment: .leading, spacing: 10) {
                            Text("分类明细")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(categoryStatistics, id: \.category.id) { stat in
                                CategoryStatRow(stat: stat, total: selectedSegment == "expense" ? monthlyExpense : monthlyIncome)
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: "chart.pie")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("暂无\(selectedSegment == "expense" ? "支出" : "收入")数据")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .frame(height: 300)
                    }

                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationTitle("统计分析")
        }
    }
}

struct StatCard: View {
    let title: String
    let amount: Double
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .foregroundColor(.secondary)
            }
            .font(.subheadline)

            Text(String(format: "%.2f", amount))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct CategoryStatistic: Identifiable {
    let id = UUID()
    let category: Category
    var amount: Double
    var count: Int
}

struct PieChartView: View {
    let categoryStatistics: [CategoryStatistic]
    @State private var selectedCategory: UUID?

    var body: some View {
        Chart(categoryStatistics) { stat in
            SectorMark(
                angle: .value("金额", stat.amount),
                innerRadius: .ratio(0.5),
                angularInset: 1.5
            )
            .foregroundStyle(Color(hex: stat.category.color))
            .cornerRadius(4)
            .opacity(selectedCategory == nil || selectedCategory == stat.category.id ? 1 : 0.5)
        }
        .chartLegend(.hidden)
        .chartBackground { chartProxy in
            GeometryReader { geometry in
                if let selectedCategoryId = selectedCategory,
                   let selectedStat = categoryStatistics.first(where: { $0.category.id == selectedCategoryId }) {
                    let frame = geometry[chartProxy.plotFrame!]
                    VStack {
                        Text(selectedStat.category.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.2f", selectedStat.amount))
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("\(selectedStat.count)笔")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .position(x: frame.midX, y: frame.midY)
                }
            }
        }
    }
}

struct CategoryStatRow: View {
    let stat: CategoryStatistic
    let total: Double

    private var percentage: Double {
        guard total > 0 else { return 0 }
        return stat.amount / total
    }

    var body: some View {
        HStack {
            Image(systemName: stat.category.icon)
                .foregroundColor(Color(hex: stat.category.color))
                .frame(width: 30, height: 30)
                .background(Color(hex: stat.category.color).opacity(0.1))
                .cornerRadius(15)

            VStack(alignment: .leading, spacing: 4) {
                Text(stat.category.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(height: 6)
                            .cornerRadius(3)

                        Rectangle()
                            .fill(Color(hex: stat.category.color))
                            .frame(width: geometry.size.width * percentage, height: 6)
                            .cornerRadius(3)
                    }
                }
                .frame(height: 6)
            }

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.2f", stat.amount))
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(String(format: "%.1f%%", percentage * 100))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 80, alignment: .trailing)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct CategoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]
    @State private var showAddCategory = false
    @State private var selectedType: String = "expense"

    var filteredCategories: [Category] {
        categories.filter { $0.type == selectedType }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 类型切换
                Picker("类型", selection: $selectedType) {
                    Text("支出").tag("expense")
                    Text("收入").tag("income")
                }
                .pickerStyle(.segmented)
                .padding()

                if filteredCategories.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "tag.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("暂无分类")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Button("添加分类") {
                            showAddCategory = true
                        }
                        .buttonStyle(.borderedProminent)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(filteredCategories) { category in
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(Color(hex: category.color))
                                    .frame(width: 30, height: 30)
                                    .background(Color(hex: category.color).opacity(0.1))
                                    .cornerRadius(15)
                                Text(category.name)
                                Spacer()
                                if category.isDefault {
                                    Text("默认")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(.systemGray5))
                                        .cornerRadius(4)
                                }
                            }
                        }
                        .onDelete(perform: deleteCategories)
                    }
                }
            }
            .navigationTitle("分类管理")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddCategory = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddCategory) {
                AddCategoryView()
            }
        }
    }

    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            let category = filteredCategories[index]
            if !category.isDefault {
                modelContext.delete(category)
                try? modelContext.save()
            }
        }
    }
}

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showExportSheet = false
    @State private var showImportPicker = false
    @State private var showBackupAlert = false
    @State private var showRestoreAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var exportURL: URL?
    @State private var isExporting = false
    @State private var isImporting = false

    var body: some View {
        NavigationStack {
            List {
                Section("数据管理") {
                    NavigationLink {
                        CategoryManagementView()
                    } label: {
                        Label("分类管理", systemImage: "tag")
                    }

                    Button {
                        exportCSV()
                    } label: {
                        Label("导出CSV", systemImage: "square.and.arrow.up")
                    }
                    .disabled(isExporting)

                    Button {
                        showImportPicker = true
                    } label: {
                        Label("导入数据", systemImage: "square.and.arrow.down")
                    }
                    .disabled(isImporting)
                }

                Section("备份恢复") {
                    Button {
                        createBackup()
                    } label: {
                        Label("创建备份", systemImage: "externaldrive.badge.plus")
                    }

                    Button {
                        showRestoreAlert = true
                    } label: {
                        Label("恢复备份", systemImage: "externaldrive.badge.minus")
                    }
                }

                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("构建")
                        Spacer()
                        Text("1")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("设置")
            .alert("错误", isPresented: $showErrorAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("创建备份", isPresented: $showBackupAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text("备份已成功创建并分享")
            }
            .alert("恢复备份", isPresented: $showRestoreAlert) {
                Button("取消", role: .cancel) { }
                Button("确认", role: .destructive) {
                    restoreBackup()
                }
            } message: {
                Text("恢复备份将替换所有现有数据，确定要继续吗？")
            }
            .sheet(isPresented: $showExportSheet) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .fileImporter(isPresented: $showImportPicker, allowedContentTypes: [.json]) { result in
                handleImport(result)
            }
        }
    }

    private func exportCSV() {
        isExporting = true
        do {
            let csvString = try DataService.shared.exportDataAsCSV()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let fileName = "SimpleAccounting_\(dateFormatter.string(from: Date())).csv"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

            try csvString.write(to: tempURL, atomically: true, encoding: .utf8)
            exportURL = tempURL
            showExportSheet = true
        } catch {
            errorMessage = "导出CSV失败: \(error.localizedDescription)"
            showErrorAlert = true
        }
        isExporting = false
    }

    private func createBackup() {
        do {
            let data = try DataService.shared.exportData()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let fileName = "SimpleAccounting_Backup_\(dateFormatter.string(from: Date())).dat"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

            try data.write(to: tempURL)
            exportURL = tempURL
            showBackupAlert = true
        } catch {
            errorMessage = "创建备份失败: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }

    private func restoreBackup() {
        showImportPicker = true
    }

    private func handleImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            isImporting = true
            do {
                try DataService.shared.importData(from: url)
                errorMessage = "数据导入成功"
                showErrorAlert = true
            } catch {
                errorMessage = "导入失败: \(error.localizedDescription)"
                showErrorAlert = true
            }
            isImporting = false
        case .failure(let error):
            errorMessage = "选择文件失败: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
}

struct CategoryManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]
    @State private var showAddCategory = false

    var body: some View {
        List {
            Section("支出分类") {
                ForEach(categories.filter { $0.type == "expense" }) { category in
                    HStack {
                        Image(systemName: category.icon)
                            .foregroundColor(Color(hex: category.color))
                            .frame(width: 30, height: 30)
                            .background(Color(hex: category.color).opacity(0.1))
                            .cornerRadius(15)
                        Text(category.name)
                        Spacer()
                        if category.isDefault {
                            Text("默认")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete { offsets in
                    deleteCategories(at: offsets, type: "expense")
                }
            }

            Section("收入分类") {
                ForEach(categories.filter { $0.type == "income" }) { category in
                    HStack {
                        Image(systemName: category.icon)
                            .foregroundColor(Color(hex: category.color))
                            .frame(width: 30, height: 30)
                            .background(Color(hex: category.color).opacity(0.1))
                            .cornerRadius(15)
                        Text(category.name)
                        Spacer()
                        if category.isDefault {
                            Text("默认")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete { offsets in
                    deleteCategories(at: offsets, type: "income")
                }
            }
        }
        .navigationTitle("分类管理")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddCategory = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddCategory) {
            AddCategoryView()
        }
    }

    private func deleteCategories(at offsets: IndexSet, type: String) {
        let filteredCategories = categories.filter { $0.type == type }
        for index in offsets {
            let category = filteredCategories[index]
            if !category.isDefault {
                modelContext.delete(category)
                try? modelContext.save()
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
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
    do {
        let container = try ModelContainer(for: schema, configurations: configuration)
        return ContentView()
            .modelContainer(container)
    } catch {
        fatalError("无法创建 ModelContainer: \(error)")
    }
}
