//
//  UserVideoProcessingViewModel.swift
//  AdmoiOS
//
//  Created by Eugene Cullen on 02/02/2026.
//
import Foundation
import FirebaseAuth
import FirebaseStorage

@MainActor
final class UserVideoProcessingViewModel: ObservableObject {

    enum Stage: Equatable {
        case idle
        case uploading(Double)     // 0..1
        case processing(Int)       // 0..100
        case finished
        case failed(String)
    }

    @Published var stage: Stage = .idle
    @Published var editedURLForPreview: URL? = nil
    @Published var editedStoragePath: String? = nil

    private let storage = Storage.storage()
    private let cloudRun = VideoEditCloudRunService()

    func uploadAndProcess(userVideoURL: URL) async {
        do {
            guard let uid = Auth.auth().currentUser?.uid else {
                stage = .failed("You are not signed in.")
                return
            }

            // 1) Upload raw clip to Storage
            let ext = userVideoURL.pathExtension.isEmpty ? "mov" : userVideoURL.pathExtension
            let rawName = "raw_\(UUID().uuidString).\(ext)"
            let rawPath = "users/\(uid)/videos/\(rawName)"
            let rawRef = storage.reference(withPath: rawPath)

            stage = .uploading(0)

            let data = try Data(contentsOf: userVideoURL)
            let meta = StorageMetadata()
            meta.contentType = (ext.lowercased() == "mov") ? "video/quicktime" : "video/mp4"

            let uploadTask = rawRef.putData(data, metadata: meta)

            uploadTask.observe(.progress) { [weak self] snapshot in
                guard let self else { return }
                let pct = Double(snapshot.progress?.fractionCompleted ?? 0)
                Task { @MainActor in self.stage = .uploading(pct) }
            }

            _ = try await awaitUploadCompletion(uploadTask)

            // 2) Call Cloud Run
            let bucket = storage.reference().bucket // e.g. admo-dd828.firebasestorage.app
            let gsURL = "gs://\(bucket)/\(rawPath)"

            // ✅ choose exactly where edited should land
            let editedPath = "users/\(uid)/edited/edited_\(UUID().uuidString).mp4"

            stage = .processing(0)

            let result = try await cloudRun.removeSilence(
                videoURL: gsURL,
                storagePath: editedPath,
                onProgress: { [weak self] pct in
                    Task { @MainActor in self?.stage = .processing(pct) }
                }
            )

            // Save output info
            editedURLForPreview = result.signedURL
            editedStoragePath = result.storagePath ?? editedPath

            // 3) Cleanup raw clip after success ✅
            try? await deleteObject(rawRef)

            stage = .finished

        } catch {
            stage = .failed(error.localizedDescription)
        }
    }

    // MARK: - Async helpers

    private func awaitUploadCompletion(_ task: StorageUploadTask) async throws -> StorageMetadata {
        try await withCheckedThrowingContinuation { continuation in
            task.observe(.success) { snapshot in
                if let meta = snapshot.metadata {
                    continuation.resume(returning: meta)
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "AdMo",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Upload finished but metadata was missing."]
                    ))
                }
            }
            task.observe(.failure) { snapshot in
                if let error = snapshot.error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "AdMo",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Upload failed with an unknown error."]
                    ))
                }
            }
        }
    }

    private func deleteObject(_ ref: StorageReference) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            ref.delete { error in
                if let error {
                    cont.resume(throwing: error)
                } else {
                    cont.resume(returning: ())
                }
            }
        }
    }
}
