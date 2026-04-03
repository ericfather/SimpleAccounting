import SwiftUI

struct TransactionListView: View {
    @State private var transactions: [Transaction] = []
    @State private var currentPage = 1
    @State private var isLoading = false
    @State private var hasMoreData = true
    @State private var isEditMode = false
    @State private var selectedTransactions: Set<UUID> = []
    
    private let pageSize = 20
    
    var body: some View {
        NavigationStack {
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
        }
    }
    
    private func loadInitialData() {
        isLoading = true
        DispatchQueue.global(qos: .background).async {
            do {
                let initialTransactions = try DataService.shared.getTransactions(page: 1, pageSize: pageSize)
                DispatchQueue.main.async {
                    transactions = initialTransactions
                    currentPage = 1
                    hasMoreData = initialTransactions.count == pageSize
                    isLoading = false
                }
            } catch {
                print("加载初始数据失败: \(error)")
                DispatchQueue.main.async {
                    isLoading = false
                }
            }
        }
    }
    
    private func loadMoreData() {
        guard !isLoading && hasMoreData else { return }
        
        isLoading = true
        DispatchQueue.global(qos: .background).async {
            do {
                let nextPage = currentPage + 1
                let moreTransactions = try DataService.shared.getTransactions(page: nextPage, pageSize: pageSize)
                DispatchQueue.main.async {
                    transactions.append(contentsOf: moreTransactions)
                    currentPage = nextPage
                    hasMoreData = moreTransactions.count == pageSize
                    isLoading = false
                }
            } catch {
                print("加载更多数据失败: \(error)")
                DispatchQueue.main.async {
                    isLoading = false
                }
            }
        }
    }
    
    private func batchDelete() {
        let selectedIds = selectedTransactions
        
        // 先从数据库中删除
        DispatchQueue.global(qos: .background).async {
            for id in selectedIds {
                // 这里应该从数据库中获取交易并删除
                // 简化实现，假设DataService有根据ID删除的方法
                // 或者我们可以修改DataService添加批量删除方法
                do {
                    // 这里需要实现根据ID删除交易的逻辑
                    // 暂时使用遍历所有交易的方式
                    let allTransactions = try DataService.shared.getTransactions()
                    if let transaction = allTransactions.first(where: { $0.id == id }) {
                        try DataService.shared.deleteTransaction(transaction)
                    }
                } catch {
                    print("删除交易失败: \(error)")
                }
            }
            
            DispatchQueue.main.async {
                // 从本地数组中移除选中的交易
                self.transactions.removeAll { selectedIds.contains($0.id) }
                self.isEditMode = false
                self.selectedTransactions.removeAll()
            }
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    let isSelected: Bool
    let isEditMode: Bool
    let onSelect: (UUID) -> Void
    
    var body: some View {
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
}

#Preview {
    TransactionListView()
}
