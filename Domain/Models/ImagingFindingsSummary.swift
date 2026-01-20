//
//  ImagingFindingsSummary.swift
//  MediScribe
//
//  Domain model for imaging findings output
//

import Foundation

struct ImagingFindingsSummary: Codable {
    let imageType: String
    let imageQuality: String
    let anatomicalObservations: AnatomicalObservations
    let comparisonWithPrior: String
    let areasHighlighted: String
    let limitations: String

    enum CodingKeys: String, CodingKey {
        case imageType = "image_type"
        case imageQuality = "image_quality"
        case anatomicalObservations = "anatomical_observations"
        case comparisonWithPrior = "comparison_with_prior"
        case areasHighlighted = "areas_highlighted"
        case limitations
    }
}
