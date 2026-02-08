import SwiftUI
import PhotosUI
import AVKit
import UniformTypeIdentifiers

struct CreateAdView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    enum Field {
        case brand, title, description, category, tags, reward, budget
    }

    // ✅ Navigate to Manage Ads after success + highlight new campaign
    @State private var goToManageAds: Bool = false
    @State private var createdAdId: String? = nil

    // Video
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var localVideoURL: URL? = nil
    @State private var videoFileExtension: String = "mp4"
    @State private var player: AVPlayer? = nil
    @State private var isPlaying: Bool = true
    @State private var isMuted: Bool = true
    @State private var endObserver: NSObjectProtocol? = nil
    @State private var isLoadingVideo: Bool = false

    // Form fields
    @State private var brandName: String = ""
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var category: String = ""
    @State private var tagsText: String = ""

    @State private var rewardPer1KText: String = "0.50"
    @State private var budgetText: String = "50"
    @State private var mirrorToGlobal: Bool = true

    // Upload
    @State private var isUploading: Bool = false
    @State private var progress: Double = 0
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil

    private let service = AdUploadService()

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {


                    headerCard

                    // VIDEO PREVIEW / PICKER
                    GlowCard {
                        VStack(alignment: .leading, spacing: 12) {
                            sectionTitle("Video Preview", icon: "video.fill")

                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Theme.surface2)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Theme.neon.opacity(0.14), lineWidth: 1)
                                    )

                                if isLoadingVideo {
                                    VStack(spacing: 10) {
                                        ProgressView().tint(Theme.neon)
                                        Text("Loading video…")
                                            .foregroundStyle(Theme.textSecondary)
                                            .font(.subheadline)
                                    }
                                    .frame(height: 260)
                                } else if let player {
                                    VideoPlayer(player: player)
                                        .frame(height: 260)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .overlay(previewOverlay, alignment: .topLeading)
                                        .overlay(controlsOverlay, alignment: .topTrailing)
                                        .overlay(bottomOverlay, alignment: .bottom)
                                        .onAppear { configurePlayer() }
                                } else {
                                    VStack(spacing: 12) {
                                        Image(systemName: "film")
                                            .appSymbol(color: Theme.neon, size: 22, frame: 34)
                                        Text("Select a video to preview")
                                            .foregroundStyle(Theme.textPrimary)
                                            .font(.headline)
                                        Text("Upload the ad video you want users to share.")
                                            .foregroundStyle(Theme.textSecondary)
                                            .font(.subheadline)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 10)
                                    }
                                    .frame(height: 260)
                                }
                            }

                            PhotosPicker(selection: $selectedItem, matching: .videos) {
                                HStack(spacing: 12) {
                                    Image(systemName: localVideoURL == nil ? "plus.circle.fill" : "arrow.triangle.2.circlepath.circle.fill")
                                        .appSymbol(color: .black, size: 18, frame: Theme.iconFrame)
                                    Text(localVideoURL == nil ? "Choose Video" : "Change Video")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .appSymbol(color: .black.opacity(0.55), size: 14, frame: 18)
                                }
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(isUploading)
                        }
                    }

                    // DETAILS
                    GlowCard {
                        VStack(alignment: .leading, spacing: 12) {
                            sectionTitle("Ad Details", icon: "doc.text.fill")

                            labeledField(icon: "building.2.fill", label: "Brand Name") {
                                TextField("e.g. GreenCo", text: $brandName)
                                    .focused($focusedField, equals: .brand)
                                    .textInputAutocapitalization(.words)
                                    .neonField()
                            }

                            labeledField(icon: "textformat.size.larger", label: "Title") {
                                TextField("e.g. Eco Bottle Promo", text: $title)
                                    .focused($focusedField, equals: .title)
                                    .textInputAutocapitalization(.sentences)
                                    .neonField()
                            }

                            labeledField(icon: "quote.bubble.fill", label: "Description (optional)") {
                                TextField("Short hook or CTA…", text: $description, axis: .vertical)
                                    .focused($focusedField, equals: .description)
                                    .lineLimit(3...6)
                                    .neonField()
                            }

                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Category (optional)")
                                        .foregroundStyle(Theme.textSecondary)
                                        .font(.caption.weight(.semibold))
                                    TextField("e.g. Retail", text: $category)
                                        .focused($focusedField, equals: .category)
                                        .neonField()
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Tags (comma separated)")
                                        .foregroundStyle(Theme.textSecondary)
                                        .font(.caption.weight(.semibold))
                                    TextField("eco, bottle, sale", text: $tagsText)
                                        .focused($focusedField, equals: .tags)
                                        .neonField()
                                }
                            }
                        }
                        .disabled(isUploading)
                    }

                    // REWARDS + BUDGET
                    GlowCard {
                        VStack(alignment: .leading, spacing: 12) {
                            sectionTitle("Rewards & Budget", icon: "banknote.fill")

                            HStack(spacing: 12) {
                                metricInputCard(
                                    title: "Reward / 1K views",
                                    subtitle: "£ paid per 1,000 views",
                                    icon: "sterlingsign.circle.fill",
                                    text: $rewardPer1KText,
                                    field: .reward,
                                    placeholder: "0.50"
                                )

                                metricInputCard(
                                    title: "Campaign budget",
                                    subtitle: "Total spend limit (£)",
                                    icon: "creditcard.fill",
                                    text: $budgetText,
                                    field: .budget,
                                    placeholder: "50"
                                )
                            }

                            Toggle(isOn: $mirrorToGlobal) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Show in global ads feed")
                                        .foregroundStyle(Theme.textPrimary)
                                        .font(.subheadline.weight(.semibold))
                                    Text("Makes it easier for users to discover.")
                                        .foregroundStyle(Theme.textSecondary)
                                        .font(.caption)
                                }
                            }
                            .tint(Theme.neon)
                            .disabled(isUploading)

                            Divider().overlay(Theme.neon.opacity(0.08))

                            HStack {
                                summaryPill(icon: "banknote.fill", text: "£\(safeMoney(rewardPer1KText))/1K")
                                summaryPill(icon: "creditcard.fill", text: "Budget £\(safeMoney(budgetText))")
                                Spacer()
                            }
                        }
                        .disabled(isUploading)
                    }

                    // ERRORS / SUCCESS
                    if let errorMessage {
                        GlowCard {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .appSymbol(color: Theme.neon)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Upload failed")
                                        .foregroundStyle(Theme.textPrimary)
                                        .font(.headline)
                                    Text(errorMessage)
                                        .foregroundStyle(Theme.textSecondary)
                                        .font(.subheadline)
                                }
                                Spacer()
                            }
                        }
                    }

                    if let successMessage {
                        GlowCard {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.seal.fill")
                                    .appSymbol(color: Theme.neon)
                                Text(successMessage)
                                    .foregroundStyle(Theme.textPrimary)
                                Spacer()
                            }
                        }
                    }

                    // PUBLISH
                    GlowCard {
                        VStack(spacing: 12) {
                            Button {
                                Task { await publishTapped() }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "icloud.and.arrow.up.fill")
                                        .appSymbol(color: .black, size: 18, frame: Theme.iconFrame)
                                    Text(isUploading ? "Publishing…" : "Publish Ad")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .appSymbol(color: .black.opacity(0.55), size: 14, frame: 18)
                                }
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(!canSubmit || isUploading)

                            if isUploading {
                                VStack(alignment: .leading, spacing: 8) {
                                    ProgressView(value: progress)
                                        .tint(Theme.neon)
                                    Text("\(Int(progress * 100))% uploaded")
                                        .foregroundStyle(Theme.textSecondary)
                                        .font(.caption)
                                }
                            }

                            Text("Tip: Keep videos short (10–25s) for best engagement.")
                                .foregroundStyle(Theme.textMuted)
                                .font(.caption)
                        }
                    }

                    Spacer(minLength: 22)
                }
                .padding()
            }
        }
        .navigationTitle("Create Ad")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Close") { dismiss() }
                    .foregroundStyle(Theme.neon)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
                    .foregroundStyle(Theme.neon)
            }
        }
        .onChange(of: selectedItem) { _, newValue in
            guard let newValue else { return }
            Task { await loadVideo(from: newValue) }
        }
        .onDisappear {
            cleanupObserver()
            player?.pause()
        }
        .navigationDestination(isPresented: $goToManageAds) {
            ManageAdsView(
                showCampaignCreatedToast: true,
                highlightAdId: createdAdId
            )
        }
    }

    // MARK: - Overlays

    private var previewOverlay: some View {
        Text("Preview")
            .font(.caption.weight(.semibold))
            .foregroundStyle(Theme.textPrimary)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                Capsule()
                    .fill(Theme.surface)
                    .overlay(Capsule().stroke(Theme.neon.opacity(0.18), lineWidth: 1))
            )
            .padding(10)
    }

    private var controlsOverlay: some View {
        HStack(spacing: 10) {
            Button { toggleMute() } label: {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .appSymbol(color: .black, size: 14, frame: 28)
                    .background(Circle().fill(Theme.neon))
            }
            .buttonStyle(.plain)

            Button { togglePlay() } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .appSymbol(color: .black, size: 14, frame: 28)
                    .background(Circle().fill(Theme.neon))
            }
            .buttonStyle(.plain)
        }
        .padding(10)
    }

    private var bottomOverlay: some View {
        LinearGradient(
            colors: [.clear, .black.opacity(0.65)],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 80)
        .overlay(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title.isEmpty ? "Your ad title" : title)
                    .foregroundStyle(Theme.textPrimary)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                Text(brandName.isEmpty ? "Brand name" : brandName)
                    .foregroundStyle(Theme.textSecondary)
                    .font(.caption)
                    .lineLimit(1)
            }
            .padding(12)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - UI helpers

    private var headerCard: some View {
        GlowCard {
            VStack(alignment: .leading, spacing: 6) {
                Text("Post a company ad")
                    .font(.title2.bold())
                    .foregroundStyle(Theme.textPrimary)

                Text("Upload a video, set the reward per 1,000 views, and allocate a campaign budget.")
                    .foregroundStyle(Theme.textSecondary)
                    .font(.subheadline)
            }
        }
    }

    private func sectionTitle(_ text: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .appSymbol(color: Theme.neon, size: 16, frame: 22)
            Text(text)
                .foregroundStyle(Theme.textPrimary)
                .font(.headline)
            Spacer()
        }
    }

    private func labeledField<Content: View>(icon: String, label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .appSymbol(color: Theme.neon, size: 14, frame: 18)
                Text(label)
                    .foregroundStyle(Theme.textSecondary)
                    .font(.caption.weight(.semibold))
            }
            content()
        }
    }

    private func metricInputCard(
        title: String,
        subtitle: String,
        icon: String,
        text: Binding<String>,
        field: Field,
        placeholder: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .appSymbol(color: Theme.neon, size: 16, frame: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundStyle(Theme.textPrimary)
                        .font(.subheadline.weight(.semibold))
                    Text(subtitle)
                        .foregroundStyle(Theme.textSecondary)
                        .font(.caption)
                }
                Spacer()
            }

            TextField(placeholder, text: text)
                .keyboardType(.decimalPad)
                .focused($focusedField, equals: field)
                .neonField()
        }
        .frame(maxWidth: .infinity)
    }

    private func summaryPill(icon: String, text: String) -> some View {
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

    // MARK: - Logic

    private var canSubmit: Bool {
        guard localVideoURL != nil else { return false }
        guard !brandName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard Double(rewardPer1KText.replacingOccurrences(of: ",", with: ".")) != nil else { return false }
        guard Double(budgetText.replacingOccurrences(of: ",", with: ".")) != nil else { return false }
        return true
    }

    private func parseTags() -> [String] {
        tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func safeMoney(_ str: String) -> String {
        let cleaned = str.replacingOccurrences(of: ",", with: ".")
        guard let val = Double(cleaned) else { return "0.00" }
        return String(format: "%.2f", val)
    }

    private func loadVideo(from item: PhotosPickerItem) async {
        errorMessage = nil
        successMessage = nil
        isLoadingVideo = true

        do {
            if let type = item.supportedContentTypes.first {
                if type == .quickTimeMovie { videoFileExtension = "mov" }
                else if type == .mpeg4Movie { videoFileExtension = "mp4" }
                else { videoFileExtension = "mp4" }
            } else {
                videoFileExtension = "mp4"
            }

            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw NSError(domain: "AdMo", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not read video data."])
            }

            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("admo_preview_\(UUID().uuidString)")
                .appendingPathExtension(videoFileExtension)

            try data.write(to: tempURL, options: [.atomic])

            await MainActor.run {
                self.localVideoURL = tempURL
                self.player = AVPlayer(url: tempURL)
                self.player?.isMuted = self.isMuted
                self.isPlaying = true
                self.isLoadingVideo = false
                self.configurePlayer()
            }
        } catch {
            await MainActor.run {
                self.localVideoURL = nil
                self.player = nil
                self.isLoadingVideo = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func configurePlayer() {
        cleanupObserver()
        guard let player, let item = player.currentItem else { return }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { _ in
            item.seek(to: .zero) { _ in
                if isPlaying { player.play() }
            }
        }

        player.isMuted = isMuted
        player.play()
    }

    private func cleanupObserver() {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
    }

    private func togglePlay() {
        guard let player else { return }
        if isPlaying { player.pause() } else { player.play() }
        isPlaying.toggle()
    }

    private func toggleMute() {
        isMuted.toggle()
        player?.isMuted = isMuted
    }

    private func publishTapped() async {
        errorMessage = nil
        successMessage = nil
        focusedField = nil

        guard let url = localVideoURL else {
            errorMessage = "Please select a video first."
            return
        }

        guard let reward = Double(rewardPer1KText.replacingOccurrences(of: ",", with: ".")),
              let budget = Double(budgetText.replacingOccurrences(of: ",", with: ".")) else {
            errorMessage = "Please enter valid numbers for reward and budget."
            return
        }

        isUploading = true
        progress = 0

        do {
            let videoData = try Data(contentsOf: url)

            // ✅ capture the created adId
            let newAdId = try await service.createAdAndUploadVideo(
                videoData: videoData,
                fileExtension: videoFileExtension,
                brandName: brandName.trimmingCharacters(in: .whitespacesAndNewlines),
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                category: category.trimmingCharacters(in: .whitespacesAndNewlines),
                tags: parseTags(),
                rewardPer1K: reward,
                budgetGBP: budget,
                mirrorToGlobal: mirrorToGlobal,
                onProgress: { p in
                    Task { @MainActor in self.progress = p }
                }
            )

            await MainActor.run {
                isUploading = false
                successMessage = "Ad published successfully ✅"
                createdAdId = newAdId
                goToManageAds = true
            }

        } catch {
            await MainActor.run {
                isUploading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
