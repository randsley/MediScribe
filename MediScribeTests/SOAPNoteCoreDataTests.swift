//
//  SOAPNoteCoreDataTests.swift
//  MediScribeTests
//
//  Integration tests for SOAPNote Core Data entity with encryption
//

import XCTest
import CoreData
@testable import MediScribe

class SOAPNoteCoreDataTests: XCTestCase {
    // MARK: - Properties

    var managedObjectContext: NSManagedObjectContext!
    var encryptionService: EncryptionService!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()

        // Create in-memory Core Data stack
        let model = NSManagedObjectModel.mergedModel(from: [Bundle(for: type(of: self))])!
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        try? coordinator.addPersistentStore(
            ofType: NSInMemoryStoreType,
            configurationName: nil,
            at: nil,
            options: nil
        )

        managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator

        // Initialize encryption service
        encryptionService = EncryptionService()
    }

    override func tearDown() {
        encryptionService = nil
        managedObjectContext = nil
        super.tearDown()
    }

    // MARK: - Test Cases

    /// Test 1: Create SOAP note with encrypted data
    func testCreateSOAPNote() throws {
        let testData = createTestSOAPNoteData()

        // Create entity
        let entity = try SOAPNote.create(
            from: testData,
            in: managedObjectContext,
            encryptedBy: encryptionService
        )

        // Verify basic attributes
        XCTAssertEqual(entity.noteID, testData.id)
        XCTAssertEqual(entity.patientIdentifier, testData.patientIdentifier)
        XCTAssertNotNil(entity.generatedAt)

        // Verify encryption (data should be encrypted, not readable)
        XCTAssertNotNil(entity.subjectiveEncrypted)
        XCTAssertNotNil(entity.objectiveEncrypted)
        XCTAssertNotNil(entity.assessmentEncrypted)
        XCTAssertNotNil(entity.planEncrypted)
        XCTAssertNotNil(entity.metadataEncrypted)

        // Save and verify persistence
        try managedObjectContext.save()

        // Fetch from database
        let request: NSFetchRequest<SOAPNote> = SOAPNote.fetchRequest()
        request.predicate = NSPredicate(format: "noteID == %@", testData.id as CVarArg)
        let results = try managedObjectContext.fetch(request)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].noteID, testData.id)
    }

    /// Test 2: Retrieve and decrypt SOAP note data
    func testRetrieveAndDecryptSOAPNote() throws {
        let testData = createTestSOAPNoteData()

        // Create and save
        let entity = try SOAPNote.create(
            from: testData,
            in: managedObjectContext,
            encryptedBy: encryptionService
        )
        try managedObjectContext.save()

        // Decrypt and verify
        let decrypted = try entity.getDecryptedData(encryptedBy: encryptionService)

        XCTAssertEqual(decrypted.id, testData.id)
        XCTAssertEqual(decrypted.patientIdentifier, testData.patientIdentifier)
        XCTAssertEqual(decrypted.subjective.chiefComplaint, testData.subjective.chiefComplaint)
        XCTAssertEqual(decrypted.objective.vitalSigns.heartRate, testData.objective.vitalSigns.heartRate)
        XCTAssertEqual(decrypted.assessment.clinicalImpressions, testData.assessment.clinicalImpressions)
        XCTAssertEqual(decrypted.plan.nextSteps.count, testData.plan.nextSteps.count)
    }

    /// Test 3: Mark note as reviewed
    func testMarkSOAPNoteAsReviewed() throws {
        let testData = createTestSOAPNoteData()
        let clinicianID = "clinician-123"

        let entity = try SOAPNote.create(
            from: testData,
            in: managedObjectContext,
            encryptedBy: encryptionService
        )

        // Verify initial status
        XCTAssertEqual(entity.validationStatus, "unvalidated")
        XCTAssertNil(entity.clinicianReviewedBy)
        XCTAssertNil(entity.reviewedAt)

        // Mark as reviewed
        try entity.markReviewed(by: clinicianID, encryptedBy: encryptionService)

        // Verify reviewed status
        XCTAssertEqual(entity.validationStatus, "reviewed")
        XCTAssertEqual(entity.clinicianReviewedBy, clinicianID)
        XCTAssertNotNil(entity.reviewedAt)

        try managedObjectContext.save()

        // Verify metadata was updated
        let decrypted = try entity.getDecryptedData(encryptedBy: encryptionService)
        XCTAssertEqual(decrypted.metadata.clinicianReviewedBy, clinicianID)
        XCTAssertNotNil(decrypted.metadata.reviewedAt)
    }

    /// Test 4: Mark note as signed
    func testMarkSOAPNoteAsSigned() throws {
        let testData = createTestSOAPNoteData()
        let clinicianID = "clinician-456"

        let entity = try SOAPNote.create(
            from: testData,
            in: managedObjectContext,
            encryptedBy: encryptionService
        )

        // Mark as signed
        try entity.markSigned(by: clinicianID, encryptedBy: encryptionService)

        // Verify signed status
        XCTAssertEqual(entity.validationStatus, "signed")
        XCTAssertEqual(entity.clinicianReviewedBy, clinicianID)
        XCTAssertNotNil(entity.reviewedAt)
        XCTAssertNotNil(entity.completedAt)

        try managedObjectContext.save()

        // Verify data persistence
        let request: NSFetchRequest<SOAPNote> = SOAPNote.fetchRequest()
        let results = try managedObjectContext.fetch(request)
        XCTAssertEqual(results[0].validationStatus, "signed")
    }

    /// Test 5: Query SOAP notes by patient
    func testQuerySOAPNotesByPatient() throws {
        let patientID = "patient-789"

        // Create multiple notes for same patient
        let note1 = try SOAPNote.create(
            from: createTestSOAPNoteData(patientIdentifier: patientID),
            in: managedObjectContext,
            encryptedBy: encryptionService
        )

        let note2 = try SOAPNote.create(
            from: createTestSOAPNoteData(patientIdentifier: patientID),
            in: managedObjectContext,
            encryptedBy: encryptionService
        )

        // Create note for different patient
        _ = try SOAPNote.create(
            from: createTestSOAPNoteData(patientIdentifier: "other-patient"),
            in: managedObjectContext,
            encryptedBy: encryptionService
        )

        try managedObjectContext.save()

        // Query by patient
        let request: NSFetchRequest<SOAPNote> = SOAPNote.fetchRequest()
        request.predicate = NSPredicate(format: "patientIdentifier == %@", patientID)
        request.sortDescriptors = [NSSortDescriptor(key: "generatedAt", ascending: false)]

        let results = try managedObjectContext.fetch(request)

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].patientIdentifier, patientID)
        XCTAssertEqual(results[1].patientIdentifier, patientID)
    }

    /// Test 6: Get formatted text representation
    func testGetFormattedText() throws {
        let testData = createTestSOAPNoteData()

        let entity = try SOAPNote.create(
            from: testData,
            in: managedObjectContext,
            encryptedBy: encryptionService
        )

        // Get formatted text
        let formattedText = try entity.getFormattedText(encryptedBy: encryptionService)

        // Verify contains SOAP sections
        XCTAssertTrue(formattedText.contains("SUBJECTIVE"))
        XCTAssertTrue(formattedText.contains("OBJECTIVE"))
        XCTAssertTrue(formattedText.contains("ASSESSMENT"))
        XCTAssertTrue(formattedText.contains("PLAN"))
    }

    /// Test 7: Encryption verification - data should not be readable
    func testEncryptionIntegrity() throws {
        let testData = createTestSOAPNoteData()

        let entity = try SOAPNote.create(
            from: testData,
            in: managedObjectContext,
            encryptedBy: encryptionService
        )

        // Verify encrypted data is not plaintext
        guard let encryptedSubjective = entity.subjectiveEncrypted else {
            XCTFail("No encrypted subjective data")
            return
        }

        // Try to decode as JSON - should fail (it's encrypted)
        do {
            _ = try JSONDecoder().decode(SOAPSubjective.self, from: encryptedSubjective)
            XCTFail("Encrypted data should not be readable as JSON")
        } catch {
            // Expected - data is encrypted
        }
    }

    /// Test 8: Update existing note
    func testUpdateSOAPNote() throws {
        let testData = createTestSOAPNoteData()

        let entity = try SOAPNote.create(
            from: testData,
            in: managedObjectContext,
            encryptedBy: encryptionService
        )

        try managedObjectContext.save()

        // Update with new data
        var updatedData = testData
        updatedData.subjective = SOAPSubjective(
            chiefComplaint: "Updated complaint",
            historyOfPresentIllness: "Updated history",
            pastMedicalHistory: [],
            allergies: [],
            medications: []
        )

        try entity.update(from: updatedData, encryptedBy: encryptionService)
        try managedObjectContext.save()

        // Verify update
        let decrypted = try entity.getDecryptedData(encryptedBy: encryptionService)
        XCTAssertEqual(decrypted.subjective.chiefComplaint, "Updated complaint")
    }

    /// Test 9: Multiple encryption/decryption cycles
    func testMultipleEncryptionCycles() throws {
        let testData = createTestSOAPNoteData()

        let entity = try SOAPNote.create(
            from: testData,
            in: managedObjectContext,
            encryptedBy: encryptionService
        )

        // Encrypt, decrypt, re-encrypt cycle
        for _ in 0..<3 {
            let decrypted = try entity.getDecryptedData(encryptedBy: encryptionService)
            try entity.update(from: decrypted, encryptedBy: encryptionService)
        }

        try managedObjectContext.save()

        // Verify data integrity after cycles
        let final = try entity.getDecryptedData(encryptedBy: encryptionService)
        XCTAssertEqual(final.subjective.chiefComplaint, testData.subjective.chiefComplaint)
    }

    /// Test 10: Delete SOAP note
    func testDeleteSOAPNote() throws {
        let testData = createTestSOAPNoteData()

        let entity = try SOAPNote.create(
            from: testData,
            in: managedObjectContext,
            encryptedBy: encryptionService
        )

        try managedObjectContext.save()

        // Verify it exists
        var request: NSFetchRequest<SOAPNote> = SOAPNote.fetchRequest()
        var results = try managedObjectContext.fetch(request)
        XCTAssertEqual(results.count, 1)

        // Delete
        managedObjectContext.delete(entity)
        try managedObjectContext.save()

        // Verify deletion
        request = SOAPNote.fetchRequest()
        results = try managedObjectContext.fetch(request)
        XCTAssertEqual(results.count, 0)
    }

    // MARK: - Helper Methods

    private func createTestSOAPNoteData(
        patientIdentifier: String = "test-patient-001"
    ) -> SOAPNoteData {
        let vitals = VitalSigns(
            temperature: 37.2,
            heartRate: 78,
            respiratoryRate: 16,
            systolicBP: 120,
            diastolicBP: 80,
            oxygenSaturation: 98
        )

        let subjective = SOAPSubjective(
            chiefComplaint: "Persistent cough",
            historyOfPresentIllness: "Patient reports 2-week cough, worse at night",
            pastMedicalHistory: ["Asthma"],
            allergies: ["Penicillin"],
            medications: ["Albuterol inhaler"]
        )

        let objective = SOAPObjective(
            vitalSigns: vitals,
            physicalExamFindings: "Lungs clear to auscultation bilaterally",
            labResults: [],
            imagingFindings: []
        )

        let assessment = SOAPAssessment(
            clinicalImpressions: "Likely viral upper respiratory infection",
            differentialDiagnosis: ["URTI", "Allergic rhinitis"],
            riskFactors: []
        )

        let plan = SOAPPlan(
            nextSteps: ["Follow-up in 1 week", "Rest and fluids"],
            investigations: [],
            followUpInstructions: "Return if symptoms worsen"
        )

        let metadata = SOAPMetadata(
            modelVersion: "MedGemma 1.5 4B",
            generationTime: 2.5,
            promptTemplate: "standard",
            clinicianReviewedBy: nil,
            reviewedAt: nil,
            encryptionVersion: "v1"
        )

        return SOAPNoteData(
            id: UUID(),
            patientIdentifier: patientIdentifier,
            generatedAt: Date(),
            completedAt: nil,
            subjective: subjective,
            objective: objective,
            assessment: assessment,
            plan: plan,
            metadata: metadata,
            validationStatus: .unvalidated
        )
    }
}
