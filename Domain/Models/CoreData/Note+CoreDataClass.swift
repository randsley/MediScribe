//
//  Note+CoreDataClass.swift
//  MediScribe
//
//  Created by Nigel Randsley on 20/01/2026.
//
//

import Foundation
import CoreData

public typealias NoteCoreDataClassSet = NSSet

@objc(Note)
public class Note: NSManagedObject {

    // MARK: - Encrypted Field Access

    private let encryptionService = EncryptionService.shared

    /// Sets the field note with automatic encryption
    /// - Parameter fieldNote: The FieldNote to encrypt and store
    /// - Throws: EncryptionError if encryption fails
    func setFieldNote(_ fieldNote: FieldNote) throws {
        // Encrypt the FieldNote
        let encryptedData = try encryptionService.encrypt(fieldNote)

        // Store encrypted data
        self.noteData = encryptedData

        // Update denormalized patientID for filtering
        self.patientID = fieldNote.meta.patient.id
    }

    /// Retrieves and decrypts the field note
    /// - Returns: Decrypted FieldNote
    /// - Throws: EncryptionError if decryption fails, or if noteData is nil
    func getFieldNote() throws -> FieldNote {
        guard let encryptedData = self.noteData else {
            throw EncryptionError.invalidData
        }

        return try encryptionService.decrypt(encryptedData, as: FieldNote.self)
    }

    // MARK: - Migration Support

    /// Attempts to decrypt data, falling back to legacy unencrypted format
    /// This supports migration from unencrypted to encrypted storage
    /// - Returns: Decrypted FieldNote
    /// - Throws: Error if both decryption and legacy decode fail
    func getFieldNoteWithMigration() throws -> FieldNote {
        guard let data = self.noteData else {
            throw EncryptionError.invalidData
        }

        // Try encrypted format first
        do {
            return try encryptionService.decrypt(data, as: FieldNote.self)
        } catch {
            // Fall back to legacy unencrypted format
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(FieldNote.self, from: data)
        }
    }

    // MARK: - Signing and Legal Defensibility

    /// Signs the note, locking it from further edits
    /// - Parameters:
    ///   - clinicianName: Name of the clinician signing the note
    ///   - clinicianID: ID of the clinician signing the note
    /// - Throws: NoteSigningError if note is already signed or if signing fails
    func sign(by clinicianName: String, clinicianID: String) throws {
        // Check if already signed
        if isLocked {
            throw NoteSigningError.alreadySigned
        }

        // Update signing fields
        self.signedAt = Date()
        self.signedBy = "\(clinicianName) (ID: \(clinicianID))"
        self.isLocked = true
    }

    /// Adds an addendum to a signed note for corrections or additional information
    /// - Parameters:
    ///   - text: The addendum text
    ///   - authorName: Name of the clinician adding the addendum
    ///   - authorID: ID of the clinician
    ///   - correctionOf: Optional field path being corrected (e.g., "/objective/vitals/0/spo2")
    ///   - context: Managed object context
    /// - Returns: The created addendum
    /// - Throws: NoteSigningError if note is not signed, EncryptionError if encryption fails
    func addAddendum(text: String, authorName: String, authorID: String, correctionOf: String? = nil, context: NSManagedObjectContext) throws -> NoteAddendum {
        // Only allow addenda on signed notes
        guard isLocked else {
            throw NoteSigningError.noteNotSigned
        }

        // Create addendum
        let addendum = NoteAddendum(context: context)
        addendum.id = UUID()
        addendum.createdAt = Date()
        addendum.authorName = authorName
        addendum.authorID = authorID
        addendum.correctionOf = correctionOf
        addendum.note = self

        // Store addendum text with encryption
        try addendum.setAddendumText(text)

        return addendum
    }

    /// Checks if the note can be edited
    var canEdit: Bool {
        return !isLocked
    }

    /// Gets all addenda sorted by creation date
    var sortedAddenda: [NoteAddendum] {
        let addendaSet = addenda as? Set<NoteAddendum> ?? []
        return addendaSet.sorted { $0.createdAt ?? Date.distantPast < $1.createdAt ?? Date.distantPast }
    }
}

// MARK: - Note Signing Errors

enum NoteSigningError: Error, LocalizedError {
    case alreadySigned
    case noteNotSigned
    case cannotEditLockedNote

    var errorDescription: String? {
        switch self {
        case .alreadySigned:
            return "This note has already been signed and cannot be signed again."
        case .noteNotSigned:
            return "Addenda can only be added to signed notes."
        case .cannotEditLockedNote:
            return "This note is locked and cannot be edited. Please add an addendum instead."
        }
    }
}
