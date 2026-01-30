//
//  Language.swift
//  MediScribe
//
//  Supported languages for UI and content generation
//

import Foundation

/// Supported languages for MediScribe
enum Language: String, CaseIterable {
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case portuguese = "pt"

    /// Display name for language picker
    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .spanish:
            return "Español"
        case .french:
            return "Français"
        case .portuguese:
            return "Português"
        }
    }

    /// Locale identifier for Foundation APIs
    var localeIdentifier: String {
        switch self {
        case .english:
            return "en_US"
        case .spanish:
            return "es_ES"
        case .french:
            return "fr_FR"
        case .portuguese:
            return "pt_BR"
        }
    }

    /// Language code for API/model prompts
    var languageCode: String {
        self.rawValue
    }

    /// Forbidden phrases in this language
    var forbiddenPhrases: [String] {
        switch self {
        case .english:
            return ForbiddenPhrases.english
        case .spanish:
            return ForbiddenPhrases.spanish
        case .french:
            return ForbiddenPhrases.french
        case .portuguese:
            return ForbiddenPhrases.portuguese
        }
    }
}

/// Forbidden phrases organized by language
struct ForbiddenPhrases {
    static let english = [
        // Disease/diagnostic terms
        "diagnose", "diagnosis", "disease", "condition", "syndrome",
        "likely has", "probably has", "suspect", "suspicious for",
        "consistent with", "indicative of", "concerning for",
        "rule out", "differential diagnosis",
        // Specific diseases
        "pneumonia", "tuberculosis", "cancer", "fracture", "stroke",
        "myocardial infarction", "sepsis", "diabetes", "hypertension",
        "heart failure", "arrhythmia", "pneumothorax", "hemothorax",
        "pulmonary embolism", "deep vein thrombosis", "aortic aneurysm",
        "acute abdomen", "appendicitis", "meningitis", "encephalitis",
        // Prescriptive language
        "treat", "prescribe", "recommend", "refer", "urgent",
        "immediate", "critical", "needs intervention", "should be treated"
    ]

    static let spanish = [
        // Disease/diagnostic terms
        "diagnosticar", "diagnóstico", "enfermedad", "condición", "síndrome",
        "probablemente tiene", "sospechar", "sospechoso de",
        "consistente con", "indicativo de", "preocupante por",
        "descartar", "diagnóstico diferencial",
        // Specific diseases
        "neumonía", "tuberculosis", "cáncer", "fractura", "accidente cerebrovascular",
        "infarto de miocardio", "sepsis", "diabetes", "hipertensión",
        "insuficiencia cardíaca", "arritmia", "neumotórax", "hemotórax",
        "embolia pulmonar", "trombosis venosa profunda", "aneurisma aórtico",
        "abdomen agudo", "apendicitis", "meningitis", "encefalitis",
        // Prescriptive language
        "tratar", "prescribir", "recomendar", "referir", "urgente",
        "inmediato", "crítico", "necesita intervención", "debe ser tratado"
    ]

    static let french = [
        // Disease/diagnostic terms
        "diagnostiquer", "diagnostic", "maladie", "condition", "syndrome",
        "probablement atteint", "suspecter", "suspect de",
        "compatible avec", "indicatif de", "préoccupant pour",
        "éliminer", "diagnostic différentiel",
        // Specific diseases
        "pneumonie", "tuberculose", "cancer", "fracture", "accident vasculaire cérébral",
        "infarctus du myocarde", "septicémie", "diabète", "hypertension",
        "insuffisance cardiaque", "arythmie", "pneumothorax", "hémothorax",
        "embolie pulmonaire", "thrombose veineuse profonde", "anévrisme aortique",
        "abdomen aigu", "appendicite", "méningite", "encéphalite",
        // Prescriptive language
        "traiter", "prescrire", "recommander", "orienter", "urgent",
        "immédiat", "critique", "nécessite intervention", "doit être traité"
    ]

    static let portuguese = [
        // Disease/diagnostic terms
        "diagnosticar", "diagnóstico", "doença", "condição", "síndrome",
        "provavelmente tem", "suspeitar", "suspeito de",
        "consistente com", "indicativo de", "preocupante para",
        "descartar", "diagnóstico diferencial",
        // Specific diseases
        "pneumonia", "tuberculose", "câncer", "fratura", "acidente vascular cerebral",
        "infarto do miocárdio", "sepse", "diabetes", "hipertensão",
        "insuficiência cardíaca", "arritmia", "pneumotórax", "hemotórax",
        "embolia pulmonar", "trombose venosa profunda", "aneurisma aórtico",
        "abdômen agudo", "apendicite", "meningite", "encefalite",
        // Prescriptive language
        "tratar", "prescrever", "recomendar", "encaminhar", "urgente",
        "imediato", "crítico", "necessita intervenção", "deve ser tratado"
    ]
}
