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

    init(text: String, binding: Binding<Bool>) {
        mytext = text
        mybinding = binding
    }
}

struct DismissafterMessageView: View {
    private var dismissafter: Double
    private var mytext: String

    @State private var showtext: Bool = true

    var body: some View {
        if showtext {
            ZStack {
                RoundedRectangle(cornerRadius: 15).fill(Color.gray.opacity(0.3))
                Text(mytext)
                    .font(.title3)
                    .foregroundColor(Color.blue)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .allowsTightening(true)
                    .minimumScaleFactor(0.5)
            }
            .frame(height: 30, alignment: .center)
            .background(RoundedRectangle(cornerRadius: 25).stroke(Color.gray, lineWidth: 4))
            .onAppear(perform: {
                Task {
                    try await Task.sleep(seconds: dismissafter)
                    showtext = false
                }
            })
            .padding(100)
        }
    }

    init(dismissafter: Double, mytext: String) {
        self.dismissafter = dismissafter
        self.mytext = mytext
    }
}

struct MessageView: View {
    private var mytext: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15).fill(Color.gray.opacity(0.3))
            Text(mytext)
                .font(.caption2)
                .foregroundColor(Color.green)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .allowsTightening(false)
                .minimumScaleFactor(0.5)
        }
        .frame(height: 30, alignment: .center)
        .background(RoundedRectangle(cornerRadius: 25).stroke(Color.gray, lineWidth: 1))
        .padding()
        }

    init(mytext: String) {
        self.mytext = mytext
    }
}
