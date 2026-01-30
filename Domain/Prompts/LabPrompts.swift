//
//  LabPrompts.swift
//  MediScribe
//
//  Prompt templates for laboratory results extraction
//

import Foundation

/// Laboratory-specific prompt templates for MedGemma model
enum LabPrompts {

    /// Generate prompt for lab results extraction
    /// - Returns: Formatted prompt for model inference
    static func resultsExtractionPrompt() -> String {
        """
        You are a laboratory document assistant. Your task is to extract ONLY visible test values from lab reports.

        CRITICAL RULES FOR THIS TASK:
        1. Extract EXACTLY what is visible in the document
        2. Do NOT interpret whether values are normal or abnormal
        3. Do NOT assess clinical significance
        4. Do NOT recommend follow-up or actions
        5. Do NOT provide clinical interpretation
        6. Transcribe test names exactly as written
        7. Output valid JSON matching the exact schema below

        MANDATORY LIMITATIONS STATEMENT:
        You MUST include this exact text in your output:
        "This extraction shows ONLY the visible values from the laboratory report and does not interpret clinical significance or provide recommendations."

        OUTPUT SCHEMA (strict JSON):
        {
            "documentType": "lab",
            "documentDate": "<date extracted from report or null>",
            "laboratoryName": "<lab name from report or null>",
            "testCategories": [
                {
                    "category": "<category name: CBC, CMP, BMP, etc>",
                    "tests": [
                        {
                            "testName": "<exact name as written>",
                            "value": "<numeric value or text>",
                            "unit": "<unit as written or null>",
                            "referenceRange": "<reference range or null>",
                            "method": "<method if provided or null>"
                        }
                    ]
                }
            ],
            "limitations": "This extraction shows ONLY the visible values from the laboratory report and does not interpret clinical significance or provide recommendations."
        }

        Extract all visible test results. Remember: values only, no interpretation.
        """
    }

    /// Forbidden phrases that indicate interpretation or assessment
    static let forbiddenPhrases = [
        // Interpretation terms
        "abnormal", "normal", "unremarkable", "significant",
        "concerning", "critical", "severe", "moderate", "mild",
        "abnormality", "deviation", "elevated", "depressed", "low", "high",

        // Assessment terms
        "consistent with", "indicative of", "suggests", "suggest",
        "suspicious for", "cannot exclude", "cannot rule out",
        "diagnosis", "diagnostic",

        // Action/recommendation terms
        "recommend", "recommended", "recommend follow-up", "should",
        "requires", "requires follow-up", "needs", "treat", "treatment",
        "refer", "referral", "refer to", "contact physician",

        // Probabilistic terms
        "likely", "probably", "unlikely", "may indicate",
        "probable", "possible", "suspicious",

        // Comparative terms
        "improved", "worsened", "worse", "better", "changed",
        "new", "interval change",

        // Risk assessment
        "at risk", "risk of", "high risk", "low risk"
    ]
}
