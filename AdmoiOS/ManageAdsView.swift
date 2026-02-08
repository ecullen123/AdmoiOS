import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct ManageAdsView: View {
    let showCampaignCreatedToast: Bool
    let highlightAdId: String?

    @StateObject private var vm = ManageAdsViewModel()

    @State private var toastVisible: Bool = false
    @State private var highlightPulse: Bool = true

    init(showCampaignCreatedToast: Bool = false, highlightAdId: String? = nil) {
        self.showCampaignCreatedToast = showCampaignCreatedToast
        self.highlightAdId = highlightAdId
    }

    var body: some View {
        ZStack {
            AppBackground()

            Group {
                if vm.isLoading {
                    VStack(spacing: 12) {
                        ProgressView().tint(Theme.neon)
                        Text("Loading your ads…")
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
                } else if vm.ads.isEmpty {
                    GlowCard {
                        VStack(spacing: 10) {
                            Image(systemName: "rectangle.stack.fill")
                                .appSymbol(color: Theme.neon)
                            Text("No ads yet")
                                .foregroundStyle(Theme.textPrimary)
                                .font(.headline)
                            Text("Create an ad to start running campaigns.")
                                .foregroundStyle(Theme.textSecondary)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding()
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(vm.ads) { ad in
                                    ManageAdCard(
                                        ad: ad,
                                        isHighlighted: ad.id == highlightAdId,
                                        pulse: highlightPulse,
                                        onToggleActive: { vm.toggleActive(for: ad) },
                                        onDelete: { vm.delete(ad: ad) }
                                    )
                                    .id(ad.id ?? UUID().uuidString)
                                }
                                Spacer(minLength: 20)
                            }
                            .padding()
                        }
                        .onChange(of: vm.ads.count) { _, _ in
                            scrollToHighlightIfNeeded(proxy: proxy)
                        }
                        .onAppear {
                            scrollToHighlightIfNeeded(proxy: proxy)
                        }
                    }
                }
            }

            // ✅ Toast overlay
            if toastVisible {
                toastView
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(999)
                    .padding(.top, 10)
                    .padding(.horizontal, 16)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
        }
        .navigationTitle("Manage Ads")
        .task { vm.load() }
        .onAppear {
            if showCampaignCreatedToast {
                showToast()
            }
            if highlightAdId != nil {
                startPulseThenStop()
            }
        }
        .alert("Action failed", isPresented: $vm.showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(vm.alertMessage ?? "Something went wrong.")
        }
    }

    private func scrollToHighlightIfNeeded(proxy: ScrollViewProxy) {
        guard let id = highlightAdId else { return }
        // Wait a tick so layout exists
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                proxy.scrollTo(id, anchor: .top)
            }
        }
    }

    private func startPulseThenStop() {
        highlightPulse = true
        // after 3.5 seconds, stop pulsing but keep a subtle highlight
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.easeOut(duration: 0.35)) {
                highlightPulse = false
            }
        }
    }

    private var toastView: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .appSymbol(color: .black, size: 16, frame: 24)
                .background(Circle().fill(Theme.neon))

            VStack(alignment: .leading, spacing: 2) {
                Text("Campaign created")
                    .foregroundStyle(Theme.textPrimary)
                    .font(.subheadline.weight(.semibold))
                Text("Your ad is live and ready to be shared.")
                    .foregroundStyle(Theme.textSecondary)
                    .font(.caption)
            }

            Spacer(minLength: 10)

            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    toastVisible = false
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .appSymbol(color: Theme.textMuted, size: 16, frame: 18)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Theme.neon.opacity(0.18), lineWidth: 1)
                )
        )
        .shadow(color: Theme.neon.opacity(0.18), radius: 18, x: 0, y: 10)
    }

    private func showToast() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            toastVisible = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeOut(duration: 0.25)) {
                toastVisible = false
            }
        }
    }
}

// MARK: - ViewModel

final class ManageAdsViewModel: ObservableObject {
    @Published var ads: [AdMetadata] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    @Published var showingAlert: Bool = false
    @Published var alertMessage: String? = nil

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    func load() {
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "You are not signed in."
            return
        }

        isLoading = true
        errorMessage = nil

        db.collection("businesses")
            .document(uid)
            .collection("advertisements")
            .order(by: "createdAt", descending: true)
            .getDocuments { [weak self] snap, err in
                guard let self else { return }

                if let err {
                    DispatchQueue.main.async {
                        self.errorMessage = err.localizedDescription
                        self.isLoading = false
                    }
                    return
                }

                do {
                    let docs = snap?.documents ?? []
                    let decoded = try docs.map { try $0.data(as: AdMetadata.self) }
                    DispatchQueue.main.async {
                        self.ads = decoded
                        self.isLoading = false
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.errorMessage = error.localizedDescription
                        self.isLoading = false
                    }
                }
            }
    }

    func toggleActive(for ad: AdMetadata) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let adId = ad.id else { return }

        let newValue = !ad.isActive
        let now = Timestamp(date: Date())

        db.collection("businesses")
            .document(uid)
            .collection("advertisements")
            .document(adId)
            .updateData([
                "isActive": newValue,
                "updatedAt": now
            ]) { [weak self] err in
                if let err {
                    self?.showAlert("Failed to update: \(err.localizedDescription)")
                    return
                }

                self?.db.collection("global_advertisements")
                    .document(adId)
                    .updateData([
                        "isActive": newValue,
                        "updatedAt": now
                    ]) { _ in }

                DispatchQueue.main.async {
                    if let idx = self?.ads.firstIndex(where: { $0.id == adId }) {
                        self?.ads[idx].isActive = newValue
                        self?.ads[idx].updatedAt = now
                    }
                }
            }
    }

    func delete(ad: AdMetadata) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let adId = ad.id else { return }

        Task {
            do {
                try await db.collection("businesses")
                    .document(uid)
                    .collection("advertisements")
                    .document(adId)
                    .delete()

                try? await db.collection("global_advertisements")
                    .document(adId)
                    .delete()

                let folderRef = storage.reference(withPath: "advertisements/\(uid)/\(adId)")
                let list = try await listAll(folderRef)
                for item in list.items {
                    try await deleteObject(item)
                }

                await MainActor.run {
                    self.ads.removeAll { $0.id == adId }
                }
            } catch {
                await MainActor.run {
                    self.showAlert("Failed to delete: \(error.localizedDescription)")
                }
            }
        }
    }

    private func showAlert(_ text: String) {
        DispatchQueue.main.async {
            self.alertMessage = text
            self.showingAlert = true
        }
    }

    private func listAll(_ ref: StorageReference) async throws -> StorageListResult {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<StorageListResult, Error>) in
            ref.listAll { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: result!)
            }
        }
    }

    private func deleteObject(_ ref: StorageReference) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ref.delete { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}

// MARK: - Card UI

struct ManageAdCard: View {
    let ad: AdMetadata
    let isHighlighted: Bool
    let pulse: Bool
    let onToggleActive: () -> Void
    let onDelete: () -> Void

    var body: some View {
        GlowCard {
            VStack(alignment: .leading, spacing: 10) {

                HStack(spacing: 10) {
                    Image(systemName: ad.isActive ? "bolt.fill" : "pause.circle.fill")
                        .appSymbol(color: ad.isActive ? Theme.neon : Theme.textMuted)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(ad.title)
                            .foregroundStyle(Theme.textPrimary)
                            .font(.headline)
                            .lineLimit(1)

                        Text(ad.brandName)
                            .foregroundStyle(Theme.textSecondary)
                            .font(.caption)
                            .lineLimit(1)
                    }

                    Spacer()

                    Text(ad.isActive ? "Active" : "Paused")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ad.isActive ? Theme.neon : Theme.textMuted)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(
                            Capsule()
                                .fill(Theme.surface2)
                                .overlay(Capsule().stroke(Theme.neon.opacity(0.15), lineWidth: 1))
                        )
                }

                HStack(spacing: 10) {
                    pill(icon: "banknote.fill", text: String(format: "£%.2f / 1K", ad.rewardPer1K))
                    pill(icon: "creditcard.fill", text: String(format: "Budget £%.2f", ad.budgetGBP))
                }

                if let category = ad.category, !category.isEmpty {
                    pill(icon: "tag.fill", text: category)
                }

                HStack(spacing: 10) {
                    Button {
                        onToggleActive()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: ad.isActive ? "pause.fill" : "play.fill")
                                .appSymbol(color: Theme.neon, size: 16, frame: 22)
                            Text(ad.isActive ? "Pause" : "Activate")
                            Spacer()
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "trash.fill")
                                .appSymbol(color: Theme.textPrimary, size: 16, frame: 22)
                            Text("Delete")
                            Spacer()
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
        // ✅ Glow + badge overlays
        .overlay(alignment: .center) {
            highlightOverlay
        }
        .overlay(alignment: .topTrailing) {
            if isHighlighted {
                newBadge
                    .padding(10)
            }
        }
    }

    private var highlightOverlay: some View {
        Group {
            if isHighlighted {
                RoundedRectangle(cornerRadius: Theme.corner)
                    .stroke(Theme.neon.opacity(pulse ? 0.70 : 0.30), lineWidth: pulse ? 2 : 1)
                    .shadow(color: Theme.neon.opacity(pulse ? 0.35 : 0.18),
                            radius: pulse ? 18 : 10,
                            x: 0, y: 8)
                    .animation(
                        .easeInOut(duration: 0.7).repeatCount(pulse ? 4 : 0, autoreverses: true),
                        value: pulse
                    )
            }
        }
    }

    private var newBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .appSymbol(color: .black, size: 12, frame: 14)

            Text("NEW")
                .font(.caption2.weight(.heavy))
                .foregroundStyle(.black)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            Capsule()
                .fill(Theme.neon)
        )
        .shadow(color: Theme.neon.opacity(0.35), radius: 10, x: 0, y: 6)
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
