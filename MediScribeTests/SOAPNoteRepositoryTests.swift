//
//  SOAPNoteRepositoryTests.swift
//  MediScribeTests
//
//  Integration tests for SOAPNoteRepository CRUD operations
//

import XCTest
import CoreData
@testable import MediScribe

class SOAPNoteRepositoryTests: XCTestCase {
    // MARK: - Properties

    var repository: SOAPNoteRepository!
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

        // Initialize services
        encryptionService = EncryptionService()
        repository = SOAPNoteRepository(context: managedObjectContext, encryptionService: encryptionService)
    }

    override func tearDown() {
        repository = nil
        encryptionService = nil
        managedObjectContext = nil
        super.tearDown()
    }

    // MARK: - Test Cases

    /// Test 1: Save new SOAP note
    func testSaveNewSOAPNote() throws {
        let noteData = createTestSOAPNoteData()

        try repository.saveSOAPNote(noteData)

        // Verify persistence
        let saved = try repository.fetchSOAPNote(with: noteData.id)
        XCTAssertNotNil(saved)
        XCTAssertEqual(saved?.id, noteData.id)
    }

    /// Test 2: Fetch SOAP note by ID
    func testFetchSOAPNoteByID() throws {
        let noteData = createTestSOAPNoteData()
        try repository.saveSOAPNote(noteData)

        let fetched = try repository.fetchSOAPNote(with: noteData.id)

        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.id, noteData.id)
        XCTAssertEqual(fetched?.patientIdentifier, noteData.patientIdentifier)
    }

    /// Test 3: Fetch all notes for patient
    func testFetchAllNotesForPatient() throws {
        let patientID = "patient-001"

        // Create multiple notes
        let note1 = createTestSOAPNoteData(patientIdentifier: patientID)
        let note2 = createTestSOAPNoteData(patientIdentifier: patientID)
        let note3 = createTestSOAPNoteData(patientIdentifier: "other-patient")

        try repository.saveSOAPNote(note1)
        try repository.saveSOAPNote(note2)
        try repository.saveSOAPNote(note3)

        // Fetch all for patient
        let patientNotes = try repository.fetchAllForPatient(patientID)

        XCTAssertEqual(patientNotes.count, 2)
        XCTAssertTrue(patientNotes.allSatisfy { $0.patientIdentifier == patientID })
    }

    /// Test 4: Update SOAP note
    func testUpdateSOAPNote() throws {
        let noteData = createTestSOAPNoteData()
        try repository.saveSOAPNote(noteData)

        // Update
        var updated = noteData
        updated.subjective = SOAPSubjective(
            chiefComplaint: "Updated",
            historyOfPresentIllness: "Updated HPI",
            pastMedicalHistory: [],
            allergies: [],
            medications: []
        )

        try repository.updateSOAPNote(updated)

        // Verify update
        let fetched = try repository.fetchSOAPNote(with: noteData.id)
        XCTAssertEqual(fetched?.subjective.chiefComplaint, "Updated")
    }

    /// Test 5: Mark note as reviewed
    func testMarkAsReviewed() throws {
        let noteData = createTestSOAPNoteData()
        try repository.saveSOAPNote(noteData)

        let clinicianID = "clinician-001"
        try repository.markAsReviewed(noteID: noteData.id, by: clinicianID)

        let fetched = try repository.fetchSOAPNote(with: noteData.id)
        XCTAssertEqual(fetched?.metadata.clinicianReviewedBy, clinicianID)
        XCTAssertNotNil(fetched?.metadata.reviewedAt)
    }

    /// Test 6: Mark note as signed
    func testMarkAsSigned() throws {
        let noteData = createTestSOAPNoteData()
        try repository.saveSOAPNote(noteData)

        let clinicianID = "clinician-002"
        try repository.markAsSigned(noteID: noteData.id, by: clinicianID)

        let fetched = try repository.fetchSOAPNote(with: noteData.id)
        XCTAssertEqual(fetched?.validationStatus, .signed)
        XCTAssertEqual(fetched?.metadata.clinicianReviewedBy, clinicianID)
    }

    /// Test 7: Delete SOAP note
    func testDeleteSOAPNote() throws {
        let noteData = createTestSOAPNoteData()
        try repository.saveSOAPNote(noteData)

        try repository.deleteSOAPNote(with: noteData.id)

        let fetched = try repository.fetchSOAPNote(with: noteData.id)
        XCTAssertNil(fetched)
    }

    /// Test 8: Fetch notes with status filter
    func testFetchNotesWithStatusFilter() throws {
        let patientID = "patient-002"

        // Create notes with different statuses
        let unvalidatedNote = createTestSOAPNoteData(patientIdentifier: patientID)
        try repository.saveSOAPNote(unvalidatedNote)

        let reviewedNoteData = createTestSOAPNoteData(patientIdentifier: patientID)
        try repository.saveSOAPNote(reviewedNoteData)
        try repository.markAsReviewed(noteID: reviewedNoteData.id, by: "clinician-001")

        let signedNoteData = createTestSOAPNoteData(patientIdentifier: patientID)
        try repository.saveSOAPNote(signedNoteData)
        try repository.markAsSigned(noteID: signedNoteData.id, by: "clinician-002")

        // Query by status
        let signed = try repository.fetchByStatus(.signed)
        XCTAssertTrue(signed.count >= 1)
        XCTAssertTrue(signed.contains { $0.id == signedNoteData.id })
    }

    /// Test 9: Fetch recent notes (sorted by date)
    func testFetchRecentNotes() throws {
        let patientID = "patient-003"

        // Create notes at different times
        var note1Data = createTestSOAPNoteData(patientIdentifier: patientID)
        note1Data.generatedAt = Date(timeIntervalSinceNow: -3600) // 1 hour ago

        var note2Data = createTestSOAPNoteData(patientIdentifier: patientID)
        note2Data.generatedAt = Date() // now

        try repository.saveSOAPNote(note1Data)
        try repository.saveSOAPNote(note2Data)

        // Fetch recent (should be in descending order)
        let recent = try repository.fetchRecentNotes(for: patientID, limit: 10)

        XCTAssertEqual(recent.count, 2)
        XCTAssertEqual(recent[0].id, note2Data.id) // Most recent first
        XCTAssertEqual(recent[1].id, note1Data.id)
    }

    /// Test 10: Batch operations
    func testBatchSaveAndFetch() throws {
        let patientID = "patient-004"

        // Create multiple notes
        var notesList: [SOAPNoteData] = []
        for i in 0..<5 {
            var data = createTestSOAPNoteData(patientIdentifier: patientID)
            data.subjective.chiefComplaint = "Complaint \(i)"
            notesList.append(data)
        }

        // Batch save
        try repository.saveBatch(notesList)

        // Verify all saved
        let fetched = try repository.fetchAllForPatient(patientID)
        XCTAssertEqual(fetched.count, 5)

        // Verify content
        for (index, note) in fetched.enumerated() {
            XCTAssertEqual(note.subjective.chiefComplaint, "Complaint \(index)")
        }
    }

    /// Test 11: Count notes for patient
    func testCountNotesForPatient() throws {
        let patientID = "patient-005"

        for i in 0..<3 {
            var data = createTestSOAPNoteData(patientIdentifier: patientID)
            data.subjective.chiefComplaint = "Note \(i)"
            try repository.saveSOAPNote(data)
        }

        let count = try repository.countForPatient(patientID)
        XCTAssertEqual(count, 3)
    }

    /// Test 12: Repository with encryption
    func testRepositoryEncryptionIntegrity() throws {
        let noteData = createTestSOAPNoteData()
        try repository.saveSOAPNote(noteData)

        // Fetch and verify encryption is maintained
        let fetched = try repository.fetchSOAPNote(with: noteData.id)
        XCTAssertNotNil(fetched)

        // Data should be decrypted automatically by repository
        XCTAssertEqual(fetched?.subjective.chiefComplaint, noteData.subjective.chiefComplaint)
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
            chiefComplaint: "Test complaint",
            historyOfPresentIllness: "Test history",
            pastMedicalHistory: ["Asthma"],
            allergies: ["Penicillin"],
            medications: ["Albuterol"]
        )

        let objective = SOAPObjective(
            vitalSigns: vitals,
            physicalExamFindings: "Test findings",
            labResults: [],
            imagingFindings: []
        )

        let assessment = SOAPAssessment(
            clinicalImpressions: "Test impression",
            differentialDiagnosis: ["URTI"],
            riskFactors: []
        )

        let plan = SOAPPlan(
            nextSteps: ["Follow-up"],
            investigations: [],
            followUpInstructions: "Return if worse"
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
