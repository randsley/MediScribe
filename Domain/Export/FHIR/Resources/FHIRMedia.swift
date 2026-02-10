//
//  FHIRMedia.swift
//  MediScribe
//
//  FHIR R4 Media resource — image attachments (base64-encoded).
//

import Foundation

struct FHIRMedia: Codable {
    let resourceType: String = "Media"
    let id: String
    let meta: FHIRMeta?
    let text: FHIRNarrative?
    let identifier: [FHIRIdentifier]?
    let basedOn: [FHIRReference]?
    let partOf: [FHIRReference]?
    let status: String              // preparation | in-progress | not-done | on-hold | stopped | completed | entered-in-error | unknown
    let type: FHIRCodeableConcept?
    let modality: FHIRCodeableConcept?
    let view: FHIRCodeableConcept?
    let subject: FHIRReference?
    let encounter: FHIRReference?
    let createdDateTime: String?
    let issued: String?
    let `operator`: FHIRReference?
    let reasonCode: [FHIRCodeableConcept]?
    let bodySite: FHIRCodeableConcept?
    let deviceName: String?
    let device: FHIRReference?
    let height: Int?
    let width: Int?
    let frames: Int?
    let duration: Double?
    let content: FHIRAttachment     // MANDATORY — the actual media
    let note: [FHIRAnnotation]?

    enum CodingKeys: String, CodingKey {
        case resourceType, id, meta, text, identifier, basedOn, partOf,
             status, type, modality, view, subject, encounter,
             createdDateTime, issued, `operator`, reasonCode, bodySite,
             deviceName, device, height, width, frames, duration,
             content, note
    }

    init(id: String = UUID().uuidString,
         meta: FHIRMeta? = nil,
         status: String = "completed",
         type: FHIRCodeableConcept? = nil,
         subject: FHIRReference? = nil,
         createdDateTime: String? = nil,
         content: FHIRAttachment,
         note: [FHIRAnnotation]? = nil,
         text: FHIRNarrative? = nil) {
        self.id = id
        self.meta = meta
        self.text = text
        self.identifier = nil
        self.basedOn = nil
        self.partOf = nil
        self.status = status
        self.type = type
        self.modality = nil
        self.view = nil
        self.subject = subject
        self.encounter = nil
        self.createdDateTime = createdDateTime
        self.issued = nil
        self.operator = nil
        self.reasonCode = nil
        self.bodySite = nil
        self.deviceName = nil
        self.device = nil
        self.height = nil
        self.width = nil
        self.frames = nil
        self.duration = nil
        self.content = content
        self.note = note
    }
}
