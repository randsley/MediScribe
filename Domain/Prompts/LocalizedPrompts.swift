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

    /// Build SOAP note generation prompt in selected language
    func buildSOAPPrompt(from context: PatientContext) -> String {
        switch language {
        case .english:
            return englishSOAPPrompt(context)
        case .spanish:
            return spanishSOAPPrompt(context)
        case .french:
            return frenchSOAPPrompt(context)
        case .portuguese:
            return portugueseSOAPPrompt(context)
        }
    }

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

    private func englishSOAPPrompt(_ context: PatientContext) -> String {
        let vitalSigns = formatVitalSigns(context.vitalSigns)
        let medicalHistory = formatList(context.medicalHistory ?? [])
        let medications = formatList(context.currentMedications ?? [])
        let allergies = formatList(context.allergies ?? [])

        return """
        You are a clinical documentation assistant. Generate a SOAP note based on the patient information below.

        CRITICAL SAFETY GUIDELINES:
        - Focus on documented findings only
        - Use neutral, descriptive language
        - Do NOT diagnose or speculate on diagnoses
        - Do NOT recommend treatments or investigations
        - Do NOT assess urgency or severity
        - Do NOT use probabilistic language (likely, probably, concerning, etc.)
        - All output must be reviewed by clinician before use

        PATIENT INFORMATION:
        Age: \(context.age)
        Sex: \(context.sex)
        Chief Complaint: \(context.chiefComplaint)

        VITAL SIGNS:
        \(vitalSigns)

        MEDICAL HISTORY:
        \(medicalHistory.isEmpty ? "Not provided" : medicalHistory)

        CURRENT MEDICATIONS:
        \(medications.isEmpty ? "Not provided" : medications)

        ALLERGIES:
        \(allergies.isEmpty ? "NKDA" : allergies)

        INSTRUCTIONS:
        Generate a SOAP note with distinct Subjective, Objective, Assessment, and Plan sections.
        Output format must be valid JSON.

        {
          "subjective": "Patient's reported symptoms and history...",
          "objective": "Vital signs and observable findings...",
          "assessment": "Clinical impression based on findings (descriptive only, no diagnosis)...",
          "plan": "Documentation of next steps (clinician review required)...",
          "generated_at": "ISO8601 timestamp"
        }

        Generate the SOAP note in JSON format:
        """
    }

    private func englishImagingPrompt(_ imageContext: String) -> String {
        return """
        You are a medical imaging assistant. Describe ONLY what is visible in this image.

        CRITICAL RULES:
        - Describe visible anatomical structures only
        - Use neutral, observational language
        - Do NOT provide diagnoses or interpretations
        - Do NOT assess clinical significance
        - Output JSON matching this exact schema
        - Include mandatory limitations statement

        Image context: \(imageContext)

        Output JSON format:
        {
          "limitations": "This summary describes visible image features only and does not assess clinical significance or provide a diagnosis.",
          "anatomicalObservations": {
            "lungs": "...",
            "heart": "...",
            "abdomen": "..."
          }
        }

        Generate the findings in JSON format:
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

    private func spanishSOAPPrompt(_ context: PatientContext) -> String {
        let vitalSigns = formatVitalSigns(context.vitalSigns)
        let medicalHistory = formatList(context.medicalHistory ?? [])
        let medications = formatList(context.currentMedications ?? [])
        let allergies = formatList(context.allergies ?? [])

        return """
        Eres un asistente de documentación clínica. Genera una nota SOAP basada en la información del paciente a continuación.

        PAUTAS DE SEGURIDAD CRÍTICAS:
        - Enfócate solo en los hallazgos documentados
        - Usa lenguaje neutral y descriptivo
        - NO diagnostiques ni especules sobre diagnósticos
        - NO recomiendes tratamientos ni investigaciones
        - NO evalúes urgencia o gravedad
        - NO uses lenguaje probabilístico (probable, posible, preocupante, etc.)
        - Todo el contenido debe ser revisado por el clínico antes de usarlo

        INFORMACIÓN DEL PACIENTE:
        Edad: \(context.age)
        Sexo: \(context.sex)
        Motivo de Consulta: \(context.chiefComplaint)

        SIGNOS VITALES:
        \(vitalSigns)

        ANTECEDENTES MÉDICOS:
        \(medicalHistory.isEmpty ? "No proporcionado" : medicalHistory)

        MEDICAMENTOS ACTUALES:
        \(medications.isEmpty ? "No proporcionado" : medications)

        ALERGIAS:
        \(allergies.isEmpty ? "NKDA" : allergies)

        INSTRUCCIONES:
        Genera una nota SOAP con secciones distintas de Subjetivo, Objetivo, Evaluación y Plan.
        El formato de salida debe ser JSON válido.

        {
          "subjective": "Síntomas reportados e historia del paciente...",
          "objective": "Signos vitales y hallazgos observables...",
          "assessment": "Impresión clínica basada en hallazgos (solo descriptivo, sin diagnóstico)...",
          "plan": "Documentación de los próximos pasos (se requiere revisión clínica)...",
          "generated_at": "Marca de tiempo ISO8601"
        }

        Genera la nota SOAP en formato JSON:
        """
    }

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

    private func frenchSOAPPrompt(_ context: PatientContext) -> String {
        let vitalSigns = formatVitalSigns(context.vitalSigns)
        let medicalHistory = formatList(context.medicalHistory ?? [])
        let medications = formatList(context.currentMedications ?? [])
        let allergies = formatList(context.allergies ?? [])

        return """
        Vous êtes un assistant de documentation clinique. Générez une note SOAP basée sur les informations du patient ci-dessous.

        DIRECTIVES DE SÉCURITÉ CRITIQUES:
        - Concentrez-vous uniquement sur les constatations documentées
        - Utilisez un langage neutre et descriptif
        - NE PAS diagnostiquer ou spéculer sur les diagnostics
        - NE PAS recommander de traitements ou d'investigations
        - NE PAS évaluer l'urgence ou la gravité
        - NE PAS utiliser de langage probabiliste (probable, possible, préoccupant, etc.)
        - Tout le contenu doit être examiné par le clinicien avant utilisation

        INFORMATIONS DU PATIENT:
        Âge: \(context.age)
        Sexe: \(context.sex)
        Motif de Consultation: \(context.chiefComplaint)

        SIGNES VITAUX:
        \(vitalSigns)

        ANTÉCÉDENTS MÉDICAUX:
        \(medicalHistory.isEmpty ? "Non fourni" : medicalHistory)

        MÉDICAMENTS ACTUELS:
        \(medications.isEmpty ? "Non fourni" : medications)

        ALLERGIES:
        \(allergies.isEmpty ? "AUCUNE" : allergies)

        INSTRUCTIONS:
        Générez une note SOAP avec des sections distinctes Subjectif, Objectif, Évaluation et Plan.
        Le format de sortie doit être JSON valide.

        {
          "subjective": "Symptômes rapportés et antécédents du patient...",
          "objective": "Signes vitaux et constatations observables...",
          "assessment": "Impression clinique basée sur les constatations (descriptif uniquement, pas de diagnostic)...",
          "plan": "Documentation des prochaines étapes (révision clinique requise)...",
          "generated_at": "Horodatage ISO8601"
        }

        Générez la note SOAP au format JSON:
        """
    }

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

    private func portugueseSOAPPrompt(_ context: PatientContext) -> String {
        let vitalSigns = formatVitalSigns(context.vitalSigns)
        let medicalHistory = formatList(context.medicalHistory ?? [])
        let medications = formatList(context.currentMedications ?? [])
        let allergies = formatList(context.allergies ?? [])

        return """
        Você é um assistente de documentação clínica. Gere uma nota SOAP com base nas informações do paciente abaixo.

        DIRETRIZES DE SEGURANÇA CRÍTICAS:
        - Concentre-se apenas em achados documentados
        - Use linguagem neutra e descritiva
        - NÃO faça diagnósticos ou especule sobre diagnósticos
        - NÃO recomende tratamentos ou investigações
        - NÃO avalie urgência ou gravidade
        - NÃO use linguagem probabilística (provável, possível, preocupante, etc.)
        - Todo o conteúdo deve ser revisado pelo clínico antes do uso

        INFORMAÇÕES DO PACIENTE:
        Idade: \(context.age)
        Sexo: \(context.sex)
        Queixa Principal: \(context.chiefComplaint)

        SINAIS VITAIS:
        \(vitalSigns)

        ANTECEDENTES MÉDICOS:
        \(medicalHistory.isEmpty ? "Não fornecido" : medicalHistory)

        MEDICAMENTOS ATUAIS:
        \(medications.isEmpty ? "Não fornecido" : medications)

        ALERGIAS:
        \(allergies.isEmpty ? "NKDA" : allergies)

        INSTRUÇÕES:
        Gere uma nota SOAP com seções distintas de Subjetivo, Objetivo, Avaliação e Plano.
        O formato de saída deve ser JSON válido.

        {
          "subjective": "Sintomas relatados e histórico do paciente...",
          "objective": "Sinais vitais e achados observáveis...",
          "assessment": "Impressão clínica com base nos achados (apenas descritivo, sem diagnóstico)...",
          "plan": "Documentação das próximas etapas (revisão clínica obrigatória)...",
          "generated_at": "Carimbo de data/hora ISO8601"
        }

        Gere a nota SOAP em formato JSON:
        """
    }

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

    // MARK: - Helper Methods

    private func formatVitalSigns(_ vitals: VitalSigns) -> String {
        var parts: [String] = []

        if let temp = vitals.temperature {
            parts.append(language == .spanish ? "Temperatura: \(String(format: "%.1f", temp))°C" :
                         language == .french ? "Température: \(String(format: "%.1f", temp))°C" :
                         language == .portuguese ? "Temperatura: \(String(format: "%.1f", temp))°C" :
                         "Temperature: \(String(format: "%.1f", temp))°C")
        }
        if let hr = vitals.heartRate {
            let label = language == .spanish ? "Frecuencia Cardíaca:" :
                       language == .french ? "Fréquence Cardiaque:" :
                       language == .portuguese ? "Frequência Cardíaca:" :
                       "Heart Rate:"
            parts.append("\(label) \(hr) bpm")
        }

        return parts.isEmpty ? (language == .spanish ? "No registrado" :
                               language == .french ? "Non enregistré" :
                               language == .portuguese ? "Não registrado" :
                               "Not recorded") : parts.joined(separator: "\n")
    }

    private func formatList(_ items: [String]) -> String {
        items.isEmpty ? (language == .spanish ? "Ninguno reportado" :
                        language == .french ? "Aucun signalé" :
                        language == .portuguese ? "Nenhum relatado" :
                        "None reported") : items.joined(separator: "\n- ")
    }
}
