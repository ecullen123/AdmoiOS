//
//  CombineWithAdViewModel.swift
//  AdmoiOS
//
//  Created by Eugene Cullen on 06/02/2026.
//
import Foundation
import SwiftUI

@MainActor
final class CombineWithAdViewModel: ObservableObject {

    enum Stage: Equatable {
        case idle
        case combining(pct: Double, label: String)
        case finished(result: AdCompositorResult)
        case failed(message: String)
    }

    @Published var stage: Stage = .idle

    private let service = AdCompositorService()

    func combine(adVideoGSURL: String, userEditedGSURL: String, outputStoragePath: String?) async {
        stage = .combining(pct: 0.05, label: "Starting…")

        do {
            let result = try await service.combine(
                adVideoGSURL: adVideoGSURL,
                userEditedGSURL: userEditedGSURL,
                outputStoragePath: outputStoragePath
            ) { [weak self] event in
                guard let self else { return }
                let pct = Double(event.pct ?? 0) / 100.0

                let label: String
                switch event.step ?? "" {
                case "download": label = "Downloading videos…"
                case "probe": label = "Analyzing clips…"
                case "plan": label = "Planning edit…"
                case "render":
                    if let mode = event.mode {
                        label = "Rendering (\(mode))…"
                    } else {
                        label = "Rendering…"
                    }
                case "concat": label = "Stitching together…"
                case "upload": label = "Uploading final ad…"
                case "done": label = "Done!"
                default: label = event.step ?? "Working…"
                }

                self.stage = .combining(pct: max(0.02, min(0.99, pct)), label: label)
            }

            stage = .finished(result: result)
        } catch {
            stage = .failed(message: error.localizedDescription)
        }
    }
}
