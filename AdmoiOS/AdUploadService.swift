//
//  AdUploadService.swift
//  AdmoiOS
//
//  Created by Eugene Cullen on 29/01/2026.
//
import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

enum AdUploadError: LocalizedError {
    case notSignedIn
    case missingVideoData

    var errorDescription: String? {
        switch self {
        case .notSignedIn: return "You must be signed in."
        case .missingVideoData: return "Could not read video data."
        }
    }
}

final class AdUploadService {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    /// Uploads video to Storage and creates Firestore metadata.
    /// - Returns: the created adId
    func createAdAndUploadVideo(
        videoData: Data,
        fileExtension: String,
        brandName: String,
        title: String,
        description: String?,
        category: String?,
        tags: [String],
        rewardPer1K: Double,
        budgetGBP: Double,
        mirrorToGlobal: Bool,
        onProgress: @escaping (Double) -> Void
    ) async throws -> String {

        guard let user = Auth.auth().currentUser else { throw AdUploadError.notSignedIn }

        let businessId = user.uid
        let adId = UUID().uuidString
        let storagePath = "advertisements/\(businessId)/\(adId)/\(adId).\(fileExtension)"

        // 1) Upload to Storage
        let fileRef = storage.reference(withPath: storagePath)
        let metadata = StorageMetadata()
        metadata.contentType = contentType(for: fileExtension)

        try await uploadData(
            videoData,
            to: fileRef,
            metadata: metadata,
            onProgress: onProgress
        )

        // 2) Get download URL (useful for playback)
        let downloadURL = try await fileRef.downloadURL()

        // 3) Write Firestore metadata
        let now = Timestamp(date: Date())
        let ad = AdMetadata(
            id: adId,
            businessId: businessId,
            brandName: brandName,
            title: title,
            description: description?.isEmpty == true ? nil : description,
            category: category?.isEmpty == true ? nil : category,
            tags: tags,
            rewardPer1K: rewardPer1K,
            budgetGBP: budgetGBP,
            storagePath: storagePath,
            videoDownloadURL: downloadURL.absoluteString,
            isActive: true,
            createdAt: now,
            updatedAt: now
        )

        // business scoped ads
        try db
            .collection("businesses")
            .document(businessId)
            .collection("advertisements")
            .document(adId)
            .setData(from: ad, merge: true)

        // optional global
        if mirrorToGlobal {
            try db
                .collection("global_advertisements")
                .document(adId)
                .setData(from: ad, merge: true)
        }

        return adId
    }

    // MARK: - Helpers

    private func uploadData(
        _ data: Data,
        to ref: StorageReference,
        metadata: StorageMetadata,
        onProgress: @escaping (Double) -> Void
    ) async throws {

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let task = ref.putData(data, metadata: metadata) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }

            task.observe(.progress) { snap in
                guard let p = snap.progress else { return }
                let frac = p.totalUnitCount > 0 ? Double(p.completedUnitCount) / Double(p.totalUnitCount) : 0
                onProgress(frac)
            }
        }
    }

    private func contentType(for ext: String) -> String {
        switch ext.lowercased() {
        case "mp4": return "video/mp4"
        case "mov": return "video/quicktime"
        case "m4v": return "video/x-m4v"
        default: return "application/octet-stream"
        }
    }
}
