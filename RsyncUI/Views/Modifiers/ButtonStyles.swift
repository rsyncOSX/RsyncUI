//
//  ButtonStyles.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 24/03/2021.
//

import SwiftUI

struct HelpButtonStyle: ButtonStyle {
    let redorwhitebutton: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(redorwhitebutton ? .red : .blue)
            .contentShape(Capsule())
    }
}

@available(macOS 26.0, *)
fileprivate extension Color {
    @MainActor static var glassBorderLight = Color.white.opacity(0.35)
    @MainActor static var glassBorderDark = Color.white.opacity(0.12)
    @MainActor static var glassShadowLight = Color.black.opacity(0.10)
    @MainActor static var glassShadowDark = Color.black.opacity(0.45)
}

@available(macOS 26.0, *)
public struct RefinedGlassButtonStyle: ButtonStyle {
    public var cornerRadius: CGFloat = 10
    public var horizontalPadding: CGFloat = 16
    public var verticalPadding: CGFloat = 10
    public var font: Font = .headline

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        cornerRadius: CGFloat = 10,
        horizontalPadding: CGFloat = 16,
        verticalPadding: CGFloat = 10,
        font: Font = .headline
    ) {
        self.cornerRadius = cornerRadius
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.font = font
    }

    public func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed

        configuration.label
            .font(font)
            .foregroundColor(.primary)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(
                ZStack {
                    // soft material base
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)

                    // subtle top gloss (kept to the upper area)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(colorScheme == .dark ? 0.06 : 0.18),
                                         Color.white.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                        .blendMode(.overlay)
                        .mask(
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .padding(.bottom, cornerRadius * 0.35)
                        )

                    // fine border
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.glassBorderDark : Color.glassBorderLight, lineWidth: 1)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            // Shadow reacts to press (press sinks the button)
            .shadow(color: colorScheme == .dark ? Color.glassShadowDark : Color.glassShadowLight,
                    radius: pressed ? 2 : 8, x: 0, y: pressed ? 1 : 6)
            // subtle scale on press
            .scaleEffect(pressed ? 0.975 : 1.0)
            .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.7), value: pressed)
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
