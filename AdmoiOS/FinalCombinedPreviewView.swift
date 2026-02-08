//
//  FinalCombinedPreviewView.swift
//  AdmoiOS
//
//  Created by Eugene Cullen on 06/02/2026.
//
import SwiftUI
import AVKit

struct FinalCombinedPreviewView: View {
    let combinedVideoURL: URL
    let storagePath: String

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {

                    GlowCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 10) {
                                Image(systemName: "sparkles.tv.fill")
                                    .appSymbol(color: Theme.neon)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Final Ad Created")
                                        .foregroundStyle(Theme.textPrimary)
                                        .font(.title2.bold())
                                    Text(storagePath)
                                        .foregroundStyle(Theme.textSecondary)
                                        .font(.caption)
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                            Text("Preview your composed vertical ad below.")
                                .foregroundStyle(Theme.textSecondary)
                                .font(.subheadline)
                        }
                    }

                    GlowCard {
                        VideoPlayer(player: AVPlayer(url: combinedVideoURL))
                            .frame(height: 520)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.corner))
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.corner)
                                    .stroke(Theme.neon.opacity(0.15), lineWidth: 1)
                            )
                    }

                    Spacer(minLength: 20)
                }
                .padding()
            }
        }
        .navigationTitle("Final Preview")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Theme.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}
