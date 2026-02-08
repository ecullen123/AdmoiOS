//
//  Theme.swift
//  AdmoiOS
//
//  Created by Eugene Cullen on 27/01/2026.
//
import SwiftUI

enum Theme {
    // Core palette
    static let bg = Color.black
    static let surface = Color(red: 0.06, green: 0.07, blue: 0.08)          // near-black card
    static let surface2 = Color(red: 0.10, green: 0.11, blue: 0.12)         // elevated
    static let neon = Color(red: 0.20, green: 0.95, blue: 0.50)             // neon green
    static let neonSoft = Color(red: 0.20, green: 0.95, blue: 0.50).opacity(0.20)

    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.70)
    static let textMuted = Color.white.opacity(0.50)

    // Gradients
    static let backgroundGradient = LinearGradient(
        colors: [
            Color.black,
            Color(red: 0.03, green: 0.05, blue: 0.04),
            Color.black
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let neonGradient = LinearGradient(
        colors: [neon, neon.opacity(0.70)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Layout
    static let corner: CGFloat = 16

    // Icon sizing (key to alignment)
    static let iconFrame: CGFloat = 28
    static let iconSize: CGFloat = 19
}

struct AppBackground: View {
    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()
            RadialGradient(
                colors: [Theme.neonSoft, .clear],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 380
            )
            .ignoresSafeArea()
        }
    }
}

struct GlowCard<Content: View>: View {
    var content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: Theme.corner)
                    .fill(Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.corner)
                            .stroke(Theme.neon.opacity(0.20), lineWidth: 1)
                    )
            )
            .shadow(color: Theme.neon.opacity(0.12), radius: 18, x: 0, y: 10)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.black)
            .padding(.vertical, 12)
            .padding(.horizontal, 14) // ✅ add consistent left/right padding
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.neonGradient)
                    .opacity(configuration.isPressed ? 0.85 : 1.0)
            )
            .shadow(color: Theme.neon.opacity(0.25), radius: 14, x: 0, y: 10)
            .scaleEffect(configuration.isPressed ? 0.99 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Theme.textPrimary)
            .padding(.vertical, 12)
            .padding(.horizontal, 14) // ✅ add consistent left/right padding
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.surface2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Theme.neon.opacity(0.18), lineWidth: 1)
                    )
                    .opacity(configuration.isPressed ? 0.90 : 1.0)
            )
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct NeonTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.surface2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Theme.neon.opacity(0.22), lineWidth: 1)
                    )
            )
            .foregroundStyle(Theme.textPrimary)
    }
}

extension View {
    func neonField() -> some View { modifier(NeonTextFieldStyle()) }
}

// MARK: - SF Symbol alignment helper (THIS fixes “icons look off”)

extension Image {
    /// Applies consistent sizing + centering to SF Symbols so they align with text nicely.
    func appSymbol(
        color: Color = Theme.neon,
        size: CGFloat = Theme.iconSize,
        frame: CGFloat = Theme.iconFrame,
        weight: Font.Weight = .semibold
    ) -> some View {
        self
            .font(.system(size: size, weight: weight))
            .symbolRenderingMode(.hierarchical)
            .frame(width: frame, height: frame, alignment: .center)
            .foregroundStyle(color)
    }
}
