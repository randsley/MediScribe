//
//  Finding+CoreDataProperties.swift
//  MediScribe
//
//  Core Data properties for Finding entity
//

import Foundation
import CoreData

extension Finding {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Finding> {
        return NSFetchRequest<Finding>(entityName: "Finding")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var createdAt: Date?
    @NSManaged public var documentType: String?
    @NSManaged public var imageType: String?
    @NSManaged public var reviewedAt: Date?
    @NSManaged public var reviewedBy: String?

    // Legacy unencrypted fields (kept for migration)
    @NSManaged public var findingsJSON: String?
    @NSManaged public var imageData: Data?

    // Encrypted fields
    @NSManaged public var encryptedFindingsData: Data?
    @NSManaged public var encryptedImageData: Data?
    @NSManaged public var isEncrypted: Bool

    // Relationships
    @NSManaged public var patient: Patient?
    @NSManaged public var referrals: NSSet?
}

// MARK: - Referrals Accessors

extension Finding {

    @objc(addReferralsObject:)
    @NSManaged public func addToReferrals(_ value: Referral)

    @objc(removeReferralsObject:)
    @NSManaged public func removeFromReferrals(_ value: Referral)

    @objc(addReferrals:)
    @NSManaged public func addToReferrals(_ values: NSSet)

    @objc(removeReferrals:)
    @NSManaged public func removeFromReferrals(_ values: NSSet)
}

extension Finding: Identifiable {
}
