//
//  ToggleView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 18/02/2021.
//

import SwiftUI

struct ToggleView: View {
    private var mytext: String?
    private var mybinding: Binding<Bool>

    var body: some View {
        VStack {
            Text(mytext ?? "")
                .foregroundColor(mybinding.wrappedValue ? .white : .gray)
                .toggleStyle(SwitchToggleStyle(tint: .green))
            Toggle(mytext ?? "", isOn: mybinding)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .green))
        }.padding()
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(lineWidth: 1)
                    .foregroundColor(mybinding.wrappedValue ? .accentColor : .gray)
            )
    }

    init(_ text: String, _ binding: Binding<Bool>) {
        mytext = text
        mybinding = binding
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

struct ToggleViewNolabel: View {
    private var mybinding: Binding<Bool>

    var body: some View {
        HStack {
            Toggle("", isOn: mybinding)
                .labelsHidden()
                .toggleStyle(CheckboxToggleStyle())
        }
    }

    init(_ binding: Binding<Bool>) {
        mybinding = binding
    }
}
