//
//  KeychainManager.swift
//  MediScribe
//
//  Manages secure storage of encryption keys in iOS Keychain
//

import Foundation
import Security

enum KeychainError: Error {
    case duplicateItem
    case itemNotFound
    case unexpectedStatus(OSStatus)
    case invalidData
    case unableToCreateKey
}

final class KeychainManager {

    static let shared = KeychainManager()

    private init() {}

    // MARK: - Key Identifiers

    private let noteDataEncryptionKeyIdentifier = "com.mediscribe.encryption.notedata"

    // MARK: - Public Interface

    /// Retrieves or generates the encryption key for note data
    /// - Returns: 256-bit encryption key
    /// - Throws: KeychainError if key cannot be retrieved or created
    func getNoteDataEncryptionKey() throws -> Data {
        // Try to retrieve existing key
        if let existingKey = try? retrieveKey(identifier: noteDataEncryptionKeyIdentifier) {
            return existingKey
        }

        // Generate new key if none exists
        let newKey = generateEncryptionKey()
        try storeKey(newKey, identifier: noteDataEncryptionKeyIdentifier)
        return newKey
    }

    /// Deletes the note data encryption key (USE WITH CAUTION - will make existing data unrecoverable)
    func deleteNoteDataEncryptionKey() throws {
        try deleteKey(identifier: noteDataEncryptionKeyIdentifier)
    }

    // MARK: - Private Implementation

    private func generateEncryptionKey() -> Data {
        // Generate 256-bit (32-byte) random key
        var keyData = Data(count: 32)
        let result = keyData.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, 32, bytes.baseAddress!)
        }

        assert(result == errSecSuccess, "Failed to generate random encryption key")
        return keyData
    }

    private func storeKey(_ key: Data, identifier: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: identifier,
            kSecAttrService as String: "MediScribe",
            kSecValueData as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            if status == errSecDuplicateItem {
                throw KeychainError.duplicateItem
            }
            throw KeychainError.unexpectedStatus(status)
        }
    }

    private func retrieveKey(identifier: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: identifier,
            kSecAttrService as String: "MediScribe",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unexpectedStatus(status)
        }

        guard let keyData = result as? Data else {
            throw KeychainError.invalidData
        }

        return keyData
    }

    private func deleteKey(identifier: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: identifier,
            kSecAttrService as String: "MediScribe"
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}
