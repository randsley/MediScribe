//
//  SOAPNote+CoreData.swift
//  MediScribe
//
//  Core Data entity for SOAP notes with application-level encryption
//

import CoreData
import Foundation

// MARK: - SOAPNote Entity

extension SOAPNote {
    /// Create or update Core Data entity from SOAPNoteData
    /// - Parameters:
    ///   - noteData: Structured SOAP note data
    ///   - context: Core Data context
    ///   - encryptionService: Service for encrypting sensitive data
    /// - Returns: Managed Core Data entity
    @discardableResult
    static func create(
        from noteData: SOAPNoteData,
        in context: NSManagedObjectContext,
        encryptedBy encryptionService: EncryptionService
    ) throws -> SOAPNote {
        let entity = NSEntityDescription.insertNewObject(
            forEntityName: "SOAPNote",
            into: context
        ) as! SOAPNote

        try entity.update(from: noteData, encryptedBy: encryptionService)
        return entity
    }

    /// Update Core Data entity from SOAPNoteData
    /// - Parameters:
    ///   - noteData: Updated SOAP note data
    ///   - encryptionService: Service for encrypting sensitive data
    func update(
        from noteData: SOAPNoteData,
        encryptedBy encryptionService: EncryptionService
    ) throws {
        // Identifiers
        self.noteID = noteData.id
        self.patientIdentifier = noteData.patientIdentifier

        // Timestamps
        self.generatedAt = noteData.generatedAt
        self.completedAt = noteData.completedAt

        // Encode and encrypt SOAP sections
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        // Subjective
        let subjectiveData = try encoder.encode(noteData.subjective)
        self.subjectiveEncrypted = try encryptionService.encrypt(subjectiveData)

        // Objective
        let objectiveData = try encoder.encode(noteData.objective)
        self.objectiveEncrypted = try encryptionService.encrypt(objectiveData)

        // Assessment
        let assessmentData = try encoder.encode(noteData.assessment)
        self.assessmentEncrypted = try encryptionService.encrypt(assessmentData)

        // Plan
        let planData = try encoder.encode(noteData.plan)
        self.planEncrypted = try encryptionService.encrypt(planData)

        // Metadata
        let metadataData = try encoder.encode(noteData.metadata)
        self.metadataEncrypted = try encryptionService.encrypt(metadataData)

        // Validation status
        self.validationStatus = noteData.validationStatus.rawValue

        // Metadata fields (not encrypted)
        self.modelVersion = noteData.metadata.modelVersion
        self.clinicianReviewedBy = noteData.metadata.clinicianReviewedBy
        self.reviewedAt = noteData.metadata.reviewedAt
        self.encryptionVersion = noteData.metadata.encryptionVersion
    }

    /// Decrypt and retrieve structured SOAP note data
    /// - Parameter encryptionService: Service for decrypting sensitive data
    /// - Returns: Decrypted structured SOAP note data
    func getDecryptedData(
        encryptedBy encryptionService: EncryptionService
    ) throws -> SOAPNoteData {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Decrypt sections
        guard let subjectiveEncrypted = subjectiveEncrypted,
              let objectiveEncrypted = objectiveEncrypted,
              let assessmentEncrypted = assessmentEncrypted,
              let planEncrypted = planEncrypted,
              let metadataEncrypted = metadataEncrypted else {
            throw CoreDataError.missingEncryptedData
        }

        let subjectiveData = try encryptionService.decrypt(subjectiveEncrypted)
        let subjective = try decoder.decode(SOAPSubjective.self, from: subjectiveData)

        let objectiveData = try encryptionService.decrypt(objectiveEncrypted)
        let objective = try decoder.decode(SOAPObjective.self, from: objectiveData)

        let assessmentData = try encryptionService.decrypt(assessmentEncrypted)
        let assessment = try decoder.decode(SOAPAssessment.self, from: assessmentData)

        let planData = try encryptionService.decrypt(planEncrypted)
        let plan = try decoder.decode(SOAPPlan.self, from: planData)

        let metadataData = try encryptionService.decrypt(metadataEncrypted)
        let metadata = try decoder.decode(SOAPMetadata.self, from: metadataData)

        return SOAPNoteData(
            id: noteID ?? UUID(),
            patientIdentifier: patientIdentifier,
            generatedAt: generatedAt ?? Date(),
            completedAt: completedAt,
            subjective: subjective,
            objective: objective,
            assessment: assessment,
            plan: plan,
            metadata: metadata,
            validationStatus: ValidationStatus(rawValue: validationStatus ?? "unvalidated") ?? .unvalidated
        )
    }

    /// Mark note as reviewed by clinician
    /// - Parameters:
    ///   - clinicianIdentifier: ID of clinician performing review
    ///   - encryptionService: Service for encrypting sensitive data
    func markReviewed(
        by clinicianIdentifier: String,
        encryptedBy encryptionService: EncryptionService
    ) throws {
        clinicianReviewedBy = clinicianIdentifier
        reviewedAt = Date()
        validationStatus = ValidationStatus.reviewed.rawValue

        // Update metadata with review information
        guard let metadataEncrypted = metadataEncrypted else {
            throw CoreDataError.missingEncryptedData
        }

        let metadataData = try encryptionService.decrypt(metadataEncrypted)
        var metadata = try JSONDecoder().decode(SOAPMetadata.self, from: metadataData)

        metadata = SOAPMetadata(
            modelVersion: metadata.modelVersion,
            generationTime: metadata.generationTime,
            promptTemplate: metadata.promptTemplate,
            clinicianReviewedBy: clinicianIdentifier,
            reviewedAt: Date(),
            encryptionVersion: metadata.encryptionVersion
        )

        let updatedMetadataData = try JSONEncoder().encode(metadata)
        metadataEncrypted = try encryptionService.encrypt(updatedMetadataData)
    }

    /// Mark note as signed/finalized
    /// - Parameters:
    ///   - clinicianIdentifier: ID of clinician signing the note
    ///   - encryptionService: Service for encrypting sensitive data
    func markSigned(
        by clinicianIdentifier: String,
        encryptedBy encryptionService: EncryptionService
    ) throws {
        try markReviewed(by: clinicianIdentifier, encryptedBy: encryptionService)
        validationStatus = ValidationStatus.signed.rawValue
    }

    /// Get plain text summary (without encryption overhead)
    /// - Parameter encryptionService: Service for decryption
    /// - Returns: Formatted text representation
    func getFormattedText(
        encryptedBy encryptionService: EncryptionService
    ) throws -> String {
        let data = try getDecryptedData(encryptedBy: encryptionService)
        return data.formattedText
    }
}

// MARK: - Core Data Error

enum CoreDataError: LocalizedError {
    case missingEncryptedData
    case encryptionFailed(String)
    case decryptionFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingEncryptedData:
            return "Encrypted data missing from SOAP note entity"
        case .encryptionFailed(let msg):
            return "Encryption failed: \(msg)"
        case .decryptionFailed(let msg):
            return "Decryption failed: \(msg)"
        }
    }
}

// MARK: - NSManagedObject Extension for Core Data Setup

@objc(SOAPNote)
public class SOAPNote: NSManagedObject {
    @NSManaged public var noteID: UUID?
    @NSManaged public var patientIdentifier: String?

    // Timestamps
    @NSManaged public var generatedAt: Date?
    @NSManaged public var completedAt: Date?

    // Encrypted sections (application-level encryption)
    @NSManaged public var subjectiveEncrypted: Data?
    @NSManaged public var objectiveEncrypted: Data?
    @NSManaged public var assessmentEncrypted: Data?
    @NSManaged public var planEncrypted: Data?
    @NSManaged public var metadataEncrypted: Data?

    // Metadata
    @NSManaged public var validationStatus: String?
    @NSManaged public var modelVersion: String?
    @NSManaged public var clinicianReviewedBy: String?
    @NSManaged public var reviewedAt: Date?
    @NSManaged public var encryptionVersion: String?

    // Query optimization indexes
    @NSManaged public var createdAtIndex: Date?
    @NSManaged public var statusIndex: String?

    // Relationships
    @NSManaged public var clinic: NSManagedObject?
    @NSManaged public var clinician: NSManagedObject?
}
