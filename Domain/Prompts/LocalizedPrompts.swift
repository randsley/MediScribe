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
        // Concrete JSON example prevents <key> placeholder confusion.
        // Limit to 3-4 keys / 2 observations each to stay within maxToken budget.
        return """
        Look at this medical image. Output ONLY the JSON object below — no text before or after, no markdown.
        Be specific: describe what you actually see. No diagnosis, no disease names, no probabilities.
        For "image_type" identify the actual modality of THIS image (e.g. "PA chest radiograph", "Fetal ultrasound", "Echocardiogram apical 4-chamber", "Abdominal CT axial").
        Limit "anatomical_observations" to 3–4 visible structures, max 2 observations per key. The example below shows a chest X-ray — adapt ALL keys and values to THIS specific image.
        {"image_type":"","image_quality":"","anatomical_observations":{"lungs":["bilateral fields appear clear"],"cardiomediastinal_silhouette":["outline visible"]},"comparison_with_prior":"No prior image available for comparison.","areas_highlighted":"No highlighted areas provided.","limitations":"This summary describes visible image features only and does not assess clinical significance or provide a diagnosis."}
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
        Sé específico: describe lo que realmente ves. Sin diagnóstico, sin nombres de enfermedades, sin probabilidades.
        En "image_type" indica la modalidad de ESTA imagen (ej. "Radiografía PA de tórax", "Ecografía fetal", "Ecocardiograma apical 4 cámaras").
        Limita "anatomical_observations" a 3–4 estructuras visibles, máximo 2 observaciones por clave. El ejemplo es una radiografía de tórax — adapta TODOS los campos a ESTA imagen.
        {"image_type":"","image_quality":"","anatomical_observations":{"pulmones":["campos bilaterales visibles"],"silueta_cardiaca":["contorno visible"]},"comparison_with_prior":"No prior image available for comparison.","areas_highlighted":"No highlighted areas provided.","limitations":"This summary describes visible image features only and does not assess clinical significance or provide a diagnosis."}
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
        Soyez précis : décrivez ce que vous voyez réellement. Pas de diagnostic, pas de noms de maladies, pas de probabilités.
        Dans "image_type" indiquez la modalité de CETTE image (ex. "Radiographie thoracique PA", "Échographie fœtale", "Échocardiogramme apical 4 cavités").
        Limitez "anatomical_observations" à 3–4 structures visibles, max 2 observations par clé. L'exemple montre une radio thoracique — adaptez TOUS les champs à CETTE image.
        {"image_type":"","image_quality":"","anatomical_observations":{"poumons":["champs bilatéraux visibles"],"silhouette_cardiaque":["contour visible"]},"comparison_with_prior":"No prior image available for comparison.","areas_highlighted":"No highlighted areas provided.","limitations":"This summary describes visible image features only and does not assess clinical significance or provide a diagnosis."}
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
        Seja específico: descreva o que você realmente vê. Sem diagnóstico, sem nomes de doenças, sem probabilidades.
        Em "image_type" indique a modalidade DESTA imagem (ex. "Radiografia PA de tórax", "Ultrassom fetal", "Ecocardiograma apical 4 câmaras").
        Limite "anatomical_observations" a 3–4 estruturas visíveis, máximo 2 observações por chave. O exemplo mostra uma radiografia — adapte TODOS os campos a ESTA imagem.
        {"image_type":"","image_quality":"","anatomical_observations":{"pulmões":["campos bilaterais visíveis"],"silhueta_cardíaca":["contorno visível"]},"comparison_with_prior":"No prior image available for comparison.","areas_highlighted":"No highlighted areas provided.","limitations":"This summary describes visible image features only and does not assess clinical significance or provide a diagnosis."}
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
