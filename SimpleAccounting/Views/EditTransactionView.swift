import SwiftUI
import SwiftData

struct EditTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let transaction: Transaction

    // 交易类型
    @State private var transactionType: String = "expense"
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
            .navigationTitle("编辑记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        updateTransaction()
                    }
                }
            }
            .alert("错误", isPresented: $showError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                loadTransactionData()
            }
        }
    }

    private func loadTransactionData() {
        transactionType = transaction.type
        amount = String(format: "%.2f", transaction.amount)
        selectedCategory = transaction.category
        date = transaction.date
        note = transaction.note
        location = transaction.location ?? ""
    }

    private func updateTransaction() {
        guard !amount.isEmpty else {
            errorMessage = "请输入金额"
            showError = true
            return
        }

        guard let amountDouble = Double(amount) else {
            errorMessage = "无效的金额格式"
            showError = true
            return
        }

        guard amountDouble > 0 else {
            errorMessage = "金额必须大于0"
            showError = true
            return
        }

        guard amountDouble <= 999999999.99 else {
            errorMessage = "金额不能超过999,999,999.99"
            showError = true
            return
        }

        let finalAmount = round(amountDouble * 100) / 100

        transaction.amount = finalAmount
        transaction.type = transactionType
        transaction.category = selectedCategory
        transaction.note = note
        transaction.date = date
        transaction.location = location.isEmpty ? nil : location
        transaction.updatedAt = Date()

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
            showError = true
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

    let transaction = Transaction(amount: 100, type: "expense", note: "测试", date: Date())
    return EditTransactionView(transaction: transaction)
        .modelContainer(container)
}
