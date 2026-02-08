//
//  AdCompositorService.swift
//  AdmoiOS
//
//  Created by Eugene Cullen on 06/02/2026.
//
import Foundation

struct AdCompositorProgressEvent: Codable {
    let step: String?
    let pct: Int?
    let index: Int?
    let mode: String?
    let url: String?
    let storage_path: String?
    let message: String?
}

struct AdCompositorResult {
    let signedURL: URL
    let storagePath: String
}

final class AdCompositorService {

    // ✅ Replace with your actual Cloud Run URL
    static let endpoint = URL(string: "https://admo-video-compositor-590242609252.europe-west1.run.app")!

    enum ServiceError: LocalizedError {
        case badResponse(String)
        case missingDonePayload
        case invalidSignedURL
        case serverError(String)

        var errorDescription: String? {
            switch self {
            case .badResponse(let s): return s
            case .missingDonePayload: return "No final result returned from compositor."
            case .invalidSignedURL: return "Compositor returned an invalid signed URL."
            case .serverError(let s): return s
            }
        }
    }

    /// Calls the compositor service and streams progress JSON lines.
    func combine(
        adVideoGSURL: String,
        userEditedGSURL: String,
        outputStoragePath: String?,
        onProgress: @escaping (AdCompositorProgressEvent) -> Void
    ) async throws -> AdCompositorResult {

        var body: [String: Any] = [
            "ad_video_url": adVideoGSURL,
            "user_video_url": userEditedGSURL
        ]
        if let outputStoragePath, !outputStoragePath.isEmpty {
            body["output_storage_path"] = outputStoragePath
        }

        var req = URLRequest(url: Self.endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        // Stream response as newline-delimited JSON
        let (bytes, response) = try await URLSession.shared.bytes(for: req)

        guard let http = response as? HTTPURLResponse else {
            throw ServiceError.badResponse("No HTTPURLResponse")
        }
        guard (200..<300).contains(http.statusCode) else {
            // try to read a little body if possible
            var text = ""
            do {
                for try await line in bytes.lines {
                    text += line
                    if text.count > 1200 { break }
                }
            } catch {}
            throw ServiceError.badResponse("HTTP \(http.statusCode): \(text)")
        }

        var finalURL: URL?
        var finalStoragePath: String?

        for try await line in bytes.lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }

            guard let data = trimmed.data(using: .utf8) else { continue }
            do {
                let event = try JSONDecoder().decode(AdCompositorProgressEvent.self, from: data)

                if event.step == "error" {
                    throw ServiceError.serverError(event.message ?? "Unknown compositor error")
                }

                onProgress(event)

                if event.step == "done" {
                    if let urlStr = event.url, let url = URL(string: urlStr) {
                        finalURL = url
                    }
                    finalStoragePath = event.storage_path
                }
            } catch {
                // ignore parse errors for non-json lines, but keep going
                continue
            }
        }

        guard let signedURL = finalURL, let storagePath = finalStoragePath else {
            throw ServiceError.missingDonePayload
        }

        return AdCompositorResult(signedURL: signedURL, storagePath: storagePath)
    }
}
