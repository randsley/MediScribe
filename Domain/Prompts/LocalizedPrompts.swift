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
        // Budget: prefill runs (256 image tokens + N prompt tokens) through all LM
        // layers; O(n²) attention. At 596 tokens total this crashed; safe limit is
        // ~450 tokens total. Keep this prompt under ~190 tokens.
        return """
        Look at this medical image. Output ONLY the JSON object below — no text before or after, no markdown.
        Be specific: describe actual visible features of THIS image. Do NOT use generic placeholders like "Medical Image" or "Unknown".
        Neutral language only — no diagnosis, no disease names, no probabilities.
        For "image_type" give the actual modality and view (e.g. "PA chest radiograph", "Fetal ultrasound", "Echocardiogram apical 4-chamber").
        Values in "anatomical_observations" must be arrays of strings. Keep all fields inside one JSON object.
        {"image_type":"","image_quality":"","anatomical_observations":{"<key>":["<specific finding>"]},"comparison_with_prior":"No prior image available for comparison.","areas_highlighted":"No highlighted areas provided.","limitations":"This summary describes visible image features only and does not assess clinical significance or provide a diagnosis."}
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
        Sé específico: describe características visibles reales. No uses términos genéricos como "Imagen médica" o "Desconocido".
        Solo lenguaje neutral — sin diagnóstico, sin nombres de enfermedades, sin probabilidades.
        En "image_type" indica la modalidad real (ej. "Radiografía PA de tórax", "Ecografía fetal").
        Los valores en "anatomical_observations" deben ser arrays. Todos los campos en un solo objeto JSON.
        {"image_type":"","image_quality":"","anatomical_observations":{"<clave>":["<hallazgo específico>"]},"comparison_with_prior":"No prior image available for comparison.","areas_highlighted":"No highlighted areas provided.","limitations":"This summary describes visible image features only and does not assess clinical significance or provide a diagnosis."}
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
        Soyez précis : décrivez les caractéristiques visibles réelles. N'utilisez pas de termes génériques comme "Image médicale" ou "Inconnu".
        Langage neutre uniquement — pas de diagnostic, pas de noms de maladies, pas de probabilités.
        Dans "image_type" indiquez la modalité réelle (ex. "Radiographie thoracique PA", "Échographie fœtale").
        Les valeurs dans "anatomical_observations" doivent être des tableaux. Tous les champs dans un seul objet JSON.
        {"image_type":"","image_quality":"","anatomical_observations":{"<clé>":["<observation spécifique>"]},"comparison_with_prior":"No prior image available for comparison.","areas_highlighted":"No highlighted areas provided.","limitations":"This summary describes visible image features only and does not assess clinical significance or provide a diagnosis."}
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
        Seja específico: descreva características visíveis reais. Não use termos genéricos como "Imagem médica" ou "Desconhecido".
        Linguagem neutra apenas — sem diagnóstico, sem nomes de doenças, sem probabilidades.
        Em "image_type" indique a modalidade real (ex. "Radiografia PA de tórax", "Ultrassom fetal").
        Os valores em "anatomical_observations" devem ser arrays. Todos os campos em um único objeto JSON.
        {"image_type":"","image_quality":"","anatomical_observations":{"<chave>":["<achado específico>"]},"comparison_with_prior":"No prior image available for comparison.","areas_highlighted":"No highlighted areas provided.","limitations":"This summary describes visible image features only and does not assess clinical significance or provide a diagnosis."}
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
