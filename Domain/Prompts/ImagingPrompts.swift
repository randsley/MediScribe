//
//  ImagingPrompts.swift
//  MediScribe
//
//  Prompt templates for medical imaging findings extraction
//

import Foundation

/// Imaging-specific prompt templates for MedGemma model
enum ImagingPrompts {

    /// Generate prompt for imaging findings extraction
    /// - Parameter imageContext: Contextual information about the image
    /// - Returns: Formatted prompt for model inference
    static func findingsExtractionPrompt(imageContext: String = "") -> String {
        """
        You are a medical imaging assistant. Your task is to describe ONLY what is visible in medical images.

        CRITICAL RULES FOR THIS TASK:
        1. Describe only anatomical structures and their appearance
        2. Use neutral, observational language
        3. Do NOT provide diagnoses or disease names
        4. Do NOT interpret clinical significance
        5. Do NOT assess severity or likelihood
        6. Do NOT make comparisons to diagnostic criteria
        7. Output valid JSON matching the exact schema below

        MANDATORY LIMITATIONS STATEMENT:
        You MUST include this exact text in your output:
        "This summary describes visible image features only and does not assess clinical significance or provide a diagnosis."

        OUTPUT SCHEMA (strict JSON):
        {
            "documentType": "imaging",
            "imageType": "<type of imaging: chest_xray, abdomen_xray, etc>",
            "findings": {
                "lungs": {
                    "leftLung": "<description of visible structures only>",
                    "rightLung": "<description of visible structures only>",
                    "pleural": "<description of pleural spaces only>"
                },
                "cardiomediastinal": "<description of heart and mediastinal silhouette>",
                "bones": "<description of visible bone structures>",
                "softTissues": "<description of visible soft tissue structures>",
                "other": "<any other visible features>"
            },
            "limitations": "This summary describes visible image features only and does not assess clinical significance or provide a diagnosis."
        }

        \(imageContext.isEmpty ? "" : "\nImage context: \(imageContext)")

        Generate findings for the described image. Remember: descriptive observations only, no interpretation.
        """
    }

    /// Forbidden phrases that indicate diagnostic or interpretive language
    static let forbiddenPhrases = [
        // Disease names
        "pneumonia", "tuberculosis", "cancer", "carcinoma", "fracture", "dislocation",
        "pneumothorax", "hemothorax", "effusion", "consolidation", "infiltrate",
        "tumor", "lesion", "neoplasm", "metastasis", "fibrosis", "atelectasis",

        // Diagnostic language
        "diagnosis", "diagnostic", "consistent with", "indicative of", "suggest",
        "suspicious for", "cannot exclude", "ruled out", "rule out", "must rule out",
        "concerning for", "warranting", "compatible with",

        // Probabilistic terms
        "likely", "probably", "unlikely", "might", "may indicate", "probable",
        "suspicious", "high suspicion", "low suspicion",

        // Management/action terms
        "recommend", "recommended", "recommend follow-up", "urgent", "emergent",
        "requires", "requires follow-up", "needs", "treat", "treatment",
        "refer", "referral indicated", "should be referred",

        // Clinical assessment terms
        "abnormal", "normal", "unremarkable", "significant", "critical",
        "severe", "moderate", "mild", "acute", "chronic",

        // AI overconfidence
        "ai detected", "algorithm detected", "more accurate than",
        "better than clinician", "model detected"
    ]
}
