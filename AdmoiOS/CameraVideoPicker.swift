//
//  CameraVideoPicker.swift
//  AdmoiOS
//
//  Created by Eugene Cullen on 01/02/2026.
//
import SwiftUI
import UIKit
import AVFoundation

struct CameraVideoPicker: UIViewControllerRepresentable {
    let onPicked: (URL) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            // No camera available (simulator etc.)
            picker.sourceType = .photoLibrary
        }

        picker.mediaTypes = ["public.movie"]
        picker.videoQuality = .typeHigh
        picker.cameraCaptureMode = .video
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraVideoPicker
        init(_ parent: CameraVideoPicker) { self.parent = parent }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            if let url = info[.mediaURL] as? URL {
                parent.onPicked(url)
            }
            picker.dismiss(animated: true)
        }
    }
}
