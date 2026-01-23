//
//  ReferralEncryptionTests.swift
//  MediScribeTests
//
//  Tests for Referral entity encryption
//

import XCTest
import CoreData
@testable import MediScribe

final class ReferralEncryptionTests: XCTestCase {

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

    // MARK: - Clinical Summary Encryption Tests

    func testEncryptDecryptClinicalSummary() throws {
        let referral = Referral(context: context)
        referral.id = UUID()
        referral.createdAt = Date()
        referral.destination = "Regional Hospital"
        referral.status = "pending"

        let originalSummary = """
        Patient presents with chest pain and shortness of breath.
        History of hypertension and diabetes.
        Current medications include metformin and lisinopril.
        """

        // Encrypt and store
        try referral.setClinicalSummary(originalSummary)

        // Verify isEncrypted flag is set
        XCTAssertTrue(referral.isEncrypted, "isEncrypted flag should be set")

        // Verify legacy field is cleared
        XCTAssertNil(referral.clinicalSummary, "Legacy clinicalSummary field should be nil")

        // Verify encrypted data exists
        XCTAssertNotNil(referral.encryptedClinicalSummary, "Encrypted data should exist")

        // Decrypt and verify
        let decryptedSummary = try referral.getClinicalSummary()
        XCTAssertEqual(decryptedSummary, originalSummary, "Decrypted summary should match original")
    }

    // MARK: - Reason Encryption Tests

    func testEncryptDecryptReason() throws {
        let referral = Referral(context: context)
        referral.id = UUID()
        referral.createdAt = Date()
        referral.destination = "Cardiology Specialist"
        referral.status = "pending"

        let originalReason = "Suspected cardiac arrhythmia requiring specialist evaluation and possible ECG monitoring"

        // Encrypt and store
        try referral.setReason(originalReason)

        // Verify isEncrypted flag is set
        XCTAssertTrue(referral.isEncrypted, "isEncrypted flag should be set")

        // Verify legacy field is cleared
        XCTAssertNil(referral.reason, "Legacy reason field should be nil")

        // Verify encrypted data exists
        XCTAssertNotNil(referral.encryptedReason, "Encrypted data should exist")

        // Decrypt and verify
        let decryptedReason = try referral.getReason()
        XCTAssertEqual(decryptedReason, originalReason, "Decrypted reason should match original")
    }

    func testEncryptBothFields() throws {
        let referral = Referral(context: context)
        referral.id = UUID()
        referral.createdAt = Date()
        referral.destination = "Multi-specialty Clinic"
        referral.status = "pending"

        let summary = "Comprehensive patient history and current status"
        let reason = "Multiple conditions requiring coordinated care"

        try referral.setClinicalSummary(summary)
        try referral.setReason(reason)

        XCTAssertTrue(referral.isEncrypted)

        let retrievedSummary = try referral.getClinicalSummary()
        let retrievedReason = try referral.getReason()

        XCTAssertEqual(retrievedSummary, summary)
        XCTAssertEqual(retrievedReason, reason)
    }

    // MARK: - Migration Tests

    func testMigrationFromLegacyClinicalSummary() throws {
        let referral = Referral(context: context)
        referral.id = UUID()
        referral.createdAt = Date()

        // Simulate legacy unencrypted storage
        let legacySummary = "Legacy clinical summary before encryption"
        referral.clinicalSummary = legacySummary
        referral.isEncrypted = false

        // Use migration method to read
        let retrievedSummary = try referral.getClinicalSummaryWithMigration()
        XCTAssertEqual(retrievedSummary, legacySummary, "Migration should read legacy data")
    }

    func testMigrationFromLegacyReason() throws {
        let referral = Referral(context: context)
        referral.id = UUID()
        referral.createdAt = Date()

        // Simulate legacy unencrypted storage
        let legacyReason = "Legacy referral reason before encryption"
        referral.reason = legacyReason
        referral.isEncrypted = false

        // Use migration method to read
        let retrievedReason = try referral.getReasonWithMigration()
        XCTAssertEqual(retrievedReason, legacyReason, "Migration should read legacy data")
    }

    func testMigrationPrefersEncryptedData() throws {
        let referral = Referral(context: context)
        referral.id = UUID()
        referral.createdAt = Date()

        // Set encrypted data first
        let encryptedSummary = "This is the encrypted summary"
        try referral.setClinicalSummary(encryptedSummary)

        // Also set legacy field (simulating partial migration state)
        referral.clinicalSummary = "This is the legacy summary"

        // Migration method should prefer encrypted data
        let retrievedSummary = try referral.getClinicalSummaryWithMigration()
        XCTAssertEqual(retrievedSummary, encryptedSummary, "Should prefer encrypted data over legacy")
    }

    func testMigrateToEncryptedStorage() throws {
        let referral = Referral(context: context)
        referral.id = UUID()
        referral.createdAt = Date()
        referral.destination = "Test Hospital"

        // Set up legacy data
        let legacySummary = "Pre-migration clinical summary"
        let legacyReason = "Pre-migration referral reason"
        referral.clinicalSummary = legacySummary
        referral.reason = legacyReason
        referral.isEncrypted = false

        // Perform migration
        try referral.migrateToEncryptedStorage()

        // Verify migration occurred
        XCTAssertTrue(referral.isEncrypted, "isEncrypted should be true after migration")
        XCTAssertNil(referral.clinicalSummary, "Legacy summary field should be cleared")
        XCTAssertNil(referral.reason, "Legacy reason field should be cleared")
        XCTAssertNotNil(referral.encryptedClinicalSummary, "Encrypted summary should exist")
        XCTAssertNotNil(referral.encryptedReason, "Encrypted reason should exist")

        // Verify data is still readable
        let retrievedSummary = try referral.getClinicalSummary()
        let retrievedReason = try referral.getReason()
        XCTAssertEqual(retrievedSummary, legacySummary)
        XCTAssertEqual(retrievedReason, legacyReason)
    }

    func testMigrationSkipsAlreadyEncrypted() throws {
        let referral = Referral(context: context)
        referral.id = UUID()
        referral.createdAt = Date()

        let originalSummary = "Already encrypted summary"

        // Encrypt first
        try referral.setClinicalSummary(originalSummary)
        let encryptedData = referral.encryptedClinicalSummary

        // Try to migrate again
        try referral.migrateToEncryptedStorage()

        // Verify data wasn't re-encrypted
        XCTAssertEqual(referral.encryptedClinicalSummary, encryptedData, "Already encrypted data should not change")
    }

    func testMigrationWithOnlyOneField() throws {
        let referral = Referral(context: context)
        referral.id = UUID()
        referral.createdAt = Date()

        // Set only clinical summary (no reason)
        let legacySummary = "Only summary, no reason"
        referral.clinicalSummary = legacySummary
        referral.isEncrypted = false

        // Perform migration
        try referral.migrateToEncryptedStorage()

        // Verify migration occurred
        XCTAssertTrue(referral.isEncrypted)
        XCTAssertNotNil(referral.encryptedClinicalSummary)
        XCTAssertNil(referral.encryptedReason)

        let retrievedSummary = try referral.getClinicalSummary()
        XCTAssertEqual(retrievedSummary, legacySummary)
    }

    // MARK: - Error Handling Tests

    func testGetClinicalSummaryWithNoData() {
        let referral = Referral(context: context)
        referral.id = UUID()
        referral.createdAt = Date()

        // No data set - should throw
        XCTAssertThrowsError(try referral.getClinicalSummary()) { error in
            XCTAssertTrue(error is EncryptionError, "Should throw EncryptionError")
        }
    }

    func testGetReasonWithNoData() {
        let referral = Referral(context: context)
        referral.id = UUID()
        referral.createdAt = Date()

        // No data set - should throw
        XCTAssertThrowsError(try referral.getReason()) { error in
            XCTAssertTrue(error is EncryptionError, "Should throw EncryptionError")
        }
    }

    func testGetClinicalSummaryWithMigrationNoData() {
        let referral = Referral(context: context)
        referral.id = UUID()
        referral.createdAt = Date()

        // No data in either field - should throw
        XCTAssertThrowsError(try referral.getClinicalSummaryWithMigration()) { error in
            XCTAssertTrue(error is EncryptionError, "Should throw EncryptionError when no data available")
        }
    }

    // MARK: - Convenience Property Tests

    func testHasClinicalSummary() throws {
        let referral = Referral(context: context)
        referral.id = UUID()
        referral.createdAt = Date()

        XCTAssertFalse(referral.hasClinicalSummary, "Should be false when no data")

        try referral.setClinicalSummary("Test summary")
        XCTAssertTrue(referral.hasClinicalSummary, "Should be true after setting encrypted data")
    }

    func testHasReason() throws {
        let referral = Referral(context: context)
        referral.id = UUID()
        referral.createdAt = Date()

        XCTAssertFalse(referral.hasReason, "Should be false when no data")

        try referral.setReason("Test reason")
        XCTAssertTrue(referral.hasReason, "Should be true after setting encrypted data")
    }

    func testHasClinicalSummaryWithLegacy() {
        let referral = Referral(context: context)
        referral.id = UUID()
        referral.createdAt = Date()
        referral.clinicalSummary = "Legacy summary"

        XCTAssertTrue(referral.hasClinicalSummary, "Should be true with legacy data")
    }

    func testHasReasonWithLegacy() {
        let referral = Referral(context: context)
        referral.id = UUID()
        referral.createdAt = Date()
        referral.reason = "Legacy reason"

        XCTAssertTrue(referral.hasReason, "Should be true with legacy data")
    }

    // MARK: - Integration Tests

    func testReferralPersistenceWithEncryption() throws {
        let referral = Referral(context: context)
        referral.id = UUID()
        referral.createdAt = Date()
        referral.destination = "Test Medical Center"
        referral.status = "pending"
        referral.sentAt = nil

        let testSummary = "Complete clinical history for referral"
        let testReason = "Specialist consultation required"

        try referral.setClinicalSummary(testSummary)
        try referral.setReason(testReason)

        // Save context
        try context.save()

        // Fetch and verify
        let fetchRequest: NSFetchRequest<Referral> = Referral.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", referral.id! as CVarArg)
        let results = try context.fetch(fetchRequest)

        XCTAssertEqual(results.count, 1)
        let fetchedReferral = results[0]

        let retrievedSummary = try fetchedReferral.getClinicalSummary()
        let retrievedReason = try fetchedReferral.getReason()

        XCTAssertEqual(retrievedSummary, testSummary)
        XCTAssertEqual(retrievedReason, testReason)
        XCTAssertEqual(fetchedReferral.destination, "Test Medical Center")
    }

    func testEncryptedDataIsNotPlaintext() throws {
        let referral = Referral(context: context)
        referral.id = UUID()
        referral.createdAt = Date()

        let sensitiveSummary = "PATIENT_MRN_987654321 diagnosed with SENSITIVE_CONDITION"
        let sensitiveReason = "Urgent referral for CONFIDENTIAL_PROCEDURE"

        try referral.setClinicalSummary(sensitiveSummary)
        try referral.setReason(sensitiveReason)

        // Verify encrypted summary doesn't contain plaintext
        let encryptedSummary = referral.encryptedClinicalSummary!
        let encryptedSummaryString = String(data: encryptedSummary, encoding: .utf8) ?? ""
        XCTAssertFalse(encryptedSummaryString.contains("PATIENT_MRN"), "Encrypted data should not contain plaintext")
        XCTAssertFalse(encryptedSummaryString.contains("987654321"), "Encrypted data should not contain plaintext identifiers")

        // Verify encrypted reason doesn't contain plaintext
        let encryptedReason = referral.encryptedReason!
        let encryptedReasonString = String(data: encryptedReason, encoding: .utf8) ?? ""
        XCTAssertFalse(encryptedReasonString.contains("CONFIDENTIAL"), "Encrypted data should not contain plaintext")
    }

    func testSpecialCharactersPreserved() throws {
        let referral = Referral(context: context)
        referral.id = UUID()
        referral.createdAt = Date()

        let textWithSpecialChars = """
        Patient: José García-López
        Temperature: 38.5°C
        Notes: "Acute presentation" — immediate attention required
        Symbols: ≥ ≤ ± μg/mL
        """

        try referral.setClinicalSummary(textWithSpecialChars)

        let retrieved = try referral.getClinicalSummary()
        XCTAssertEqual(retrieved, textWithSpecialChars, "Special characters should be preserved")
    }
}
