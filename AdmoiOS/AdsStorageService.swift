//
//  AdsStorageService.swift
//  AdmoiOS
//
//  Created by Eugene Cullen on 29/01/2026.
//
import Foundation
import FirebaseStorage

final class AdsStorageService {
    private let storage = Storage.storage()

    /// Fetches all advertisement videos stored under:
    /// advertisements/{businessId}/{adId}/{filename}
    func fetchAllAdvertisementVideos() async throws -> [AdVideo] {
        let root = storage.reference(withPath: "advertisements")

        // Recursively collect every file reference under advertisements/
        let allItems = try await listAllItemsRecursively(from: root)

        // Optional: only keep common video types
        let videoItems = allItems.filter { ref in
            let name = ref.name.lowercased()
            return name.hasSuffix(".mp4") || name.hasSuffix(".mov") || name.hasSuffix(".m4v")
        }

        // Convert each reference to AdVideo (downloadURL required to play)
        var videos: [AdVideo] = []
        videos.reserveCapacity(videoItems.count)

        for item in videoItems {
            let url = try await downloadURL(for: item)

            videos.append(
                AdVideo(
                    id: item.fullPath,
                    name: item.name,
                    fullPath: item.fullPath,
                    downloadURL: url
                )
            )
        }

        // Sort by path so it’s stable
        return videos.sorted { $0.fullPath < $1.fullPath }
    }

    // MARK: - Recursive listing

    private func listAllItemsRecursively(from ref: StorageReference) async throws -> [StorageReference] {
        let result = try await listAll(ref)

        var items = result.items

        // Recurse into subfolders
        for prefix in result.prefixes {
            let nested = try await listAllItemsRecursively(from: prefix)
            items.append(contentsOf: nested)
        }

        return items
    }

    // MARK: - Async wrappers

    private func listAll(_ ref: StorageReference) async throws -> StorageListResult {
        try await withCheckedThrowingContinuation { continuation in
            ref.listAll { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: result!)
            }
        }
    }

    private func downloadURL(for ref: StorageReference) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            ref.downloadURL { url, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let url else {
                    continuation.resume(
                        throwing: NSError(
                            domain: "AdMo",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Missing download URL for \(ref.fullPath)"]
                        )
                    )
                    return
                }
                continuation.resume(returning: url)
            }
        }
    }
}
