//
//  EditValueScheme.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 25/02/2021.
//

import SwiftUI

struct EditValueScheme: View {
    @Environment(\.colorScheme) var colorScheme

    var myvalue: Binding<String>
    var mywidth: CGFloat?
    var myprompt: Text?

    var body: some View {
        TextField("", text: myvalue, prompt: myprompt)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .frame(width: mywidth, alignment: .trailing)
            .lineLimit(1)
            .foregroundColor(colorScheme == .dark ? .white : .black)
    }

    init(_ width: CGFloat, _ str: String?, _ value: Binding<String>) {
        mywidth = width
        myvalue = value
        myprompt = Text(str ?? "")
    }
}

struct EditValueNoScheme: View {
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

struct EditValueError: View {
    var myvalue: Binding<String>
    var mywidth: CGFloat?

    var body: some View {
        TextField("", text: myvalue)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .frame(width: mywidth, alignment: .trailing)
            .lineLimit(1)
            .foregroundColor(Color.red)
    }

    init(_ width: CGFloat, _ value: Binding<String>) {
        mywidth = width
        myvalue = value
    }
}
