//
//  LabsHomeView.swift
//  MediScribe
//
//  Home view for laboratory results capture and management
//

import SwiftUI

struct LabsHomeView: View {
    @State private var showingCamera = false
    @State private var capturedImage: UIImage?
    @State private var showingProcessing = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                Text("Laboratory Results")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                Text("Capture and transcribe lab reports, blood work, and diagnostic test results")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                Spacer()

                // Main action
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue)

                    Button(action: {
                        showingCamera = true
                    }) {
                        Label("Capture Lab Report", systemImage: "camera")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)

                    // History button
                    NavigationLink(destination: LabsHistoryView()) {
                        Label("View History", systemImage: "clock.arrow.circlepath")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                }

                Spacer()

                // Safety reminder
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Important")
                            .fontWeight(.semibold)
                    }

                    Text("This tool extracts and transcribes visible test values only. It does not interpret results or assess clinical significance. All values require clinician review.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }
            .padding(.vertical)
            .sheet(isPresented: $showingCamera) {
                LabsCameraView(capturedImage: $capturedImage, showingCamera: $showingCamera)
            }
            .sheet(item: $capturedImage) { image in
                LabsProcessView(image: image)
            }
        }
    }
}

// Helper to make UIImage identifiable for sheet presentation
extension UIImage: @retroactive Identifiable {
    public var id: String {
        return UUID().uuidString
    }
}

#Preview {
    LabsHomeView()
}
