//
//  WalletView.swift
//  AdmoiOS
//
//  Created by Eugene Cullen on 28/01/2026.
//
import SwiftUI

struct WalletView: View {
    // Demo values (replace with Firestore later)
    @State private var balance: Double = 0.00
    @State private var pending: Double = 0.00
    @State private var lifetime: Double = 0.00

    struct Txn: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let amount: Double
        let isCredit: Bool
    }

    @State private var transactions: [Txn] = [
        .init(title: "Ad share", subtitle: "Pending verification", amount: 0.25, isCredit: true),
        .init(title: "Ad share", subtitle: "Pending verification", amount: 0.40, isCredit: true),
        .init(title: "Payout", subtitle: "To bank (coming soon)", amount: 0.00, isCredit: false)
    ]

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(spacing: 14) {

                    GlowCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Wallet")
                                .font(.title2.bold())
                                .foregroundStyle(Theme.textPrimary)

                            HStack(spacing: 12) {
                                walletStat(title: "Balance", value: String(format: "£%.2f", balance), icon: "wallet.pass.fill")
                                walletStat(title: "Pending", value: String(format: "£%.2f", pending), icon: "clock.fill")
                            }

                            walletStat(title: "Lifetime earned", value: String(format: "£%.2f", lifetime), icon: "sparkles")

                            Button {
                                // TODO: payout flow
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .appSymbol(color: .black, size: 18, frame: Theme.iconFrame)
                                    Text("Withdraw (Coming soon)")
                                    Spacer()
                                }
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }
                    }

                    GlowCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent activity")
                                .foregroundStyle(Theme.textSecondary)
                                .font(.subheadline)

                            ForEach(transactions) { t in
                                HStack(spacing: 12) {
                                    Image(systemName: t.isCredit ? "plus.circle.fill" : "minus.circle.fill")
                                        .appSymbol(color: t.isCredit ? Theme.neon : Theme.textMuted)

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(t.title)
                                            .foregroundStyle(Theme.textPrimary)
                                            .font(.subheadline.weight(.semibold))
                                        Text(t.subtitle)
                                            .foregroundStyle(Theme.textSecondary)
                                            .font(.caption)
                                    }

                                    Spacer()

                                    Text("\(t.isCredit ? "+" : "-")£\(abs(t.amount), specifier: "%.2f")")
                                        .foregroundStyle(t.isCredit ? Theme.neon : Theme.textMuted)
                                        .font(.subheadline.weight(.bold))
                                }

                                Divider().overlay(Theme.neon.opacity(0.08))
                            }
                        }
                    }

                    Spacer(minLength: 20)
                }
                .padding()
            }
        }
        .navigationTitle("Wallet")
    }

    private func walletStat(title: String, value: String, icon: String) -> some View {
        GlowCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
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
}

