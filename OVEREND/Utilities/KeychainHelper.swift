//
//  KeychainHelper.swift
//  OVEREND
//
//  Keychain 安全存取工具
//  用於安全存儲 API 金鑰等敏感資訊
//

import Foundation
import Security

// MARK: - Keychain Helper

/// 統一的 Keychain 存取工具
enum KeychainHelper {
    
    // MARK: - Keychain Keys
    
    /// 預定義的 Keychain 金鑰
    enum Key: String {
        case geminiAPIKey = "com.overend.gemini.api.key"
        case notionAPIKey = "com.overend.notion.api.key"
        case zoteroAPIKey = "com.overend.zotero.api.key"
        case crossrefAPIKey = "com.overend.crossref.api.key"
    }
    
    // MARK: - Error Types
    
    /// Keychain 操作錯誤
    enum KeychainError: Error, LocalizedError {
        case duplicateEntry
        case unknown(OSStatus)
        case itemNotFound
        case invalidData
        
        var errorDescription: String? {
            switch self {
            case .duplicateEntry:
                return "Keychain 項目已存在"
            case .unknown(let status):
                return "Keychain 操作失敗，錯誤代碼: \(status)"
            case .itemNotFound:
                return "Keychain 項目未找到"
            case .invalidData:
                return "無效的數據格式"
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// 保存數據到 Keychain
    /// - Parameters:
    ///   - key: 存儲金鑰
    ///   - value: 要存儲的值
    /// - Throws: KeychainError
    static func save(key: Key, value: String) throws {
        try save(key: key.rawValue, value: value)
    }
    
    /// 保存數據到 Keychain（使用自定義 key）
    /// - Parameters:
    ///   - key: 存儲金鑰字串
    ///   - value: 要存儲的值
    /// - Throws: KeychainError
    static func save(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        
        // 先嘗試更新现有项目
        let updateQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let updateAttributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
        
        if updateStatus == errSecSuccess {
            return
        }
        
        if updateStatus == errSecItemNotFound {
            // 项目不存在，创建新项目
            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
            ]
            
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            
            guard addStatus == errSecSuccess else {
                throw KeychainError.unknown(addStatus)
            }
        } else {
            throw KeychainError.unknown(updateStatus)
        }
    }
    
    /// 從 Keychain 載入數據
    /// - Parameter key: 存儲金鑰
    /// - Returns: 存儲的值，如果不存在則返回 nil
    static func load(key: Key) -> String? {
        return load(key: key.rawValue)
    }
    
    /// 從 Keychain 載入數據（使用自定義 key）
    /// - Parameter key: 存儲金鑰字串
    /// - Returns: 存儲的值，如果不存在則返回 nil
    static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
    
    /// 從 Keychain 刪除數據
    /// - Parameter key: 存儲金鑰
    /// - Throws: KeychainError
    static func delete(key: Key) throws {
        try delete(key: key.rawValue)
    }
    
    /// 從 Keychain 刪除數據（使用自定義 key）
    /// - Parameter key: 存儲金鑰字串
    /// - Throws: KeychainError
    static func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unknown(status)
        }
    }
    
    /// 檢查 Keychain 中是否存在指定金鑰
    /// - Parameter key: 存儲金鑰
    /// - Returns: 是否存在
    static func exists(key: Key) -> Bool {
        return exists(key: key.rawValue)
    }
    
    /// 檢查 Keychain 中是否存在指定金鑰（使用自定義 key）
    /// - Parameter key: 存儲金鑰字串
    /// - Returns: 是否存在
    static func exists(key: String) -> Bool {
        return load(key: key) != nil
    }
    
    // MARK: - Migration Helpers
    
    /// 從 UserDefaults 遷移到 Keychain
    /// - Parameters:
    ///   - userDefaultsKey: UserDefaults 中的金鑰
    ///   - keychainKey: Keychain 中的目標金鑰
    ///   - deleteAfterMigration: 遷移後是否刪除 UserDefaults 中的值
    /// - Returns: 是否成功遷移
    @discardableResult
    static func migrateFromUserDefaults(
        userDefaultsKey: String,
        to keychainKey: Key,
        deleteAfterMigration: Bool = true
    ) -> Bool {
        guard let value = UserDefaults.standard.string(forKey: userDefaultsKey),
              !value.isEmpty else {
            return false
        }
        
        do {
            try save(key: keychainKey, value: value)
            
            if deleteAfterMigration {
                UserDefaults.standard.removeObject(forKey: userDefaultsKey)
            }
            
            logInfo("Successfully migrated \(userDefaultsKey) to Keychain", category: .security)
            return true
        } catch {
            logError("Failed to migrate \(userDefaultsKey) to Keychain", category: .security, error: error)
            return false
        }
    }
}

// MARK: - Convenience Extensions

extension KeychainHelper {
    
    /// Gemini API Key 便捷訪問器
    static var geminiAPIKey: String {
        get { load(key: .geminiAPIKey) ?? "" }
        set {
            do {
                if newValue.isEmpty {
                    try delete(key: .geminiAPIKey)
                } else {
                    try save(key: .geminiAPIKey, value: newValue)
                }
            } catch {
                logError("Failed to save Gemini API Key", category: .security, error: error)
            }
        }
    }
    
    /// Notion API Key 便捷訪問器
    static var notionAPIKey: String {
        get { load(key: .notionAPIKey) ?? "" }
        set {
            do {
                if newValue.isEmpty {
                    try delete(key: .notionAPIKey)
                } else {
                    try save(key: .notionAPIKey, value: newValue)
                }
            } catch {
                logError("Failed to save Notion API Key", category: .security, error: error)
            }
        }
    }
    
    /// Zotero API Key 便捷訪問器
    static var zoteroAPIKey: String {
        get { load(key: .zoteroAPIKey) ?? "" }
        set {
            do {
                if newValue.isEmpty {
                    try delete(key: .zoteroAPIKey)
                } else {
                    try save(key: .zoteroAPIKey, value: newValue)
                }
            } catch {
                logError("Failed to save Zotero API Key", category: .security, error: error)
            }
        }
    }
}
