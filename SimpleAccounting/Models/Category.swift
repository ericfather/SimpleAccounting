import Foundation
import SwiftData

@Model
class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String
    var color: String
    var type: String // "income" or "expense"
    var sortOrder: Int
    var isDefault: Bool
    var parentCategory: Category?
    var createdAt: Date
    
    init(name: String, icon: String, color: String, type: String, sortOrder: Int = 0, isDefault: Bool = false, parentCategory: Category? = nil) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.color = color
        self.type = type
        self.sortOrder = sortOrder
        self.isDefault = isDefault
        self.parentCategory = parentCategory
        self.createdAt = Date()
    }
    
    init(from dict: [String: Any]) {
        self.id = UUID(uuidString: dict["id"] as? String ?? UUID().uuidString) ?? UUID()
        self.name = dict["name"] as? String ?? ""
        self.icon = dict["icon"] as? String ?? ""
        self.color = dict["color"] as? String ?? "#000000"
        self.type = dict["type"] as? String ?? "expense"
        self.sortOrder = dict["sortOrder"] as? Int ?? 0
        self.isDefault = dict["isDefault"] as? Bool ?? false
        self.createdAt = (dict["createdAt"] as? String ?? "").dateFromISO8601 ?? Date()
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id.uuidString,
            "name": name,
            "icon": icon,
            "color": color,
            "type": type,
            "sortOrder": sortOrder,
            "isDefault": isDefault,
            "createdAt": createdAt.iso8601
        ]
        
        if let parentCategory = parentCategory {
            dict["parentCategoryId"] = parentCategory.id.uuidString
        }
        
        return dict
    }
}