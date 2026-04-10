//
//  Keychain.swift
//  Coding-Test-2026-04-SRAM
//
//  Created by Ky directing Claude 4.6 Sonnet on 2026-04-10.
//

import Foundation
import Security

import Introspection



/// Thin, type-safe wrapper around the system Keychain.
///
/// Prefer this over `UserDefaults` for any credential storage. All entries are
/// namespaced under a service identifier so they can't collide with other apps,
/// and they survive app reinstalls via iCloud Keychain backup.
///
/// Usage:
/// ```swift
/// try Keychain.save("tok_abc", forKey: "access_token")
/// let token = try Keychain.load(forKey: "access_token")
/// try Keychain.delete(forKey: "access_token")
/// ```
enum Keychain {

    private static let service = Introspection.bundleId

    enum KeychainError: LocalizedError {
        case unexpectedData
        case itemNotFound
        case unhandledError(OSStatus)

        var errorDescription: String? {
            switch self {
            case .unexpectedData:             return "Unexpected keychain data format"
            case .itemNotFound:               return "Keychain item not found"
            case .unhandledError(let status): return "Keychain OSStatus \(status)"
            }
        }
    }

    /// Persists a string value under the given key, replacing any prior value.
    static func save(_ value: String, forKey key: String) throws {
        let data  = Data(value.utf8)
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecValueData:   data
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.unhandledError(status) }
    }

    /// Retrieves and decodes a previously saved string value.
    static func load(forKey key: String) throws -> String {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecReturnData:  true,
            kSecMatchLimit:  kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else {
            throw status == errSecItemNotFound ? KeychainError.itemNotFound
                                               : KeychainError.unhandledError(status)
        }
        guard let data = result as? Data, let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedData
        }
        return string
    }

    /// Removes the stored value for the given key. No-ops silently if the key doesn't exist.
    static func delete(forKey key: String) throws {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status)
        }
    }
}
