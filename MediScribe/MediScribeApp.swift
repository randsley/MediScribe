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
                .task {
                    // Initialize MedGemma multimodal vision support on app launch
                    await initializeVisionSupport()
                }
        }
    }

    // MARK: - Vision Support Initialization

    private func initializeVisionSupport() async {
        do {
            // Construct path to MedGemma multimodal model
            // Expected location: ~/MediScribe/models/medgemma-4b-mm-mlx/
            let homeDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let modelPath = (homeDir as NSString).appendingPathComponent("../MediScribe/models/medgemma-4b-mm-mlx")

            // Initialize MLXMedGemmaBridge with converted model
            try await MLXModelBridge.initializeVisionSupport(modelPath: modelPath)
            print("✅ MedGemma multimodal vision support initialized successfully")

        } catch {
            print("⚠️ Failed to initialize MedGemma multimodal vision support: \(error.localizedDescription)")
            print("   App will continue with fallback model")
            // App continues - vision features will use fallback/placeholder models
        }
    }
}
