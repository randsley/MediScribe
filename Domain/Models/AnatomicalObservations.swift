//
//  AnatomicalObservations.swift
//  MediScribe
//
//  Domain model for anatomical observations within imaging findings
//

import Foundation

struct AnatomicalObservations: Codable {
    let lungs: [String]
    let pleuralRegions: [String]
    let cardiomediastinalSilhouette: [String]
    let bonesAndSoftTissues: [String]

    enum CodingKeys: String, CodingKey {
        case lungs
        case pleuralRegions = "pleural_regions"
        case cardiomediastinalSilhouette = "cardiomediastinal_silhouette"
        case bonesAndSoftTissues = "bones_and_soft_tissues"
    }
}
