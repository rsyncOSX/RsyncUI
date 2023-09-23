// MIT License
//
// Copyright (c) 2021 Elai Zuberman
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import Combine
import SwiftUI

// MARK: - Main View

public struct AlertToast: View {
    public enum BannerAnimation {
        case slide, pop
    }

    /// Determine how the alert will be display
    public enum DisplayMode: Equatable {
        /// Present at the center of the screen
        case alert

        /// Drop from the top of the screen
        case hud

        /// Banner from the bottom of the view
        case banner(_ transition: BannerAnimation)
    }

    /// Determine what the alert will display
    public enum AlertType: Equatable {
        /// Animated checkmark
        case complete(_ color: Color)

        /// Animated xmark
        case error(_ color: Color)

        /// System image from `SFSymbols`
        case systemImage(_ name: String, _ color: Color)

        /// Image from Assets
        case image(_ name: String, _ color: Color)

        /// Loading indicator (Circular)
        case loading

        /// Only text alert
        case regular
    }

    /// Customize Alert Appearance
    public enum AlertStyle: Equatable {
        case style(
            backgroundColor: Color? = nil,
            titleColor: Color? = nil,
            subTitleColor: Color? = nil,
            titleFont: Font? = nil,
            subTitleFont: Font? = nil
        )

        /// Get background color
        var backgroundColor: Color? {
            switch self {
            case let .style(backgroundColor: color, _, _, _, _):
                return color
            }
        }

        /// Get title color
        var titleColor: Color? {
            switch self {
            case let .style(_, color, _, _, _):
                return color
            }
        }

        /// Get subTitle color
        var subtitleColor: Color? {
            switch self {
            case let .style(_, _, color, _, _):
                return color
            }
        }

        /// Get title font
        var titleFont: Font? {
            switch self {
            case let .style(_, _, _, titleFont: font, _):
                return font
            }
        }

        /// Get subTitle font
        var subTitleFont: Font? {
            switch self {
            case let .style(_, _, _, _, subTitleFont: font):
                return font
            }
        }
    }

    /// The display mode
    /// - `alert`
    /// - `hud`
    /// - `banner`
    public var displayMode: DisplayMode = .alert

    /// What the alert would show
    /// `complete`, `error`, `systemImage`, `image`, `loading`, `regular`
    public var type: AlertType

    /// The title of the alert (`Optional(String)`)
    public var title: String? = nil

    /// The subtitle of the alert (`Optional(String)`)
    public var subTitle: String? = nil

    /// Customize your alert appearance
    public var style: AlertStyle? = nil

    /// Full init
    public init(
        displayMode: DisplayMode = .alert,
        type: AlertType,
        title: String? = nil,
        subTitle: String? = nil,
        style: AlertStyle? = nil
    ) {
        self.displayMode = displayMode
        self.type = type
        self.title = title
        self.subTitle = subTitle
        self.style = style
    }

    /// Short init with most used parameters
    public init(
        displayMode: DisplayMode,
        type: AlertType,
        title: String? = nil
    ) {
        self.displayMode = displayMode
        self.type = type
        self.title = title
    }

    /// Banner from the bottom of the view
    public var banner: some View {
        VStack {
            Spacer()

            // Banner view starts here
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    switch type {
                    case let .complete(color):
                        Image(systemName: "checkmark")
                            .foregroundColor(color)
                    case let .error(color):
                        Image(systemName: "xmark")
                            .foregroundColor(color)
                    case let .systemImage(name, color):
                        Image(systemName: name)
                            .foregroundColor(color)
                    case let .image(name, color):
                        Image(name)
                            .renderingMode(.template)
                            .foregroundColor(color)
                    case .loading:
                        ProgressView()
                    case .regular:
                        EmptyView()
                    }

                    Text(LocalizedStringKey(title ?? ""))
                        .font(style?.titleFont ?? Font.headline.bold())
                }

                if let subTitle = subTitle {
                    Text(LocalizedStringKey(subTitle))
                        .font(style?.subTitleFont ?? Font.subheadline)
                }
            }
            .multilineTextAlignment(.leading)
            .ifLet(of: style?.titleColor) { view, titleColor in
                view.foregroundColor(titleColor)
            }
            .padding()
            .frame(maxWidth: 400, alignment: .leading)
            .ifLet(of: style?.backgroundColor) { view, backgroundColor in
                view.background(backgroundColor)
            }
            .cornerRadius(10)
            .padding([.horizontal, .bottom])
        }
    }

    /// HUD View
    public var hud: some View {
        Group {
            HStack(spacing: 16) {
                switch type {
                case let .complete(color):
                    Image(systemName: "checkmark")
                        .hudModifier()
                        .foregroundColor(color)
                case let .error(color):
                    Image(systemName: "xmark")
                        .hudModifier()
                        .foregroundColor(color)
                case let .systemImage(name, color):
                    Image(systemName: name)
                        .hudModifier()
                        .foregroundColor(color)
                case let .image(name, color):
                    Image(name)
                        .hudModifier()
                        .foregroundColor(color)
                case .loading:
                    ProgressView()
                case .regular:
                    EmptyView()
                }

                if title != nil || subTitle != nil {
                    VStack(alignment: type == .regular ? .center : .leading, spacing: 2) {
                        if let title = title {
                            Text(LocalizedStringKey(title))
                                .font(style?.titleFont ?? Font.body.bold())
                                .multilineTextAlignment(.center)
                                .ifLet(of: style?.titleColor) { view, titleColor in
                                    view.foregroundColor(titleColor)
                                }
                        }
                        if let subTitle = subTitle {
                            Text(LocalizedStringKey(subTitle))
                                .font(style?.subTitleFont ?? Font.footnote)
                                .opacity(0.7)
                                .multilineTextAlignment(.center)
                                .ifLet(of: style?.subtitleColor) { view, subtitleColor in
                                    view.foregroundColor(subtitleColor)
                                }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .frame(minHeight: 50)
            .ifLet(of: style?.backgroundColor) { view, backgroundColor in
                view.background(backgroundColor)
            }
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.gray.opacity(0.2), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 6)
            .compositingGroup()
        }
        .padding(.top)
    }

    /// Alert View
    public var alert: some View {
        VStack {
            switch type {
            case let .complete(color):
                Spacer()
                AnimatedCheckmark(color: color)
                Spacer()
            case let .error(color):
                Spacer()
                AnimatedXmark(color: color)
                Spacer()
            case let .systemImage(name, color):
                Spacer()
                Image(systemName: name)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaledToFit()
                    .foregroundColor(color)
                    .padding(.bottom)
                Spacer()
            case let .image(name, color):
                Spacer()
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaledToFit()
                    .foregroundColor(color)
                    .padding(.bottom)
                Spacer()
            case .loading:
                ProgressView()
            case .regular:
                EmptyView()
            }

            VStack(spacing: type == .regular ? 8 : 2) {
                if let title = title {
                    Text(LocalizedStringKey(title))
                        .font(style?.titleFont ?? Font.body.bold())
                        .multilineTextAlignment(.center)
                        .ifLet(of: style?.titleColor) { view, titleColor in
                            view.foregroundColor(titleColor)
                        }
                }
                if let subTitle = subTitle {
                    Text(LocalizedStringKey(subTitle))
                        .font(style?.subTitleFont ?? Font.footnote)
                        .opacity(0.7)
                        .multilineTextAlignment(.center)
                        .ifLet(of: style?.subtitleColor) { view, subtitleColor in
                            view.foregroundColor(subtitleColor)
                        }
                }
            }
        }
        .padding()
        .if(type != .regular && type != .loading) {
            $0.frame(maxWidth: 175, maxHeight: 175, alignment: .center)
        }
        .ifLet(of: style?.backgroundColor) { view, backgroundColor in
            view.background(backgroundColor)
        }
        .cornerRadius(10)
    }

    /// Body init determine by `displayMode`
    public var body: some View {
        switch displayMode {
        case .alert:
            alert
        case .hud:
            hud
        case .banner:
            banner
        }
    }
}

private extension Image {
    func hudModifier() -> some View {
        renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 20, maxHeight: 20, alignment: .center)
    }
}
