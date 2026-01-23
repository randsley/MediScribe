//
//  NoteAddendum+CoreDataProperties.swift
//  MediScribe
//
//  Core Data properties for NoteAddendum entity
//

import Foundation
import CoreData

extension NoteAddendum {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<NoteAddendum> {
        return NSFetchRequest<NoteAddendum>(entityName: "NoteAddendum")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var createdAt: Date?
    @NSManaged public var authorName: String?
    @NSManaged public var authorID: String?
    @NSManaged public var correctionOf: String?

    // Legacy unencrypted field (kept for migration)
    @NSManaged public var addendumText: String?

    // Encrypted fields
    @NSManaged public var encryptedAddendumText: Data?
    @NSManaged public var isEncrypted: Bool

    // Relationships
    @NSManaged public var note: Note?
}

extension NoteAddendum: Identifiable {
}
