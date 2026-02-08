import SwiftUI
import AVKit

struct EditedClipPreviewView: View {

    // Signed URL for preview (from your snipper service)
    let editedVideoURL: URL

    // Needed to combine:
    let ad: AdVideo
    let editedStoragePath: String   // e.g. "users/<uid>/edited/edited_xxx.mp4"

    // Your Firebase storage bucket
    private let bucket = "admo-dd828.firebasestorage.app"

    @StateObject private var vm = CombineWithAdViewModel()
    @State private var goToFinal = false
    @State private var finalResult: AdCompositorResult? = nil

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {

                    GlowCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.seal.fill")
                                    .appSymbol(color: Theme.neon)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Edited Clip Ready")
                                        .foregroundStyle(Theme.textPrimary)
                                        .font(.title2.bold())
                                    Text("Now you can combine it with the business ad.")
                                        .foregroundStyle(Theme.textSecondary)
                                        .font(.subheadline)
                                }
                                Spacer()
                            }
                        }
                    }

                    GlowCard {
                        VideoPlayer(player: AVPlayer(url: editedVideoURL))
                            .frame(height: 520)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.corner))
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.corner)
                                    .stroke(Theme.neon.opacity(0.15), lineWidth: 1)
                            )
                    }

                    // Combine card
                    GlowCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: "rectangle.split.2x2.fill")
                                    .appSymbol(color: Theme.neon)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Combine with Business Ad")
                                        .foregroundStyle(Theme.textPrimary)
                                        .font(.headline)
                                    Text("Creates a high-quality vertical ad (split-screen + smart switching).")
                                        .foregroundStyle(Theme.textSecondary)
                                        .font(.subheadline)
                                }
                                Spacer()
                            }

                            combineStatusView

                            Button {
                                Task { await startCombine() }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "wand.and.stars")
                                        .appSymbol(color: .black, size: 18, frame: Theme.iconFrame)
                                    Text("Combine with Business Ad")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .appSymbol(color: .black.opacity(0.55), size: 14, frame: 18)
                                }
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(isBusy)
                        }
                    }

                    Spacer(minLength: 20)
                }
                .padding()
            }
        }
        .navigationTitle("Edited Preview")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Theme.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationDestination(isPresented: $goToFinal) {
            if let result = finalResult {
                FinalCombinedPreviewView(combinedVideoURL: result.signedURL, storagePath: result.storagePath)
            } else {
                ZStack {
                    AppBackground()
                    GlowCard {
                        Text("No combined result available.")
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding()
                }
            }
        }
    }

    private var isBusy: Bool {
        if case .combining = vm.stage { return true }
        return false
    }

    private func startCombine() async {
        // Build gs:// URLs expected by your compositor service
        let adGSURL = "gs://\(bucket)/\(ad.fullPath)"
        let userEditedGSURL = "gs://\(bucket)/\(editedStoragePath)"

        // Optional: choose where final combined video is stored
        // If you want it under the user:
        let outputPath = editedStoragePath
            .replacingOccurrences(of: "/edited/", with: "/posts/")
            .replacingOccurrences(of: "edited_", with: "final_")

        await vm.combine(
            adVideoGSURL: adGSURL,
            userEditedGSURL: userEditedGSURL,
            outputStoragePath: outputPath
        )

        if case .finished(let result) = vm.stage {
            finalResult = result
            goToFinal = true
        }
    }

    @ViewBuilder
    private var combineStatusView: some View {
        switch vm.stage {
        case .idle:
            EmptyView()

        case .combining(let pct, let label):
            VStack(alignment: .leading, spacing: 8) {
                ProgressView(value: pct)
                    .tint(Theme.neon)
                Text(label)
                    .foregroundStyle(Theme.textSecondary)
                    .font(.caption)
            }

        case .finished:
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .appSymbol(color: Theme.neon)
                Text("Combined ad ready.")
                    .foregroundStyle(Theme.textSecondary)
                    .font(.caption)
                Spacer()
            }

        case .failed(let message):
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .appSymbol(color: Theme.neon)
                Text(message)
                    .foregroundStyle(Theme.textSecondary)
                    .font(.caption)
                Spacer()
            }
        }
    }
}
