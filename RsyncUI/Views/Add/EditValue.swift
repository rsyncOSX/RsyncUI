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
                                .frame(height: 30)
                                .overlay {
                                    TextEditor(text: myvalue)
                                }
    }

    init(_ width: CGFloat, _ str: String?, _ value: Binding<String>) {
        mywidth = width
        myvalue = value
        myprompt = Text(str ?? "")
    }
}
