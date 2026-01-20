//
//  LabsCameraView.swift
//  MediScribe
//
//  Camera interface for capturing lab reports
//

import SwiftUI
import UIKit

struct LabsCameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Binding var showingCamera: Bool

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: LabsCameraView

        init(_ parent: LabsCameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.capturedImage = image
            }
            parent.showingCamera = false
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.showingCamera = false
        }
    }
}
