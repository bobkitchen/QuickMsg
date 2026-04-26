import Foundation
import Security

/// Thin wrapper around `kSecClassGenericPassword` for the Worker shared secret.
///
/// Items use:
///   - `kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`
///     so the secret is readable from the locked device after first unlock —
///     required for `SendMessageIntent` to run from CarPlay or Siri without
///     prompting Face ID.
///   - `kSecAttrAccessGroup: LangoConstants.keychainAccessGroup` so the
///     widget extension can read the same item via Keychain Sharing.
enum KeychainService {
    enum KeychainError: Error {
        case unhandled(OSStatus)
    }

    static func setSecret(_ secret: String, account: String = LangoConstants.workerSecretKeychainAccount) throws {
        guard let data = secret.data(using: .utf8) else { return }

        // Update if exists, otherwise add.
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrAccessGroup as String: LangoConstants.keychainAccessGroup,
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        switch updateStatus {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            var addQuery = query
            addQuery.merge(attributes) { _, new in new }
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.unhandled(addStatus)
            }
        default:
            throw KeychainError.unhandled(updateStatus)
        }
    }

    static func getSecret(account: String = LangoConstants.workerSecretKeychainAccount) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrAccessGroup as String: LangoConstants.keychainAccessGroup,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let str = String(data: data, encoding: .utf8) else {
            return nil
        }
        return str
    }

    static func deleteSecret(account: String = LangoConstants.workerSecretKeychainAccount) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrAccessGroup as String: LangoConstants.keychainAccessGroup,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
