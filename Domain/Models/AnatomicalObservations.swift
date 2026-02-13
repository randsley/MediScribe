//
//  AnatomicalObservations.swift
//  MediScribe
//
//  Flexible container for anatomical observations within imaging findings.
//  Stores any structure-name → [observation] mapping so the model can use
//  keys appropriate to the actual image modality (chest X-ray, ultrasound,
//  echocardiogram, CT, etc.) rather than being locked to four chest-X-ray fields.
//

import Foundation

struct AnatomicalObservations: Codable {
    /// Keyed observations: structure name → array of observational strings.
    /// Keys are chosen by the model to match what is visible (e.g. "lungs",
    /// "pleural_regions" for chest X-ray; "fetal_head", "amniotic_fluid" for
    /// obstetric ultrasound; "cardiac_chambers" for echocardiography).
    let structures: [String: [String]]

    init(_ structures: [String: [String]] = [:]) {
        self.structures = structures
    }

    // Decode the JSON object directly as a [String:[String]] map
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        structures = try container.decode([String: [String]].self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(structures)
    }
}
