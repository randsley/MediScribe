//
//  LabResult.swift
//  MediScribe
//
//  Lab result data structure extracted from photographed documents
//

import Foundation

/// Represents a single lab test result
struct LabTestResult: Codable, Equatable {
    let testName: String
    let value: String
    let unit: String?
    let referenceRange: String?
    let method: String?

    enum CodingKeys: String, CodingKey {
        case testName = "test_name"
        case value
        case unit
        case referenceRange = "reference_range"
        case method
    }
}

/// Category of lab tests (e.g., CBC, metabolic panel, etc.)
struct LabTestCategory: Codable, Equatable {
    let category: String
    let tests: [LabTestResult]
}

/// Complete lab results document summary
struct LabResultsSummary: Codable, Equatable {
    let documentType: String
    let documentDate: String?
    let laboratoryName: String?
    let patientIdentifier: String?
    let orderingProvider: String?

    let testCategories: [LabTestCategory]

    let notes: String?
    let limitations: String

    enum CodingKeys: String, CodingKey {
        case documentType = "document_type"
        case documentDate = "document_date"
        case laboratoryName = "laboratory_name"
        case patientIdentifier = "patient_identifier"
        case orderingProvider = "ordering_provider"
        case testCategories = "test_categories"
        case notes
        case limitations
    }
}
