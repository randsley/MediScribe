//
//  FHIRVitalsMapper.swift
//  MediScribe
//
//  Maps VitalSignsData to FHIR Observation resources with LOINC codes and UCUM units.
//

import Foundation

struct FHIRVitalsMapper {

    // MARK: - LOINC / UCUM Constants

    private enum VitalLOINC {
        static let temperature      = "8310-5"
        static let heartRate        = "8867-4"
        static let respiratoryRate  = "9279-1"
        static let systolicBP       = "8480-6"
        static let diastolicBP      = "8462-4"
        static let bloodPressure    = "55284-4"  // Panel code for BP
        static let spO2             = "59408-5"
        static let gcsTotal         = "9269-2"
    }

    private enum VitalDisplay {
        static let temperature      = "Body temperature"
        static let heartRate        = "Heart rate"
        static let respiratoryRate  = "Respiratory rate"
        static let systolicBP       = "Systolic blood pressure"
        static let diastolicBP      = "Diastolic blood pressure"
        static let bloodPressure    = "Blood pressure panel"
        static let spO2             = "Oxygen saturation in Arterial blood by Pulse oximetry"
    }

    private enum UCUM {
        static let celsius          = "Cel"
        static let beatsPerMinute   = "/min"
        static let breathsPerMinute = "/min"
        static let mmHg             = "mm[Hg]"
        static let percent          = "%"
    }

    // MARK: - Vital Signs Category

    private static var vitalCategory: [FHIRCodeableConcept] {
        [FHIRCodeableConcept.coded(
            system: FHIRSystems.observationCategory,
            code: "vital-signs",
            display: "Vital Signs"
        )]
    }

    // MARK: - Public API

    /// Convert VitalSignsData to an array of FHIR Observations.
    static func observations(
        from vitals: VitalSignsData,
        patientRef: FHIRReference,
        effectiveDateTime: String? = nil
    ) -> [FHIRObservation] {
        var observations: [FHIRObservation] = []
        let effective = effectiveDateTime ?? vitals.recordedAt?.fhirDateTime

        if let temp = vitals.temperature {
            observations.append(makeTemperature(temp, patientRef: patientRef, effective: effective))
        }
        if let hr = vitals.heartRate {
            observations.append(makeHeartRate(hr, patientRef: patientRef, effective: effective))
        }
        if let rr = vitals.respiratoryRate {
            observations.append(makeRespiratoryRate(rr, patientRef: patientRef, effective: effective))
        }
        if let sys = vitals.systolicBP, let dia = vitals.diastolicBP {
            observations.append(makeBloodPressure(systolic: sys, diastolic: dia,
                                                  patientRef: patientRef, effective: effective))
        }
        if let o2 = vitals.oxygenSaturation {
            observations.append(makeSpO2(o2, patientRef: patientRef, effective: effective))
        }

        return observations
    }

    // MARK: - Private Builders

    private static func makeTemperature(
        _ celsius: Double,
        patientRef: FHIRReference,
        effective: String?
    ) -> FHIRObservation {
        return FHIRObservation(
            status: "final",
            category: vitalCategory,
            code: FHIRCodeableConcept.coded(
                system: FHIRSystems.loinc,
                code: VitalLOINC.temperature,
                display: VitalDisplay.temperature
            ),
            subject: patientRef,
            effectiveDateTime: effective,
            valueQuantity: FHIRQuantity.ucum(
                value: celsius,
                unit: "°C",
                ucumCode: UCUM.celsius
            )
        )
    }

    private static func makeHeartRate(
        _ bpm: Double,
        patientRef: FHIRReference,
        effective: String?
    ) -> FHIRObservation {
        FHIRObservation(
            status: "final",
            category: vitalCategory,
            code: FHIRCodeableConcept.coded(
                system: FHIRSystems.loinc,
                code: VitalLOINC.heartRate,
                display: VitalDisplay.heartRate
            ),
            subject: patientRef,
            effectiveDateTime: effective,
            valueQuantity: FHIRQuantity.ucum(
                value: bpm,
                unit: "beats/min",
                ucumCode: UCUM.beatsPerMinute
            )
        )
    }

    private static func makeRespiratoryRate(
        _ brpm: Double,
        patientRef: FHIRReference,
        effective: String?
    ) -> FHIRObservation {
        FHIRObservation(
            status: "final",
            category: vitalCategory,
            code: FHIRCodeableConcept.coded(
                system: FHIRSystems.loinc,
                code: VitalLOINC.respiratoryRate,
                display: VitalDisplay.respiratoryRate
            ),
            subject: patientRef,
            effectiveDateTime: effective,
            valueQuantity: FHIRQuantity.ucum(
                value: brpm,
                unit: "breaths/min",
                ucumCode: UCUM.breathsPerMinute
            )
        )
    }

    private static func makeBloodPressure(
        systolic: Int,
        diastolic: Int,
        patientRef: FHIRReference,
        effective: String?
    ) -> FHIRObservation {
        let systolicComponent = FHIRObservationComponent(
            code: FHIRCodeableConcept.coded(
                system: FHIRSystems.loinc,
                code: VitalLOINC.systolicBP,
                display: VitalDisplay.systolicBP
            ),
            valueQuantity: FHIRQuantity.ucum(
                value: Double(systolic),
                unit: "mmHg",
                ucumCode: UCUM.mmHg
            )
        )
        let diastolicComponent = FHIRObservationComponent(
            code: FHIRCodeableConcept.coded(
                system: FHIRSystems.loinc,
                code: VitalLOINC.diastolicBP,
                display: VitalDisplay.diastolicBP
            ),
            valueQuantity: FHIRQuantity.ucum(
                value: Double(diastolic),
                unit: "mmHg",
                ucumCode: UCUM.mmHg
            )
        )
        return FHIRObservation(
            status: "final",
            category: vitalCategory,
            code: FHIRCodeableConcept.coded(
                system: FHIRSystems.loinc,
                code: VitalLOINC.bloodPressure,
                display: VitalDisplay.bloodPressure
            ),
            subject: patientRef,
            effectiveDateTime: effective,
            component: [systolicComponent, diastolicComponent]
        )
    }

    private static func makeSpO2(
        _ percent: Int,
        patientRef: FHIRReference,
        effective: String?
    ) -> FHIRObservation {
        FHIRObservation(
            status: "final",
            category: vitalCategory,
            code: FHIRCodeableConcept.coded(
                system: FHIRSystems.loinc,
                code: VitalLOINC.spO2,
                display: VitalDisplay.spO2
            ),
            subject: patientRef,
            effectiveDateTime: effective,
            valueQuantity: FHIRQuantity.ucum(
                value: Double(percent),
                unit: "%",
                ucumCode: UCUM.percent
            )
        )
    }
}
