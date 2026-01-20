//
//  DocumentType.swift
//  MediScribe
//
//  Types of medical documents the model can process
//

import Foundation

enum DocumentType {
    case medicalImaging  // X-rays, CT scans, MRI, ultrasound
    case labResults      // Blood work, diagnostic test results
    case prescription    // Medication prescriptions
    case discharge       // Hospital discharge summaries
    case referral        // Referral letters
    case other           // Other medical documents

    var description: String {
        switch self {
        case .medicalImaging:
            return "Medical Imaging"
        case .labResults:
            return "Laboratory Results"
        case .prescription:
            return "Prescription"
        case .discharge:
            return "Discharge Summary"
        case .referral:
            return "Referral Letter"
        case .other:
            return "Other Medical Document"
        }
    }

    /// Returns the appropriate system prompt for this document type
    var systemPromptPrefix: String {
        switch self {
        case .medicalImaging:
            return "You are a medical imaging documentation assistant. Your role is to describe visible features in this medical image for clinical documentation purposes."
        case .labResults:
            return "You are a laboratory results transcription assistant. Your role is to extract and structure visible test results from this document for clinical documentation purposes."
        case .prescription, .discharge, .referral, .other:
            return "You are a medical document transcription assistant. Your role is to extract and structure visible information from this document for clinical documentation purposes."
        }
    }
}

/// Result from processing any document type
struct DocumentProcessingResult {
    let jsonOutput: String
    let processingTime: TimeInterval
    let modelVersion: String
    let documentType: DocumentType
}
