import Foundation
import SwiftData

@Model
class Transaction {
    @Attribute(.unique) var id: UUID
    var amount: Double
    var type: String // "income" or "expense"
    var category: Category?
    var ledger: Ledger?
    var tags: [Tag]?
    var note: String
    var date: Date
    var location: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(amount: Double, type: String, category: Category? = nil, ledger: Ledger? = nil, tags: [Tag]? = nil, note: String = "", date: Date = Date(), location: String? = nil) {
        self.id = UUID()
        self.amount = amount
        self.type = type
        self.category = category
        self.ledger = ledger
        self.tags = tags
        self.note = note
        self.date = date
        self.location = location
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    init(from dict: [String: Any], in context: ModelContext) {
        self.id = UUID(uuidString: dict["id"] as? String ?? UUID().uuidString) ?? UUID()
        self.amount = dict["amount"] as? Double ?? 0
        self.type = dict["type"] as? String ?? "expense"
        self.note = dict["note"] as? String ?? ""
        self.date = (dict["date"] as? String ?? "").dateFromISO8601 ?? Date()
        self.location = dict["location"] as? String
        self.createdAt = (dict["createdAt"] as? String ?? "").dateFromISO8601 ?? Date()
        self.updatedAt = (dict["updatedAt"] as? String ?? "").dateFromISO8601 ?? Date()
        self.tags = nil
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id.uuidString,
            "amount": amount,
            "type": type,
            "note": note,
            "date": date.iso8601,
            "location": location as Any,
            "createdAt": createdAt.iso8601,
            "updatedAt": updatedAt.iso8601
        ]
        
        if let category = category {
            dict["categoryId"] = category.id.uuidString
        }
        
        if let ledger = ledger {
            dict["ledgerId"] = ledger.id.uuidString
        }
        
        if let tags = tags {
            dict["tagIds"] = tags.map { $0.id.uuidString }
        }
        
        return dict
    }
}
