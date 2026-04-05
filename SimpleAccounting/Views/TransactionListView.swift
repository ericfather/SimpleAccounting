import SwiftUI
import SwiftData

struct TransactionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @State private var isEditMode = false
    @State private var selectedTransactions: Set<UUID> = []
    @State private var showAddTransaction = false

    var body: some View {
        NavigationStack {
            Group {
                if allTransactions.isEmpty {
                    EmptyTransactionView(showAddTransaction: $showAddTransaction)
                } else {
                    List {
                        ForEach(allTransactions, id: \.id) { transaction in
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
                        .onDelete { offsets in
                            for index in offsets {
                                let transaction = allTransactions[index]
                                modelContext.delete(transaction)
                            }
                            try? modelContext.save()
                        }
                    }
                    .listStyle(.plain)
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

    private func batchDelete() {
        for id in selectedTransactions {
            if let transaction = allTransactions.first(where: { $0.id == id }) {
                modelContext.delete(transaction)
            }
        }
        try? modelContext.save()
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
        HStack {
            if isEditMode {
                Button(action: {
                    onSelect(transaction.id)
                }) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .blue : .gray)
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading) {
                Text(transaction.category?.name ?? "未分类")
                    .font(.headline)
                Text(transaction.note.isEmpty ? "无备注" : transaction.note)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(transaction.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(transaction.type == "income" ? "+\(String(format: "%.2f", transaction.amount))" : "-\(String(format: "%.2f", transaction.amount))")
                .font(.headline)
                .foregroundColor(transaction.type == "income" ? .green : .red)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            if isEditMode {
                onSelect(transaction.id)
            }
        }
        .background(
            NavigationLink(destination: EditTransactionView(transaction: transaction)) {
                EmptyView()
            }
            .opacity(isEditMode ? 0 : 1)
        )
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
