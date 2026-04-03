import Foundation
import SwiftData

@Model
class Budget {
    @Attribute(.unique) var id: UUID
    var amount: Double
    var category: Category?
    var period: String // "daily", "weekly", "monthly", "yearly"
    var startDate: Date
    var alertThreshold: Double
    var currency: String
    var createdAt: Date
    
    init(amount: Double, category: Category? = nil, period: String, startDate: Date = Date(), alertThreshold: Double = 0.8, currency: String = "CNY") {
        self.id = UUID()
        self.amount = amount
        self.category = category
        self.period = period
        self.startDate = startDate
        self.alertThreshold = alertThreshold
        self.currency = currency
        self.createdAt = Date()
    }
    
    init(from dict: [String: Any], in context: ModelContext) {
        self.id = UUID(uuidString: dict["id"] as? String ?? UUID().uuidString) ?? UUID()
        self.amount = dict["amount"] as? Double ?? 0
        self.period = dict["period"] as? String ?? "monthly"
        self.startDate = (dict["startDate"] as? String ?? "").dateFromISO8601 ?? Date()
        self.alertThreshold = dict["alertThreshold"] as? Double ?? 0.8
        self.currency = dict["currency"] as? String ?? "CNY"
        self.createdAt = (dict["createdAt"] as? String ?? "").dateFromISO8601 ?? Date()
        
        // 关联关系处理
        if let categoryId = dict["categoryId"] as? String, let category = try? context.fetch(FetchDescriptor<Category>(predicate: #Predicate { $0.id.uuidString == categoryId })).first {
            self.category = category
        }
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id.uuidString,
            "amount": amount,
            "period": period,
            "startDate": startDate.iso8601,
            "alertThreshold": alertThreshold,
            "currency": currency,
            "createdAt": createdAt.iso8601
        ]
        
        if let category = category {
            dict["categoryId"] = category.id.uuidString
        }
        
        return dict
    }
}