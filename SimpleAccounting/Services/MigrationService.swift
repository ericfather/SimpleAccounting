import Foundation
import SwiftData

class MigrationService {
    static let shared = MigrationService()
    
    private let versionKey = "appDataVersion"
    private let currentVersion = 1
    
    private init() {}
    
    func checkAndMigrate() throws {
        let storedVersion = UserDefaults.standard.integer(forKey: versionKey)
        
        if storedVersion < currentVersion {
            try migrate(from: storedVersion, to: currentVersion)
            UserDefaults.standard.set(currentVersion, forKey: versionKey)
        }
    }
    
    private func migrate(from oldVersion: Int, to newVersion: Int) throws {
        switch oldVersion {
        case 0:
            // 从无版本迁移到版本1
            try migrateToVersion1()
        case 1:
            // 未来的版本迁移
            break
        default:
            break
        }
    }
    
    private func migrateToVersion1() throws {
        // 初始化默认数据
        try DataService.shared.initializeDefaultData()
        print("数据迁移到版本1完成")
    }
    
    func resetMigration() {
        UserDefaults.standard.removeObject(forKey: versionKey)
        print("迁移状态已重置")
    }
    
    func getCurrentVersion() -> Int {
        return UserDefaults.standard.integer(forKey: versionKey)
    }
}
