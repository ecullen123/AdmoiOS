//
//  VideoEditCloudRunService.swift
//  AdmoiOS
//
//  Created by Eugene Cullen on 02/02/2026.
//
import Foundation
import FirebaseAuth

struct CloudRunProgressEvent: Decodable {
    let step: String?
    let pct: Int?
    let url: String?
    let storage_path: String?
    let message: String?
}

struct CloudRunEditResult {
    let signedURL: URL
    let storagePath: String?
}

final class VideoEditCloudRunService {

    // ✅ Use trailing slash because your Flask route is "/"
    private let endpointURL = URL(string: "https://admo-video-editor-590242609252.europe-west1.run.app/")!

    /// Sends JSON { "video_url": "...", "storage_path": "..." }
    /// Reads streaming JSON lines until step == "done"
    func removeSilence(
        videoURL: String,
        storagePath: String,
        onProgress: ((Int) -> Void)? = nil
    ) async throws -> CloudRunEditResult {

        let token: String? = try? await Auth.auth().currentUser?.getIDToken()

        var req = URLRequest(url: endpointURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: Any] = [
            "video_url": videoURL,
            "storage_path": storagePath
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (bytes, response) = try await URLSession.shared.bytes(for: req)

        guard let http = response as? HTTPURLResponse else {
            throw NSError(domain: "AdMo", code: -1, userInfo: [NSLocalizedDescriptionKey: "No HTTP response from Cloud Run."])
        }

        guard (200...299).contains(http.statusCode) else {
            var text = ""
            for try await line in bytes.lines { text += line }
            throw NSError(domain: "AdMo", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Cloud Run failed (\(http.statusCode)): \(text)"])
        }

        var lastPct = 0
        for try await line in bytes.lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            guard let data = trimmed.data(using: .utf8) else { continue }
            guard let event = try? JSONDecoder().decode(CloudRunProgressEvent.self, from: data) else { continue }

            if let pct = event.pct {
                lastPct = pct
                onProgress?(pct)
            }

            if event.step == "error" {
                let msg = event.message ?? "Unknown processing error."
                throw NSError(domain: "AdMo", code: -2, userInfo: [NSLocalizedDescriptionKey: msg])
            }

            if event.step == "done",
               let urlStr = event.url,
               let url = URL(string: urlStr) {
                return CloudRunEditResult(signedURL: url, storagePath: event.storage_path)
            }
        }

        throw NSError(
            domain: "AdMo",
            code: -3,
            userInfo: [NSLocalizedDescriptionKey: "Cloud Run stream ended without a final URL. Last progress: \(lastPct)%"]
        )
    }
}
