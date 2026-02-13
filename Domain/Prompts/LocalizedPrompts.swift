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
        // IMPORTANT: example JSON uses generic section_a/section_b keys — NOT
        // chest-X-ray-specific keys — to avoid anchoring on radiology modalities.
        // Explicitly lists non-radiology types (lab report, ECG) to counteract bias.
        return """
        Examine this medical image. Output ONLY the JSON — no other text, no markdown.
        This image may be an X-ray, ultrasound, CT, MRI, ECG, lab report, photograph, or another type — identify it from the image itself.
        No diagnosis, disease names, or probabilities.
        Fill "image_type" with the specific modality of THIS image (e.g. "PA chest radiograph", "Haemogram report", "Abdominal ultrasound", "12-lead ECG trace", "Fetal ultrasound").
        Fill "anatomical_observations" with 3–4 sections or structures visible in THIS image as keys, max 2 observations each. Do NOT copy the example keys — choose keys relevant to THIS image.
        {"image_type":"","image_quality":"","anatomical_observations":{"section_a":["observation"],"section_b":["observation"]},"comparison_with_prior":"No prior image available for comparison.","areas_highlighted":"No highlighted areas provided.","limitations":"This summary describes visible image features only and does not assess clinical significance or provide a diagnosis."}
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
        Examina esta imagen médica. Genera SOLO el JSON — sin texto antes o después, sin markdown.
        Esta imagen puede ser una radiografía, ecografía, TC, RM, ECG, análisis de laboratorio, fotografía u otro tipo — identifícalo a partir de la imagen.
        Sin diagnóstico, sin nombres de enfermedades, sin probabilidades.
        Rellena "image_type" con la modalidad específica de ESTA imagen (ej. "Radiografía PA de tórax", "Hemograma", "Ecografía abdominal", "ECG de 12 derivaciones").
        Rellena "anatomical_observations" con 3–4 secciones o estructuras visibles en ESTA imagen. No copies las claves del ejemplo.
        {"image_type":"","image_quality":"","anatomical_observations":{"seccion_a":["observación"],"seccion_b":["observación"]},"comparison_with_prior":"No prior image available for comparison.","areas_highlighted":"No highlighted areas provided.","limitations":"This summary describes visible image features only and does not assess clinical significance or provide a diagnosis."}
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
        Examinez cette image médicale. Générez UNIQUEMENT le JSON — aucun texte avant ou après, aucun markdown.
        Cette image peut être une radiographie, une échographie, un scanner, une IRM, un ECG, un bilan de laboratoire, une photo ou un autre type — identifiez-le à partir de l'image.
        Pas de diagnostic, pas de noms de maladies, pas de probabilités.
        Remplissez "image_type" avec la modalité spécifique de CETTE image (ex. "Radiographie thoracique PA", "Hémogramme", "Échographie abdominale", "ECG 12 dérivations").
        Remplissez "anatomical_observations" avec 3–4 sections ou structures visibles dans CETTE image. Ne copiez pas les clés de l'exemple.
        {"image_type":"","image_quality":"","anatomical_observations":{"section_a":["observation"],"section_b":["observation"]},"comparison_with_prior":"No prior image available for comparison.","areas_highlighted":"No highlighted areas provided.","limitations":"This summary describes visible image features only and does not assess clinical significance or provide a diagnosis."}
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
        Examine esta imagem médica. Gere APENAS o JSON — sem texto antes ou depois, sem markdown.
        Esta imagem pode ser uma radiografia, ultrassom, TC, RM, ECG, exame laboratorial, fotografia ou outro tipo — identifique-o a partir da própria imagem.
        Sem diagnóstico, sem nomes de doenças, sem probabilidades.
        Preencha "image_type" com a modalidade específica DESTA imagem (ex. "Radiografia PA de tórax", "Hemograma", "Ultrassom abdominal", "ECG de 12 derivações").
        Preencha "anatomical_observations" com 3–4 seções ou estruturas visíveis NESTA imagem. Não copie as chaves do exemplo.
        {"image_type":"","image_quality":"","anatomical_observations":{"secao_a":["observação"],"secao_b":["observação"]},"comparison_with_prior":"No prior image available for comparison.","areas_highlighted":"No highlighted areas provided.","limitations":"This summary describes visible image features only and does not assess clinical significance or provide a diagnosis."}
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
