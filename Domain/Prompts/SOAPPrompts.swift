//
//  SOAPPrompts.swift
//  MediScribe
//
//  Prompt templates for SOAP note generation
//

import Foundation

/// SOAP note generation prompts for MedGemma model
enum SOAPPrompts {

    /// Generate structured SOAP note from patient context
    /// - Parameters:
    ///   - patientInfo: Patient demographic and context information
    ///   - chiefComplaint: Chief complaint
    ///   - historyOfPresentIllness: History of present illness
    ///   - physicalExam: Physical examination findings
    ///   - vitals: Vital signs
    /// - Returns: Formatted prompt for model inference
    static func soapGenerationPrompt(
        patientInfo: String,
        chiefComplaint: String,
        historyOfPresentIllness: String,
        physicalExam: String,
        vitals: String
    ) -> String {
        """
        You are a clinical documentation assistant. Generate a structured SOAP note from the provided patient information.

        CRITICAL GUIDELINES:
        1. Base output ONLY on information provided
        2. Do NOT invent clinical details
        3. Do NOT provide diagnoses or diagnostic impressions
        4. Do NOT recommend treatments or interventions
        5. Subjective: Summarize patient-reported symptoms and history
        6. Objective: Summarize documented findings and vital signs
        7. Assessment: Summarize clinical problems without diagnostic interpretation
        8. Plan: Document only what was discussed/done, not recommendations
        9. Output valid JSON matching the exact schema below

        PATIENT INFORMATION:
        \(patientInfo)

        CHIEF COMPLAINT:
        \(chiefComplaint)

        HISTORY OF PRESENT ILLNESS:
        \(historyOfPresentIllness)

        PHYSICAL EXAMINATION:
        \(physicalExam)

        VITAL SIGNS:
        \(vitals)

        OUTPUT SCHEMA (strict JSON):
        {
            "subjective": {
                "chiefComplaint": "<chief complaint>",
                "historyOfPresentIllness": "<HPI summary>",
                "reviewOfSystems": "<relevant systems review>"
            },
            "objective": {
                "vitals": {
                    "temperature": "<temp in C>",
                    "heartRate": "<HR in bpm>",
                    "bloodPressure": "<BP>",
                    "respiratoryRate": "<RR>"
                },
                "physicalExamination": "<PE findings>"
            },
            "assessment": {
                "problems": [
                    {
                        "problem": "<problem statement without diagnosis>",
                        "status": "<active/resolved>"
                    }
                ]
            },
            "plan": {
                "interventions": [
                    {
                        "intervention": "<what was done or discussed>",
                        "status": "<completed/pending>"
                    }
                ]
            }
        }

        Generate a complete SOAP note. Remember: descriptive only, no diagnoses or recommendations.
        """
    }

    /// Forbidden phrases for clinical SOAP notes
    static let forbiddenPhrases = [
        // Diagnostic language
        "diagnosis", "diagnosed with", "consistent with", "indicative of",
        "suspect", "suspicious for", "cannot exclude", "cannot rule out",
        "rule out", "ruled out", "differential diagnosis",

        // Disease/condition names (representative sample)
        "pneumonia", "bronchitis", "asthma", "diabetes", "hypertension",
        "heart failure", "myocardial infarction", "stroke", "cancer",
        "tuberculosis", "pneumothorax", "fracture", "dislocation",

        // Probabilistic terms
        "likely", "probably", "possibly", "unlikely", "may have",
        "might have", "probable", "high risk for", "suspicious",

        // Treatment recommendations
        "recommend", "recommended", "recommend that", "prescribe",
        "treatment", "should be treated", "treat with",
        "antibiotic", "medication", "medication should",

        // Management directives
        "refer to", "referral", "needs referral", "requires referral",
        "urgent referral", "emergent", "urgent", "emergent intervention",
        "requires hospitalization", "admit",

        // Prescriptive language
        "must", "should", "needs to", "has to", "required",
        "follow-up required", "follow-up needed", "recheck",

        // Assessment language
        "abnormal", "normal", "significant", "critical",
        "severe", "moderate", "mild", "concerning"
    ]
}
