//
//  EditValue.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 25/02/2021.
//

import SwiftUI

struct EditValue: View {
    var myvalue: Binding<String>
    var mywidth: CGFloat?
    var myprompt: Text?

    var body: some View {
        TextField("", text: myvalue, prompt: myprompt)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .frame(width: mywidth, alignment: .trailing)
            .lineLimit(1)
    }

    init(_ width: CGFloat, _ str: String?, _ value: Binding<String>) {
        mywidth = width
        myvalue = value
        myprompt = Text(str ?? "")
    }
}

struct EditValueTwoLines: View {
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
                    .padding(4)
                    .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary).opacity(0.5))
                    .colorMultiply(.gray)
            }
            .disabled(true)
    }

    init(_ width: CGFloat, _ str: String?, _ value: Binding<String>) {
        mywidth = width
        myvalue = value
        myprompt = Text(str ?? "")
    }
}
