import Foundation
import SwiftData

@Model
class Tag {
    @Attribute(.unique) var id: UUID
    var name: String
    var color: String
    var createdAt: Date
    
    init(name: String, color: String) {
        self.id = UUID()
        self.name = name
        self.color = color
        self.createdAt = Date()
    }
    
    init(from dict: [String: Any]) {
        self.id = UUID(uuidString: dict["id"] as? String ?? UUID().uuidString) ?? UUID()
        self.name = dict["name"] as? String ?? ""
        self.color = dict["color"] as? String ?? "#000000"
        self.createdAt = (dict["createdAt"] as? String ?? "").dateFromISO8601 ?? Date()
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id.uuidString,
            "name": name,
            "color": color,
            "createdAt": createdAt.iso8601
        ]
    }
}