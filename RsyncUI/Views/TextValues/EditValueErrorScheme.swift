//
//  Edit.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 08/07/2025.
//

import SwiftUI

struct EditValueErrorScheme: View {
    @Environment(\.colorScheme) var colorScheme

    var myvalue: Binding<String>
    var mywidth: CGFloat?
    var myprompt: Text?
    var myerror: Bool

    var body: some View {
        TextField("", text: myvalue, prompt: myprompt)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .frame(width: mywidth, alignment: .trailing)
            .lineLimit(1)
            .foregroundColor(color(error: myerror))
    }

    init(_ width: CGFloat, _ str: String?, _ value: Binding<String>, _ error: Bool) {
        mywidth = width
        myvalue = value
        myprompt = Text(str ?? "")
        myerror = error
    }
    
    func color(error: Bool) -> Color {
        error == false ? .red : (colorScheme == .dark ? .white : .black)
    }
}
