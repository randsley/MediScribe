//
//  Finding+CoreDataClass.swift
//  MediScribe
//
//  Core Data class for Finding entity with encrypted storage support
//

import Foundation
import CoreData

@objc(Finding)
public class Finding: NSManagedObject {

    // MARK: - Encrypted Field Access

    private let encryptionService = EncryptionService.shared

    // MARK: - Findings JSON (String)

    /// Sets the findings JSON with automatic encryption
    /// - Parameter json: The JSON string to encrypt and store
    /// - Throws: EncryptionError if encryption fails
    func setFindingsJSON(_ json: String) throws {
        guard let jsonData = json.data(using: .utf8) else {
            throw EncryptionError.invalidData
        }

        let encryptedData = try encryptionService.encrypt(jsonData)
        self.encryptedFindingsData = encryptedData
        self.findingsJSON = nil  // Clear legacy field
        self.isEncrypted = true
    }

    /// Retrieves and decrypts the findings JSON
    /// - Returns: Decrypted JSON string
    /// - Throws: EncryptionError if decryption fails or data is missing
    func getFindingsJSON() throws -> String {
        guard let encryptedData = self.encryptedFindingsData else {
            throw EncryptionError.invalidData
        }

        let decryptedData = try encryptionService.decrypt(encryptedData)

        guard let json = String(data: decryptedData, encoding: .utf8) else {
            throw EncryptionError.decryptionFailed
        }

        return json
    }

    /// Gets findings JSON with migration support for legacy unencrypted data
    /// - Returns: JSON string (decrypted or from legacy field)
    /// - Throws: Error if both encrypted and legacy data are unavailable
    func getFindingsJSONWithMigration() throws -> String {
        // Try encrypted format first
        if let encryptedData = self.encryptedFindingsData {
            do {
                let decryptedData = try encryptionService.decrypt(encryptedData)
                if let json = String(data: decryptedData, encoding: .utf8) {
                    return json
                }
            } catch {
                // Fall through to legacy format
            }
        }

        // Fall back to legacy unencrypted format
        guard let legacyJSON = self.findingsJSON else {
            throw EncryptionError.invalidData
        }

        return legacyJSON
    }

    // MARK: - Typed Findings (Codable)

    /// Sets findings from a Codable object with automatic encryption
    /// - Parameter findings: The findings object (ImagingFindingsSummary or LabResultsSummary)
    /// - Throws: EncryptionError if encryption fails
    func setFindings<T: Encodable>(_ findings: T) throws {
        let encryptedData = try encryptionService.encrypt(findings)
        self.encryptedFindingsData = encryptedData
        self.findingsJSON = nil  // Clear legacy field
        self.isEncrypted = true
    }

    /// Retrieves and decrypts findings to a specified type
    /// - Parameter type: The type to decode to
    /// - Returns: Decrypted and decoded findings
    /// - Throws: EncryptionError if decryption fails, DecodingError if decode fails
    func getFindings<T: Decodable>(as type: T.Type) throws -> T {
        guard let encryptedData = self.encryptedFindingsData else {
            throw EncryptionError.invalidData
        }

        return try encryptionService.decrypt(encryptedData, as: type)
    }

    /// Gets typed findings with migration support for legacy unencrypted data
    /// - Parameter type: The type to decode to
    /// - Returns: Decoded findings (from encrypted or legacy data)
    /// - Throws: Error if both encrypted and legacy data are unavailable or decode fails
    func getFindingsWithMigration<T: Decodable>(as type: T.Type) throws -> T {
        // Try encrypted format first
        if let encryptedData = self.encryptedFindingsData {
            do {
                return try encryptionService.decrypt(encryptedData, as: type)
            } catch {
                // Fall through to legacy format
            }
        }

        // Fall back to legacy unencrypted JSON
        guard let legacyJSON = self.findingsJSON,
              let jsonData = legacyJSON.data(using: .utf8) else {
            throw EncryptionError.invalidData
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: jsonData)
    }

    // MARK: - Image Data

    /// Sets image data with automatic encryption
    /// - Parameter data: The image data to encrypt and store
    /// - Throws: EncryptionError if encryption fails
    func setImage(_ data: Data) throws {
        let encryptedData = try encryptionService.encrypt(data)
        self.encryptedImageData = encryptedData
        self.imageData = nil  // Clear legacy field
        self.isEncrypted = true
    }

    /// Retrieves and decrypts the image data
    /// - Returns: Decrypted image data
    /// - Throws: EncryptionError if decryption fails or data is missing
    func getImage() throws -> Data {
        guard let encryptedData = self.encryptedImageData else {
            throw EncryptionError.invalidData
        }

        return try encryptionService.decrypt(encryptedData)
    }

    /// Gets image data with migration support for legacy unencrypted data
    /// - Returns: Image data (decrypted or from legacy field)
    /// - Throws: Error if both encrypted and legacy data are unavailable
    func getImageWithMigration() throws -> Data {
        // Try encrypted format first
        if let encryptedData = self.encryptedImageData {
            do {
                return try encryptionService.decrypt(encryptedData)
            } catch {
                // Fall through to legacy format
            }
        }

        // Fall back to legacy unencrypted format
        guard let legacyData = self.imageData else {
            throw EncryptionError.invalidData
        }

        return legacyData
    }

    // MARK: - Migration

    /// Migrates legacy unencrypted data to encrypted storage
    /// Call this method to upgrade existing findings to encrypted format
    /// - Throws: EncryptionError if migration fails
    func migrateToEncryptedStorage() throws {
        // Skip if already encrypted
        guard !isEncrypted else { return }

        var migrated = false

        // Migrate findings JSON if present
        if let legacyJSON = self.findingsJSON {
            try setFindingsJSON(legacyJSON)
            migrated = true
        }

        // Migrate image data if present
        if let legacyImage = self.imageData {
            try setImage(legacyImage)
            migrated = true
        }

        if migrated {
            self.isEncrypted = true
        }
    }

    // MARK: - Convenience

    /// Checks if this finding has any stored data (encrypted or legacy)
    var hasFindingsData: Bool {
        return encryptedFindingsData != nil || findingsJSON != nil
    }

    /// Checks if this finding has image data (encrypted or legacy)
    var hasImageData: Bool {
        return encryptedImageData != nil || imageData != nil
    }
}
