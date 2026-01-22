//
//  Note+CoreDataProperties.swift
//  MediScribe
//
//  Created by Nigel Randsley on 20/01/2026.
//
//

import Foundation
import CoreData


public typealias NoteCoreDataPropertiesSet = NSSet

extension Note {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Note> {
        return NSFetchRequest<Note>(entityName: "Note")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var createdAt: Date?
    @NSManaged public var noteData: Data?
    @NSManaged public var patientID: String?
    @NSManaged public var isLocked: Bool
    @NSManaged public var signedAt: Date?
    @NSManaged public var signedBy: String?
    @NSManaged public var addenda: NSSet?

}

extension Note : Identifiable {

}
