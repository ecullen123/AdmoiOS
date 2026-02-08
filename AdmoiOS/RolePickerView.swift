import SwiftUI
import UIKit

struct RolePickerView: View {
    var onPick: (UserRole) -> Void

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 20) {

                // App Logo (with fallback if asset is not found)
                if UIImage(named: "admo_logo") != nil {
                    Image("admo_logo")
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                        .shadow(color: Theme.neon.opacity(0.35), radius: 25, x: 0, y: 12)
                        .padding(.top, 20)
                } else {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(Theme.neon)
                        .padding(.top, 20)

                    Text("Logo not found: admo_logo")
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                }

                VStack(spacing: 6) {
                    Text("AdMo")
                        .font(.system(size: 34, weight: .heavy))
                        .foregroundStyle(Theme.textPrimary)

                    Text("Earn. Advertise. Scale.")
                        .foregroundStyle(Theme.textSecondary)
                }

                GlowCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Choose how you want to sign in")
                            .foregroundStyle(Theme.textSecondary)
                            .font(.subheadline)

                        VStack(spacing: 12) {
                            ForEach(UserRole.allCases) { role in
                                Button {
                                    onPick(role)
                                } label: {
                                    HStack(alignment: .center, spacing: 12) {
                                        Image(systemName: role.systemImage)
                                            .appSymbol(color: Theme.neon)

                                        Text("Continue as \(role.displayName)")
                                            .foregroundStyle(Theme.textPrimary)

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .appSymbol(color: Theme.textMuted, size: 14, frame: 18, weight: .semibold)
                                    }
                                }
                                .buttonStyle(SecondaryButtonStyle())
                            }
                        }
                    }
                }

                Spacer()

                Text("Black & Green mode engaged.")
                    .font(.caption)
                    .foregroundStyle(Theme.textMuted)
            }
            .padding()
        }
        .navigationTitle("Welcome")
    }
}
