import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
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
    
    // 分类列表
    @Query private var categories: [Category]
    
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
                            .pickerStyle(SegmentedPickerStyle())
                            
                            // 金额输入
                            TextField("金额", text: $amount)
                                .keyboardType(.decimalPad)
                                .font(.largeTitle)
                                .foregroundColor(transactionType == "income" ? .green : .red)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            
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
                            DatePicker("日期", selection: $date, displayedComponents: [.date, .hourAndMinute])
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
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        
                        // 金额输入
                        Section {
                            TextField("金额", text: $amount)
                                .keyboardType(.decimalPad)
                                .font(.largeTitle)
                                .foregroundColor(transactionType == "income" ? .green : .red)
                        }
                        
                        // 分类选择
                        Section {
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
                            DatePicker("日期", selection: $date, displayedComponents: [.date, .hourAndMinute])
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
                    .disabled(amount.isEmpty || selectedCategory == nil)
                }
            }
        }
    }
    
    private func saveTransaction() {
        // 金额输入验证
        guard !amount.isEmpty else {
            // 显示错误提示
            return
        }
        
        guard let amountDouble = Double(amount) else {
            // 显示错误提示：无效的金额格式
            return
        }
        
        guard amountDouble > 0 else {
            // 显示错误提示：金额必须大于0
            return
        }
        
        // 限制小数位数为2位
        let formattedAmount = String(format: "%.2f", amountDouble)
        guard let finalAmount = Double(formattedAmount) else {
            return
        }
        
        // 限制最大金额为9999999.99
        guard finalAmount <= 9999999.99 else {
            // 显示错误提示：金额过大
            return
        }
        
        let transaction = Transaction(
            amount: finalAmount,
            type: transactionType,
            category: selectedCategory,
            note: note,
            date: date,
            location: location.isEmpty ? nil : location
        )
        
        modelContext.insert(transaction)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("保存交易失败: \(error)")
        }
    }
}

// 分类选择视图
struct CategorySelectionView: View {
    @Binding var selectedCategory: Category?
    let categoryType: String
    @Environment(\.dismiss) private var dismiss
    
    @Query private var categories: [Category]
    
    var filteredCategories: [Category] {
        categories.filter { $0.type == categoryType }
    }
    
    var body: some View {
        List {
            ForEach(filteredCategories) { category in
                Button {
                    selectedCategory = category
                    // 选择分类后自动返回上一页
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
        .navigationTitle("选择分类")
    }
}

// 颜色扩展
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}
