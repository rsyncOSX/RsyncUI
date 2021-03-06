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
