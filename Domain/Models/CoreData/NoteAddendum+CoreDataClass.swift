//
//  NoteAddendum+CoreDataClass.swift
//  MediScribe
//
//  Core Data class for NoteAddendum entity with encrypted storage support
//

import Foundation
import CoreData

@objc(NoteAddendum)
public class NoteAddendum: NSManagedObject {

    // MARK: - Encrypted Field Access

    private let encryptionService = EncryptionService.shared

    // MARK: - Addendum Text Encryption

    /// Sets the addendum text with automatic encryption
    /// - Parameter text: The addendum text to encrypt and store
    /// - Throws: EncryptionError if encryption fails
    func setAddendumText(_ text: String) throws {
        guard let textData = text.data(using: .utf8) else {
            throw EncryptionError.invalidData
        }

        let encryptedData = try encryptionService.encrypt(textData)
        self.encryptedAddendumText = encryptedData
        self.addendumText = nil  // Clear legacy field
        self.isEncrypted = true
    }

    /// Retrieves and decrypts the addendum text
    /// - Returns: Decrypted addendum text
    /// - Throws: EncryptionError if decryption fails or data is missing
    func getAddendumText() throws -> String {
        guard let encryptedData = self.encryptedAddendumText else {
            throw EncryptionError.invalidData
        }

        let decryptedData = try encryptionService.decrypt(encryptedData)

        guard let text = String(data: decryptedData, encoding: .utf8) else {
            throw EncryptionError.decryptionFailed
        }

        return text
    }

    /// Gets addendum text with migration support for legacy unencrypted data
    /// - Returns: Text (decrypted or from legacy field)
    /// - Throws: Error if both encrypted and legacy data are unavailable
    func getAddendumTextWithMigration() throws -> String {
        // Try encrypted format first
        if let encryptedData = self.encryptedAddendumText {
            do {
                let decryptedData = try encryptionService.decrypt(encryptedData)
                if let text = String(data: decryptedData, encoding: .utf8) {
                    return text
                }
            } catch {
                // Fall through to legacy format
            }
        }

        // Fall back to legacy unencrypted format
        guard let legacyText = self.addendumText else {
            throw EncryptionError.invalidData
        }

        return legacyText
    }

    // MARK: - Migration

    /// Migrates legacy unencrypted data to encrypted storage
    /// - Throws: EncryptionError if migration fails
    func migrateToEncryptedStorage() throws {
        // Skip if already encrypted
        guard !isEncrypted else { return }

        // Migrate addendum text if present
        if let legacyText = self.addendumText {
            try setAddendumText(legacyText)
        }
    }

    // MARK: - Convenience

    /// Checks if this addendum has text data (encrypted or legacy)
    var hasAddendumText: Bool {
        return encryptedAddendumText != nil || addendumText != nil
    }
}
