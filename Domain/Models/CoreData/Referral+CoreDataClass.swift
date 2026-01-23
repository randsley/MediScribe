//
//  Referral+CoreDataClass.swift
//  MediScribe
//
//  Core Data class for Referral entity with encrypted storage support
//

import Foundation
import CoreData

@objc(Referral)
public class Referral: NSManagedObject {

    // MARK: - Encrypted Field Access

    private let encryptionService = EncryptionService.shared

    // MARK: - Clinical Summary Encryption

    /// Sets the clinical summary with automatic encryption
    /// - Parameter summary: The clinical summary to encrypt and store
    /// - Throws: EncryptionError if encryption fails
    func setClinicalSummary(_ summary: String) throws {
        guard let textData = summary.data(using: .utf8) else {
            throw EncryptionError.invalidData
        }

        let encryptedData = try encryptionService.encrypt(textData)
        self.encryptedClinicalSummary = encryptedData
        self.clinicalSummary = nil  // Clear legacy field
        self.isEncrypted = true
    }

    /// Retrieves and decrypts the clinical summary
    /// - Returns: Decrypted clinical summary
    /// - Throws: EncryptionError if decryption fails or data is missing
    func getClinicalSummary() throws -> String {
        guard let encryptedData = self.encryptedClinicalSummary else {
            throw EncryptionError.invalidData
        }

        let decryptedData = try encryptionService.decrypt(encryptedData)

        guard let text = String(data: decryptedData, encoding: .utf8) else {
            throw EncryptionError.decryptionFailed
        }

        return text
    }

    /// Gets clinical summary with migration support for legacy unencrypted data
    /// - Returns: Text (decrypted or from legacy field)
    /// - Throws: Error if both encrypted and legacy data are unavailable
    func getClinicalSummaryWithMigration() throws -> String {
        // Try encrypted format first
        if let encryptedData = self.encryptedClinicalSummary {
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
        guard let legacyText = self.clinicalSummary else {
            throw EncryptionError.invalidData
        }

        return legacyText
    }

    // MARK: - Reason Encryption

    /// Sets the reason with automatic encryption
    /// - Parameter reason: The reason to encrypt and store
    /// - Throws: EncryptionError if encryption fails
    func setReason(_ reason: String) throws {
        guard let textData = reason.data(using: .utf8) else {
            throw EncryptionError.invalidData
        }

        let encryptedData = try encryptionService.encrypt(textData)
        self.encryptedReason = encryptedData
        self.reason = nil  // Clear legacy field
        self.isEncrypted = true
    }

    /// Retrieves and decrypts the reason
    /// - Returns: Decrypted reason
    /// - Throws: EncryptionError if decryption fails or data is missing
    func getReason() throws -> String {
        guard let encryptedData = self.encryptedReason else {
            throw EncryptionError.invalidData
        }

        let decryptedData = try encryptionService.decrypt(encryptedData)

        guard let text = String(data: decryptedData, encoding: .utf8) else {
            throw EncryptionError.decryptionFailed
        }

        return text
    }

    /// Gets reason with migration support for legacy unencrypted data
    /// - Returns: Text (decrypted or from legacy field)
    /// - Throws: Error if both encrypted and legacy data are unavailable
    func getReasonWithMigration() throws -> String {
        // Try encrypted format first
        if let encryptedData = self.encryptedReason {
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
        guard let legacyText = self.reason else {
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

        var migrated = false

        // Migrate clinical summary if present
        if let legacySummary = self.clinicalSummary {
            try setClinicalSummary(legacySummary)
            migrated = true
        }

        // Migrate reason if present
        if let legacyReason = self.reason {
            try setReason(legacyReason)
            migrated = true
        }

        if migrated {
            self.isEncrypted = true
        }
    }

    // MARK: - Convenience

    /// Checks if this referral has clinical summary data (encrypted or legacy)
    var hasClinicalSummary: Bool {
        return encryptedClinicalSummary != nil || clinicalSummary != nil
    }

    /// Checks if this referral has reason data (encrypted or legacy)
    var hasReason: Bool {
        return encryptedReason != nil || reason != nil
    }
}
