//
//  LibraryVideoPicker.swift
//  AdmoiOS
//
//  Created by Eugene Cullen on 01/02/2026.
//
import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct LibraryVideoPicker: View {
    let onPicked: (URL) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selected: PhotosPickerItem? = nil
    @State private var isLoading = false
    @State private var error: String? = nil

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 14) {
                GlowCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .appSymbol(color: Theme.neon)
                            Text("Pick a video")
                                .foregroundStyle(Theme.textPrimary)
                                .font(.title2.bold())
                            Spacer()
                        }

                        Text("Select a clip from your library to use with this ad.")
                            .foregroundStyle(Theme.textSecondary)
                            .font(.subheadline)

                        PhotosPicker(selection: $selected, matching: .videos) {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .appSymbol(color: .black, size: 18, frame: Theme.iconFrame)
                                Text("Choose from library")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .appSymbol(color: .black.opacity(0.55), size: 14, frame: 18)
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(isLoading)
                    }
                }

                if isLoading {
                    GlowCard {
                        VStack(spacing: 10) {
                            ProgressView().tint(Theme.neon)
                            Text("Loading video…")
                                .foregroundStyle(Theme.textSecondary)
                                .font(.subheadline)
                        }
                    }
                }

                if let error {
                    GlowCard {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .appSymbol(color: Theme.neon)
                            Text(error)
                                .foregroundStyle(Theme.textSecondary)
                            Spacer()
                        }
                    }
                }

                Spacer()
            }
            .padding()
        }
        .onChange(of: selected) { _, newValue in
            guard let newValue else { return }
            Task { await loadVideo(from: newValue) }
        }
    }

    private func loadVideo(from item: PhotosPickerItem) async {
        error = nil
        isLoading = true

        do {
            // Load as Data (works well for your current pipeline)
            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw NSError(domain: "AdMo", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not read the video."])
            }

            // Determine a likely extension
            let ext: String
            if let type = item.supportedContentTypes.first {
                if type == .quickTimeMovie { ext = "mov" }
                else if type == .mpeg4Movie { ext = "mp4" }
                else { ext = "mp4" }
            } else {
                ext = "mp4"
            }

            // Write to temp URL so you can use AVPlayer + upload later
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("admo_userclip_\(UUID().uuidString)")
                .appendingPathExtension(ext)

            try data.write(to: tempURL, options: [.atomic])

            await MainActor.run {
                isLoading = false
                onPicked(tempURL)
                dismiss()
            }
        } catch {
            await MainActor.run {
                isLoading = false
                self.error = error.localizedDescription
            }
        }
    }
}
