//
//  FHIRDiagnosticReport.swift
//  MediScribe
//
//  FHIR R4 DiagnosticReport resource — labs (EU Lab IG) and imaging reports.
//  SAFETY: AI-generated reports exported with status:preliminary.
//          Limitations statement mandatory in text.div.
//

import Foundation

struct FHIRDiagnosticReport: Codable {
    let resourceType: String = "DiagnosticReport"
    let id: String
    let meta: FHIRMeta?
    let text: FHIRNarrative?    // MANDATORY: limitations statement here
    let identifier: [FHIRIdentifier]?
    let basedOn: [FHIRReference]?
    let status: String          // registered | partial | preliminary | final | amended | corrected | appended | cancelled | entered-in-error | unknown
    let category: [FHIRCodeableConcept]?
    let code: FHIRCodeableConcept
    let subject: FHIRReference?
    let encounter: FHIRReference?
    let effectiveDateTime: String?
    let effectivePeriod: FHIRPeriod?
    let issued: String?
    let performer: [FHIRReference]?
    let resultsInterpreter: [FHIRReference]?
    let specimen: [FHIRReference]?
    let result: [FHIRReference]?        // Observation references
    let imagingStudy: [FHIRReference]?  // ImagingStudy references
    let media: [FHIRDiagnosticReportMedia]?
    let conclusion: String?
    let conclusionCode: [FHIRCodeableConcept]?
    let presentedForm: [FHIRAttachment]?

    enum CodingKeys: String, CodingKey {
        case resourceType, id, meta, text, identifier, basedOn,
             status, category, code, subject, encounter,
             effectiveDateTime, effectivePeriod, issued, performer,
             resultsInterpreter, specimen, result, imagingStudy,
             media, conclusion, conclusionCode, presentedForm
    }

    init(id: String = UUID().uuidString,
         meta: FHIRMeta? = nil,
         status: String = "preliminary",
         category: [FHIRCodeableConcept]? = nil,
         code: FHIRCodeableConcept,
         subject: FHIRReference? = nil,
         effectiveDateTime: String? = nil,
         performer: [FHIRReference]? = nil,
         result: [FHIRReference]? = nil,
         imagingStudy: [FHIRReference]? = nil,
         conclusion: String? = nil,
         text: FHIRNarrative? = nil) {
        self.id = id
        self.meta = meta
        self.text = text
        self.identifier = nil
        self.basedOn = nil
        self.status = status
        self.category = category
        self.code = code
        self.subject = subject
        self.encounter = nil
        self.effectiveDateTime = effectiveDateTime
        self.effectivePeriod = nil
        self.issued = nil
        self.performer = performer
        self.resultsInterpreter = nil
        self.specimen = nil
        self.result = result
        self.imagingStudy = imagingStudy
        self.media = nil
        self.conclusion = conclusion
        self.conclusionCode = nil
        self.presentedForm = nil
    }
}

struct FHIRDiagnosticReportMedia: Codable {
    let comment: String?
    let link: FHIRReference
}
