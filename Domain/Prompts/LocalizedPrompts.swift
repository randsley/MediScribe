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
        return """
        You are a clinical documentation assistant. Examine this medical image carefully and output a structured JSON object describing ONLY what is actually visible.

        Output ONLY the JSON object below. No preamble, no explanation, no markdown.
        Be specific about what you observe — describe actual visible features, shapes, sizes, densities, and structures. Do NOT write generic placeholder text.
        Use neutral, observational language only. Do NOT use diagnostic language, disease names, probabilities, or clinical interpretations.
        Copy the "limitations" value exactly as written.

        For "image_type": identify the actual modality and region (e.g. "PA chest radiograph", "Fetal ultrasound", "Echocardiogram — apical 4-chamber view", "Abdominal CT axial").
        For "anatomical_observations": use structure names appropriate to what is actually visible in THIS image. For a chest X-ray use keys like "lungs", "pleural_regions", "cardiomediastinal_silhouette", "bones_and_soft_tissues". For an obstetric ultrasound use keys like "fetal_head", "fetal_body", "amniotic_fluid", "placenta". For an echocardiogram use keys like "cardiac_chambers", "valves", "pericardium". Include ONLY structures that are actually visible.

        {
          "image_type": "<actual modality and region visible in this image>",
          "image_quality": "<technical quality of this specific image>",
          "anatomical_observations": {
            "<structure_name>": ["<specific observation about this structure as it appears in this image>"],
            "<structure_name>": ["<specific observation about this structure as it appears in this image>"]
          },
          "comparison_with_prior": "No prior image available for comparison.",
          "areas_highlighted": "No highlighted areas provided.",
          "limitations": "This summary describes visible image features only and does not assess clinical significance or provide a diagnosis."
        }
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
        Eres un asistente de imágenes médicas. Describe SOLO lo que es visible en esta imagen.

        REGLAS CRÍTICAS:
        - Describe solo estructuras anatómicas visibles
        - Usa lenguaje neutral y observacional
        - NO proporciones diagnósticos ni interpretaciones
        - NO evalúes significancia clínica
        - Salida en JSON según el esquema exacto
        - Incluye declaración de limitaciones obligatoria

        Contexto de la imagen: \(imageContext)

        Formato JSON de salida:
        {
          "limitations": "Este resumen describe solo características visibles de la imagen y no evalúa significancia clínica ni proporciona diagnóstico.",
          "anatomicalObservations": {
            "lungs": "...",
            "heart": "...",
            "abdomen": "..."
          }
        }

        Genera los hallazgos en formato JSON:
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
        Vous êtes un assistant d'imagerie médicale. Décrivez UNIQUEMENT ce qui est visible dans cette image.

        RÈGLES CRITIQUES:
        - Décrivez uniquement les structures anatomiques visibles
        - Utilisez un langage neutre et observationnel
        - NE PAS fournir de diagnostics ou d'interprétations
        - NE PAS évaluer la signification clinique
        - Sortie JSON selon le schéma exact
        - Inclure la déclaration obligatoire des limitations

        Contexte de l'image: \(imageContext)

        Format JSON de sortie:
        {
          "limitations": "Ce résumé décrit uniquement les caractéristiques visibles de l'image et n'évalue pas la signification clinique ni ne fournit de diagnostic.",
          "anatomicalObservations": {
            "lungs": "...",
            "heart": "...",
            "abdomen": "..."
          }
        }

        Générez les constatations au format JSON:
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
        Você é um assistente de imagem médica. Descreva APENAS o que é visível nesta imagem.

        REGRAS CRÍTICAS:
        - Descreva apenas estruturas anatômicas visíveis
        - Use linguagem neutra e observacional
        - NÃO forneça diagnósticos ou interpretações
        - NÃO avalie significância clínica
        - Saída JSON seguindo o esquema exato
        - Incluir declaração obrigatória de limitações

        Contexto da imagem: \(imageContext)

        Formato JSON de saída:
        {
          "limitations": "Este resumo descreve apenas características visíveis da imagem e não avalia significância clínica nem fornece diagnóstico.",
          "anatomicalObservations": {
            "lungs": "...",
            "heart": "...",
            "abdomen": "..."
          }
        }

        Gere os achados em formato JSON:
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
