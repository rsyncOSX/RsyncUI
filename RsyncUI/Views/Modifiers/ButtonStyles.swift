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
/// A refined glass-like ButtonStyle that dims slightly when the control is disabled.
public struct RefinedGlassButtonStyle: ButtonStyle {
    public var cornerRadius: CGFloat = 10
    public var horizontalPadding: CGFloat = 16
    public var verticalPadding: CGFloat = 10
    public var font: Font = .headline

    /// How much to dim the button when disabled (0.0 - 1.0)
    public var disabledOpacity: Double = 0.6
    /// Optional small brightness shift when disabled (negative darkens slightly)
    public var disabledBrightness: Double = -0.02

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    public init(
        cornerRadius: CGFloat = 10,
        horizontalPadding: CGFloat = 16,
        verticalPadding: CGFloat = 10,
        font: Font = .headline,
        disabledOpacity: Double = 0.6,
        disabledBrightness: Double = -0.02
    ) {
        self.cornerRadius = cornerRadius
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.font = font
        self.disabledOpacity = disabledOpacity
        self.disabledBrightness = disabledBrightness
    }

    public func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let enabled = isEnabled

        // base shadow color, will be dimmed when disabled
        let baseShadow = colorScheme == .dark ? Color.glassShadowDark : Color.glassShadowLight
        let shadowOpacityMultiplier = enabled ? 1.0 : 0.45

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
            // Shadow reacts to press (press sinks the button). Reduce shadow when disabled.
            .shadow(
                color: baseShadow.opacity(shadowOpacityMultiplier),
                radius: pressed ? 2 : (enabled ? 8 : 3),
                x: 0,
                y: pressed ? 1 : (enabled ? 6 : 2)
            )
            // subtle scale on press, disabled controls won't animate or scale
            .scaleEffect((pressed && enabled) ? 0.975 : 1.0)
            // dimming and slight darken when disabled
            .opacity(enabled ? 1.0 : disabledOpacity)
            .brightness(enabled ? 0 : disabledBrightness)
            // animate press only when enabled and when user hasn't requested reduced motion
            .animation(reduceMotion || !enabled ? nil : .spring(response: 0.25, dampingFraction: 0.7), value: pressed)
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
