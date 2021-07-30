//
//  Viewmodifiers.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 19/02/2021.
//

import Foundation
import SwiftUI

struct FixedTag: ViewModifier {
    var width: CGFloat = 0
    var alignment: Alignment = .leading
    func body(content: Content) -> some View {
        content
            .frame(minWidth: width, idealWidth: width, maxWidth: width,
                   minHeight: nil, idealHeight: nil, maxHeight: nil,
                   alignment: alignment)
            .lineLimit(1)
    }

    init(_ setwidth: CGFloat, _ setalignment: Alignment) {
        width = setwidth
        alignment = setalignment
    }
}

struct FlexTag: ViewModifier {
    var minwidth: CGFloat = 0
    var alignment: Alignment = .leading
    func body(content: Content) -> some View {
        content
            .lineLimit(1)
            .frame(minWidth: 0, idealWidth: nil, maxWidth: .infinity,
                   minHeight: nil, idealHeight: nil, maxHeight: nil,
                   alignment: alignment)
    }

    init(_ setwidth: CGFloat, _ setalignment: Alignment) {
        minwidth = setwidth
        alignment = setalignment
    }
}

struct Tagheading: ViewModifier {
    var font: Font = .title
    var alignment: Alignment = .leading
    func body(content: Content) -> some View {
        content
            .frame(alignment: alignment)
            .lineLimit(1)
            .font(font)
    }

    init(_ setfont: Font, _ setalignment: Alignment) {
        font = setfont
        alignment = setalignment
    }
}

struct GaugeProgressStyle: ProgressViewStyle {
    typealias ProgressViewStyle = ProgressViewStyleConfiguration

    var strokeColor = Color.accentColor
    var strokeWidth = 5.0

    func makeBody(configuration: ProgressViewStyle) -> some View {
        let fractionCompleted = configuration.fractionCompleted ?? 0

        return ZStack {
            // ZStack {
            Circle()
                .trim(from: 0, to: CGFloat(fractionCompleted))
                .stroke(
                    strokeColor,
                    style: StrokeStyle(
                        lineWidth: CGFloat(strokeWidth),
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear, value: fractionCompleted)
            // if fractionCompleted > 0 {
            //    Text(String(Int(fractionCompleted * 100)) + "%")
            // }
            // }
        }
    }
}
