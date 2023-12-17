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

struct ToggleViewDefault: View {
    private var mytext: String?
    private var mybinding: Binding<Bool>

    var body: some View {
        HStack {
            Toggle(mytext ?? "", isOn: mybinding)
                .labelsHidden()
                .toggleStyle(CheckboxToggleStyle())
            Text(mytext ?? "")
                .foregroundColor(mybinding.wrappedValue ? .white : .gray)
                .toggleStyle(CheckboxToggleStyle())
        }
    }

    init(_ text: String, _ binding: Binding<Bool>) {
        mytext = text
        mybinding = binding
    }
}
