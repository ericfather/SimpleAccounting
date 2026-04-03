import Foundation

extension Date {
    var iso8601: String {
        return ISO8601DateFormatter().string(from: self)
    }
}

extension String {
    var dateFromISO8601: Date? {
        return ISO8601DateFormatter().date(from: self)
    }
}
