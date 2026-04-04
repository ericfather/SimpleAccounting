import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var ledgers: [Ledger]
    @Query(sort: \Category.sortOrder) private var allCategories: [Category]

    // 交易类型
    @State private var transactionType: String = "expense" // "income" or "expense"
    // 金额
    @State private var amount: String = ""
    // 分类
    @State private var selectedCategory: Category?
    // 日期
    @State private var date: Date = Date()
    // 备注
    @State private var note: String = ""
    // 位置
    @State private var location: String = ""
    // 错误提示
    @State private var showError = false
    @State private var errorMessage = ""

    // 快捷金额选项
    private let quickAmounts: [Double] = [10, 20, 50, 100, 200, 500]

    private var defaultLedger: Ledger? {
        ledgers.first(where: { $0.name == "默认账本" }) ?? ledgers.first
    }

    // 根据类型过滤分类
    private var filteredCategories: [Category] {
        allCategories.filter { $0.type == transactionType }
    }

    // 快捷分类（显示前6个）
    private var quickCategories: [Category] {
        Array(filteredCategories.prefix(6))
    }

    var body: some View {
        NavigationStack {
            GeometryReader {
                geometry in
                if geometry.size.width > geometry.size.height {
                    // 横屏模式
                    HStack(spacing: 20) {
                        // 左侧：金额和分类
                        VStack(spacing: 20) {
                            // 交易类型选择
                            Picker("类型", selection: $transactionType) {
                                Text("支出").tag("expense")
                                Text("收入").tag("income")
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: transactionType) { _, _ in
                                selectedCategory = nil
                            }

                            // 金额输入
                            TextField("金额", text: $amount)
                                .keyboardType(.decimalPad)
                                .font(.largeTitle)
                                .foregroundColor(transactionType == "income" ? .green : .red)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)

                            // 快捷金额按钮
                            QuickAmountGrid(amount: $amount, amounts: quickAmounts)

                            // 分类选择
                            NavigationLink {
                                CategorySelectionView(selectedCategory: $selectedCategory, categoryType: transactionType)
                            } label: {
                                HStack {
                                    if let category = selectedCategory {
                                        Image(systemName: category.icon)
                                            .foregroundColor(Color(hex: category.color))
                                        Text(category.name)
                                    } else {
                                        Text("选择分类")
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                        .frame(width: geometry.size.width / 2)

                        // 右侧：日期、备注、位置
                        VStack(spacing: 20) {
                            // 日期选择
                            DatePicker("日期", selection: $date, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)

                            // 备注输入
                            TextField("备注", text: $note)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)

                            // 位置输入
                            TextField("位置", text: $location)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        .padding()
                        .frame(width: geometry.size.width / 2)
                    }
                } else {
                    // 竖屏模式
                    Form {
                        // 交易类型选择
                        Section {
                            Picker("类型", selection: $transactionType) {
                                Text("支出").tag("expense")
                                Text("收入").tag("income")
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: transactionType) { _, _ in
                                selectedCategory = nil
                            }
                        }

                        // 金额输入
                        Section {
                            TextField("金额", text: $amount)
                                .keyboardType(.decimalPad)
                                .font(.largeTitle)
                                .foregroundColor(transactionType == "income" ? .green : .red)

                            // 快捷金额按钮
                            QuickAmountGrid(amount: $amount, amounts: quickAmounts)
                        }

                        // 快捷分类网格
                        Section {
                            if !quickCategories.isEmpty {
                                QuickCategoryGrid(
                                    categories: quickCategories,
                                    selectedCategory: $selectedCategory,
                                    transactionType: transactionType
                                )
                            }

                            NavigationLink {
                                CategorySelectionView(selectedCategory: $selectedCategory, categoryType: transactionType)
                            } label: {
                                HStack {
                                    if let category = selectedCategory {
                                        Image(systemName: category.icon)
                                            .foregroundColor(Color(hex: category.color))
                                        Text(category.name)
                                    } else {
                                        Text("选择分类")
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                            }
                        }

                        // 日期选择
                        Section {
                            DatePicker("日期", selection: $date, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                        }

                        // 备注输入
                        Section {
                            TextField("备注", text: $note)
                        }

                        // 位置输入
                        Section {
                            TextField("位置", text: $location)
                        }
                    }
                }
            }
            .navigationTitle(transactionType == "income" ? "记收入" : "记支出")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveTransaction()
                    }
                }
            }
            .alert("错误", isPresented: $showError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func saveTransaction() {
        if amount.isEmpty {
            errorMessage = "请输入金额"
            showError = true
            return
        }

        guard let amountDouble = Double(amount) else {
            errorMessage = "无效的金额格式"
            showError = true
            return
        }

        if amountDouble <= 0 {
            errorMessage = "金额必须大于0"
            showError = true
            return
        }

        if amountDouble > 999999999.99 {
            errorMessage = "金额不能超过999,999,999.99"
            showError = true
            return
        }

        guard let category = selectedCategory else {
            errorMessage = "请选择分类"
            showError = true
            return
        }

        guard let ledger = defaultLedger else {
            errorMessage = "账本数据异常，请重启应用"
            showError = true
            return
        }

        let finalAmount = round(amountDouble * 100) / 100

        let transaction = Transaction(
            amount: finalAmount,
            type: transactionType,
            category: category,
            ledger: ledger,
            note: note,
            date: date,
            location: location.isEmpty ? nil : location
        )

        modelContext.insert(transaction)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
            showError = true
        }
    }
}

// 快捷金额网格组件
struct QuickAmountGrid: View {
    @Binding var amount: String
    let amounts: [Double]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(amounts, id: \.self) { quickAmount in
                Button(action: {
                    if amount.isEmpty {
                        amount = String(format: "%.0f", quickAmount)
                    } else if let existingAmount = Double(amount) {
                        amount = String(format: "%.2f", existingAmount + quickAmount)
                    }
                }) {
                    Text("+\(Int(quickAmount))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// 快捷分类网格组件
struct QuickCategoryGrid: View {
    let categories: [Category]
    @Binding var selectedCategory: Category?
    let transactionType: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("快捷分类")
                .font(.caption)
                .foregroundColor(.secondary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach(categories) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        categoryItemView(category: category)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func categoryItemView(category: Category) -> some View {
        let isSelected = selectedCategory?.id == category.id
        VStack(spacing: 4) {
            Image(systemName: category.icon)
                .font(.title3)
                .foregroundColor(Color(hex: category.color))

            Text(category.name)
                .font(.caption2)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(isSelected ? Color(hex: category.color).opacity(0.2) : Color(.systemGray6))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color(hex: category.color) : Color.clear, lineWidth: 2)
        )
    }
}

// 分类选择视图
struct CategorySelectionView: View {
    @Binding var selectedCategory: Category?
    let categoryType: String
    @Environment(\.dismiss) private var dismiss
    @Query private var categories: [Category]

    init(selectedCategory: Binding<Category?>, categoryType: String) {
        self._selectedCategory = selectedCategory
        self.categoryType = categoryType
    }

    var filteredCategories: [Category] {
        categories.filter { $0.type == categoryType }
    }
    
    var body: some View {
        List {
            if filteredCategories.isEmpty {
                Text("暂无可用分类，请先添加分类")
                    .foregroundColor(.secondary)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(filteredCategories) { category in
                    Button {
                        selectedCategory = category
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(Color(hex: category.color))
                                .frame(width: 30, height: 30)
                                .background(Color(hex: category.color).opacity(0.1))
                                .cornerRadius(15)
                            Text(category.name)
                            Spacer()
                            if selectedCategory?.id == category.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("选择分类")
    }
}

// 颜色扩展
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard hex.count == 6 else {
            self.init(.gray)
            return
        }
        var rgbValue: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
