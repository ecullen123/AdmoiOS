import SwiftUI

struct BusinessDashboardView: View {
    @EnvironmentObject private var auth: AuthManager

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(spacing: 14) {
                    header

                    GlowCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Performance")
                                .foregroundStyle(Theme.textSecondary)
                                .font(.subheadline)

                            HStack(spacing: 12) {
                                metricTile(title: "Spend", value: "£0.00", icon: "creditcard.fill")
                                metricTile(title: "Impressions", value: "0", icon: "waveform.path.ecg")
                            }

                            HStack(spacing: 12) {
                                metricTile(title: "Clicks", value: "0", icon: "cursorarrow.click.2")
                                metricTile(title: "CTR", value: "0.0%", icon: "chart.line.uptrend.xyaxis")
                            }
                        }
                    }

                    GlowCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick actions")
                                .foregroundStyle(Theme.textSecondary)
                                .font(.subheadline)

                            // ✅ Create Ad
                            NavigationLink {
                                CreateAdView()
                            } label: {
                                HStack(alignment: .center, spacing: 12) {
                                    Image(systemName: "plus.circle.fill")
                                        .appSymbol(color: .black, size: 20, frame: Theme.iconFrame)

                                    Text("Create an Ad")

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .appSymbol(color: .black.opacity(0.55), size: 14, frame: 18)
                                }
                            }
                            .buttonStyle(PrimaryButtonStyle())

                            // ✅ Manage Ads
                            NavigationLink {
                                ManageAdsView()
                            } label: {
                                HStack(alignment: .center, spacing: 12) {
                                    Image(systemName: "rectangle.stack.fill")
                                        .appSymbol(color: Theme.neon)

                                    Text("Manage Ads")

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .appSymbol(color: Theme.textMuted, size: 14, frame: 18)
                                }
                            }
                            .buttonStyle(SecondaryButtonStyle())

                            // Placeholder: Add Funds (next feature)
                            Button {
                                // TODO: route to Add Funds screen
                            } label: {
                                HStack(alignment: .center, spacing: 12) {
                                    Image(systemName: "banknote.fill")
                                        .appSymbol(color: Theme.neon)

                                    Text("Add Funds")

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .appSymbol(color: Theme.textMuted, size: 14, frame: 18)
                                }
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                    }

                    GlowCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Tips")
                                .foregroundStyle(Theme.textSecondary)
                                .font(.subheadline)

                            bullet("Post 3 short ads to start testing")
                            bullet("Use clear CTAs: “Download”, “Shop”, “Learn”")
                            bullet("Monitor CTR and cost per click weekly")
                        }
                    }

                    Button {
                        auth.signOut()
                    } label: {
                        HStack(alignment: .center, spacing: 12) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .appSymbol(color: Theme.neon)

                            Text("Sign out")

                            Spacer()
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .padding(.top, 4)

                    Spacer(minLength: 20)
                }
                .padding()
            }
        }
        .navigationTitle("Business")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Business dashboard")
                        .foregroundStyle(Theme.textSecondary)
                        .font(.subheadline)

                    Text("Launch your next campaign")
                        .font(.title2.bold())
                        .foregroundStyle(Theme.textPrimary)
                }

                Spacer()

                Circle()
                    .fill(Theme.neon.opacity(0.20))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Theme.neon)
                    )
            }
        }
    }

    private func metricTile(title: String, value: String, icon: String) -> some View {
        GlowCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center) {
                    Image(systemName: icon)
                        .appSymbol(color: Theme.neon)
                    Spacer()
                }

                Text(value)
                    .font(.title3.bold())
                    .foregroundStyle(Theme.textPrimary)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Theme.neon)
                .frame(width: 7, height: 7)
                .padding(.top, 6)

            Text(text)
                .foregroundStyle(Theme.textPrimary)
                .font(.subheadline)

            Spacer()
        }
    }
}
