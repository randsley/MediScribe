//
//  FindingsValidationError.swift
//  MediScribe
//
//  Error types for findings validation failures
//

import Foundation

enum FindingsValidationError: Error {
    case invalidJSON
    case extraTopLevelKeys(found: Set<String>, allowed: Set<String>)
    case extraAnatomyKeys(found: Set<String>, allowed: Set<String>)
    case limitationsMismatch
    case forbiddenPhraseFound(String)
}
