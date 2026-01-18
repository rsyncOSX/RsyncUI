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
private extension Color {
    @MainActor static var glassBorderLight = Color.white.opacity(0.35)
    @MainActor static var glassBorderDark = Color.white.opacity(0.12)
    @MainActor static var glassShadowLight = Color.black.opacity(0.10)
    @MainActor static var glassShadowDark = Color.black.opacity(0.45)
}

/// A refined glass-like ButtonStyle with sustained pressure animation
@available(macOS 26.0, *)
public struct RefinedGlassButtonStyle: ButtonStyle {
    public var cornerRadius: CGFloat = 10
    public var horizontalPadding: CGFloat = 16
    public var verticalPadding: CGFloat = 10
    public var font: Font = .headline

    public var disabledOpacity: Double = 0.6
    public var disabledBrightness: Double = -0.02

    /// Duration to hold the pressed animation after release (in seconds)
    public var pressureHoldDuration: Double = 0.3

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    public init(
        cornerRadius: CGFloat = 10,
        horizontalPadding: CGFloat = 16,
        verticalPadding: CGFloat = 10,
        font: Font = .headline,
        disabledOpacity: Double = 0.6,
        disabledBrightness: Double = -0.02,
        pressureHoldDuration: Double = 0.3
    ) {
        self.cornerRadius = cornerRadius
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.font = font
        self.disabledOpacity = disabledOpacity
        self.disabledBrightness = disabledBrightness
        self.pressureHoldDuration = pressureHoldDuration
    }

    public func makeBody(configuration: Configuration) -> some View {
        PressureAnimatedButton(
            configuration: configuration,
            cornerRadius: cornerRadius,
            horizontalPadding: horizontalPadding,
            verticalPadding: verticalPadding,
            font: font,
            disabledOpacity: disabledOpacity,
            disabledBrightness: disabledBrightness,
            pressureHoldDuration: pressureHoldDuration,
            colorScheme: colorScheme,
            reduceMotion: reduceMotion,
            isEnabled: isEnabled
        )
    }
}

@available(macOS 26.0, *)
private struct PressureAnimatedButton: View {
    let configuration: ButtonStyle.Configuration
    let cornerRadius: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let font: Font
    let disabledOpacity: Double
    let disabledBrightness: Double
    let pressureHoldDuration: Double
    let colorScheme: ColorScheme
    let reduceMotion: Bool
    let isEnabled: Bool

    @State private var isAnimatingPressure = false

    var body: some View {
        let pressed = configuration.isPressed

        // Use the sustained pressure state instead of immediate press
        let showPressedState = isAnimatingPressure || pressed

        let baseShadow = colorScheme == .dark ? Color.glassShadowDark : Color.glassShadowLight
        let shadowOpacityMultiplier = isEnabled ? 1.0 : 0.45

        configuration.label
            .font(font)
            .foregroundColor(.primary)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)

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

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.glassBorderDark : Color.glassBorderLight, lineWidth: 1)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(
                color: baseShadow.opacity(shadowOpacityMultiplier),
                radius: showPressedState ? 2 : (isEnabled ? 8 : 3),
                x: 0,
                y: showPressedState ? 1 : (isEnabled ? 6 : 2)
            )
            .scaleEffect((showPressedState && isEnabled) ? 0.975 : 1.0)
            .opacity(isEnabled ? 1.0 : disabledOpacity)
            .brightness(isEnabled ? 0 : disabledBrightness)
            .animation(reduceMotion || !isEnabled ? nil : .spring(response: 0.25, dampingFraction: 0.7), value: showPressedState)
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .onChange(of: pressed) { _, newValue in
                if newValue, !isAnimatingPressure {
                    // Button was just pressed
                    isAnimatingPressure = true
                } else if !newValue, isAnimatingPressure {
                    // Button was released - hold the animation for specified duration
                    Task {
                        try? await Task.sleep(for: .seconds(pressureHoldDuration))
                        isAnimatingPressure = false
                    }
                }
            }
    }
}

struct ConditionalGlassButton: View {
    @Environment(\.colorScheme) var colorScheme

    let systemImage: String
    let text: String?
    let helpText: String
    let role: ButtonRole?
    var textcolor: Bool = false
    let action: () -> Void

    init(systemImage: String, text: String? = nil, helpText: String, role: ButtonRole? = nil, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.text = text
        self.helpText = helpText
        self.role = role
        self.action = action
    }

    var body: some View {
        if #available(macOS 26.0, *) {
            if systemImage.isEmpty {
                Button(role: role, action: action) {
                    if let text {
                        Text(text)
                            .foregroundColor(textcolor ? .green : (colorScheme == .dark ? .white : .black))
                    }
                }
                .buttonStyle(RefinedGlassButtonStyle())
                .help(helpText)
            } else {
                Button(role: role, action: action) {
                    Label {
                        if let text {
                            Text(text)
                                .foregroundColor(textcolor ? .green : (colorScheme == .dark ? .white : .black))
                        }
                    } icon: {
                        Image(systemName: systemImage)
                    }
                }
                .buttonStyle(RefinedGlassButtonStyle())
                .help(helpText)
            }
        } else {
            // For older macOS versions, use .cancel for close buttons, or nil for others
            let fallbackRole: ButtonRole? = {
                if #available(macOS 26.0, *) {
                    return role == .close ? .cancel : role
                }
                return role
            }()

            if systemImage.isEmpty {
                Button(role: role, action: action) {
                    if let text {
                        Text(text)
                            .foregroundColor(textcolor ? .green : (colorScheme == .dark ? .white : .black))
                    }
                }
                .buttonStyle(.borderedProminent)
                .help(helpText)
            } else {
                Button(role: fallbackRole, action: action) {
                    Label {
                        if let text {
                            Text(text)
                                .foregroundColor(textcolor ? .green : (colorScheme == .dark ? .white : .black))
                        }
                    } icon: {
                        Image(systemName: systemImage)
                    }
                }
                .buttonStyle(.borderedProminent)
                .help(helpText)
            }
        }
    }
}
