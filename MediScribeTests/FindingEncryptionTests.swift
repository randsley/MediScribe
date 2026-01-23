//
//  FindingEncryptionTests.swift
//  MediScribeTests
//
//  Tests for Finding entity encryption
//

import XCTest
import CoreData
@testable import MediScribe

final class FindingEncryptionTests: XCTestCase {

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

    // MARK: - Findings JSON Encryption Tests

    func testEncryptDecryptFindingsJSON() throws {
        let finding = Finding(context: context)
        finding.id = UUID()
        finding.createdAt = Date()
        finding.documentType = "imaging"

        let originalJSON = """
        {"image_type": "chest_xray", "limitations": "Test limitations statement"}
        """

        // Encrypt and store
        try finding.setFindingsJSON(originalJSON)

        // Verify isEncrypted flag is set
        XCTAssertTrue(finding.isEncrypted, "isEncrypted flag should be set")

        // Verify legacy field is cleared
        XCTAssertNil(finding.findingsJSON, "Legacy findingsJSON field should be nil")

        // Verify encrypted data exists
        XCTAssertNotNil(finding.encryptedFindingsData, "Encrypted data should exist")

        // Decrypt and verify
        let decryptedJSON = try finding.getFindingsJSON()
        XCTAssertEqual(decryptedJSON, originalJSON, "Decrypted JSON should match original")
    }

    func testEncryptDecryptTypedFindings() throws {
        let finding = Finding(context: context)
        finding.id = UUID()
        finding.createdAt = Date()
        finding.documentType = "lab"

        let originalResults = LabResultsSummary(
            documentType: "laboratory_report",
            documentDate: "2024-01-15",
            laboratoryName: "Test Lab",
            patientIdentifier: "PAT-123",
            orderingProvider: "Dr. Test",
            testCategories: [
                LabTestCategory(
                    category: "CBC",
                    tests: [
                        LabTestResult(testName: "WBC", value: "7.5", unit: "x10^9/L", referenceRange: "4.5-11.0", method: nil)
                    ]
                )
            ],
            notes: nil,
            limitations: "This extraction shows ONLY the visible values from the laboratory report and does not interpret clinical significance or provide recommendations."
        )

        // Encrypt and store
        try finding.setFindings(originalResults)

        // Verify encryption occurred
        XCTAssertTrue(finding.isEncrypted)
        XCTAssertNotNil(finding.encryptedFindingsData)

        // Decrypt and verify
        let decryptedResults: LabResultsSummary = try finding.getFindings(as: LabResultsSummary.self)
        XCTAssertEqual(decryptedResults.documentType, originalResults.documentType)
        XCTAssertEqual(decryptedResults.laboratoryName, originalResults.laboratoryName)
        XCTAssertEqual(decryptedResults.testCategories.count, 1)
        XCTAssertEqual(decryptedResults.testCategories[0].tests[0].testName, "WBC")
    }

    // MARK: - Image Data Encryption Tests

    func testEncryptDecryptImageData() throws {
        let finding = Finding(context: context)
        finding.id = UUID()
        finding.createdAt = Date()
        finding.documentType = "imaging"

        // Create sample image data
        let originalImageData = Data(repeating: 0xFF, count: 1024) // 1KB of test data

        // Encrypt and store
        try finding.setImage(originalImageData)

        // Verify legacy field is cleared
        XCTAssertNil(finding.imageData, "Legacy imageData field should be nil")

        // Verify encrypted data exists
        XCTAssertNotNil(finding.encryptedImageData, "Encrypted image data should exist")

        // Decrypt and verify
        let decryptedImageData = try finding.getImage()
        XCTAssertEqual(decryptedImageData, originalImageData, "Decrypted image should match original")
    }

    // MARK: - Migration Tests

    func testMigrationFromLegacyFindingsJSON() throws {
        let finding = Finding(context: context)
        finding.id = UUID()
        finding.createdAt = Date()
        finding.documentType = "imaging"

        // Simulate legacy unencrypted storage (direct assignment)
        let legacyJSON = """
        {"image_type": "ultrasound", "legacy": true}
        """
        finding.findingsJSON = legacyJSON
        finding.isEncrypted = false

        // Use migration method to read
        let retrievedJSON = try finding.getFindingsJSONWithMigration()
        XCTAssertEqual(retrievedJSON, legacyJSON, "Migration should read legacy data")
    }

    func testMigrationFromLegacyImageData() throws {
        let finding = Finding(context: context)
        finding.id = UUID()
        finding.createdAt = Date()
        finding.documentType = "imaging"

        // Simulate legacy unencrypted storage
        let legacyImageData = Data(repeating: 0xAB, count: 512)
        finding.imageData = legacyImageData
        finding.isEncrypted = false

        // Use migration method to read
        let retrievedData = try finding.getImageWithMigration()
        XCTAssertEqual(retrievedData, legacyImageData, "Migration should read legacy image data")
    }

    func testMigrateToEncryptedStorage() throws {
        let finding = Finding(context: context)
        finding.id = UUID()
        finding.createdAt = Date()
        finding.documentType = "imaging"

        // Set up legacy data
        let legacyJSON = """
        {"pre_migration": true}
        """
        let legacyImageData = Data(repeating: 0xCD, count: 256)
        finding.findingsJSON = legacyJSON
        finding.imageData = legacyImageData
        finding.isEncrypted = false

        // Perform migration
        try finding.migrateToEncryptedStorage()

        // Verify migration occurred
        XCTAssertTrue(finding.isEncrypted, "isEncrypted should be true after migration")
        XCTAssertNil(finding.findingsJSON, "Legacy JSON field should be cleared")
        XCTAssertNil(finding.imageData, "Legacy image data should be cleared")
        XCTAssertNotNil(finding.encryptedFindingsData, "Encrypted findings should exist")
        XCTAssertNotNil(finding.encryptedImageData, "Encrypted image should exist")

        // Verify data is still readable
        let retrievedJSON = try finding.getFindingsJSON()
        let retrievedImage = try finding.getImage()
        XCTAssertEqual(retrievedJSON, legacyJSON)
        XCTAssertEqual(retrievedImage, legacyImageData)
    }

    func testMigrationSkipsAlreadyEncrypted() throws {
        let finding = Finding(context: context)
        finding.id = UUID()
        finding.createdAt = Date()
        finding.documentType = "imaging"

        let originalJSON = """
        {"already_encrypted": true}
        """

        // Encrypt first
        try finding.setFindingsJSON(originalJSON)
        let encryptedData = finding.encryptedFindingsData

        // Try to migrate again
        try finding.migrateToEncryptedStorage()

        // Verify data wasn't re-encrypted
        XCTAssertEqual(finding.encryptedFindingsData, encryptedData, "Already encrypted data should not change")
    }

    // MARK: - Error Handling Tests

    func testGetFindingsJSONWithNoData() {
        let finding = Finding(context: context)
        finding.id = UUID()
        finding.createdAt = Date()

        // No data set - should throw
        XCTAssertThrowsError(try finding.getFindingsJSON()) { error in
            XCTAssertTrue(error is EncryptionError, "Should throw EncryptionError")
        }
    }

    func testGetImageWithNoData() {
        let finding = Finding(context: context)
        finding.id = UUID()
        finding.createdAt = Date()

        // No data set - should throw
        XCTAssertThrowsError(try finding.getImage()) { error in
            XCTAssertTrue(error is EncryptionError, "Should throw EncryptionError")
        }
    }

    // MARK: - Convenience Property Tests

    func testHasFindingsData() throws {
        let finding = Finding(context: context)
        finding.id = UUID()
        finding.createdAt = Date()

        XCTAssertFalse(finding.hasFindingsData, "Should be false when no data")

        try finding.setFindingsJSON("{}")
        XCTAssertTrue(finding.hasFindingsData, "Should be true after setting encrypted data")
    }

    func testHasImageData() throws {
        let finding = Finding(context: context)
        finding.id = UUID()
        finding.createdAt = Date()

        XCTAssertFalse(finding.hasImageData, "Should be false when no data")

        try finding.setImage(Data([0x00]))
        XCTAssertTrue(finding.hasImageData, "Should be true after setting encrypted data")
    }

    func testHasFindingsDataWithLegacy() {
        let finding = Finding(context: context)
        finding.id = UUID()
        finding.createdAt = Date()
        finding.findingsJSON = "{\"legacy\": true}"

        XCTAssertTrue(finding.hasFindingsData, "Should be true with legacy data")
    }

    // MARK: - Integration Tests

    func testFindingPersistenceWithEncryption() throws {
        let finding = Finding(context: context)
        finding.id = UUID()
        finding.createdAt = Date()
        finding.documentType = "imaging"
        finding.reviewedAt = Date()
        finding.reviewedBy = "Test Clinician"

        let testJSON = """
        {"test": "persistence", "encrypted": true}
        """
        let testImage = Data(repeating: 0xEF, count: 2048)

        try finding.setFindingsJSON(testJSON)
        try finding.setImage(testImage)

        // Save context
        try context.save()

        // Fetch and verify
        let fetchRequest: NSFetchRequest<Finding> = Finding.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", finding.id! as CVarArg)
        let results = try context.fetch(fetchRequest)

        XCTAssertEqual(results.count, 1)
        let fetchedFinding = results[0]

        let retrievedJSON = try fetchedFinding.getFindingsJSON()
        let retrievedImage = try fetchedFinding.getImage()

        XCTAssertEqual(retrievedJSON, testJSON)
        XCTAssertEqual(retrievedImage, testImage)
    }

    func testEncryptedDataIsNotPlaintext() throws {
        let finding = Finding(context: context)
        finding.id = UUID()
        finding.createdAt = Date()

        let sensitiveJSON = """
        {"patient_data": "SENSITIVE_INFO_12345"}
        """

        try finding.setFindingsJSON(sensitiveJSON)

        // Verify encrypted data doesn't contain plaintext
        let encryptedData = finding.encryptedFindingsData!
        let encryptedString = String(data: encryptedData, encoding: .utf8) ?? ""

        XCTAssertFalse(encryptedString.contains("SENSITIVE_INFO"), "Encrypted data should not contain plaintext")
        XCTAssertFalse(encryptedString.contains("patient_data"), "Encrypted data should not contain plaintext keys")
    }
}
