//
//  EncryptionService.swift
//  MediScribe
//
//  Provides AES-256-GCM encryption for sensitive patient data
//

import Foundation
import CryptoKit

enum EncryptionError: Error {
    case encryptionFailed
    case decryptionFailed
    case invalidData
    case keyRetrievalFailed(Error)
}

final class EncryptionService {

    static let shared = EncryptionService()

    private let keychainManager = KeychainManager.shared

    private init() {}

    // MARK: - Public Interface

    /// Encrypts data using AES-256-GCM
    /// - Parameter data: Plain data to encrypt
    /// - Returns: Encrypted data (nonce + ciphertext + tag combined)
    /// - Throws: EncryptionError if encryption fails
    func encrypt(_ data: Data) throws -> Data {
        // Retrieve encryption key from keychain
        let keyData: Data
        do {
            keyData = try keychainManager.getNoteDataEncryptionKey()
        } catch {
            throw EncryptionError.keyRetrievalFailed(error)
        }

        // Create symmetric key
        let key = SymmetricKey(data: keyData)

        // Encrypt using AES-256-GCM
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)

            // Combine nonce + ciphertext + tag for storage
            // This is the standard format returned by sealedBox.combined
            guard let combined = sealedBox.combined else {
                throw EncryptionError.encryptionFailed
            }

            return combined
        } catch {
            throw EncryptionError.encryptionFailed
        }
    }

    /// Decrypts data that was encrypted with AES-256-GCM
    /// - Parameter encryptedData: Encrypted data (nonce + ciphertext + tag combined)
    /// - Returns: Decrypted plain data
    /// - Throws: EncryptionError if decryption fails
    func decrypt(_ encryptedData: Data) throws -> Data {
        // Retrieve encryption key from keychain
        let keyData: Data
        do {
            keyData = try keychainManager.getNoteDataEncryptionKey()
        } catch {
            throw EncryptionError.keyRetrievalFailed(error)
        }

        // Create symmetric key
        let key = SymmetricKey(data: keyData)

        // Decrypt using AES-256-GCM
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return decryptedData
        } catch {
            throw EncryptionError.decryptionFailed
        }
    }
}

// MARK: - Convenience Extensions

extension EncryptionService {

    /// Encrypts a Codable object to encrypted Data
    func encrypt<T: Encodable>(_ object: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let plainData = try encoder.encode(object)
        return try encrypt(plainData)
    }

    /// Decrypts encrypted Data to a Codable object
    func decrypt<T: Decodable>(_ encryptedData: Data, as type: T.Type) throws -> T {
        let plainData = try decrypt(encryptedData)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(type, from: plainData)
    }
}
