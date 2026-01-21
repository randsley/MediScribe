//
//  LabResultsValidatorTests.swift
//  MediScribeTests
//
//  Tests for laboratory results safety validation
//

import XCTest
@testable import MediScribe

final class LabResultsValidatorTests: XCTestCase {

    // MARK: - Valid Lab Results Tests

    func testValidLabResults() throws {
        let validJSON = """
        {
            "documentType": "Laboratory Report",
            "documentDate": "2026-01-20",
            "laboratoryName": "Central Lab",
            "testCategories": [
                {
                    "category": "Complete Blood Count",
                    "tests": [
                        {
                            "testName": "Hemoglobin",
                            "value": "14.5",
                            "unit": "g/dL",
                            "referenceRange": "12.0-16.0"
                        },
                        {
                            "testName": "White Blood Cell Count",
                            "value": "7.2",
                            "unit": "x10^9/L",
                            "referenceRange": "4.0-11.0"
                        }
                    ]
                }
            ],
            "limitations": "This extraction shows ONLY the visible values from the laboratory report and does not interpret clinical significance or provide recommendations."
        }
        """

        XCTAssertNoThrow(try LabResultsValidator.decodeAndValidate(validJSON))
    }

    // MARK: - Schema Validation Tests

    func testMissingLimitationsStatement() {
        let invalidJSON = """
        {
            "testCategories": []
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
                XCTFail("Expected missingLimitationsStatement error")
            }
        }
    }

    func testIncorrectLimitationsStatement() {
        let invalidJSON = """
        {
            "testCategories": [],
            "limitations": "This is a different statement."
        }
        """

        XCTAssertThrowsError(try LabResultsValidator.decodeAndValidate(invalidJSON)) { error in
            guard let validationError = error as? LabValidationError else {
                XCTFail("Expected LabValidationError")
                return
            }
            if case .incorrectLimitationsStatement = validationError {
                // Correct error type
            } else {
                XCTFail("Expected incorrectLimitationsStatement error")
            }
        }
    }

    // MARK: - Forbidden Phrase Detection Tests

    func testForbiddenPhrase_Abnormal() {
        let invalidJSON = """
        {
            "testCategories": [
                {
                    "category": "Abnormal results detected",
                    "tests": []
                }
            ],
            "limitations": "This extraction shows ONLY the visible values from the laboratory report and does not interpret clinical significance or provide recommendations."
        }
        """

        XCTAssertThrowsError(try LabResultsValidator.decodeAndValidate(invalidJSON)) { error in
            guard let validationError = error as? LabValidationError else {
                XCTFail("Expected LabValidationError")
                return
            }
            if case .forbiddenPhrase = validationError {
                // Correct error type
            } else {
                XCTFail("Expected forbiddenPhrase error")
            }
        }
    }

    func testForbiddenPhrase_RequiresFollowUp() {
        let invalidJSON = """
        {
            "testCategories": [
                {
                    "category": "Metabolic Panel",
                    "tests": [
                        {
                            "testName": "Glucose",
                            "value": "150 - requires follow-up",
                            "unit": "mg/dL"
                        }
                    ]
                }
            ],
            "limitations": "This extraction shows ONLY the visible values from the laboratory report and does not interpret clinical significance or provide recommendations."
        }
        """

        XCTAssertThrowsError(try LabResultsValidator.decodeAndValidate(invalidJSON))
    }

    func testForbiddenPhrase_Concerning() {
        let invalidJSON = """
        {
            "documentType": "Concerning lab values",
            "testCategories": [],
            "limitations": "This extraction shows ONLY the visible values from the laboratory report and does not interpret clinical significance or provide recommendations."
        }
        """

        XCTAssertThrowsError(try LabResultsValidator.decodeAndValidate(invalidJSON))
    }

    // MARK: - Edge Cases

    func testEmptyTestCategories() throws {
        let validJSON = """
        {
            "testCategories": [],
            "limitations": "This extraction shows ONLY the visible values from the laboratory report and does not interpret clinical significance or provide recommendations."
        }
        """

        // Empty categories should be valid (maybe the extraction found no tests)
        XCTAssertNoThrow(try LabResultsValidator.decodeAndValidate(validJSON))
    }

    func testMultipleTestCategories() throws {
        let validJSON = """
        {
            "testCategories": [
                {
                    "category": "CBC",
                    "tests": [
                        {"testName": "Hemoglobin", "value": "14.5", "unit": "g/dL"}
                    ]
                },
                {
                    "category": "Metabolic Panel",
                    "tests": [
                        {"testName": "Glucose", "value": "95", "unit": "mg/dL"}
                    ]
                }
            ],
            "limitations": "This extraction shows ONLY the visible values from the laboratory report and does not interpret clinical significance or provide recommendations."
        }
        """

        XCTAssertNoThrow(try LabResultsValidator.decodeAndValidate(validJSON))
    }

    func testOptionalFields() throws {
        let validJSON = """
        {
            "documentType": "Lab Report",
            "documentDate": "2026-01-20",
            "laboratoryName": "Test Lab",
            "testCategories": [
                {
                    "category": "Basic",
                    "tests": [
                        {
                            "testName": "Test",
                            "value": "100",
                            "unit": "U",
                            "referenceRange": "90-110",
                            "method": "Automated"
                        }
                    ]
                }
            ],
            "limitations": "This extraction shows ONLY the visible values from the laboratory report and does not interpret clinical significance or provide recommendations."
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
            "testCategories": [
                {
                    "category": "Results",
                    "tests": [
                        {
                            "testName": "Test",
                            "value": "a b n o r m a l"
                        }
                    ]
                }
            ],
            "limitations": "This extraction shows ONLY the visible values from the laboratory report and does not interpret clinical significance or provide recommendations."
        }
        """

        XCTAssertThrowsError(try LabResultsValidator.decodeAndValidate(invalidJSON))
    }
}
