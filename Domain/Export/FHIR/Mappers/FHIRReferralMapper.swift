//
//  FHIRReferralMapper.swift
//  MediScribe
//
//  Maps Referral (Core Data) to FHIR ServiceRequest.
//

import Foundation

struct FHIRReferralMapper {

    struct ReferralResult {
        let serviceRequest: FHIRServiceRequest
        let serviceRequestID: String
    }

    // MARK: - Public API

    static func map(
        referral: Referral,
        patientID: String,
        practitionerID: String,
        clinicalSummary: String?,
        reason: String?
    ) -> ReferralResult {
        let patientRef = FHIRReference.urn(patientID)
        let practRef   = FHIRReference.urn(practitionerID)
        let id         = UUID().uuidString

        // Map referral status to ServiceRequest status
        let srStatus = serviceRequestStatus(referral.status ?? "draft")

        // Reason code from referral reason
        let reasonCodes: [FHIRCodeableConcept]? = reason.map {
            [FHIRCodeableConcept.text($0)]
        }

        // Note from clinical summary
        var notes: [FHIRAnnotation] = []
        if let summary = clinicalSummary, !summary.isEmpty {
            notes.append(FHIRAnnotation(
                text: summary,
                time: referral.createdAt?.fhirDateTime
            ))
        }

        // Destination as performer type text
        let performerType: FHIRCodeableConcept? = referral.destination.flatMap {
            $0.isEmpty ? nil : FHIRCodeableConcept.text($0)
        }

        let serviceRequest = FHIRServiceRequest(
            id: id,
            status: srStatus,
            intent: "proposal",
            code: EHDSProfile.referralCode,
            subject: patientRef,
            authoredOn: referral.createdAt?.fhirDateTime,
            requester: practRef,
            reasonCode: reasonCodes,
            note: notes.isEmpty ? nil : notes,
            text: FHIRNarrative.fromText(
                "Referral to: \(referral.destination ?? "Unknown"). " +
                "Status: \(referral.status ?? "draft"). " +
                (reason ?? "")
            )
        )

        return ReferralResult(serviceRequest: serviceRequest, serviceRequestID: id)
    }

    // MARK: - Private

    private static func serviceRequestStatus(_ referralStatus: String) -> String {
        switch referralStatus.lowercased() {
        case "draft":    return "draft"
        case "sent":     return "active"
        case "active":   return "active"
        case "completed", "accepted": return "completed"
        case "cancelled", "rejected": return "revoked"
        default:         return "draft"
        }
    }
}
