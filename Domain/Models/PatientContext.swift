//
//  PatientContext.swift
//  MediScribe
//
//  Patient information for SOAP note generation
//

import Foundation

/// Vital signs for SOAP note context
struct VitalSigns: Codable {
    let temperature: Double? // Celsius
    let heartRate: Int? // bpm
    let respiratoryRate: Int? // breaths/min
    let systolicBP: Int? // mmHg
    let diastolicBP: Int? // mmHg
    let oxygenSaturation: Int? // % on room air

    enum CodingKeys: String, CodingKey {
        case temperature
        case heartRate = "heart_rate"
        case respiratoryRate = "respiratory_rate"
        case systolicBP = "systolic_bp"
        case diastolicBP = "diastolic_bp"
        case oxygenSaturation = "oxygen_saturation"
    }
}

/// Patient context for SOAP note generation
struct PatientContext: Codable {
    let age: Int
    let sex: String // M, F, Other
    let chiefComplaint: String
    let vitalSigns: VitalSigns
    let medicalHistory: [String]?
    let currentMedications: [String]?
    let allergies: [String]?

    enum CodingKeys: String, CodingKey {
        case age
        case sex
        case chiefComplaint = "chief_complaint"
        case vitalSigns = "vital_signs"
        case medicalHistory = "medical_history"
        case currentMedications = "current_medications"
        case allergies
    }
}
