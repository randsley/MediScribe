//
//  NoteSigningTests.swift
//  MediScribeTests
//
//  Tests for note signing and addenda system
//

import XCTest
import CoreData
@testable import MediScribe

final class NoteSigningTests: XCTestCase {

    var persistenceController: PersistenceController!
    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        // Create a fresh in-memory store for each test to ensure test isolation
        persistenceController = PersistenceController(inMemory: true)
        context = persistenceController.container.viewContext
    }

    override func tearDown() {
        // Clean up any remaining objects to ensure isolation
        context.reset()
        persistenceController = nil
        context = nil
        super.tearDown()
    }

    // MARK: - Signing Tests

    func testSignNote() throws {
        let note = createTestNote()

        // Initially not signed
        XCTAssertFalse(note.isLocked)
        XCTAssertNil(note.signedAt)
        XCTAssertNil(note.signedBy)
        XCTAssertTrue(note.canEdit)

        // Sign the note
        try note.sign(by: "Dr. Smith", clinicianID: "CLIN_001")

        // Verify signing
        XCTAssertTrue(note.isLocked)
        XCTAssertNotNil(note.signedAt)
        XCTAssertNotNil(note.signedBy)
        XCTAssertTrue(note.signedBy!.contains("Dr. Smith"))
        XCTAssertTrue(note.signedBy!.contains("CLIN_001"))
        XCTAssertFalse(note.canEdit)
    }

    func testCannotSignTwice() throws {
        let note = createTestNote()

        // Sign once
        try note.sign(by: "Dr. Smith", clinicianID: "CLIN_001")

        // Attempt to sign again should throw
        XCTAssertThrowsError(try note.sign(by: "Dr. Jones", clinicianID: "CLIN_002")) { error in
            guard let signingError = error as? NoteSigningError else {
                XCTFail("Expected NoteSigningError")
                return
            }
            XCTAssertEqual(signingError, .alreadySigned)
        }
    }

    func testCannotEditLockedNote() throws {
        let note = createTestNote()
        let fieldNote = createSampleFieldNote()

        // Save initial note
        try note.setFieldNote(fieldNote)

        // Sign the note
        try note.sign(by: "Dr. Smith", clinicianID: "CLIN_001")

        // Attempt to save should be prevented by checking isLocked
        // (This would be enforced in the UI/saveNote logic)
        XCTAssertTrue(note.isLocked)
        XCTAssertFalse(note.canEdit)
    }

    // MARK: - Addendum Tests

    func testAddAddendumToSignedNote() throws {
        let note = createTestNote()

        // Sign the note first
        try note.sign(by: "Dr. Smith", clinicianID: "CLIN_001")

        // Add addendum
        let addendum = try note.addAddendum(
            text: "Patient's SpO2 was actually 82%, not 84% as originally documented.",
            authorName: "Dr. Smith",
            authorID: "CLIN_001",
            correctionOf: "/objective/vitals/0/spo2",
            context: context
        )

        // Verify addendum
        XCTAssertNotNil(addendum.id)
        XCTAssertNotNil(addendum.createdAt)
        let addendumText = try addendum.getAddendumText()
        XCTAssertEqual(addendumText, "Patient's SpO2 was actually 82%, not 84% as originally documented.")
        XCTAssertEqual(addendum.authorName, "Dr. Smith")
        XCTAssertEqual(addendum.authorID, "CLIN_001")
        XCTAssertEqual(addendum.correctionOf, "/objective/vitals/0/spo2")
        XCTAssertEqual(addendum.note, note)
    }

    func testCannotAddAddendumToUnsignedNote() throws {
        let note = createTestNote()

        // Attempt to add addendum without signing
        XCTAssertThrowsError(
            try note.addAddendum(
                text: "Test addendum",
                authorName: "Dr. Smith",
                authorID: "CLIN_001",
                context: context
            )
        ) { error in
            guard let signingError = error as? NoteSigningError else {
                XCTFail("Expected NoteSigningError")
                return
            }
            XCTAssertEqual(signingError, .noteNotSigned)
        }
    }

    func testMultipleAddenda() throws {
        let note = createTestNote()

        // Sign the note
        try note.sign(by: "Dr. Smith", clinicianID: "CLIN_001")

        // Add multiple addenda
        _ = try note.addAddendum(
            text: "First addendum",
            authorName: "Dr. Smith",
            authorID: "CLIN_001",
            context: context
        )

        _ = try note.addAddendum(
            text: "Second addendum",
            authorName: "Dr. Jones",
            authorID: "CLIN_002",
            context: context
        )

        _ = try note.addAddendum(
            text: "Third addendum",
            authorName: "Dr. Smith",
            authorID: "CLIN_001",
            context: context
        )

        // Verify all addenda are associated
        let sortedAddenda = note.sortedAddenda
        XCTAssertEqual(sortedAddenda.count, 3)

        // Verify chronological order
        XCTAssertEqual(try sortedAddenda[0].getAddendumText(), "First addendum")
        XCTAssertEqual(try sortedAddenda[1].getAddendumText(), "Second addendum")
        XCTAssertEqual(try sortedAddenda[2].getAddendumText(), "Third addendum")
    }

    func testAddendumWithoutCorrection() throws {
        let note = createTestNote()
        try note.sign(by: "Dr. Smith", clinicianID: "CLIN_001")

        // Add general addendum (not a correction)
        let addendum = try note.addAddendum(
            text: "Patient's family arrived and was updated on condition.",
            authorName: "Dr. Smith",
            authorID: "CLIN_001",
            correctionOf: nil,
            context: context
        )

        XCTAssertNil(addendum.correctionOf)
        XCTAssertEqual(try addendum.getAddendumText(), "Patient's family arrived and was updated on condition.")
    }

    // MARK: - Persistence Tests

    func testSigningPersistence() throws {
        let note = createTestNote()
        try note.sign(by: "Dr. Smith", clinicianID: "CLIN_001")

        // Save context
        try context.save()

        // Fetch and verify
        let fetchRequest: NSFetchRequest<Note> = Note.fetchRequest()
        let results = try context.fetch(fetchRequest)

        XCTAssertEqual(results.count, 1)
        let fetchedNote = results[0]

        XCTAssertTrue(fetchedNote.isLocked)
        XCTAssertNotNil(fetchedNote.signedAt)
        XCTAssertNotNil(fetchedNote.signedBy)
    }

    func testAddendaPersistence() throws {
        let note = createTestNote()
        try note.sign(by: "Dr. Smith", clinicianID: "CLIN_001")

        let addendum = try note.addAddendum(
            text: "Test addendum for persistence",
            authorName: "Dr. Smith",
            authorID: "CLIN_001",
            context: context
        )

        // Save context
        try context.save()

        // Fetch and verify
        let fetchRequest: NSFetchRequest<NoteAddendum> = NoteAddendum.fetchRequest()
        let results = try context.fetch(fetchRequest)

        XCTAssertEqual(results.count, 1)
        let fetchedAddendum = results[0]

        XCTAssertEqual(try fetchedAddendum.getAddendumText(), "Test addendum for persistence")
        XCTAssertEqual(fetchedAddendum.authorName, "Dr. Smith")
        XCTAssertNotNil(fetchedAddendum.note)
    }

    func testCascadeDelete() throws {
        let note = createTestNote()
        try note.sign(by: "Dr. Smith", clinicianID: "CLIN_001")

        // Add addenda
        _ = try note.addAddendum(text: "Addendum 1", authorName: "Dr. Smith", authorID: "CLIN_001", context: context)
        _ = try note.addAddendum(text: "Addendum 2", authorName: "Dr. Smith", authorID: "CLIN_001", context: context)

        try context.save()

        // Delete note
        context.delete(note)
        try context.save()

        // Verify addenda are also deleted (cascade delete)
        let fetchRequest: NSFetchRequest<NoteAddendum> = NoteAddendum.fetchRequest()
        let remainingAddenda = try context.fetch(fetchRequest)

        XCTAssertEqual(remainingAddenda.count, 0, "Addenda should be cascade deleted with note")
    }

    // MARK: - Helper Methods

    private func createTestNote() -> Note {
        let note = Note(context: context)
        note.id = UUID()
        note.createdAt = Date()
        note.patientID = "TEST-PATIENT-001"
        return note
    }

    private func createSampleFieldNote() -> FieldNote {
        return FieldNote(
            meta: NoteMeta(
                author: NoteAuthor(id: "test", displayName: "Test Doctor", role: "Physician"),
                patient: NotePatient(id: "TEST-PATIENT-001", estimatedAgeYears: 30, sexAtBirth: .male),
                encounter: NoteEncounter(setting: .tent, locationText: "Test Location"),
                consent: NoteConsent(status: .obtained)
            )
        )
    }
}
