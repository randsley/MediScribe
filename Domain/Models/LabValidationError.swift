//
//  LabValidationError.swift
//  MediScribe
//
//  Validation errors for lab results output
//

import Foundation

enum LabValidationError: Error, Equatable {
    case invalidJSON
    case missingRequiredField(String)
    case invalidTopLevelKey(String)
    case missingLimitationsStatement
    case forbiddenPhraseDetected(String)
    case emptyTestCategories

    var localizedDescription: String {
        switch self {
        case .invalidJSON:
            return "Output does not contain valid JSON"
        case .missingRequiredField(let field):
            return "Required field '\(field)' is missing"
        case .invalidTopLevelKey(let key):
            return "Invalid top-level key '\(key)' detected"
        case .missingLimitationsStatement:
            return "Required limitations statement is missing or incorrect"
        case .forbiddenPhraseDetected(let phrase):
            return "Forbidden phrase detected: '\(phrase)'"
        case .emptyTestCategories:
            return "No test results were extracted"
        }
    }
}
