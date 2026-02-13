//
//  Patient+CoreDataClass.swift
//  MediScribe
//
//  Core Data class for Patient entity with encrypted demographic storage
//

import Foundation
import CoreData

@objc(Patient)
public class Patient: NSManagedObject {

    // MARK: - Encrypted Field Access

    private let encryptionService = EncryptionService.shared

    // MARK: - Name

    /// Sets the patient name with automatic encryption
    func setName(_ name: String) throws {
        guard let data = name.data(using: .utf8) else {
            throw EncryptionError.invalidData
        }
        self.nameEncrypted = try encryptionService.encrypt(data)
        self.name = nil
        self.isEncrypted = true
    }

    /// Retrieves and decrypts the patient name
    func getName() throws -> String {
        guard let encrypted = self.nameEncrypted else {
            throw EncryptionError.invalidData
        }
        let data = try encryptionService.decrypt(encrypted)
        guard let name = String(data: data, encoding: .utf8) else {
            throw EncryptionError.decryptionFailed
        }
        return name
    }

    /// Gets patient name with migration support for legacy plaintext data
    func getNameWithMigration() throws -> String {
        if let encrypted = self.nameEncrypted {
            do {
                let data = try encryptionService.decrypt(encrypted)
                if let name = String(data: data, encoding: .utf8) {
                    return name
                }
            } catch {
                // Fall through to legacy field
            }
        }
        guard let legacy = self.name else {
            throw EncryptionError.invalidData
        }
        return legacy
    }

    // MARK: - Date of Birth

    /// Sets the date of birth with automatic encryption
    func setDateOfBirth(_ date: Date) throws {
        let isoString = ISO8601DateFormatter().string(from: date)
        guard let data = isoString.data(using: .utf8) else {
            throw EncryptionError.invalidData
        }
        self.dateOfBirthEncrypted = try encryptionService.encrypt(data)
        self.dateOfBirth = nil
        self.isEncrypted = true
    }

    /// Retrieves and decrypts the date of birth
    func getDateOfBirth() throws -> Date {
        guard let encrypted = self.dateOfBirthEncrypted else {
            throw EncryptionError.invalidData
        }
        let data = try encryptionService.decrypt(encrypted)
        guard let isoString = String(data: data, encoding: .utf8),
              let date = ISO8601DateFormatter().date(from: isoString) else {
            throw EncryptionError.decryptionFailed
        }
        return date
    }

    /// Gets date of birth with migration support for legacy plaintext data
    func getDateOfBirthWithMigration() throws -> Date {
        if let encrypted = self.dateOfBirthEncrypted {
            do {
                let data = try encryptionService.decrypt(encrypted)
                if let isoString = String(data: data, encoding: .utf8),
                   let date = ISO8601DateFormatter().date(from: isoString) {
                    return date
                }
            } catch {
                // Fall through to legacy field
            }
        }
        guard let legacy = self.dateOfBirth else {
            throw EncryptionError.invalidData
        }
        return legacy
    }

    // MARK: - Medical Record Number

    /// Sets the medical record number with automatic encryption
    func setMedicalRecordNumber(_ mrn: String) throws {
        guard let data = mrn.data(using: .utf8) else {
            throw EncryptionError.invalidData
        }
        self.medicalRecordNumberEncrypted = try encryptionService.encrypt(data)
        self.medicalRecordNumber = nil
        self.isEncrypted = true
    }

    /// Retrieves and decrypts the medical record number
    func getMedicalRecordNumber() throws -> String {
        guard let encrypted = self.medicalRecordNumberEncrypted else {
            throw EncryptionError.invalidData
        }
        let data = try encryptionService.decrypt(encrypted)
        guard let mrn = String(data: data, encoding: .utf8) else {
            throw EncryptionError.decryptionFailed
        }
        return mrn
    }

    /// Gets MRN with migration support for legacy plaintext data
    func getMedicalRecordNumberWithMigration() throws -> String {
        if let encrypted = self.medicalRecordNumberEncrypted {
            do {
                let data = try encryptionService.decrypt(encrypted)
                if let mrn = String(data: data, encoding: .utf8) {
                    return mrn
                }
            } catch {
                // Fall through to legacy field
            }
        }
        guard let legacy = self.medicalRecordNumber else {
            throw EncryptionError.invalidData
        }
        return legacy
    }

    // MARK: - Migration

    /// Migrates any remaining plaintext demographic fields to encrypted storage
    func migrateToEncryptedStorage() throws {
        guard !isEncrypted else { return }

        var migrated = false

        if let legacyName = self.name, !legacyName.isEmpty {
            try setName(legacyName)
            migrated = true
        }

        if let legacyDOB = self.dateOfBirth {
            try setDateOfBirth(legacyDOB)
            migrated = true
        }

        if let legacyMRN = self.medicalRecordNumber, !legacyMRN.isEmpty {
            try setMedicalRecordNumber(legacyMRN)
            migrated = true
        }

        if migrated {
            self.isEncrypted = true
        }
    }

    // MARK: - Convenience

    /// True if the patient has an encrypted name stored
    var hasName: Bool {
        return nameEncrypted != nil || name != nil
    }

    /// True if any demographic field has been encrypted
    var hasDemographics: Bool {
        return nameEncrypted != nil || dateOfBirthEncrypted != nil || medicalRecordNumberEncrypted != nil
    }
}
