import Foundation
import SwiftData

@Model
class Ledger {
    @Attribute(.unique) var id: UUID
    var name: String
    var description: String
    var createdAt: Date
    var updatedAt: Date
    
    init(name: String, description: String = "") {
        self.id = UUID()
        self.name = name
        self.description = description
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    init(from dict: [String: Any]) {
        self.id = UUID(uuidString: dict["id"] as? String ?? UUID().uuidString) ?? UUID()
        self.name = dict["name"] as? String ?? ""
        self.description = dict["description"] as? String ?? ""
        self.createdAt = (dict["createdAt"] as? String ?? "").dateFromISO8601 ?? Date()
        self.updatedAt = (dict["updatedAt"] as? String ?? "").dateFromISO8601 ?? Date()
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id.uuidString,
            "name": name,
            "description": description,
            "createdAt": createdAt.iso8601,
            "updatedAt": updatedAt.iso8601
        ]
    }
}