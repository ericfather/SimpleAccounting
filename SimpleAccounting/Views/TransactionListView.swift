import SwiftUI
import SwiftData

struct TransactionListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var transactions: [Transaction] = []
    @State private var currentPage = 1
    @State private var isLoading = false
    @State private var hasMoreData = true
    @State private var isEditMode = false
    @State private var selectedTransactions: Set<UUID> = []
    @State private var showAddTransaction = false

    private let pageSize = 20

    var body: some View {
        NavigationStack {
            Group {
                if transactions.isEmpty && !isLoading {
                    EmptyTransactionView(showAddTransaction: $showAddTransaction)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(transactions, id: \.id) { transaction in
                                TransactionRow(
                                    transaction: transaction,
                                    isSelected: selectedTransactions.contains(transaction.id),
                                    isEditMode: isEditMode,
                                    onSelect: { id in
                                        if selectedTransactions.contains(id) {
                                            selectedTransactions.remove(id)
                                        } else {
                                            selectedTransactions.insert(id)
                                        }
                                    }
                                )
                            }

                            if isLoading {
                                ProgressView()
                                    .padding()
                            }

                            if !isLoading && hasMoreData {
                                Color.clear
                                    .frame(height: 10)
                                    .onAppear {
                                        loadMoreData()
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .onAppear {
                if transactions.isEmpty {
                    loadInitialData()
                }
            }
            .navigationTitle("交易记录")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditMode {
                        Button("取消") {
                            isEditMode = false
                            selectedTransactions.removeAll()
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditMode {
                        Button("删除") {
                            batchDelete()
                        }
                        .disabled(selectedTransactions.isEmpty)
                    } else {
                        Button("编辑") {
                            isEditMode = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddTransaction) {
                AddTransactionView()
            }
        }
    }

    private func loadInitialData() {
        isLoading = true
        do {
            let initialTransactions = try DataService.shared.getTransactions(page: 1, pageSize: pageSize)
            transactions = initialTransactions
            currentPage = 1
            hasMoreData = initialTransactions.count == pageSize
        } catch {
            print("加载初始数据失败: \(error)")
        }
        isLoading = false
    }

    private func loadMoreData() {
        guard !isLoading && hasMoreData else { return }

        isLoading = true
        do {
            let nextPage = currentPage + 1
            let moreTransactions = try DataService.shared.getTransactions(page: nextPage, pageSize: pageSize)
            transactions.append(contentsOf: moreTransactions)
            currentPage = nextPage
            hasMoreData = moreTransactions.count == pageSize
        } catch {
            print("加载更多数据失败: \(error)")
        }
        isLoading = false
    }

    private func batchDelete() {
        let selectedIds = selectedTransactions

        do {
            for id in selectedIds {
                try DataService.shared.deleteTransaction(id: id)
            }
            transactions.removeAll { selectedIds.contains($0.id) }
        } catch {
            print("删除交易失败: \(error)")
        }

        isEditMode = false
        selectedTransactions.removeAll()
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    let isSelected: Bool
    let isEditMode: Bool
    let onSelect: (UUID) -> Void

    var body: some View {
        NavigationLink {
            EditTransactionView(transaction: transaction)
        } label: {
            HStack {
                if isEditMode {
                    Button(action: {
                        onSelect(transaction.id)
                    }) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isSelected ? .blue : .gray)
                            .padding(.trailing, 8)
                    }
                }

                VStack(alignment: .leading) {
                    Text(transaction.category?.name ?? "未分类")
                        .font(.headline)
                    Text(transaction.note)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text(transaction.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(transaction.type == "income" ? "+\(transaction.amount)" : "-\(transaction.amount)")
                    .font(.headline)
                    .foregroundColor(transaction.type == "income" ? .green : .red)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .disabled(isEditMode)
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

    return TransactionListView()
        .modelContainer(container)
}

// 空状态视图组件
struct EmptyTransactionView: View {
    @Binding var showAddTransaction: Bool

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 70))
                .foregroundColor(.gray)

            Text("暂无交易记录")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            Text("点击下方按钮开始记账")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button(action: {
                showAddTransaction = true
            }) {
                Text("记一笔")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .cornerRadius(25)
            }
            .padding(.top, 10)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
