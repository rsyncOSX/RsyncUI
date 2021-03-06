//
//  EditValue.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 25/02/2021.
//

import SwiftUI

struct EditValue: View {
    var myvalue: Binding<String>
    var mytext: String?
    var mywidth: CGFloat?

    var body: some View {
        TextField(mytext ?? "", text: myvalue)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .frame(width: mywidth)
            .lineLimit(1)
    }

    init(_ width: CGFloat, _ text: String?, _ value: Binding<String>) {
        mywidth = width
        myvalue = value
        mytext = text
    }
}
