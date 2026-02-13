//
//  LocalizedPrompts.swift
//  MediScribe
//
//  Language-specific prompt templates
//

import Foundation

/// Provides prompts in multiple languages
struct LocalizedPrompts {
    let language: Language

    /// Build imaging findings prompt in selected language
    func buildImagingPrompt(imageContext: String) -> String {
        switch language {
        case .english:
            return englishImagingPrompt(imageContext)
        case .spanish:
            return spanishImagingPrompt(imageContext)
        case .french:
            return frenchImagingPrompt(imageContext)
        case .portuguese:
            return portugueseImagingPrompt(imageContext)
        }
    }

    /// Build lab results extraction prompt in selected language
    func buildLabPrompt() -> String {
        switch language {
        case .english:
            return englishLabPrompt()
        case .spanish:
            return spanishLabPrompt()
        case .french:
            return frenchLabPrompt()
        case .portuguese:
            return portugueseLabPrompt()
        }
    }

    // MARK: - English Prompts

    private func englishImagingPrompt(_ imageContext: String) -> String {
        // Keep this prompt short — prefill processes (image tokens + prompt tokens)
        // together through all LM layers; O(n²) attention means every extra token
        // costs quadratically in memory. Target ≤ 120 prompt tokens.
        return """
        Look at this medical image. Output ONLY the JSON below — no text before or after, no markdown.
        Neutral descriptive language only: no diagnosis, no disease names, no probabilities.
        {"image_type":"","image_quality":"","anatomical_observations":{"<key>":["<observation>"]},"comparison_with_prior":"No prior image available for comparison.","areas_highlighted":"No highlighted areas provided.","limitations":"This summary describes visible image features only and does not assess clinical significance or provide a diagnosis."}
        """
    }

    private func englishLabPrompt() -> String {
        return """
        You are a laboratory document assistant. Extract ONLY visible values from this lab report.

        CRITICAL RULES:
        - Transcribe visible test names and values exactly
        - Do NOT interpret whether values are normal or abnormal
        - Do NOT assess clinical significance
        - Do NOT recommend actions or follow-up
        - Output JSON matching this exact schema
        - Include mandatory limitations statement

        Output JSON format:
        {
          "documentType": "laboratory_report",
          "testCategories": [
            {
              "category": "...",
              "tests": [
                {"testName": "...", "value": "...", "unit": "..."}
              ]
            }
          ],
          "limitations": "This extraction shows ONLY the visible values from the laboratory report and does not interpret clinical significance or provide recommendations."
        }

        Extract the lab values in JSON format:
        """
    }

    // MARK: - Spanish Prompts

    private func spanishImagingPrompt(_ imageContext: String) -> String {
        return """
        Observa esta imagen médica. Genera SOLO el JSON siguiente — sin texto antes o después, sin markdown.
        Solo lenguaje descriptivo neutral: sin diagnóstico, sin nombres de enfermedades, sin probabilidades.
        {"image_type":"","image_quality":"","anatomical_observations":{"<clave>":["<observación>"]},"comparison_with_prior":"No prior image available for comparison.","areas_highlighted":"No highlighted areas provided.","limitations":"This summary describes visible image features only and does not assess clinical significance or provide a diagnosis."}
        """
    }

    private func spanishLabPrompt() -> String {
        return """
        Eres un asistente de documentos de laboratorio. Extrae SOLO valores visibles de este informe de laboratorio.

        REGLAS CRÍTICAS:
        - Transcribe exactamente nombres de pruebas y valores visibles
        - NO interpretes si los valores son normales o anormales
        - NO evalúes significancia clínica
        - NO recomiendes acciones o seguimiento
        - Salida en JSON según el esquema exacto
        - Incluye declaración de limitaciones obligatoria

        Formato JSON de salida:
        {
          "documentType": "laboratory_report",
          "testCategories": [
            {
              "category": "...",
              "tests": [
                {"testName": "...", "value": "...", "unit": "..."}
              ]
            }
          ],
          "limitations": "Esta extracción muestra SOLO los valores visibles del informe de laboratorio y no interpreta significancia clínica ni proporciona recomendaciones."
        }

        Extrae los valores de laboratorio en formato JSON:
        """
    }

    // MARK: - French Prompts

    private func frenchImagingPrompt(_ imageContext: String) -> String {
        return """
        Examinez cette image médicale. Générez UNIQUEMENT le JSON ci-dessous — aucun texte avant ou après, aucun markdown.
        Langage descriptif neutre uniquement : pas de diagnostic, pas de noms de maladies, pas de probabilités.
        {"image_type":"","image_quality":"","anatomical_observations":{"<clé>":["<observation>"]},"comparison_with_prior":"No prior image available for comparison.","areas_highlighted":"No highlighted areas provided.","limitations":"This summary describes visible image features only and does not assess clinical significance or provide a diagnosis."}
        """
    }

    private func frenchLabPrompt() -> String {
        return """
        Vous êtes un assistant de documents de laboratoire. Extrayez UNIQUEMENT les valeurs visibles de ce rapport de laboratoire.

        RÈGLES CRITIQUES:
        - Transcrivez exactement les noms et valeurs de tests visibles
        - NE PAS interpréter si les valeurs sont normales ou anormales
        - NE PAS évaluer la signification clinique
        - NE PAS recommander d'actions ou de suivi
        - Sortie JSON selon le schéma exact
        - Inclure la déclaration obligatoire des limitations

        Format JSON de sortie:
        {
          "documentType": "laboratory_report",
          "testCategories": [
            {
              "category": "...",
              "tests": [
                {"testName": "...", "value": "...", "unit": "..."}
              ]
            }
          ],
          "limitations": "Cette extraction montre UNIQUEMENT les valeurs visibles du rapport de laboratoire et n'interprète pas la signification clinique ni ne fournit de recommandations."
        }

        Extrayez les valeurs de laboratoire au format JSON:
        """
    }

    // MARK: - Portuguese Prompts

    private func portugueseImagingPrompt(_ imageContext: String) -> String {
        return """
        Examine esta imagem médica. Gere APENAS o JSON abaixo — sem texto antes ou depois, sem markdown.
        Linguagem descritiva neutra apenas: sem diagnóstico, sem nomes de doenças, sem probabilidades.
        {"image_type":"","image_quality":"","anatomical_observations":{"<chave>":["<observação>"]},"comparison_with_prior":"No prior image available for comparison.","areas_highlighted":"No highlighted areas provided.","limitations":"This summary describes visible image features only and does not assess clinical significance or provide a diagnosis."}
        """
    }

    private func portugueseLabPrompt() -> String {
        return """
        Você é um assistente de documentos de laboratório. Extraia APENAS valores visíveis deste relatório de laboratório.

        REGRAS CRÍTICAS:
        - Transcreva exatamente nomes e valores de testes visíveis
        - NÃO interprete se os valores são normais ou anormais
        - NÃO avalie significância clínica
        - NÃO recomende ações ou acompanhamento
        - Saída JSON seguindo o esquema exato
        - Incluir declaração obrigatória de limitações

        Formato JSON de saída:
        {
          "documentType": "laboratory_report",
          "testCategories": [
            {
              "category": "...",
              "tests": [
                {"testName": "...", "value": "...", "unit": "..."}
              ]
            }
          ],
          "limitations": "Esta extração mostra APENAS os valores visíveis do relatório de laboratório e não interpreta significância clínica nem fornece recomendações."
        }

        Extraia os valores do laboratório em formato JSON:
        """
    }
}
