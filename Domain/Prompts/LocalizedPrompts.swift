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
        // Budget: prefill is (256 image + N prompt) tokens through all LM layers.
        // O(n²) attention — keep prompt under ~200 tokens (safe limit ~450 total).
        // imageContext = clinician-selected modality (pre-filled in image_type).
        // Model only needs to fill image_quality + anatomical_observations —
        // no modality guessing required.
        return """
        Examine this medical image (\(imageContext)). Output ONLY the JSON — no other text, no markdown.
        No diagnosis, disease names, or probabilities. Describe only what you actually see.
        Complete the blank fields. Do not change "image_type". Use 3–4 structures or sections relevant to THIS image as keys in "anatomical_observations", max 2 observations each. Do not use the example keys.
        {\"image_type\":\"\(imageContext)\",\"image_quality\":\"\",\"anatomical_observations\":{\"section_a\":[\"observation\"],\"section_b\":[\"observation\"]},\"comparison_with_prior\":\"No prior image available for comparison.\",\"areas_highlighted\":\"No highlighted areas provided.\",\"limitations\":\"This summary describes visible image features only and does not assess clinical significance or provide a diagnosis.\"}
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
        Examina esta imagen médica (\(imageContext)). Genera SOLO el JSON — sin texto antes o después, sin markdown.
        Sin diagnóstico, sin nombres de enfermedades, sin probabilidades. Describe solo lo que ves.
        Completa los campos vacíos. No cambies "image_type". Usa 3–4 estructuras de ESTA imagen como claves en "anatomical_observations", máximo 2 observaciones. No copies las claves del ejemplo.
        {\"image_type\":\"\(imageContext)\",\"image_quality\":\"\",\"anatomical_observations\":{\"seccion_a\":[\"observación\"],\"seccion_b\":[\"observación\"]},\"comparison_with_prior\":\"No prior image available for comparison.\",\"areas_highlighted\":\"No highlighted areas provided.\",\"limitations\":\"This summary describes visible image features only and does not assess clinical significance or provide a diagnosis.\"}
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
        Examinez cette image médicale (\(imageContext)). Générez UNIQUEMENT le JSON — aucun texte avant ou après, aucun markdown.
        Pas de diagnostic, noms de maladies ni probabilités. Décrivez uniquement ce que vous voyez.
        Complétez les champs vides. Ne modifiez pas "image_type". Utilisez 3–4 structures de CETTE image comme clés dans "anatomical_observations", max 2 observations. Ne copiez pas les clés de l'exemple.
        {\"image_type\":\"\(imageContext)\",\"image_quality\":\"\",\"anatomical_observations\":{\"section_a\":[\"observation\"],\"section_b\":[\"observation\"]},\"comparison_with_prior\":\"No prior image available for comparison.\",\"areas_highlighted\":\"No highlighted areas provided.\",\"limitations\":\"This summary describes visible image features only and does not assess clinical significance or provide a diagnosis.\"}
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
        Examine esta imagem médica (\(imageContext)). Gere APENAS o JSON — sem texto antes ou depois, sem markdown.
        Sem diagnóstico, nomes de doenças ou probabilidades. Descreva apenas o que você vê.
        Preencha os campos vazios. Não altere "image_type". Use 3–4 estruturas DESTA imagem como chaves em "anatomical_observations", máximo 2 observações. Não copie as chaves do exemplo.
        {\"image_type\":\"\(imageContext)\",\"image_quality\":\"\",\"anatomical_observations\":{\"secao_a\":[\"observação\"],\"secao_b\":[\"observação\"]},\"comparison_with_prior\":\"No prior image available for comparison.\",\"areas_highlighted\":\"No highlighted areas provided.\",\"limitations\":\"This summary describes visible image features only and does not assess clinical significance or provide a diagnosis.\"}
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
