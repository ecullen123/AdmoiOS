//
//  UseAdView.swift
//  AdmoiOS
//
//  Created by Eugene Cullen on 01/02/2026.
//

import SwiftUI
import AVKit

struct UseAdView: View {
    let ad: AdVideo
    @Environment(\.dismiss) private var dismiss

    @State private var showCamera = false
    @State private var showLibrary = false

    @State private var userVideoURL: URL? = nil

    // Processing
    @StateObject private var vm = UserVideoProcessingViewModel()
    @State private var goToEditedPreview = false

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {

                    GlowCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 10) {
                                Image(systemName: "play.rectangle.fill")
                                    .appSymbol(color: Theme.neon)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Use this Ad")
                                        .foregroundStyle(Theme.textPrimary)
                                        .font(.title2.bold())

                                    Text(ad.fullPath)
                                        .foregroundStyle(Theme.textSecondary)
                                        .font(.caption)
                                        .lineLimit(1)
                                }

                                Spacer()
                            }

                            Text("Choose how you want to create your content for this campaign.")
                                .foregroundStyle(Theme.textSecondary)
                                .font(.subheadline)
                        }
                    }

                    GlowCard {
                        VStack(spacing: 12) {
                            Button {
                                showCamera = true
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "camera.fill")
                                        .appSymbol(color: .black, size: 18, frame: Theme.iconFrame)
                                    Text("Film using camera now")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .appSymbol(color: .black.opacity(0.55), size: 14, frame: 18)
                                }
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(isBusy)

                            Button {
                                showLibrary = true
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .appSymbol(color: Theme.neon)
                                    Text("Upload from library")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .appSymbol(color: Theme.textMuted, size: 14, frame: 18)
                                }
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .disabled(isBusy)
                        }
                    }

                    if let userVideoURL {
                        GlowCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Selected video")
                                    .foregroundStyle(Theme.textSecondary)
                                    .font(.subheadline)

                                VideoPlayer(player: AVPlayer(url: userVideoURL))
                                    .frame(height: 260)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Theme.neon.opacity(0.15), lineWidth: 1)
                                    )

                                processingStatusView

                                Button {
                                    Task {
                                        await vm.uploadAndProcess(userVideoURL: userVideoURL)
                                        if case .finished = vm.stage {
                                            goToEditedPreview = true
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "wand.and.stars")
                                            .appSymbol(color: .black, size: 18, frame: Theme.iconFrame)
                                        Text("Continue")
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .appSymbol(color: .black.opacity(0.55), size: 14, frame: 18)
                                    }
                                }
                                .buttonStyle(PrimaryButtonStyle())
                                .disabled(!canContinue || isBusy)
                            }
                        }
                    }

                    // ✅ Nicer processing card + subtle shimmer
                    if case .processing(_) = vm.stage {
                        ProcessingShimmerCard()
                    }

                    Spacer(minLength: 22)
                }
                .padding()
            }
        }
        .navigationTitle("Create Content")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Theme.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)

        // ✅ iOS16+ navigation destination (no deprecated NavigationLink init)
        .navigationDestination(isPresented: $goToEditedPreview) {
            if let editedURL = vm.editedURLForPreview,
               let editedStoragePath = vm.editedStoragePath,
               !editedStoragePath.isEmpty {
                EditedClipPreviewView(
                    editedVideoURL: editedURL,
                    ad: ad,
                    editedStoragePath: editedStoragePath
                )
            } else if let editedURL = vm.editedURLForPreview {
                // Preview still works; combine will need storage path set.
                EditedClipPreviewView(
                    editedVideoURL: editedURL,
                    ad: ad,
                    editedStoragePath: ""
                )
            } else {
                ZStack {
                    AppBackground()
                    GlowCard {
                        Text("No edited clip available.")
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding()
                }
            }
        }

        .sheet(isPresented: $showCamera) {
            CameraVideoPicker { url in
                self.userVideoURL = url
                self.showCamera = false
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showLibrary) {
            LibraryVideoPicker { url in
                self.userVideoURL = url
                self.showLibrary = false
            }
        }

        // ✅ Disable back button during processing/uploading
        .navigationBarBackButtonHidden(isBusy)
        .toolbar {
            if isBusy {
                // Show disabled back UI (prevents accidental tap)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {}) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundStyle(Theme.textMuted)
                    }
                    .disabled(true)
                }
            }
        }
    }

    private var canContinue: Bool { userVideoURL != nil }

    private var isBusy: Bool {
        switch vm.stage {
        case .uploading: return true
        case .processing: return true
        default: return false
        }
    }

    @ViewBuilder
    private var processingStatusView: some View {
        switch vm.stage {
        case .idle:
            EmptyView()

        case .uploading(let p):
            VStack(alignment: .leading, spacing: 8) {
                ProgressView(value: p).tint(Theme.neon)
                Text("Uploading… \(Int(p * 100))%")
                    .foregroundStyle(Theme.textSecondary)
                    .font(.caption)
            }

        case .processing(let pct):
            VStack(alignment: .leading, spacing: 8) {
                ProgressView(value: Double(pct) / 100.0).tint(Theme.neon)
                Text("Processing (removing silence)… \(pct)%")
                    .foregroundStyle(Theme.textSecondary)
                    .font(.caption)
            }

        case .finished:
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .appSymbol(color: Theme.neon)
                Text("Edited clip ready.")
                    .foregroundStyle(Theme.textSecondary)
                    .font(.caption)
                Spacer()
            }

        case .failed(let msg):
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .appSymbol(color: Theme.neon)
                Text(msg)
                    .foregroundStyle(Theme.textSecondary)
                    .font(.caption)
                Spacer()
            }
        }
    }
}


// MARK: - Fancy Processing Card (subtle neon shimmer)

private struct ProcessingShimmerCard: View {
    @State private var animate = false

    var body: some View {
        GlowCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .appSymbol(color: Theme.neon)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Processing")
                            .foregroundStyle(Theme.textPrimary)
                            .font(.headline)
                        Text("Trimming silence and optimizing your clip…")
                            .foregroundStyle(Theme.textSecondary)
                            .font(.subheadline)
                    }

                    Spacer()

                    ProgressView()
                        .tint(Theme.neon)
                }

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.surface2)
                        .frame(height: 10)

                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Theme.neon.opacity(0.00),
                                    Theme.neon.opacity(0.35),
                                    Theme.neon.opacity(0.00)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 10)
                        .offset(x: animate ? 220 : -180)
                        .animation(.linear(duration: 1.2).repeatForever(autoreverses: false), value: animate)
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .onAppear { animate = true }
        .padding(.top, 2)
    }
}
