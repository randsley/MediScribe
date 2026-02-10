//
//  FHIRBundle.swift
//  MediScribe
//
//  FHIR R4 Bundle resource (document type for IPS).
//

import Foundation

// MARK: - Bundle

struct FHIRBundle: Codable {
    let resourceType: String = "Bundle"
    let id: String
    let meta: FHIRMeta?
    let identifier: FHIRIdentifier?
    let type: String            // document | transaction | collection | ...
    let timestamp: String?      // instant
    let total: Int?
    let link: [FHIRBundleLink]?
    let entry: [FHIRBundleEntry]?

    enum CodingKeys: String, CodingKey {
        case resourceType, id, meta, identifier, type, timestamp, total, link, entry
    }

    init(id: String = UUID().uuidString,
         type: String,
         meta: FHIRMeta? = nil,
         identifier: FHIRIdentifier? = nil,
         timestamp: String? = nil,
         entry: [FHIRBundleEntry]? = nil) {
        self.id = id
        self.meta = meta
        self.identifier = identifier
        self.type = type
        self.timestamp = timestamp
        self.total = entry.map { $0.count }
        self.link = nil
        self.entry = entry
    }
}

// MARK: - Bundle.Link

struct FHIRBundleLink: Codable {
    let relation: String
    let url: String
}

// MARK: - Bundle.Entry

struct FHIRBundleEntry: Codable {
    let fullUrl: String?
    let resource: FHIRAnyResource?
    let request: FHIRBundleRequest?
    let response: FHIRBundleResponse?
    let search: FHIRBundleSearch?

    init(fullUrl: String? = nil, resource: FHIRAnyResource,
         request: FHIRBundleRequest? = nil) {
        self.fullUrl = fullUrl
        self.resource = resource
        self.request = request
        self.response = nil
        self.search = nil
    }

    static func urn(_ id: String, resource: FHIRAnyResource) -> FHIRBundleEntry {
        FHIRBundleEntry(fullUrl: "urn:uuid:\(id)", resource: resource)
    }
}

// MARK: - Bundle.Request

struct FHIRBundleRequest: Codable {
    let method: String   // GET | HEAD | POST | PUT | DELETE | PATCH
    let url: String
    let ifNoneMatch: String?
    let ifModifiedSince: String?
    let ifMatch: String?
    let ifNoneExist: String?
}

// MARK: - Bundle.Response

struct FHIRBundleResponse: Codable {
    let status: String
    let location: String?
    let etag: String?
    let lastModified: String?
}

// MARK: - Bundle.Search

struct FHIRBundleSearch: Codable {
    let mode: String? // match | include | outcome
    let score: Double?
}

// MARK: - FHIRAnyResource (type-erased wrapper for Codable dispatch)

/// Type-erased FHIR resource wrapper for Bundle.entry.resource.
/// Each resource encodes itself; decoding reconstructs based on "resourceType".
struct FHIRAnyResource: Codable {
    private let base: any Codable

    init(_ resource: any Codable) {
        self.base = resource
    }

    func encode(to encoder: Encoder) throws {
        try base.encode(to: encoder)
    }

    // Decoding is not required for export-only flow.
    init(from decoder: Decoder) throws {
        // Export-only: decode as raw JSON dict
        let container = try decoder.singleValueContainer()
        let dict = try container.decode([String: AnyCodable].self)
        self.base = dict
    }
}

// MARK: - AnyCodable (minimal, for decode fallback)

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) { self.value = value }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let s = try? container.decode(String.self) { value = s }
        else if let i = try? container.decode(Int.self) { value = i }
        else if let d = try? container.decode(Double.self) { value = d }
        else if let b = try? container.decode(Bool.self) { value = b }
        else if let arr = try? container.decode([AnyCodable].self) { value = arr.map { $0.value } }
        else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let s as String: try container.encode(s)
        case let i as Int: try container.encode(i)
        case let d as Double: try container.encode(d)
        case let b as Bool: try container.encode(b)
        case let arr as [Any]: try container.encode(arr.map { AnyCodable($0) })
        case let dict as [String: Any]: try container.encode(dict.mapValues { AnyCodable($0) })
        default: try container.encodeNil()
        }
    }
}
