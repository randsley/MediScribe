//
//  NoteAddendumEncryptionTests.swift
//  MediScribeTests
//
//  Tests for NoteAddendum entity encryption
//

import XCTest
import CoreData
@testable import MediScribe

final class NoteAddendumEncryptionTests: XCTestCase {

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

    // MARK: - Addendum Text Encryption Tests

    func testEncryptDecryptAddendumText() throws {
        let addendum = NoteAddendum(context: context)
        addendum.id = UUID()
        addendum.createdAt = Date()
        addendum.authorName = "Dr. Test"
        addendum.authorID = "TEST_001"

        let originalText = "Patient condition improved after intervention. Vital signs stable."

        // Encrypt and store
        try addendum.setAddendumText(originalText)

        // Verify isEncrypted flag is set
        XCTAssertTrue(addendum.isEncrypted, "isEncrypted flag should be set")

        // Verify legacy field is cleared
        XCTAssertNil(addendum.addendumText, "Legacy addendumText field should be nil")

        // Verify encrypted data exists
        XCTAssertNotNil(addendum.encryptedAddendumText, "Encrypted data should exist")

        // Decrypt and verify
        let decryptedText = try addendum.getAddendumText()
        XCTAssertEqual(decryptedText, originalText, "Decrypted text should match original")
    }

    func testEncryptDecryptLongAddendumText() throws {
        let addendum = NoteAddendum(context: context)
        addendum.id = UUID()
        addendum.createdAt = Date()

        // Create a longer addendum with special characters
        let originalText = """
        Addendum to clinical note dated 01/15/2024:

        Upon further review of laboratory results, the following corrections are noted:
        - SpO2 reading was 94%, not 84% as initially documented
        - Patient's chief complaint also included "dizziness" which was not recorded

        This addendum is made for accuracy and completeness of the medical record.

        Signed: Dr. Test Clinician
        """

        try addendum.setAddendumText(originalText)

        let decryptedText = try addendum.getAddendumText()
        XCTAssertEqual(decryptedText, originalText, "Long text with special characters should be preserved")
    }

    // MARK: - Migration Tests

    func testMigrationFromLegacyAddendumText() throws {
        let addendum = NoteAddendum(context: context)
        addendum.id = UUID()
        addendum.createdAt = Date()

        // Simulate legacy unencrypted storage (direct assignment)
        let legacyText = "Legacy addendum text before encryption was implemented"
        addendum.addendumText = legacyText
        addendum.isEncrypted = false

        // Use migration method to read
        let retrievedText = try addendum.getAddendumTextWithMigration()
        XCTAssertEqual(retrievedText, legacyText, "Migration should read legacy data")
    }

    func testMigrationPrefersEncryptedData() throws {
        let addendum = NoteAddendum(context: context)
        addendum.id = UUID()
        addendum.createdAt = Date()

        // Set encrypted data first
        let encryptedText = "This is the encrypted version"
        try addendum.setAddendumText(encryptedText)

        // Also set legacy field (simulating partial migration state)
        addendum.addendumText = "This is the legacy version"

        // Migration method should prefer encrypted data
        let retrievedText = try addendum.getAddendumTextWithMigration()
        XCTAssertEqual(retrievedText, encryptedText, "Should prefer encrypted data over legacy")
    }

    func testMigrateToEncryptedStorage() throws {
        let addendum = NoteAddendum(context: context)
        addendum.id = UUID()
        addendum.createdAt = Date()
        addendum.authorName = "Dr. Migration Test"

        // Set up legacy data
        let legacyText = "Pre-migration addendum text"
        addendum.addendumText = legacyText
        addendum.isEncrypted = false

        // Perform migration
        try addendum.migrateToEncryptedStorage()

        // Verify migration occurred
        XCTAssertTrue(addendum.isEncrypted, "isEncrypted should be true after migration")
        XCTAssertNil(addendum.addendumText, "Legacy field should be cleared")
        XCTAssertNotNil(addendum.encryptedAddendumText, "Encrypted data should exist")

        // Verify data is still readable
        let retrievedText = try addendum.getAddendumText()
        XCTAssertEqual(retrievedText, legacyText)
    }

    func testMigrationSkipsAlreadyEncrypted() throws {
        let addendum = NoteAddendum(context: context)
        addendum.id = UUID()
        addendum.createdAt = Date()

        let originalText = "Already encrypted addendum"

        // Encrypt first
        try addendum.setAddendumText(originalText)
        let encryptedData = addendum.encryptedAddendumText

        // Try to migrate again
        try addendum.migrateToEncryptedStorage()

        // Verify data wasn't re-encrypted
        XCTAssertEqual(addendum.encryptedAddendumText, encryptedData, "Already encrypted data should not change")
    }

    // MARK: - Error Handling Tests

    func testGetAddendumTextWithNoData() {
        let addendum = NoteAddendum(context: context)
        addendum.id = UUID()
        addendum.createdAt = Date()

        // No data set - should throw
        XCTAssertThrowsError(try addendum.getAddendumText()) { error in
            XCTAssertTrue(error is EncryptionError, "Should throw EncryptionError")
        }
    }

    func testGetAddendumTextWithMigrationNoData() {
        let addendum = NoteAddendum(context: context)
        addendum.id = UUID()
        addendum.createdAt = Date()

        // No data in either field - should throw
        XCTAssertThrowsError(try addendum.getAddendumTextWithMigration()) { error in
            XCTAssertTrue(error is EncryptionError, "Should throw EncryptionError when no data available")
        }
    }

    // MARK: - Convenience Property Tests

    func testHasAddendumText() throws {
        let addendum = NoteAddendum(context: context)
        addendum.id = UUID()
        addendum.createdAt = Date()

        XCTAssertFalse(addendum.hasAddendumText, "Should be false when no data")

        try addendum.setAddendumText("Test addendum")
        XCTAssertTrue(addendum.hasAddendumText, "Should be true after setting encrypted data")
    }

    func testHasAddendumTextWithLegacy() {
        let addendum = NoteAddendum(context: context)
        addendum.id = UUID()
        addendum.createdAt = Date()
        addendum.addendumText = "Legacy addendum"

        XCTAssertTrue(addendum.hasAddendumText, "Should be true with legacy data")
    }

    // MARK: - Integration Tests

    func testAddendumPersistenceWithEncryption() throws {
        let addendum = NoteAddendum(context: context)
        addendum.id = UUID()
        addendum.createdAt = Date()
        addendum.authorName = "Dr. Persistence Test"
        addendum.authorID = "PERS_001"
        addendum.correctionOf = "/objective/vitals/0/spo2"

        let testText = "Correcting SpO2 value from 84% to 94%."

        try addendum.setAddendumText(testText)

        // Save context
        try context.save()

        // Fetch and verify
        let fetchRequest: NSFetchRequest<NoteAddendum> = NoteAddendum.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", addendum.id! as CVarArg)
        let results = try context.fetch(fetchRequest)

        XCTAssertEqual(results.count, 1)
        let fetchedAddendum = results[0]

        let retrievedText = try fetchedAddendum.getAddendumText()
        XCTAssertEqual(retrievedText, testText)
        XCTAssertEqual(fetchedAddendum.correctionOf, "/objective/vitals/0/spo2")
    }

    func testEncryptedAddendumIsNotPlaintext() throws {
        let addendum = NoteAddendum(context: context)
        addendum.id = UUID()
        addendum.createdAt = Date()

        let sensitiveText = "PATIENT_SSN_123-45-6789 has condition XYZ"

        try addendum.setAddendumText(sensitiveText)

        // Verify encrypted data doesn't contain plaintext
        let encryptedData = addendum.encryptedAddendumText!
        let encryptedString = String(data: encryptedData, encoding: .utf8) ?? ""

        XCTAssertFalse(encryptedString.contains("PATIENT_SSN"), "Encrypted data should not contain plaintext")
        XCTAssertFalse(encryptedString.contains("123-45-6789"), "Encrypted data should not contain plaintext identifiers")
    }

    // MARK: - Integration with Note Entity

    func testAddendumCreatedThroughNoteUsesEncryption() throws {
        // Create a signed note
        let note = Note(context: context)
        note.id = UUID()
        note.createdAt = Date()
        note.isLocked = false

        // Sign the note first (addenda require signed notes)
        try note.sign(by: "Dr. Test", clinicianID: "TEST_001")

        // Add addendum through the Note entity
        let addendumText = "Addendum added through Note entity"
        let addendum = try note.addAddendum(
            text: addendumText,
            authorName: "Dr. Test",
            authorID: "TEST_001",
            correctionOf: nil,
            context: context
        )

        // Verify addendum uses encryption
        XCTAssertTrue(addendum.isEncrypted, "Addendum created through Note should use encryption")
        XCTAssertNil(addendum.addendumText, "Legacy field should be nil")
        XCTAssertNotNil(addendum.encryptedAddendumText, "Encrypted data should exist")

        // Verify text can be retrieved
        let retrievedText = try addendum.getAddendumText()
        XCTAssertEqual(retrievedText, addendumText)
    }
}
