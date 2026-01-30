//
//  LabResultsValidator.swift
//  MediScribe
//
//  Safety validator for lab results extraction
//

import Foundation

struct LabResultsValidator {
    // MARK: - Constants

    /// Exact limitations statement that must appear in all lab results output
    static let requiredLimitationsStatement = "This summary transcribes visible values from the document and does not interpret clinical significance or provide medical advice."

    /// Allowed top-level keys in lab results JSON
    static let allowedTopLevelKeys: Set<String> = [
        "document_type",
        "document_date",
        "laboratory_name",
        "patient_identifier",
        "ordering_provider",
        "test_categories",
        "notes",
        "limitations"
    ]

    /// Allowed keys within each test result
    static let allowedTestKeys: Set<String> = [
        "test_name",
        "value",
        "unit",
        "reference_range",
        "method"
    ]

    // MARK: - Validation

    /// Validates lab results JSON output against safety rules
    /// - Parameter jsonString: Raw JSON string from model
    /// - Parameter language: Language to use for phrase validation
    /// - Returns: Validated LabResultsSummary struct
    /// - Throws: LabValidationError if validation fails
    static func decodeAndValidate(_ jsonString: String, language: Language = .english) throws -> LabResultsSummary {
        // 1. Parse JSON
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw LabValidationError.invalidJSON
        }

        guard let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw LabValidationError.invalidJSON
        }

        // 2. Validate top-level keys
        for key in jsonObject.keys {
            if !allowedTopLevelKeys.contains(key) {
                throw LabValidationError.invalidTopLevelKey(key)
            }
        }

        // 3. Validate required fields
        guard jsonObject["document_type"] != nil else {
            throw LabValidationError.missingRequiredField("document_type")
        }

        guard jsonObject["test_categories"] != nil else {
            throw LabValidationError.missingRequiredField("test_categories")
        }

        // 4. Validate limitations statement
        guard let limitations = jsonObject["limitations"] as? String,
              limitations == requiredLimitationsStatement else {
            throw LabValidationError.missingLimitationsStatement
        }

        // 5. Check for forbidden phrases in all text content
        let allText = extractAllText(from: jsonObject)
        if let forbiddenPhrase = TextSanitizer.findForbiddenInLanguage(in: allText, language: language) {
            throw LabValidationError.forbiddenPhraseDetected(forbiddenPhrase)
        }

        // 6. Decode to struct
        let decoder = JSONDecoder()
        guard let summary = try? decoder.decode(LabResultsSummary.self, from: jsonData) else {
            throw LabValidationError.invalidJSON
        }

        // 7. Validate test categories are not empty
        if summary.testCategories.isEmpty {
            throw LabValidationError.emptyTestCategories
        }

        return summary
    }

    // MARK: - Private Helpers

    /// Extracts all text content from JSON for phrase checking
    private static func extractAllText(from json: [String: Any]) -> String {
        var allText = ""

        func extract(from value: Any) {
            if let string = value as? String {
                allText += " " + string
            } else if let dict = value as? [String: Any] {
                for val in dict.values {
                    extract(from: val)
                }
            } else if let array = value as? [Any] {
                for val in array {
                    extract(from: val)
                }
            }
        }

        extract(from: json)
        return allText.lowercased()
    }

}
