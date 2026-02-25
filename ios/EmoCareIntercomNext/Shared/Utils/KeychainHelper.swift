import Foundation
import Security

struct KeychainHelper {
    private static let service = "com.emocare.intercom.next"
    private static let authTokenKey = "auth_token"
    private static let userIdKey = "user_id"
    
    // MARK: - Auth Token Management
    
    static func saveAuthToken(_ token: String) {
        save(token, forKey: authTokenKey)
    }
    
    static func getAuthToken() -> String? {
        return retrieve(forKey: authTokenKey)
    }
    
    static func clearAuthToken() {
        delete(forKey: authTokenKey)
    }
    
    // MARK: - User ID Management
    
    static func saveUserId(_ userId: String) {
        save(userId, forKey: userIdKey)
    }
    
    static func getUserId() -> String? {
        return retrieve(forKey: userIdKey)
    }
    
    static func clearUserId() {
        delete(forKey: userIdKey)
    }
    
    // MARK: - Generic Keychain Operations
    
    private static func save(_ value: String, forKey key: String) {
        guard let data = value.data(using: .utf8) else {
            print("❌ Failed to convert string to data")
            return
        }
        
        // 既存のアイテムを削除
        delete(forKey: key)
        
        // 新しいアイテムを保存
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("✅ Keychain item saved successfully for key: \(key)")
        } else {
            print("❌ Failed to save keychain item for key: \(key), status: \(status)")
        }
    }
    
    private static func retrieve(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let value = String(data: data, encoding: .utf8) {
            return value
        } else {
            if status != errSecItemNotFound {
                print("❌ Failed to retrieve keychain item for key: \(key), status: \(status)")
            }
            return nil
        }
    }
    
    private static func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess || status == errSecItemNotFound {
            // 成功またはアイテムが存在しない場合は正常
        } else {
            print("❌ Failed to delete keychain item for key: \(key), status: \(status)")
        }
    }
    
    // MARK: - Bulk Operations
    
    static func clearAllData() {
        clearAuthToken()
        clearUserId()
        print("✅ All keychain data cleared")
    }
    
    static func hasStoredCredentials() -> Bool {
        return getAuthToken() != nil
    }
}

// MARK: - Keychain Error Handling

extension KeychainHelper {
    private static func keychainErrorDescription(status: OSStatus) -> String {
        switch status {
        case errSecSuccess:
            return "Success"
        case errSecUnimplemented:
            return "Function or operation not implemented"
        case errSecIO:
            return "I/O error"
        case errSecOpWr:
            return "File already open with with write permission"
        case errSecParam:
            return "One or more parameters passed to a function were not valid"
        case errSecAllocate:
            return "Failed to allocate memory"
        case errSecUserCanceled:
            return "User canceled the operation"
        case errSecBadReq:
            return "Bad parameter or invalid state for operation"
        case errSecInternalComponent:
            return "Internal component error"
        case errSecNotAvailable:
            return "No keychain is available"
        case errSecDuplicateItem:
            return "The specified item already exists in the keychain"
        case errSecItemNotFound:
            return "The specified item could not be found in the keychain"
        case errSecInteractionNotAllowed:
            return "User interaction is not allowed"
        case errSecDecode:
            return "Unable to decode the provided data"
        case errSecAuthFailed:
            return "The user name or passphrase you entered is not correct"
        default:
            return "Unknown error (\(status))"
        }
    }
}
