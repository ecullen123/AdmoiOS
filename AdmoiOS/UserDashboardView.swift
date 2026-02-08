//
//  UserDashboardView.swift
//  AdmoiOS
//
//  Created by Eugene Cullen on 28/01/2026.
//
import SwiftUI

struct UserDashboardView: View {
    @EnvironmentObject private var auth: AuthManager

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(spacing: 14) {

                    header

                    GlowCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Today")
                                .foregroundStyle(Theme.textSecondary)
                                .font(.subheadline)

                            HStack(spacing: 12) {
                                statTile(title: "Earnings", value: "£0.00", icon: "sterlingsign.circle.fill")
                                statTile(title: "Views", value: "0", icon: "eye.fill")
                            }

                            HStack(spacing: 12) {
                                statTile(title: "Shares", value: "0", icon: "square.and.arrow.up.fill")
                                statTile(title: "Level", value: "1", icon: "bolt.fill")
                            }
                        }
                    }

                    // ✅ Quick actions with navigation
                    GlowCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick actions")
                                .foregroundStyle(Theme.textSecondary)
                                .font(.subheadline)

                            NavigationLink {
                                BrowseAdsView()
                            } label: {
                                HStack(alignment: .center, spacing: 12) {
                                    Image(systemName: "play.rectangle.fill")
                                        .appSymbol(color: Theme.neon)

                                    Text("Browse Ads")
                                        .foregroundStyle(Theme.textPrimary)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .appSymbol(color: Theme.textMuted, size: 14, frame: 18)
                                }
                            }
                            .buttonStyle(SecondaryButtonStyle())

                            NavigationLink {
                                WalletView()
                            } label: {
                                HStack(alignment: .center, spacing: 12) {
                                    Image(systemName: "wallet.pass.fill")
                                        .appSymbol(color: Theme.neon)

                                    Text("Wallet")
                                        .foregroundStyle(Theme.textPrimary)

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
                            Text("Getting started")
                                .foregroundStyle(Theme.textSecondary)
                                .font(.subheadline)

                            bullet("Connect your social account (later)")
                            bullet("Share ads to earn")
                            bullet("Track earnings in your wallet")
                        }
                    }

                    Button {
                        auth.signOut()
                    } label: {
                        HStack(alignment: .center, spacing: 12) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .appSymbol(color: Theme.neon)

                            Text("Sign out")
                                .foregroundStyle(Theme.textPrimary)

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
        .navigationTitle("User")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back")
                        .foregroundStyle(Theme.textSecondary)
                        .font(.subheadline)

                    Text("Ready to earn?")
                        .font(.title2.bold())
                        .foregroundStyle(Theme.textPrimary)
                }

                Spacer()

                Circle()
                    .fill(Theme.neon.opacity(0.20))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Theme.neon)
                    )
            }
        }
    }

    private func statTile(title: String, value: String, icon: String) -> some View {
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
