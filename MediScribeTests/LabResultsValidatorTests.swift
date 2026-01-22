//
//  LabResultsValidatorTests.swift
//  MediScribeTests
//
//  Tests for laboratory results safety validation
//

import XCTest
@testable import MediScribe

final class LabResultsValidatorTests: XCTestCase {

    // Required limitations statement from LabResultsValidator
    private let validLimitations = "This summary transcribes visible values from the document and does not interpret clinical significance or provide medical advice."

    // MARK: - Valid Lab Results Tests

    func testValidLabResults() throws {
        let validJSON = """
        {
            "document_type": "Laboratory Report",
            "document_date": "2026-01-20",
            "laboratory_name": "Central Lab",
            "test_categories": [
                {
                    "category": "Complete Blood Count",
                    "tests": [
                        {
                            "test_name": "Hemoglobin",
                            "value": "14.5",
                            "unit": "g/dL",
                            "reference_range": "12.0-16.0"
                        },
                        {
                            "test_name": "White Blood Cell Count",
                            "value": "7.2",
                            "unit": "x10^9/L",
                            "reference_range": "4.0-11.0"
                        }
                    ]
                }
            ],
            "limitations": "\(validLimitations)"
        }
        """

        XCTAssertNoThrow(try LabResultsValidator.decodeAndValidate(validJSON))
    }

    // MARK: - Schema Validation Tests

    func testMissingLimitationsStatement() {
        let invalidJSON = """
        {
            "document_type": "Lab Report",
            "test_categories": []
        }
        """

        XCTAssertThrowsError(try LabResultsValidator.decodeAndValidate(invalidJSON)) { error in
            guard let validationError = error as? LabValidationError else {
                XCTFail("Expected LabValidationError")
                return
            }
            if case .missingLimitationsStatement = validationError {
                // Correct error type
            } else {
                XCTFail("Expected missingLimitationsStatement error, got \(validationError)")
            }
        }
    }

    func testIncorrectLimitationsStatement() {
        let invalidJSON = """
        {
            "document_type": "Lab Report",
            "test_categories": [
                {
                    "category": "CBC",
                    "tests": [{"test_name": "Test", "value": "1"}]
                }
            ],
            "limitations": "This is a different statement."
        }
        """

        XCTAssertThrowsError(try LabResultsValidator.decodeAndValidate(invalidJSON)) { error in
            guard let validationError = error as? LabValidationError else {
                XCTFail("Expected LabValidationError")
                return
            }
            if case .missingLimitationsStatement = validationError {
                // Correct error type - incorrect statement treated as missing
            } else {
                XCTFail("Expected missingLimitationsStatement error, got \(validationError)")
            }
        }
    }

    func testMissingDocumentType() {
        let invalidJSON = """
        {
            "test_categories": [],
            "limitations": "\(validLimitations)"
        }
        """

        XCTAssertThrowsError(try LabResultsValidator.decodeAndValidate(invalidJSON)) { error in
            guard let validationError = error as? LabValidationError else {
                XCTFail("Expected LabValidationError")
                return
            }
            if case .missingRequiredField("document_type") = validationError {
                // Correct error type
            } else {
                XCTFail("Expected missingRequiredField(document_type) error, got \(validationError)")
            }
        }
    }

    func testInvalidTopLevelKey() {
        let invalidJSON = """
        {
            "document_type": "Lab Report",
            "test_categories": [],
            "invalid_key": "should fail",
            "limitations": "\(validLimitations)"
        }
        """

        XCTAssertThrowsError(try LabResultsValidator.decodeAndValidate(invalidJSON)) { error in
            guard let validationError = error as? LabValidationError else {
                XCTFail("Expected LabValidationError")
                return
            }
            if case .invalidTopLevelKey = validationError {
                // Correct error type
            } else {
                XCTFail("Expected invalidTopLevelKey error, got \(validationError)")
            }
        }
    }

    // MARK: - Forbidden Phrase Detection Tests

    func testForbiddenPhrase_Abnormal() {
        let invalidJSON = """
        {
            "document_type": "Lab Report",
            "test_categories": [
                {
                    "category": "Abnormal results detected",
                    "tests": [{"test_name": "Test", "value": "1"}]
                }
            ],
            "limitations": "\(validLimitations)"
        }
        """

        XCTAssertThrowsError(try LabResultsValidator.decodeAndValidate(invalidJSON)) { error in
            guard let validationError = error as? LabValidationError else {
                XCTFail("Expected LabValidationError")
                return
            }
            if case .forbiddenPhraseDetected = validationError {
                // Correct error type
            } else {
                XCTFail("Expected forbiddenPhraseDetected error, got \(validationError)")
            }
        }
    }

    func testForbiddenPhrase_RequiresFollowUp() {
        let invalidJSON = """
        {
            "document_type": "Lab Report",
            "test_categories": [
                {
                    "category": "Metabolic Panel",
                    "tests": [
                        {
                            "test_name": "Glucose",
                            "value": "150 - requires follow-up",
                            "unit": "mg/dL"
                        }
                    ]
                }
            ],
            "limitations": "\(validLimitations)"
        }
        """

        XCTAssertThrowsError(try LabResultsValidator.decodeAndValidate(invalidJSON)) { error in
            guard let validationError = error as? LabValidationError else {
                XCTFail("Expected LabValidationError")
                return
            }
            if case .forbiddenPhraseDetected = validationError {
                // Correct error type
            } else {
                XCTFail("Expected forbiddenPhraseDetected error, got \(validationError)")
            }
        }
    }

    func testForbiddenPhrase_Concerning() {
        let invalidJSON = """
        {
            "document_type": "Concerning lab values",
            "test_categories": [
                {
                    "category": "Tests",
                    "tests": [{"test_name": "Test", "value": "1"}]
                }
            ],
            "limitations": "\(validLimitations)"
        }
        """

        XCTAssertThrowsError(try LabResultsValidator.decodeAndValidate(invalidJSON)) { error in
            guard let validationError = error as? LabValidationError else {
                XCTFail("Expected LabValidationError")
                return
            }
            if case .forbiddenPhraseDetected = validationError {
                // Correct error type
            } else {
                XCTFail("Expected forbiddenPhraseDetected error, got \(validationError)")
            }
        }
    }

    // MARK: - Edge Cases

    func testEmptyTestCategories() {
        // Empty test_categories should throw emptyTestCategories error
        let invalidJSON = """
        {
            "document_type": "Lab Report",
            "test_categories": [],
            "limitations": "\(validLimitations)"
        }
        """

        XCTAssertThrowsError(try LabResultsValidator.decodeAndValidate(invalidJSON)) { error in
            guard let validationError = error as? LabValidationError else {
                XCTFail("Expected LabValidationError")
                return
            }
            if case .emptyTestCategories = validationError {
                // Correct error type
            } else {
                XCTFail("Expected emptyTestCategories error, got \(validationError)")
            }
        }
    }

    func testMultipleTestCategories() throws {
        let validJSON = """
        {
            "document_type": "Lab Report",
            "test_categories": [
                {
                    "category": "CBC",
                    "tests": [
                        {"test_name": "Hemoglobin", "value": "14.5", "unit": "g/dL"}
                    ]
                },
                {
                    "category": "Metabolic Panel",
                    "tests": [
                        {"test_name": "Glucose", "value": "95", "unit": "mg/dL"}
                    ]
                }
            ],
            "limitations": "\(validLimitations)"
        }
        """

        XCTAssertNoThrow(try LabResultsValidator.decodeAndValidate(validJSON))
    }

    func testOptionalFields() throws {
        let validJSON = """
        {
            "document_type": "Lab Report",
            "document_date": "2026-01-20",
            "laboratory_name": "Test Lab",
            "test_categories": [
                {
                    "category": "Basic",
                    "tests": [
                        {
                            "test_name": "Test",
                            "value": "100",
                            "unit": "U",
                            "reference_range": "90-110",
                            "method": "Automated"
                        }
                    ]
                }
            ],
            "limitations": "\(validLimitations)"
        }
        """

        let result = try LabResultsValidator.decodeAndValidate(validJSON)
        XCTAssertEqual(result.documentType, "Lab Report")
        XCTAssertEqual(result.documentDate, "2026-01-20")
        XCTAssertEqual(result.laboratoryName, "Test Lab")
        XCTAssertEqual(result.testCategories.count, 1)
        XCTAssertEqual(result.testCategories[0].tests[0].method, "Automated")
    }

    // MARK: - Text Sanitization Tests

    func testObfuscatedForbiddenPhrase() {
        // Test that spaces/formatting don't bypass detection
        let invalidJSON = """
        {
            "document_type": "Lab Report",
            "test_categories": [
                {
                    "category": "Results",
                    "tests": [
                        {
                            "test_name": "Test",
                            "value": "a b n o r m a l"
                        }
                    ]
                }
            ],
            "limitations": "\(validLimitations)"
        }
        """

        XCTAssertThrowsError(try LabResultsValidator.decodeAndValidate(invalidJSON))
    }
}
