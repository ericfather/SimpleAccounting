import Foundation
import Security
import CryptoKit

class EncryptionService {
    static let shared = EncryptionService()
    
    private let keychainService = "com.simpleaccounting.keychain"
    private let encryptionKeyTag = "encryptionKey"
    
    private init() {}
    
    func getEncryptionKey() throws -> Data {
        if let existingKey = try retrieveKeyFromKeychain() {
            return existingKey
        } else {
            let newKey = try generateEncryptionKey()
            try storeKeyInKeychain(newKey)
            return newKey
        }
    }
    
    private func generateEncryptionKey() throws -> Data {
        var key = Data(count: 32)
        let result = key.withUnsafeMutableBytes { mutableBytes in
            SecRandomCopyBytes(kSecRandomDefault, 32, mutableBytes)
        }
        
        guard result == errSecSuccess else {
            throw EncryptionError.keyGenerationFailed
        }
        
        return key
    }
    
    private func storeKeyInKeychain(_ key: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: encryptionKeyTag,
            kSecValueData as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw EncryptionError.keyStorageFailed
        }
    }
    
    private func retrieveKeyFromKeychain() throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: encryptionKeyTag,
            kSecReturnData as String: true as CFBoolean
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess {
            return result as? Data
        } else if status == errSecItemNotFound {
            return nil
        } else {
            throw EncryptionError.keyRetrievalFailed
        }
    }
    
    func encrypt(data: Data) throws -> Data {
        let key = try getEncryptionKey()
        return try AESGCM.encrypt(data: data, key: key)
    }
    
    func decrypt(data: Data) throws -> Data {
        let key = try getEncryptionKey()
        return try AESGCM.decrypt(data: data, key: key)
    }
    
    func encryptString(_ string: String) throws -> String {
        guard let data = string.data(using: .utf8) else {
            throw EncryptionError.invalidData
        }
        let encryptedData = try encrypt(data: data)
        return encryptedData.base64EncodedString()
    }
    
    func decryptString(_ encryptedString: String) throws -> String {
        guard let encryptedData = Data(base64Encoded: encryptedString) else {
            throw EncryptionError.invalidData
        }
        let decryptedData = try decrypt(data: encryptedData)
        guard let string = String(data: decryptedData, encoding: .utf8) else {
            throw EncryptionError.invalidData
        }
        return string
    }
}

enum EncryptionError: Error, LocalizedError {
    case keyGenerationFailed
    case keyStorageFailed
    case keyRetrievalFailed
    case encryptionFailed
    case decryptionFailed
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .keyGenerationFailed:
            return "密钥生成失败"
        case .keyStorageFailed:
            return "密钥存储失败"
        case .keyRetrievalFailed:
            return "密钥获取失败"
        case .encryptionFailed:
            return "加密失败"
        case .decryptionFailed:
            return "解密失败"
        case .invalidData:
            return "无效的数据"
        }
    }
}

// AES-GCM加密实现
struct AESGCM {
    static func encrypt(data: Data, key: Data) throws -> Data {
        // 确保密钥长度正确
        guard key.count == 32 else {
            throw EncryptionError.encryptionFailed
        }
        
        do {
            // 创建对称密钥
            let symmetricKey = SymmetricKey(data: key)
            
            // 生成随机IV
            let iv = AES.GCM.Nonce()
            
            // 加密数据
            let sealedBox = try AES.GCM.seal(data, using: symmetricKey, nonce: iv)
            
            // 组合IV、密文和认证标签
            var result = Data()
            result.append(iv.withUnsafeBytes { Data($0) })
            result.append(sealedBox.ciphertext)
            result.append(sealedBox.tag)
            
            return result
        } catch {
            throw EncryptionError.encryptionFailed
        }
    }
    
    static func decrypt(data: Data, key: Data) throws -> Data {
        // 确保密钥长度正确
        guard key.count == 32 else {
            throw EncryptionError.decryptionFailed
        }
        
        let nonceByteCount = 12
        
        // 确保数据长度足够
        guard data.count >= nonceByteCount + 16 else {
            throw EncryptionError.invalidData
        }
        
        do {
            // 提取IV、密文和认证标签
            let iv = try AES.GCM.Nonce(data: data.prefix(nonceByteCount))
            let ciphertext = data.subdata(in: nonceByteCount..<(data.count - 16))
            let tag = data.suffix(16)
            
            // 创建对称密钥
            let symmetricKey = SymmetricKey(data: key)
            
            // 创建密封盒
            let sealedBox = try AES.GCM.SealedBox(nonce: iv, ciphertext: ciphertext, tag: tag)
            
            // 解密数据
            let decryptedData = try AES.GCM.open(sealedBox, using: symmetricKey)
            
            return decryptedData
        } catch {
            throw EncryptionError.decryptionFailed
        }
    }
}
