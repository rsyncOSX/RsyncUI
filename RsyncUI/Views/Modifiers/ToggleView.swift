//
//  ToggleView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 18/02/2021.
//

import SwiftUI

struct ToggleView: View {
    @StateObject var usersettings = ObserveableReference()

    private var mytext: String?
    private var mybinding: Binding<Bool>

    var body: some View {
        VStack {
            Text(mytext ?? "")
                .foregroundColor(mybinding.wrappedValue ? .green : .gray)
                .toggleStyle(SwitchToggleStyle(tint: .red))
            Toggle(mytext ?? "", isOn: mybinding)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .red))
        }.padding()
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(lineWidth: 2)
                    .foregroundColor(mybinding.wrappedValue ? .green : .gray)
            )
    }

    init(_ text: String, _ binding: Binding<Bool>) {
        mytext = text
        mybinding = binding
    }
}
