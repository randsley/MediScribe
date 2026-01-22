//
//  EncryptionServiceTests.swift
//  MediScribeTests
//
//  Tests for application-level encryption
//

import XCTest
import CoreData
@testable import MediScribe

final class EncryptionServiceTests: XCTestCase {

    var encryptionService: EncryptionService!
    var keychainManager: KeychainManager!

    override func setUp() {
        super.setUp()
        encryptionService = EncryptionService.shared
        keychainManager = KeychainManager.shared
    }

    override func tearDown() {
        // Clean up keychain after each test
        try? keychainManager.deleteNoteDataEncryptionKey()
        super.tearDown()
    }

    // MARK: - Basic Encryption/Decryption Tests

    func testEncryptDecryptData() throws {
        let originalData = "Sensitive patient information".data(using: .utf8)!

        let encrypted = try encryptionService.encrypt(originalData)
        let decrypted = try encryptionService.decrypt(encrypted)

        XCTAssertEqual(originalData, decrypted, "Decrypted data should match original")
        XCTAssertNotEqual(originalData, encrypted, "Encrypted data should differ from original")
    }

    func testEncryptDecryptCodableObject() throws {
        let originalNote = FieldNote(
            meta: NoteMeta(
                author: NoteAuthor(id: "test_001", displayName: "Dr. Test", role: "Physician"),
                patient: NotePatient(id: "PAT-123", estimatedAgeYears: 45, sexAtBirth: .male),
                encounter: NoteEncounter(setting: .tent, locationText: "Test Camp"),
                consent: NoteConsent(status: .obtained)
            )
        )

        let encrypted: Data = try encryptionService.encrypt(originalNote)
        let decrypted: FieldNote = try encryptionService.decrypt(encrypted, as: FieldNote.self)

        XCTAssertEqual(decrypted.meta.patient.id, originalNote.meta.patient.id)
        XCTAssertEqual(decrypted.meta.author.displayName, originalNote.meta.author.displayName)
    }

    // MARK: - Key Persistence Tests

    func testKeyPersistence() throws {
        let key1 = try keychainManager.getNoteDataEncryptionKey()
        let key2 = try keychainManager.getNoteDataEncryptionKey()

        XCTAssertEqual(key1, key2, "Same key should be retrieved on subsequent calls")
    }

    func testKeyGeneration() throws {
        let key = try keychainManager.getNoteDataEncryptionKey()

        XCTAssertEqual(key.count, 32, "Encryption key should be 256 bits (32 bytes)")
    }

    // MARK: - Error Handling Tests

    func testDecryptInvalidData() {
        let invalidData = "not encrypted data".data(using: .utf8)!

        XCTAssertThrowsError(try encryptionService.decrypt(invalidData)) { error in
            XCTAssertTrue(error is EncryptionError, "Should throw EncryptionError")
        }
    }

    func testDecryptEmptyData() {
        let emptyData = Data()

        XCTAssertThrowsError(try encryptionService.decrypt(emptyData)) { error in
            XCTAssertTrue(error is EncryptionError, "Should throw EncryptionError for empty data")
        }
    }

    // MARK: - Security Tests

    func testDifferentEncryptionsProduceDifferentCiphertext() throws {
        let originalData = "Same plaintext".data(using: .utf8)!

        let encrypted1 = try encryptionService.encrypt(originalData)
        let encrypted2 = try encryptionService.encrypt(originalData)

        // AES-GCM uses random nonces, so same plaintext should produce different ciphertext
        XCTAssertNotEqual(encrypted1, encrypted2, "Same plaintext should produce different ciphertext due to random nonce")

        // But both should decrypt to same plaintext
        let decrypted1 = try encryptionService.decrypt(encrypted1)
        let decrypted2 = try encryptionService.decrypt(encrypted2)

        XCTAssertEqual(decrypted1, decrypted2)
        XCTAssertEqual(decrypted1, originalData)
    }

    // MARK: - Integration Tests

    func testNoteEntityEncryptionIntegration() throws {
        let persistenceController = PersistenceController.preview
        let context = persistenceController.container.viewContext

        let originalNote = FieldNote(
            meta: NoteMeta(
                author: NoteAuthor(id: "int_test", displayName: "Integration Test", role: "Tester"),
                patient: NotePatient(id: "INT-001"),
                encounter: NoteEncounter(setting: .home),
                consent: NoteConsent(status: .impliedEmergency)
            )
        )

        let noteEntity = Note(context: context)
        noteEntity.id = UUID()
        noteEntity.createdAt = Date()

        // Test encrypted save
        try noteEntity.setFieldNote(originalNote)

        // Verify data is encrypted (not plain JSON)
        let storedData = noteEntity.noteData!
        XCTAssertThrowsError(try JSONDecoder().decode(FieldNote.self, from: storedData)) {
            _ in
            // Should not be able to decode as plain JSON
        }

        // Test encrypted load
        let retrievedNote = try noteEntity.getFieldNote()

        XCTAssertEqual(retrievedNote.meta.patient.id, originalNote.meta.patient.id)
        XCTAssertEqual(retrievedNote.meta.author.displayName, originalNote.meta.author.displayName)
    }

    func testMigrationFromUnencryptedToEncrypted() throws {
        let persistenceController = PersistenceController.preview
        let context = persistenceController.container.viewContext

        let originalNote = FieldNote(
            meta: NoteMeta(
                author: NoteAuthor(id: "migration_test", displayName: "Migration Test", role: "Tester"),
                patient: NotePatient(id: "MIG-001"),
                encounter: NoteEncounter(setting: .ambulance),
                consent: NoteConsent(status: .obtained)
            )
        )

        // Simulate legacy unencrypted storage
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let unencryptedData = try encoder.encode(originalNote)

        let noteEntity = Note(context: context)
        noteEntity.id = UUID()
        noteEntity.createdAt = Date()
        noteEntity.noteData = unencryptedData
        noteEntity.patientID = originalNote.meta.patient.id

        // Test migration method can read legacy format
        let retrievedNote = try noteEntity.getFieldNoteWithMigration()

        XCTAssertEqual(retrievedNote.meta.patient.id, originalNote.meta.patient.id)
        XCTAssertEqual(retrievedNote.meta.author.id, originalNote.meta.author.id)
    }
}
