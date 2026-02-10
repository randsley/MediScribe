//
//  SOAPNoteRepository.swift
//  MediScribe
//
//  Repository for managing SOAP note persistence and encryption
//

import CoreData
import Foundation

/// Repository for SOAP note CRUD operations with HIPAA compliance
class SOAPNoteRepository {
    // MARK: - Properties

    private let managedObjectContext: NSManagedObjectContext
    private let encryptionService: EncryptionService

    // MARK: - Initialization

    init(
        managedObjectContext: NSManagedObjectContext,
        encryptionService: EncryptionService
    ) {
        self.managedObjectContext = managedObjectContext
        self.encryptionService = encryptionService
    }

    // MARK: - CRUD Operations

    /// Save SOAP note with encryption and validation
    /// - Parameter noteData: Structured SOAP note data
    /// - Returns: Note ID for retrieval
    /// - Throws: Validation error if note violates safety constraints
    func save(_ noteData: SOAPNoteData) throws -> UUID {
        // Validate before persisting
        _ = try SOAPNoteValidator.validate(noteData)

        let note = try SOAPNote.create(
            from: noteData,
            in: managedObjectContext,
            encryptedBy: encryptionService
        )

        try managedObjectContext.save()
        return noteData.id
    }

    /// Retrieve SOAP note by ID
    /// - Parameter id: Note UUID
    /// - Returns: Decrypted SOAP note data
    func fetch(id: UUID) throws -> SOAPNoteData? {
        let fetchRequest = NSFetchRequest<SOAPNote>(entityName: "SOAPNote")
        fetchRequest.predicate = NSPredicate(format: "noteID == %@", id as CVarArg)
        fetchRequest.returnsObjectsAsFaults = false

        let results = try managedObjectContext.fetch(fetchRequest)
        guard let note = results.first else { return nil }

        return try note.getDecryptedData(encryptedBy: encryptionService)
    }

    /// Retrieve all SOAP notes for a patient
    /// - Parameter patientID: Patient identifier
    /// - Returns: Array of decrypted SOAP notes
    func fetchAllForPatient(_ patientID: String?) -> [SOAPNoteData] {
        let fetchRequest: NSFetchRequest<SOAPNote>

        if let patientID = patientID {
            fetchRequest = SOAPNote.fetchRequestForPatient(patientID)
        } else {
            fetchRequest = SOAPNote.fetchRecentNotes(limit: Int.max)
        }

        fetchRequest.returnsObjectsAsFaults = false

        guard let results = try? managedObjectContext.fetch(fetchRequest) else {
            return []
        }

        return results.compactMap { note in
            try? note.getDecryptedData(encryptedBy: encryptionService)
        }
    }

    /// Retrieve notes by validation status
    /// - Parameter status: Validation status to filter by
    /// - Returns: Array of matching notes
    func fetchByStatus(_ status: ValidationStatus) -> [SOAPNoteData] {
        let fetchRequest = SOAPNote.fetchRequestForStatus(status)
        fetchRequest.returnsObjectsAsFaults = false

        guard let results = try? managedObjectContext.fetch(fetchRequest) else {
            return []
        }

        return results.compactMap { note in
            try? note.getDecryptedData(encryptedBy: encryptionService)
        }
    }

    /// Retrieve notes for a patient with a specific status
    /// - Parameters:
    ///   - patientID: Patient identifier
    ///   - status: Validation status to filter by
    /// - Returns: Array of matching notes
    func fetchForPatient(_ patientID: String, status: ValidationStatus) -> [SOAPNoteData] {
        let fetchRequest = SOAPNote.fetchRequestForPatient(patientID, status: status)
        fetchRequest.returnsObjectsAsFaults = false

        guard let results = try? managedObjectContext.fetch(fetchRequest) else {
            return []
        }

        return results.compactMap { note in
            try? note.getDecryptedData(encryptedBy: encryptionService)
        }
    }

    /// Update SOAP note
    /// - Parameters:
    ///   - id: Note ID to update
    ///   - noteData: Updated note data
    func update(id: UUID, with noteData: SOAPNoteData) throws {
        let fetchRequest = NSFetchRequest<SOAPNote>(entityName: "SOAPNote")
        fetchRequest.predicate = NSPredicate(format: "noteID == %@", id as CVarArg)
        fetchRequest.returnsObjectsAsFaults = false

        guard let note = try managedObjectContext.fetch(fetchRequest).first else {
            throw RepositoryError.notFound
        }

        try note.update(from: noteData, encryptedBy: encryptionService)
        try managedObjectContext.save()
    }

    /// Delete SOAP note
    /// - Parameter id: Note ID to delete
    func delete(id: UUID) throws {
        let fetchRequest = NSFetchRequest<SOAPNote>(entityName: "SOAPNote")
        fetchRequest.predicate = NSPredicate(format: "noteID == %@", id as CVarArg)

        guard let note = try managedObjectContext.fetch(fetchRequest).first else {
            throw RepositoryError.notFound
        }

        managedObjectContext.delete(note)
        try managedObjectContext.save()
    }

    /// Mark note as reviewed
    /// - Parameters:
    ///   - id: Note ID
    ///   - clinicianID: Reviewing clinician's ID
    func markReviewed(id: UUID, by clinicianID: String) throws {
        let fetchRequest = NSFetchRequest<SOAPNote>(entityName: "SOAPNote")
        fetchRequest.predicate = NSPredicate(format: "noteID == %@", id as CVarArg)
        fetchRequest.returnsObjectsAsFaults = false

        guard let note = try managedObjectContext.fetch(fetchRequest).first else {
            throw RepositoryError.notFound
        }

        try note.markReviewed(by: clinicianID, encryptedBy: encryptionService)
        try managedObjectContext.save()
    }

    /// Sign/finalize note
    /// - Parameters:
    ///   - id: Note ID
    ///   - clinicianID: Signing clinician's ID
    func markSigned(id: UUID, by clinicianID: String) throws {
        let fetchRequest = NSFetchRequest<SOAPNote>(entityName: "SOAPNote")
        fetchRequest.predicate = NSPredicate(format: "noteID == %@", id as CVarArg)
        fetchRequest.returnsObjectsAsFaults = false

        guard let note = try managedObjectContext.fetch(fetchRequest).first else {
            throw RepositoryError.notFound
        }

        try note.markSigned(by: clinicianID, encryptedBy: encryptionService)
        try managedObjectContext.save()
    }

    /// Get text representation of note
    /// - Parameter id: Note ID
    /// - Returns: Formatted text
    func getFormattedText(id: UUID) throws -> String {
        let fetchRequest = NSFetchRequest<SOAPNote>(entityName: "SOAPNote")
        fetchRequest.predicate = NSPredicate(format: "noteID == %@", id as CVarArg)
        fetchRequest.returnsObjectsAsFaults = false

        guard let note = try managedObjectContext.fetch(fetchRequest).first else {
            throw RepositoryError.notFound
        }

        return try note.getFormattedText(encryptedBy: encryptionService)
    }

    /// Get statistics about stored SOAP notes
    /// - Returns: Repository statistics
    func getStatistics() -> SOAPNoteStatistics {
        let fetchRequest = NSFetchRequest<SOAPNote>(entityName: "SOAPNote")
        fetchRequest.returnsObjectsAsFaults = false

        guard let allNotes = try? managedObjectContext.fetch(fetchRequest) else {
            return SOAPNoteStatistics(
                totalNotes: 0,
                unvalidated: 0,
                validated: 0,
                reviewed: 0,
                signed: 0
            )
        }

        let unvalidated = allNotes.filter { $0.validationStatus == ValidationStatus.unvalidated.rawValue }.count
        let validated = allNotes.filter { $0.validationStatus == ValidationStatus.validated.rawValue }.count
        let reviewed = allNotes.filter { $0.validationStatus == ValidationStatus.reviewed.rawValue }.count
        let signed = allNotes.filter { $0.validationStatus == ValidationStatus.signed.rawValue }.count

        return SOAPNoteStatistics(
            totalNotes: allNotes.count,
            unvalidated: unvalidated,
            validated: validated,
            reviewed: reviewed,
            signed: signed
        )
    }
}

// MARK: - Supporting Types

/// Statistics about stored SOAP notes
struct SOAPNoteStatistics: Codable {
    let totalNotes: Int
    let unvalidated: Int
    let validated: Int
    let reviewed: Int
    let signed: Int

    enum CodingKeys: String, CodingKey {
        case totalNotes = "total_notes"
        case unvalidated
        case validated
        case reviewed
        case signed
    }
}

/// Repository error types
enum RepositoryError: LocalizedError {
    case notFound
    case saveFailed(Error)
    case fetchFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "SOAP note not found"
        case .saveFailed(let error):
            return "Failed to save SOAP note: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch SOAP note: \(error.localizedDescription)"
        }
    }
}
