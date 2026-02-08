//
//  BrowseAdsView.swift
//  AdmoiOS
//
//  Created by Eugene Cullen on 28/01/2026.
//

import SwiftUI
import AVKit

struct BrowseAdsView: View {
    @StateObject private var vm = BrowseAdsViewModel()

    var body: some View {
        ZStack {
            AppBackground()

            Group {
                if vm.isLoading {
                    VStack(spacing: 12) {
                        ProgressView().tint(Theme.neon)
                        Text("Loading ads…")
                            .foregroundStyle(Theme.textSecondary)
                    }
                } else if let err = vm.errorMessage {
                    GlowCard {
                        VStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .appSymbol(color: Theme.neon)

                            Text("Couldn’t load ads")
                                .foregroundStyle(Theme.textPrimary)
                                .font(.headline)

                            Text(err)
                                .foregroundStyle(Theme.textSecondary)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)

                            Button("Retry") { vm.load() }
                                .buttonStyle(PrimaryButtonStyle())
                        }
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            searchBar

                            ForEach(vm.filteredVideos) { video in
                                AdVideoCard(video: video)
                            }

                            if vm.filteredVideos.isEmpty {
                                GlowCard {
                                    VStack(spacing: 10) {
                                        Image(systemName: "magnifyingglass")
                                            .appSymbol(color: Theme.neon)

                                        Text("No ads found")
                                            .foregroundStyle(Theme.textPrimary)
                                            .font(.headline)

                                        Text("Try another search.")
                                            .foregroundStyle(Theme.textSecondary)
                                            .font(.subheadline)
                                    }
                                    .padding(.vertical, 6)
                                }
                            }

                            Spacer(minLength: 20)
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("Browse Ads")
        .task { vm.load() }
    }

    private var searchBar: some View {
        GlowCard {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .appSymbol(color: Theme.textMuted, size: 16, frame: 18)

                TextField("Search business/ad/filename…", text: $vm.searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(Theme.textPrimary)

                if !vm.searchText.isEmpty {
                    Button {
                        vm.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .appSymbol(color: Theme.textMuted, size: 16, frame: 18)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - ViewModel

final class BrowseAdsViewModel: ObservableObject {
    @Published var videos: [AdVideo] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let service = AdsStorageService()

    var filteredVideos: [AdVideo] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty { return videos }

        return videos.filter { v in
            let info = v.parsedAdInfo
            return v.name.localizedCaseInsensitiveContains(q)
                || v.fullPath.localizedCaseInsensitiveContains(q)
                || info.businessId.localizedCaseInsensitiveContains(q)
                || info.adId.localizedCaseInsensitiveContains(q)
        }
    }

    func load() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let vids = try await service.fetchAllAdvertisementVideos()
                await MainActor.run {
                    self.videos = vids
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Parsed Ad Info

struct ParsedAdInfo: Hashable {
    let businessId: String
    let adId: String
    let filename: String

    var businessShort: String { String(businessId.prefix(10)) + "…" }
    var adShort: String { String(adId.prefix(10)) + "…" }

    var displayTitle: String {
        "Ad \(adShort)"
    }

    var displaySubtitle: String {
        "Business \(businessShort) • \(filename)"
    }
}

extension AdVideo {
    /// Parses: advertisements/{businessId}/{adId}/{filename}
    var parsedAdInfo: ParsedAdInfo {
        let parts = fullPath.split(separator: "/").map(String.init)
        let businessId = parts.count > 1 ? parts[1] : "UnknownBusiness"
        let adId = parts.count > 2 ? parts[2] : "UnknownAd"
        let filename = parts.last ?? name
        return ParsedAdInfo(
            businessId: businessId,
            adId: adId,
            filename: filename
        )
    }
}

// MARK: - Card

struct AdVideoCard: View {
    let video: AdVideo
    private var info: ParsedAdInfo { video.parsedAdInfo }

    @State private var player: AVPlayer? = nil
    @State private var isPlaying = false

    var body: some View {
        GlowCard {
            VStack(alignment: .leading, spacing: 12) {

                // Header
                HStack(spacing: 10) {
                    Image(systemName: "play.rectangle.fill")
                        .appSymbol(color: Theme.neon)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(info.displayTitle)
                            .foregroundStyle(Theme.textPrimary)
                            .font(.headline)
                            .lineLimit(1)

                        Text(info.displaySubtitle)
                            .foregroundStyle(Theme.textSecondary)
                            .font(.caption)
                            .lineLimit(1)
                    }

                    Spacer()

                    Button {
                        togglePlay()
                    } label: {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .appSymbol(color: .black, size: 16, frame: 28)
                            .background(Circle().fill(Theme.neon))
                    }
                    .buttonStyle(.plain)
                }

                // Video
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Theme.surface2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Theme.neon.opacity(0.15), lineWidth: 1)
                        )

                    if let player {
                        VideoPlayer(player: player)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .frame(height: 220)
                    } else {
                        VStack(spacing: 10) {
                            ProgressView().tint(Theme.neon)
                            Text("Preparing video…")
                                .foregroundStyle(Theme.textSecondary)
                                .font(.subheadline)
                        }
                        .frame(height: 220)
                    }
                }

                // Metadata
                HStack(spacing: 10) {
                    pill(icon: "building.2.fill", text: info.businessShort)
                    pill(icon: "tag.fill", text: info.adShort)
                }

                // ✅ UPDATED: Navigation to UseAdView
                NavigationLink {
                    UseAdView(ad: video)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.up.fill")
                            .appSymbol(color: .black, size: 18, frame: Theme.iconFrame)
                        Text("Use this ad")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .appSymbol(color: .black.opacity(0.55), size: 14, frame: 18)
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .onAppear {
            if player == nil {
                player = AVPlayer(url: video.downloadURL)
            }
        }
        .onDisappear {
            player?.pause()
            isPlaying = false
        }
    }

    private func togglePlay() {
        guard let player else { return }
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }

    private func pill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .appSymbol(color: Theme.neon, size: 14, frame: 18)
            Text(text)
                .foregroundStyle(Theme.textSecondary)
                .font(.caption.weight(.semibold))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.surface2)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.neon.opacity(0.14), lineWidth: 1)
                )
        )
    }
}
