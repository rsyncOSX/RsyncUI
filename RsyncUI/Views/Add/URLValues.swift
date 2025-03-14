//
//  URLValues.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 14/03/2025.
//

import SwiftUI

struct URLValues: View {
    var myvalue: Binding<String>
    var mywidth: CGFloat?
    var myprompt: Text?

    var body: some View {
        TextField("", text: myvalue, prompt: myprompt)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .frame(width: mywidth, alignment: .trailing)
            .lineLimit(2)
            .frame(height: 40)
            .overlay {
                TextEditor(text: myvalue)
                    .foregroundColor(Color.gray)
                    .padding(4)
                    .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary).opacity(0.5))
                    .colorMultiply(.gray)
            }
    }

    init(_ width: CGFloat, _ str: String?, _ value: Binding<String>) {
        mywidth = width
        myvalue = value
        myprompt = Text(str ?? "")
    }
}
