//
//  Referral+CoreDataProperties.swift
//  MediScribe
//
//  Core Data properties for Referral entity
//

import Foundation
import CoreData

extension Referral {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Referral> {
        return NSFetchRequest<Referral>(entityName: "Referral")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var createdAt: Date?
    @NSManaged public var destination: String?
    @NSManaged public var sentAt: Date?
    @NSManaged public var status: String?

    // Legacy unencrypted fields (kept for migration)
    @NSManaged public var clinicalSummary: String?
    @NSManaged public var reason: String?

    // Encrypted fields
    @NSManaged public var encryptedClinicalSummary: Data?
    @NSManaged public var encryptedReason: Data?
    @NSManaged public var isEncrypted: Bool

    // Relationships
    @NSManaged public var patient: Patient?
    @NSManaged public var attachedFindings: NSSet?
}

// MARK: - AttachedFindings Accessors

extension Referral {

    @objc(addAttachedFindingsObject:)
    @NSManaged public func addToAttachedFindings(_ value: Finding)

    @objc(removeAttachedFindingsObject:)
    @NSManaged public func removeFromAttachedFindings(_ value: Finding)

    @objc(addAttachedFindings:)
    @NSManaged public func addToAttachedFindings(_ values: NSSet)

    @objc(removeAttachedFindings:)
    @NSManaged public func removeFromAttachedFindings(_ values: NSSet)
}

extension Referral: Identifiable {
}
