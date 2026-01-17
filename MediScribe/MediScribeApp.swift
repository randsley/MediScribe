//
//  MediScribeApp.swift
//  MediScribe
//
//  Created by Nigel Randsley on 17/01/2026.
//

import SwiftUI
import CoreData

@main
struct MediScribeApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
