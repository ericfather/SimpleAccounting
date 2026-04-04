import Foundation
import SwiftData

class DataService {
    static let shared = DataService()
    
    var modelContext: ModelContext?
    
    private init() {}
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func initializeDefaultData() throws {
        guard let modelContext = modelContext else { throw DataError.noContext }
        
        // 检查是否已有默认分类
        let categoryFetchDescriptor = FetchDescriptor<Category>(predicate: #Predicate<Category> { $0.isDefault == true })
        let existingCategories = try modelContext.fetch(categoryFetchDescriptor)
        
        if existingCategories.isEmpty {
            // 创建默认支出分类
            let expenseCategories = [
                Category(name: "餐饮", icon: "fork.knife", color: "#FF6B6B", type: "expense", sortOrder: 0, isDefault: true),
                Category(name: "交通", icon: "car", color: "#4ECDC4", type: "expense", sortOrder: 1, isDefault: true),
                Category(name: "购物", icon: "cart", color: "#45B7D1", type: "expense", sortOrder: 2, isDefault: true),
                Category(name: "娱乐", icon: "film", color: "#96CEB4", type: "expense", sortOrder: 3, isDefault: true),
                Category(name: "医疗", icon: "cross", color: "#FFEAA7", type: "expense", sortOrder: 4, isDefault: true),
                Category(name: "教育", icon: "book", color: "#DDA0DD", type: "expense", sortOrder: 5, isDefault: true),
                Category(name: "房租", icon: "house", color: "#98D8C8", type: "expense", sortOrder: 6, isDefault: true),
                Category(name: "其他", icon: "ellipsis", color: "#95A5A6", type: "expense", sortOrder: 7, isDefault: true)
            ]
            
            // 创建默认收入分类
            let incomeCategories = [
                Category(name: "工资", icon: "briefcase", color: "#2ECC71", type: "income", sortOrder: 0, isDefault: true),
                Category(name: "奖金", icon: "star", color: "#F1C40F", type: "income", sortOrder: 1, isDefault: true),
                Category(name: "投资", icon: "chart.line.uptrend.xyaxis", color: "#3498DB", type: "income", sortOrder: 2, isDefault: true),
                Category(name: "其他", icon: "ellipsis", color: "#95A5A6", type: "income", sortOrder: 3, isDefault: true)
            ]
            
            // 添加默认分类到上下文
            expenseCategories.forEach { modelContext.insert($0) }
            incomeCategories.forEach { modelContext.insert($0) }
            
            // 创建默认账本
            let defaultLedger = Ledger(name: "默认账本", description: "默认账本")
            modelContext.insert(defaultLedger)
            
            // 保存更改
            try modelContext.save()
        }
    }
    
    // 加密相关方法
    func encryptData(_ data: Data) throws -> Data {
        return try EncryptionService.shared.encrypt(data: data)
    }
    
    func decryptData(_ data: Data) throws -> Data {
        return try EncryptionService.shared.decrypt(data: data)
    }
    
    func encryptString(_ string: String) throws -> String {
        return try EncryptionService.shared.encryptString(string)
    }
    
    func decryptString(_ encryptedString: String) throws -> String {
        return try EncryptionService.shared.decryptString(encryptedString)
    }
    
    // 数据备份相关方法
    func exportData() throws -> Data {
        guard let modelContext = modelContext else { throw DataError.noContext }
        do {
            // 导出所有数据
            let transactions = try modelContext.fetch(FetchDescriptor<Transaction>())
            let categories = try modelContext.fetch(FetchDescriptor<Category>())
            let ledgers = try modelContext.fetch(FetchDescriptor<Ledger>())
            let tags = try modelContext.fetch(FetchDescriptor<Tag>())
            let budgets = try modelContext.fetch(FetchDescriptor<Budget>())
            
            // 创建导出数据结构
            let exportData: [String: Any] = [
                "transactions": transactions.map { $0.toDictionary() },
                "categories": categories.map { $0.toDictionary() },
                "ledgers": ledgers.map { $0.toDictionary() },
                "tags": tags.map { $0.toDictionary() },
                "budgets": budgets.map { $0.toDictionary() }
            ]
            
            // 序列化为JSON
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            
            // 加密数据
            return try encryptData(jsonData)
        } catch {
            throw DataError.exportFailed(error)
        }
    }
    
    func importData(from url: URL) throws {
        guard let modelContext = modelContext else { throw DataError.noContext }
        do {
            // 读取文件数据
            let encryptedData = try Data(contentsOf: url)
            
            // 解密数据
            let decryptedData = try decryptData(encryptedData)
            
            // 解析JSON
            guard let json = try JSONSerialization.jsonObject(with: decryptedData, options: []) as? [String: Any] else {
                throw DataError.importFailed("Invalid JSON format")
            }
            
            // 清空现有数据
            try clearAllData()
            
            // 导入分类
            if let categoriesData = json["categories"] as? [[String: Any]] {
                for categoryDict in categoriesData {
                    let category = Category(
                        name: categoryDict["name"] as? String ?? "",
                        icon: categoryDict["icon"] as? String ?? "",
                        color: categoryDict["color"] as? String ?? "",
                        type: categoryDict["type"] as? String ?? "expense",
                        sortOrder: categoryDict["sortOrder"] as? Int ?? 0,
                        isDefault: categoryDict["isDefault"] as? Bool ?? false
                    )
                    modelContext.insert(category)
                }
            }
            
            // 导入账本
            if let ledgersData = json["ledgers"] as? [[String: Any]] {
                for ledgerDict in ledgersData {
                    let ledger = Ledger(
                        name: ledgerDict["name"] as? String ?? "",
                        description: ledgerDict["description"] as? String ?? ""
                    )
                    modelContext.insert(ledger)
                }
            }
            
            // 导入标签
            if let tagsData = json["tags"] as? [[String: Any]] {
                for tagDict in tagsData {
                    let tag = Tag(
                        name: tagDict["name"] as? String ?? "",
                        color: tagDict["color"] as? String ?? ""
                    )
                    modelContext.insert(tag)
                }
            }
            
            // 导入预算
            if let budgetsData = json["budgets"] as? [[String: Any]] {
                for budgetDict in budgetsData {
                    let budget = Budget(
                        amount: budgetDict["amount"] as? Double ?? 0,
                        period: budgetDict["period"] as? String ?? "monthly",
                        startDate: Date(timeIntervalSince1970: budgetDict["startDate"] as? TimeInterval ?? 0)
                    )
                    modelContext.insert(budget)
                }
            }
            
            // 导入交易记录
            if let transactionsData = json["transactions"] as? [[String: Any]] {
                let ledgers = try modelContext.fetch(FetchDescriptor<Ledger>())
                let defaultLedger = ledgers.first(where: { $0.name == "默认账本" }) ?? ledgers.first

                for transactionDict in transactionsData {
                    let transaction = Transaction(
                        amount: transactionDict["amount"] as? Double ?? 0,
                        type: transactionDict["type"] as? String ?? "expense",
                        category: nil,
                        ledger: defaultLedger,
                        tags: nil,
                        note: transactionDict["note"] as? String ?? "",
                        date: Date(timeIntervalSince1970: transactionDict["date"] as? TimeInterval ?? 0),
                        location: transactionDict["location"] as? String
                    )
                    modelContext.insert(transaction)
                }
            }
            
            // 保存更改
            try modelContext.save()
        } catch {
            throw DataError.importFailed(error.localizedDescription)
        }
    }
    
    func clearAllData() throws {
        guard let modelContext = modelContext else { throw DataError.noContext }
        do {
            // 删除所有交易记录
            let transactions = try modelContext.fetch(FetchDescriptor<Transaction>())
            for transaction in transactions {
                modelContext.delete(transaction)
            }
            
            // 删除所有预算
            let budgets = try modelContext.fetch(FetchDescriptor<Budget>())
            for budget in budgets {
                modelContext.delete(budget)
            }
            
            // 删除所有标签
            let tags = try modelContext.fetch(FetchDescriptor<Tag>())
            for tag in tags {
                modelContext.delete(tag)
            }
            
            // 删除所有账本
            let ledgers = try modelContext.fetch(FetchDescriptor<Ledger>())
            for ledger in ledgers {
                modelContext.delete(ledger)
            }
            
            // 删除所有分类
            let categories = try modelContext.fetch(FetchDescriptor<Category>())
            for category in categories {
                modelContext.delete(category)
            }
            
            // 保存更改
            try modelContext.save()
        } catch {
            throw DataError.clearFailed(error)
        }
    }
    
    // 交易记录相关方法
    func addTransaction(_ transaction: Transaction) throws {
        guard let modelContext = modelContext else { throw DataError.noContext }
        modelContext.insert(transaction)
        try modelContext.save()
    }
    
    func updateTransaction(_ transaction: Transaction) throws {
        guard let modelContext = modelContext else { throw DataError.noContext }
        try modelContext.save()
    }
    
    func deleteTransaction(_ transaction: Transaction) throws {
        guard let modelContext = modelContext else { throw DataError.noContext }
        modelContext.delete(transaction)
        try modelContext.save()
    }

    func deleteTransaction(id: UUID) throws {
        guard let modelContext = modelContext else { throw DataError.noContext }
        let descriptor = FetchDescriptor<Transaction>(predicate: #Predicate { $0.id == id })
        if let transaction = try modelContext.fetch(descriptor).first {
            modelContext.delete(transaction)
            try modelContext.save()
        }
    }
    
    func getTransactions() throws -> [Transaction] {
        guard let modelContext = modelContext else { throw DataError.noContext }
        let descriptor = FetchDescriptor<Transaction>(sortBy: [SortDescriptor<Transaction>(\.date, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }
    
    func getTransactions(page: Int, pageSize: Int) throws -> [Transaction] {
        guard let modelContext = modelContext else { throw DataError.noContext }
        guard page > 0 else { throw DataError.fetchFailed }
        var descriptor = FetchDescriptor<Transaction>(sortBy: [SortDescriptor<Transaction>(\.date, order: .reverse)])
        descriptor.fetchLimit = pageSize
        descriptor.fetchOffset = (page - 1) * pageSize
        return try modelContext.fetch(descriptor)
    }
    
    // 分类相关方法
    func addCategory(_ category: Category) throws {
        guard let modelContext = modelContext else { throw DataError.noContext }
        modelContext.insert(category)
        try modelContext.save()
    }
    
    func updateCategory(_ category: Category) throws {
        guard let modelContext = modelContext else { throw DataError.noContext }
        try modelContext.save()
    }
    
    func deleteCategory(_ category: Category) throws {
        guard let modelContext = modelContext else { throw DataError.noContext }
        modelContext.delete(category)
        try modelContext.save()
    }
    
    func getCategories(byType type: String) throws -> [Category] {
        guard let modelContext = modelContext else { throw DataError.noContext }
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate<Category> { $0.type == type },
            sortBy: [SortDescriptor<Category>(\.sortOrder)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    // 账本相关方法
    func addLedger(_ ledger: Ledger) throws {
        guard let modelContext = modelContext else { throw DataError.noContext }
        modelContext.insert(ledger)
        try modelContext.save()
    }
    
    func updateLedger(_ ledger: Ledger) throws {
        guard let modelContext = modelContext else { throw DataError.noContext }
        try modelContext.save()
    }
    
    func deleteLedger(_ ledger: Ledger) throws {
        guard let modelContext = modelContext else { throw DataError.noContext }
        modelContext.delete(ledger)
        try modelContext.save()
    }
    
    func getLedgers() throws -> [Ledger] {
        guard let modelContext = modelContext else { throw DataError.noContext }
        let descriptor = FetchDescriptor<Ledger>(sortBy: [SortDescriptor<Ledger>(\.createdAt)])
        return try modelContext.fetch(descriptor)
    }
    
    // 标签相关方法
    func addTag(_ tag: Tag) throws {
        guard let modelContext = modelContext else { throw DataError.noContext }
        modelContext.insert(tag)
        try modelContext.save()
    }
    
    func updateTag(_ tag: Tag) throws {
        guard let modelContext = modelContext else { throw DataError.noContext }
        try modelContext.save()
    }
    
    func deleteTag(_ tag: Tag) throws {
        guard let modelContext = modelContext else { throw DataError.noContext }
        modelContext.delete(tag)
        try modelContext.save()
    }
    
    func getTags() throws -> [Tag] {
        guard let modelContext = modelContext else { throw DataError.noContext }
        let descriptor = FetchDescriptor<Tag>(sortBy: [SortDescriptor<Tag>(\.name)])
        return try modelContext.fetch(descriptor)
    }
    
    // 预算相关方法
    func addBudget(_ budget: Budget) throws {
        guard let modelContext = modelContext else { throw DataError.noContext }
        modelContext.insert(budget)
        try modelContext.save()
    }
    
    func updateBudget(_ budget: Budget) throws {
        guard let modelContext = modelContext else { throw DataError.noContext }
        try modelContext.save()
    }
    
    func deleteBudget(_ budget: Budget) throws {
        guard let modelContext = modelContext else { throw DataError.noContext }
        modelContext.delete(budget)
        try modelContext.save()
    }
    
    func getBudgets() throws -> [Budget] {
        guard let modelContext = modelContext else { throw DataError.noContext }
        let descriptor = FetchDescriptor<Budget>(sortBy: [SortDescriptor<Budget>(\.startDate, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }

    // CSV导出方法
    func exportDataAsCSV() throws -> String {
        guard let modelContext = modelContext else { throw DataError.noContext }

        let transactions = try modelContext.fetch(FetchDescriptor<Transaction>(sortBy: [SortDescriptor<Transaction>(\.date, order: .reverse)]))

        var csvContent = "日期,类型,分类,金额,位置,备注\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.locale = Locale(identifier: "zh_CN")

        for transaction in transactions {
            let dateString = dateFormatter.string(from: transaction.date)
            let typeString = transaction.type == "income" ? "收入" : "支出"
            let categoryName = transaction.category?.name ?? "未分类"
            let amountString = String(format: "%.2f", transaction.amount)
            let locationString = transaction.location ?? ""
            let noteString = transaction.note.replacingOccurrences(of: ",", with: ";").replacingOccurrences(of: "\n", with: " ")

            csvContent += "\"\(dateString)\",\"\(typeString)\",\"\(categoryName)\",\(amountString),\"\(locationString)\",\"\(noteString)\"\n"
        }

        return csvContent
    }
}

enum DataError: Error, LocalizedError {
    case noContext
    case saveFailed
    case fetchFailed
    case exportFailed(Error)
    case importFailed(String)
    case clearFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .noContext:
            return "数据上下文未初始化"
        case .saveFailed:
            return "保存数据失败"
        case .fetchFailed:
            return "获取数据失败"
        case .exportFailed(let error):
            return "导出数据失败: \(error.localizedDescription)"
        case .importFailed(let message):
            return "导入数据失败: \(message)"
        case .clearFailed(let error):
            return "清空数据失败: \(error.localizedDescription)"
        }
    }
}
