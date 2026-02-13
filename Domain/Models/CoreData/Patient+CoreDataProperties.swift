//
//  Patient+CoreDataProperties.swift
//  MediScribe
//
//  Core Data properties for Patient entity
//

import Foundation
import CoreData

extension Patient {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Patient> {
        return NSFetchRequest<Patient>(entityName: "Patient")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var createdAt: Date?

    // Legacy plaintext fields (kept for migration; nil after encryption)
    @NSManaged public var name: String?
    @NSManaged public var dateOfBirth: Date?
    @NSManaged public var medicalRecordNumber: String?

    // Encrypted fields
    @NSManaged public var nameEncrypted: Data?
    @NSManaged public var dateOfBirthEncrypted: Data?
    @NSManaged public var medicalRecordNumberEncrypted: Data?
    @NSManaged public var isEncrypted: Bool

    // Unencrypted general notes (non-identifying)
    @NSManaged public var notes: String?

    // Relationships
    @NSManaged public var findings: NSSet?
    @NSManaged public var referrals: NSSet?
}

// MARK: - Findings Accessors

extension Patient {

    @objc(addFindingsObject:)
    @NSManaged public func addToFindings(_ value: Finding)

    @objc(removeFindingsObject:)
    @NSManaged public func removeFromFindings(_ value: Finding)

    @objc(addFindings:)
    @NSManaged public func addToFindings(_ values: NSSet)

    @objc(removeFindings:)
    @NSManaged public func removeFromFindings(_ values: NSSet)
}

// MARK: - Referrals Accessors

extension Patient {

    @objc(addReferralsObject:)
    @NSManaged public func addToReferrals(_ value: Referral)

    @objc(removeReferralsObject:)
    @NSManaged public func removeFromReferrals(_ value: Referral)

    @objc(addReferrals:)
    @NSManaged public func addToReferrals(_ values: NSSet)

    @objc(removeReferrals:)
    @NSManaged public func removeFromReferrals(_ values: NSSet)
}

extension Patient: Identifiable {
}
